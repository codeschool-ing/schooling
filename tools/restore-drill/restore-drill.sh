#!/usr/bin/env bash
# ==========================================================================
# Schooling — restore a backup, prove it, throw it away
#
# THE ROADMAP DOES NOT ASK FOR BACKUPS. It asks for a backup that has been
# RESTORED, and the difference is the whole reason this file exists.
# `infra/database.tf` declares backups and point-in-time recovery, and a
# declaration is a belief: it says the console shows green, not that the bytes
# come back. Every backup story that ended badly ended with somebody finding
# out at restore time.
#
# So this runs the restore for real, on the live data, and answers a question
# that can be wrong: is the restored database the same database?
#
# # IT NEVER TOUCHES THE LIVE INSTANCE
#
# The restore goes to a NEW instance, cloned from the transaction log, and the
# live one is only ever read. Restoring over production to see whether the
# backup works is the one way to turn a drill into the outage it was meant to
# prevent — the restore is the destructive operation, and it destroys the
# thing you would need if the restore turned out to be bad.
#
# There is no staging environment to hold the clone either, which is deliberate:
# a permanent second instance is a permanent second bill and a permanent second
# copy of everybody's data. This one lives for as long as the check takes and
# is deleted in a trap, including when the check fails.
#
# # WHAT "VERIFIED" MEANS
#
# `verify.sql` runs against both instances and the answer is whether the two
# reports are identical — schema, indexes, constraints, migrations applied,
# a row count per table, and the school. See that file for why it is written as
# a report rather than as a list of expectations.
#
# BOTH SIDES ARE ONE MOMENT, and that is what makes "identical" an honest
# demand rather than a wish. The live database is read FIRST, in a single
# REPEATABLE READ snapshot; the instant of that snapshot comes from the
# database's own clock; and the clone is restored to exactly it.
#
# The first version compared a clone from forty minutes ago against a live
# database read now, and every visitor who arrived in between counted as a
# difference. It failed a perfectly good restore over six rows of ordinary
# traffic, which is the beginning of a tolerance, and a tolerance is the
# beginning of a check nobody believes. This closes the window instead of
# widening the threshold.
#
# ONE EXCEPTION SURVIVES, and it is named in the output: point-in-time recovery
# resolves to the second and a snapshot does not, so a row written in the same
# second as the snapshot can land on one side only. It shows as one or two rows
# on a single table and it does not repeat — a real fault does.
#
# # RUNNING IT
#
#   tools/restore-drill/restore-drill.sh                    # clone, verify, destroy
#   tools/restore-drill/restore-drill.sh --keep             # leave the clone up
#   tools/restore-drill/restore-drill.sh --attach <clone>   # one that already exists
#
# `--attach` is for the run that died after the slow part. Building the clone is
# fifteen minutes; verifying it is seconds. It still gets destroyed at the end —
# the flag changes where the clone came from, not what happens to it.
#
# From Cloud Shell, or anywhere with `gcloud`, `psql` and credentials that can
# administer Cloud SQL and read the database secret. NOT from CI: it costs
# money, it takes a quarter of an hour, and it needs production access — three
# reasons a scheduled run would be turned off within a month. It is a drill,
# and a drill is something a person does on purpose.
#
# It reaches both instances through the Cloud SQL Auth Proxy, which is the same
# path `infra/database.tf` describes for a person. `gcloud sql connect` would
# be shorter and would add this machine's address to the instance's authorised
# networks to do it — a change to production, and Terraform drift, in order to
# run a read-only check.
# ==========================================================================

set -Eeuo pipefail

# `|| true` so that a machine without gcloud still reaches the preflight check
# below and is told what is missing. Without it, `set -e` kills the script on
# this line — including `--help`, which needs no gcloud at all.
PROJECT="${PROJECT:-$(gcloud config get-value project 2>/dev/null || true)}"
REGION="${REGION:-us-central1}"
SOURCE="${SOURCE:-schooling}"
SECRET="${SECRET:-schooling-database-url}"
DATABASE="${DATABASE:-schooling}"
DBUSER="${DBUSER:-schooling}"
KEEP=0
ATTACH=""

# Pinned, because a drill that downloads whatever is newest is a drill that can
# fail for a reason that has nothing to do with the backup.
PROXY_VERSION="v2.14.3"

while [ $# -gt 0 ]; do
  case "$1" in
    --instance) SOURCE="$2"; shift 2 ;;
    --region)   REGION="$2"; shift 2 ;;
    --keep)     KEEP=1; shift ;;
    --attach)   ATTACH="$2"; shift 2 ;;
    -h|--help)  sed -n '3,72p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="$(mktemp -d)"
CLONE=""
PROXY_PIDS=()

say() { printf '\n\033[1m%s\033[0m\n' "$*"; }

# ---------- cleanup ----------
#
# A trap and not a last line, because the reason to be careful is the run that
# does not reach the last line. A failed verification is exactly when an
# unattended db-f1-micro gets left running with a full copy of production on it.
cleanup() {
  local code=$?
  set +e

  # Two of them now: one opened before the clone exists, one after.
  for pid in ${PROXY_PIDS+"${PROXY_PIDS[@]}"}; do
    kill "$pid" 2>/dev/null
    wait "$pid" 2>/dev/null
  done

  if [ -n "$CLONE" ]; then
    if [ "$KEEP" = "1" ]; then
      say "The clone is still up, by request: $CLONE"
      echo "Delete it when you are done — it is a full copy of production:"
      echo "  gcloud sql instances patch $CLONE --no-deletion-protection --quiet"
      echo "  gcloud sql instances delete $CLONE --quiet"
    else
      # THE NAME IS CHECKED BEFORE THE DELETE. This script is the only thing
      # that makes a name in this shape, so a variable that got mangled cannot
      # aim `instances delete` at the live instance.
      if [[ "$CLONE" =~ ^.+-drill-[0-9]{14}$ ]]; then
        say "Destroying the clone: $CLONE"

        # NOTHING CAN BE DELETED WHILE SOMETHING ELSE IS HAPPENING TO IT. Cloud
        # SQL runs one operation per instance and refuses the rest with a 409,
        # and the very case this trap exists for — a run that died while the
        # clone was still being built — is the case where an operation is
        # always in flight. The first version went straight to `delete`, got
        # its 409, and left a full copy of production running.
        for _ in $(seq 1 120); do
          gcloud sql operations list --instance="$CLONE" --filter='status != DONE' \
            --format='value(name)' 2>/dev/null | grep -q . || break
          sleep 15
        done

        # Cloning copies the source's settings, deletion protection included,
        # so the flag has to come off before the instance can go.
        gcloud sql instances patch "$CLONE" --no-deletion-protection --quiet >/dev/null 2>&1

        # And retried, because "no operation in flight" is true until the
        # moment another one starts.
        for attempt in 1 2 3 4 5; do
          gcloud sql instances delete "$CLONE" --quiet && break
          echo "delete refused (attempt $attempt); waiting" >&2
          sleep 20
        done
      else
        echo "REFUSING to delete '$CLONE': not a name this script makes." >&2
        echo "Delete it by hand once you have checked what it is." >&2
      fi
    fi
  fi

  rm -rf "$WORK"
  exit $code
}
trap cleanup EXIT

# ---------- preflight ----------
#
# EVERYTHING CHEAP THAT CAN FAIL, FAILS HERE — before the fifteen minutes and
# not after them. That ordering was learned: a run got all the way through
# building a clone and then died because a port was busy, and the clone was
# destroyed with nothing checked. None of the missing pieces needed the clone
# to exist, and none of them took a second to find.
#
# The rule this leaves behind: if a step does not need the restored instance,
# it belongs above the restore.

for tool in gcloud psql diff curl; do
  command -v "$tool" >/dev/null || { echo "missing: $tool" >&2; exit 1; }
done
[ -n "$PROJECT" ] || { echo "no project set: gcloud config set project …" >&2; exit 1; }

say "Drilling $SOURCE in $PROJECT ($REGION)"

# A PORT THAT IS FREE, FOUND RATHER THAN ASSUMED. 5433 and 5434 were written in
# as constants and one of them was already held — by a `cloud-sql-proxy` some
# earlier session had left running, which is not an unusual thing to find on a
# machine somebody works on. A tool that only runs on a tidy machine is a tool
# that fails on the day it is needed.
free_port() {
  local port
  for port in $(seq "$1" "$(($1 + 100))"); do
    # A refused connection means nothing is listening, which is what free means.
    if ! (exec 3<>"/dev/tcp/127.0.0.1/$port") 2>/dev/null; then
      echo "$port"
      return 0
    fi
  done
  return 1
}

PORT_LIVE="$(free_port 5433)" || { echo "no free port near 5433" >&2; exit 1; }
PORT_CLONE="$(free_port "$((PORT_LIVE + 1))")" || { echo "no second free port" >&2; exit 1; }

# The proxy binary, and the password. Neither needs a clone, and discovering
# that a secret cannot be read is worth discovering immediately.
PROXY="$(command -v cloud-sql-proxy || true)"
if [ -z "$PROXY" ]; then
  ARCH="$(uname -m)"
  case "$ARCH" in
    x86_64) ARCH=amd64 ;;
    aarch64) ARCH=arm64 ;;
    *) echo "no proxy build for $ARCH; install cloud-sql-proxy yourself" >&2; exit 1 ;;
  esac
  say "Fetching the Cloud SQL Auth Proxy $PROXY_VERSION"
  PROXY="$WORK/cloud-sql-proxy"
  curl -sSL -o "$PROXY" \
    "https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/$PROXY_VERSION/cloud-sql-proxy.linux.$ARCH"
  chmod +x "$PROXY"
fi

# The clone carries the source's roles and their passwords, so one secret opens
# both. It is read into a variable and never printed: `set -x` on this script
# would be a password in a terminal and in whatever keeps that terminal's
# scrollback.
URL="$(gcloud secrets versions access latest --secret="$SECRET")"
PREFIX="postgres://${DBUSER}:"
case "$URL" in
  "$PREFIX"*) ;;
  # A SILENT WRONG ANSWER IS THE FAILURE TO AVOID: `${URL#prefix}` leaves the
  # string untouched when the prefix does not match, so an unrecognised URL
  # would become a "password" that is really the whole connection string, and
  # the drill would fail at the login prompt with no idea why.
  *) echo "$SECRET does not start with $PREFIX — cannot read the password out of it" >&2; exit 1 ;;
esac
PASSWORD="${URL#"$PREFIX"}"
PASSWORD="${PASSWORD%%@*}"
unset URL
[ -n "$PASSWORD" ] || { echo "no password between ':' and '@' in $SECRET" >&2; exit 1; }
export PGPASSWORD="$PASSWORD"

# ATTACHING TO A CLONE THAT ALREADY EXISTS. Building one costs fifteen minutes,
# so a run that died after the clone was made should not have to pay for it
# again — and the first one did exactly that. The instance is still destroyed at
# the end: this changes where the clone came from, not what happens to it.
if [ -n "$ATTACH" ]; then
  if [[ ! "$ATTACH" =~ ^.+-drill-[0-9]{14}$ ]]; then
    echo "--attach takes a clone this script made, named …-drill-<timestamp>." >&2
    echo "It is destroyed at the end, so it will not take any other name." >&2
    exit 2
  fi
  CLONE="$ATTACH"
  WHEN="(unknown: this clone was made by an earlier run)"
  say "Attaching to $CLONE"
fi

# POINT-IN-TIME RECOVERY NEEDS A BACKUP TO RECOVER FROM. The transaction log is
# a delta against the last full backup, so an instance created after the last
# backup window has PITR enabled and nothing to apply it to. Saying that here
# beats reading it out of an API error.
if [ -z "$ATTACH" ] && ! gcloud sql backups list --instance="$SOURCE" --limit=1 --format='value(id)' | grep -q .; then
  cat >&2 <<EOF

There are no backups of $SOURCE yet, so there is nothing to restore.

Backups run in the window declared in infra/database.tf. If the instance was
created after today's window, wait for the next one — or take one now and run
this again in a few minutes:

  gcloud sql backups create --instance=$SOURCE

EOF
  exit 1
fi

SOURCE_CONN="$(gcloud sql instances describe "$SOURCE" --format='value(connectionName)')"

# A proxy, a wait, and a report. Used twice: once for the live instance before
# the clone exists, once for the clone after it does.
open_proxy() {
  "$PROXY" "${1}?port=${2}" >>"$WORK/proxy.log" 2>&1 &
  PROXY_PIDS+=($!)

  for _ in $(seq 1 60); do
    psql -h 127.0.0.1 -p "$2" -U "$DBUSER" -d "$DATABASE" -qtAXc 'SELECT 1' >/dev/null 2>&1 && return 0
    sleep 2
  done

  echo "$1 did not answer through the proxy after two minutes." >&2
  echo "the proxy said:" >&2
  cat "$WORK/proxy.log" >&2
  return 1
}

report() {
  psql -h 127.0.0.1 -p "$1" -U "$DBUSER" -d "$DATABASE" \
       -qtAX -v ON_ERROR_STOP=1 -f "$HERE/verify.sql"
}

# ---------- the live snapshot, and it comes first ----------
#
# THE TWO SIDES HAVE TO BE THE SAME MOMENT. They were not: live used to be read
# at the END, some forty minutes after the point the clone was restored to, so
# every visitor who arrived in between showed up as a difference — and the drill
# could not tell that from a restore that had lost rows. The first real run
# against production ended with `events` and `visitors` six rows apart and a
# verdict of failure on a restore that was perfectly good.
#
# The fix is not a tolerance. It is reading the live database FIRST, in one
# REPEATABLE READ snapshot, taking the instant of that snapshot from the
# database's own clock, and restoring the clone to exactly it. Then identical is
# the honest expectation again — with students writing, with crawlers arriving,
# with anything happening — because the two reports describe one instant.
say "Reading the live database, in one snapshot"
open_proxy "$SOURCE_CONN" "$PORT_LIVE"
report "$PORT_LIVE" >"$WORK/live.txt"

SNAPSHOT="$(sed -n 's/^snapshot|//p' "$WORK/live.txt")"
[ -n "$SNAPSHOT" ] || { echo "verify.sql did not report the snapshot instant" >&2; exit 1; }
echo "the live database as it was at $SNAPSHOT"

# ---------- the restore ----------

if [ -z "$ATTACH" ]; then
  WHEN="$SNAPSHOT"
  CLONE="${SOURCE}-drill-$(date -u +%Y%m%d%H%M%S)"

  # A POINT IN TIME HAS TO BE PAST, and "past" is the API's opinion rather than
  # ours. The snapshot is seconds old when we get here, so wait until there is
  # no argument to have.
  while [ "$(( $(date -u +%s) - $(date -u -d "$SNAPSHOT" +%s) ))" -lt 120 ]; do
    sleep 5
  done

  say "Cloning to $CLONE, as of $WHEN"
  echo "This is the slow part: a new instance is built from the last backup and"
  echo "the transaction log replayed onto it. Fifteen minutes is normal."

  # --async AND OUR OWN WAIT, because `gcloud sql instances clone` waits with a
  # deadline of its own and then GIVES UP ON WATCHING — printing
  #
  #   ERROR: … Operation … is taking longer than expected
  #
  # which is not the clone failing. The clone carries on and finishes; only the
  # watching stopped. Under `set -e` that non-zero exit killed the first run of
  # this script mid-drill, and the trap then tried to delete an instance that
  # was still being built.
  #
  # So: start it, get the operation, and wait on our own terms. `describe` in a
  # loop rather than `operations wait --timeout=unlimited` — one flag fewer to
  # be wrong about fifteen minutes into something.
  OPERATION="$(gcloud sql instances clone "$SOURCE" "$CLONE" \
    --point-in-time="$WHEN" --async --format='value(name)')"
  echo "operation: $OPERATION"

  for _ in $(seq 1 240); do
    STATUS="$(gcloud sql operations describe "$OPERATION" --format='value(status)' 2>/dev/null)"
    [ "$STATUS" = "DONE" ] && break
    printf '.'
    sleep 15
  done
  echo

  [ "$STATUS" = "DONE" ] || { echo "the clone is still running after an hour: $OPERATION" >&2; exit 1; }

  FAILED="$(gcloud sql operations describe "$OPERATION" --format='value(error.errors[0].message)')"
  [ -z "$FAILED" ] || { echo "the clone failed: $FAILED" >&2; exit 1; }
fi

CLONE_CONN="$(gcloud sql instances describe "$CLONE" --format='value(connectionName)')"

# ---------- and the same question, of the clone ----------

say "Reading the clone"
open_proxy "$CLONE_CONN" "$PORT_CLONE"
report "$PORT_CLONE" >"$WORK/clone.txt"

# THE ONE LINE THAT IS ALLOWED TO DIFFER. The clone answers with the moment IT
# was read, which is now, rather than the moment it holds.
sed -i '/^snapshot|/d' "$WORK/live.txt" "$WORK/clone.txt"

echo "live:  $(wc -l <"$WORK/live.txt") lines"
echo "clone: $(wc -l <"$WORK/clone.txt") lines"

if diff -u "$WORK/live.txt" "$WORK/clone.txt" >"$WORK/diff.txt"; then
  say "RESTORED AND VERIFIED"
  echo "instance:      $CLONE"
  echo "point in time: $WHEN"
  echo "tables:        $(grep -c '^rows|' "$WORK/live.txt")"
  echo "rows:          $(awk -F'|' '/^rows\|/ {n += $3} END {print n}' "$WORK/live.txt")"
  echo "migrations:    $(grep -c '^migration|' "$WORK/live.txt")"
  grep '^tenant|' "$WORK/live.txt" | sed 's/^tenant|/school:        /'
  grep '^domain|' "$WORK/live.txt" | sed 's/^domain|/host:          /'
  RESULT=0
else
  say "THE CLONE IS NOT THE SAME DATABASE"
  cat "$WORK/diff.txt"
  echo
  echo "Left is the live database at $SNAPSHOT."
  echo
  if [ -n "$ATTACH" ]; then
    echo "Right is a clone an earlier run built, and NOTHING HERE KNOWS WHAT"
    echo "INSTANT IT HOLDS — so the row counts are not comparable and only the"
    echo "structural lines are a verdict. For a whole answer, run the drill"
    echo "without --attach."
  else
    echo "Right is a clone restored to that same instant, so every line above is"
    echo "a difference between two readings of one moment — there is no window"
    echo "for a visitor to have arrived in."
    echo
    echo "The one honest exception is a row written in the same SECOND the"
    echo "snapshot was taken — point-in-time recovery resolves to the second,"
    echo "and the snapshot does not. That shows as one or two rows on a single"
    echo "table and it does not repeat. Anything else, and anything under"
    echo "'column', 'index', 'constraint', 'migration' or a school that did not"
    echo "come back, is the restore."
  fi
  RESULT=1
fi

exit $RESULT
