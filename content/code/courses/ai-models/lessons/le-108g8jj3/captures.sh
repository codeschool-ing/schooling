#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of ai-models, as a script that
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
# huggingface.co could not be reached from the machine this was recorded on.
# What is read instead is Hugging Face's own source, at the commits sources.py
# pins: the list of tasks in huggingface.js and the Hub's documentation. The
# card in cards.py is ana's, written for the course, and huggingface_hub (the
# real library, at the version lab.sh pins) turns it into the metadata a Hub
# repository carries.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture-lib.sh

lab reset >/dev/null

give tasks.py tasks.md python 1

block tasks
quote quote hf-tasks "To determine which|filters at the left"
on 'python tasks.py nlp'

block the-hub
on 'python -c "import inspect, huggingface_hub as h; print(h.__version__); print(*list(inspect.signature(h.hf_hub_download).parameters)[:6], sep=chr(10))"'

give cards.py cards.md python 1

block cards
quote quote hub-model-cards "simple Markdown files with additional metadata|YAML.*section at the top"
on 'python cards.py'

block community
quote quote hub-model-cards "is a fine-tune, an adapter, or a quantized|infer the type of relationship"
