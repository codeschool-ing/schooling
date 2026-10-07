#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of ai-models, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash ../../lab.sh up        # once: Ollama, the models, ~/desk
#   sudo bash captures.sh
#
# A line that starts with ana@desk:~/desk$ is what ana typed and what it
# printed. A program it runs is the student's, shown whole in the lesson and
# taken from it here.
#
# generativelanguage.googleapis.com answers from the machine this was
# recorded on, but only with a key, and a key is an account a course cannot
# hand out; Ollama does not speak this API. So each program runs through the
# student's relay.py (lesson 9), which writes down the request google-genai
# really sends and gets Ollama's 404 for it, and then straight to Google with
# the placeholder key, which Google refuses. Nothing here answers in Google's
# shape, and the lesson says so.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture-lib.sh

lab reset >/dev/null

give gemini_sort.py shape.md python 1
give field.py shape.md python 2
give gemini_extract.py structured.md python 1

relay_up
block shape
session <<'SH'
export GOOGLE_GEMINI_BASE_URL=http://127.0.0.1:8500 GOOGLE_API_KEY=ollama
python gemini_sort.py
python relay.py show --headers x-goog-api-key,user-agent
python field.py Content.role
unset GOOGLE_GEMINI_BASE_URL
python gemini_sort.py
SH

block structured
session <<'SH'
export GOOGLE_GEMINI_BASE_URL=http://127.0.0.1:8500 GOOGLE_API_KEY=ollama
python gemini_extract.py
python relay.py show --body | python -c "import json, sys; print(json.dumps(json.load(sys.stdin)[\"generationConfig\"], indent=2))"
SH
on 'python field.py GenerateContentConfig.response_schema'
on 'python field.py GenerateContentResponse.parsed'
relay_down

block text-none
on 'python -c "import inspect; from google.genai import types; print(inspect.getsource(types.GenerateContentResponse._get_text))" | head -24'
on 'python -c "from google.genai import types; print(types.FinishReason.__members__.keys())"'
