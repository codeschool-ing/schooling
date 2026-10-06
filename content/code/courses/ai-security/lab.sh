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
#                  SCORER, below), moderation.py (THE STAND-IN MODERATION
#                  ENDPOINT, below), enduser.py and ratelimit.py (end-user
#                  ids and limits), kyc.py (deciding who gets API access),
#                  shapes.py and retry.py (what goes into a call and what
#                  comes out), toolgate.py (which tool calls an agent may
#                  make), ground.py (whether an answer stands on its
#                  sources), pipeline.py (the chain of output filters) and
#                  cli.py (every command)
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
#   keys/          the HMAC keys `guard enduser` uses, FIXED so that the
#                  captures repeat; see the comment where they are written
#
# WHAT IS WRITTEN BY THE COURSE AND NOT MEASURED
#
#   - Every record in the log, prompts AND replies, was written by the
#     course. No model produced any of the replies; they are there so the
#     tools have something realistic to read. Every CPF, card number,
#     phone number, e-mail address and key in them is invented: the CPFs
#     have valid check digits on purpose, the cards are the networks'
#     published test numbers, and the AWS key is the one Amazon's own
#     documentation uses as an example.
#   - guardlab/standin.py is NOT A MODEL. It is a scoring rule the course
#     wrote, with a bonus for Southeastern postcodes put there on purpose so
#     that lesson 9 has a proxy to find. The shortlist decisions in
#     data/shortlist-v1.csv and -v2.csv are written from the counts in
#     guardlab/fairness.py, and the profiles in data/profiles.jsonl are
#     invented.
#   - The requests in data/api-requests.jsonl were written by the lab, from
#     the table in guardlab/ratelimit.py, and the addresses in
#     data/emails.txt are invented: every first name with every surname.
#   - The applications for API access, data/cnpj-registry.json (which
#     stands in for the Receita Federal's public CNPJ data) and the usage
#     log in data/partner-usage.jsonl were written by the course. The
#     companies are invented; the CNPJ check-digit algorithm is the real one.
#   - The model replies in data/outputs.jsonl were written by the course, each
#     one to be caught by a different rule; `guard retry` replays them in
#     place of a model's attempts. The requests in data/inputs.jsonl were
#     written by the course too.
#   - The help centre in data/helpdesk/, the answers in data/answers.jsonl
#     (in place of a model's replies), data/registry-snapshot.txt (a short
#     stand-in for a package index) and data/suggested-deps.txt were written
#     by the course.
#   - data/owasp-llm-2025.json maps the ten categories of the OWASP Top 10
#     for LLM Applications (2025) to this lab's commands; the names are
#     OWASP's, the one-line meanings and the mapping are the course's.
#   - data/surface.json, the inventory of the assistant's entry points, was
#     written by the course for an invented company.
#   - data/system-prompt.txt, with its harmless canary marker, and the
#     replies in data/pipeline-outputs.jsonl were written by the course; no
#     model produced the replies.
#   - The tool calls in data/proposed-calls.jsonl were written by the
#     course in place of what an agent would propose; no model proposed
#     them.
#   - guardlab/moderation.py is NOT A MODERATION MODEL either: a list of
#     English words with weights the course chose, answering with a score
#     per category the way a moderation endpoint does. The sixty messages in
#     data/forum.jsonl and their labels were written by the course.
#   - data/reply-4471.txt is what the course wrote in place of a model's
#     reply to the minimised ticket. No model was called; it exists so that
#     `guard restore` has placeholders to put back.
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
cp -R "$here"/lab/data/. "$LAB/data/"
mv "$LAB/data/retention.json" "$LAB/data/holds.json" "$LAB/"
cat > "$LAB/bin/guard" <<'GUARD'
#!/usr/bin/env bash
here=$(cd "$(dirname "$0")/.." && pwd)
GUARD=$here PYTHONPATH=$here exec python3 -m guardlab.cli "$@"
GUARD
chmod +x "$LAB/bin/guard"
find "$LAB/guardlab" -name __pycache__ -prune -exec rm -rf {} +
# THE KEYS ARE FIXED, so that every capture prints the same ids. A real key
# is random, at least 32 bytes, and kept in a secret store, never in a file
# beside the code.
mkdir -p "$LAB/keys"
printf 'lab-key-for-provider-a-not-secret-0001\n' > "$LAB/keys/provider-a.key"
printf 'lab-key-for-provider-b-not-secret-0002\n' > "$LAB/keys/provider-b.key"
"$LAB/bin/guard" _build
echo "lab ready in $LAB — put $LAB/bin on your PATH"
