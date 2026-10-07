#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of ai-models, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash ../../lab.sh up        # once: Ollama, the models, ~/desk
#   sudo bash captures.sh
#
# A line that starts with ana@desk:~/desk$ is what ana typed and what it
# printed. A program it runs is the student's, shown whole in the lesson and
# taken from it here; a quotation carries no prompt, and is read by
# lab/sources.py at the commit it pins.
#
# api.openai.com was refused by the network of the machine this was recorded
# on. Ollama speaks the Responses API, so what answers is llama3.2:3b, through
# the student's relay.py (lesson 9), which shows what the openai library
# sends. Where Ollama does not do what OpenAI documents (it ignores
# previous_response_id and truncation, and keeps no store), the lesson says
# so, and quotes the parameter documentation that ships inside the library.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture-lib.sh

lab reset >/dev/null

# The parameter documentation the openai library carries, one parameter at a
# time, from the docstring of Responses.create.
give doc.py state.md python 1
give resp_sort.py shape.md python 1
give chain.py state.md python 2
give forget.py store.md python 1
give long.py limits.md python 1
give parse.py limits.md python 2
relay_up

block shape
on "$RELAY_EXPORT"
via 'python resp_sort.py'
via 'python relay.py show --body'

block state
on 'python doc.py previous_response_id instructions'
via 'python chain.py'
via 'python relay.py show --body | head -6'

block store
on 'python doc.py store'
via 'python forget.py 2>&1 | tail -1'
via 'python relay.py show --count 2'

block limits
on 'python doc.py truncation'
via 'python long.py'
via 'python long.py auto'
on 'python doc.py text'
via 'python parse.py'
via 'python relay.py show --body | python -c "import json, sys; print(json.dumps(json.load(sys.stdin)[\"text\"], indent=2))"'

relay_down
