#!/usr/bin/env bash
# The lab of ai-security's defensive lessons: ~/guard, a directory of files
# and one command, `guard`, that every capture in those lessons was taken
# with.
#
#   bash lab.sh reset      rebuild ~/guard from nothing
#
# It needs Python 3.8 or later and nothing else: no package, no network, no
# API key, no model. Every lesson's captures.sh starts by running it. Set
# GUARD to build it somewhere other than ~/guard.
#
# THE STORY. Tarefa is a Brazilian marketplace where clients hire
# freelancers, and it has an assistant built on a third-party model: it
# answers both sides in a chat and drafts proposals. Tarefa is invented.
#
# WHAT IS IN IT
#
#   guardlab/      the tools, in Python's standard library: detect.py (what
#                  counts as personal data in free text), minimise.py (what
#                  a ticket loses before a third-party model sees it),
#                  fairness.py (rates per group), standin.py (THE STAND-IN
#                  SCORER, below) and cli.py (every command)
#   bin/guard      the command line
#   logs/raw/      the assistant's call log, one file per day, word for word
#   logs/redacted/ the same records with personal data replaced
#   logs/metrics/  counts per day: calls, tokens, the slowest call
#   retention.json how long each of the three is kept
#   holds.json     files a sweep must not delete, and why
#   data/          what the logs and the rest were built from, and the
#                  inputs of later lessons: a support ticket, the purposes
#                  it may be sent to a model for, a reply to restore
#   outbox/ vault/ written by `guard minimise`: what would be sent, and the
#                  placeholders that stay behind
#
# WHAT IS WRITTEN BY THE COURSE AND NOT MEASURED
#
#   - Every record in the log, prompts AND replies, was written by the
#     course. No model produced any of the replies; they are there so the
#     tools have something realistic to read.
#   - guardlab/standin.py is NOT A MODEL. It is a scoring rule the course
#     wrote, with a bonus for Southeastern postcodes put there on purpose so
#     that lesson 9 has a proxy to find. The shortlist decisions in
#     data/shortlist-v1.csv and -v2.csv are written from the counts in
#     guardlab/fairness.py, and the profiles in data/profiles.jsonl are
#     invented.
#   - data/reply-4471.txt is what the course wrote in place of a model's
#     reply to the minimised ticket. No model was called; it exists so that
#     `guard restore` has placeholders to put back.
#   - Every CPF, card number, phone number, e-mail address and key in them
#     is invented. The CPFs have valid check digits on purpose, the cards are
#     the networks' published test numbers, and the AWS key is the one
#     Amazon's own documentation uses as an example.
#
# What IS real is everything the tools compute: every count, match and file
# a lesson quotes was printed by running them.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
LAB=${GUARD:-$HOME/guard}

case ${1:-} in
  reset) ;;
  *) echo "usage: bash lab.sh reset" >&2; exit 2 ;;
esac

rm -rf "$LAB"
mkdir -p "$LAB/bin" "$LAB/data"
cp -R "$here/lab/guardlab" "$LAB/guardlab"
cp "$here"/lab/data/* "$LAB/data/"
mv "$LAB/data/retention.json" "$LAB/data/holds.json" "$LAB/"
cat > "$LAB/bin/guard" <<'GUARD'
#!/usr/bin/env bash
here=$(cd "$(dirname "$0")/.." && pwd)
GUARD=$here PYTHONPATH=$here exec python3 -m guardlab.cli "$@"
GUARD
chmod +x "$LAB/bin/guard"
find "$LAB/guardlab" -name __pycache__ -prune -exec rm -rf {} +
"$LAB/bin/guard" _build
echo "lab ready in $LAB — put $LAB/bin on your PATH"
