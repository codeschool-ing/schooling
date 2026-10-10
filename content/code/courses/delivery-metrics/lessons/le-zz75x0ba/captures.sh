#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of delivery-metrics, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, and ../../lab/check.py says whether
# the lesson still quotes it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# The programs are read out of the lesson's own prose by lab/extract.py:
# billing.py from `the-team-data`, littles.py from `law-on-real-data`.
#
# STAGED, and not typed in the lesson: ana's account and the empty ~/delivery,
# and, for `when-setup-fails`, broken.py, which is billing.py with the
# indentation of one line lost the way a bad paste loses it.
#
# Recorded with Python 3.13, TZ=America/Sao_Paulo, on 2026-10-10.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
COURSE=$HERE/../..
lab() { bash "$COURSE/lab.sh" "$@"; }
put() { python3 "$COURSE/lab/extract.py" "$HERE" "$1" | lab exec "cat > '$1'"; }
on() { printf 'ana@laptop:~/delivery$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }

lab up >/dev/null
lab reset

block version
on 'python3 --version'

put billing.py
block run
on 'python3 billing.py'
on 'head -5 items.csv'
on 'head -3 deploys.csv'

block typo
on 'python3 biling.py'

python3 "$COURSE/lab/extract.py" "$HERE" billing.py \
  | sed 's/^            reviewed.append(name)$/reviewed.append(name)/' | lab exec 'cat > broken.py'
block paste
on 'python3 broken.py'

block elsewhere
lab exec 'rm -f items.csv deploys.csv broken.py'
printf 'ana@laptop:~/delivery$ cd ..\n'
printf 'ana@laptop:~$ python3 delivery/billing.py\n'; lab exec 'cd .. && python3 delivery/billing.py' 2>&1
printf 'ana@laptop:~$ ls -1 delivery\n'; lab exec 'cd .. && ls -1 delivery' 2>&1
printf 'ana@laptop:~$ ls -1 *.csv\n'; lab exec 'cd .. && ls -1 *.csv' 2>&1
lab exec 'cd .. && rm -f items.csv deploys.csv'
lab exec 'python3 billing.py >/dev/null'

put littles.py
block september
on 'python3 littles.py 2026-09-01 2026-09-30'
block august
on 'python3 littles.py 2026-08-01 2026-08-31'
block whole
on 'python3 littles.py 2026-06-01 2026-09-30'
