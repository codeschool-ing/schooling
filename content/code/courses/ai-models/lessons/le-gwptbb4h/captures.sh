#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of ai-models, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash ../../lab.sh up        # once: Ollama, the models, ~/desk
#   sudo bash captures.sh
#
# A line that starts with ana@desk:~$ or ana@desk:~/desk$ is what ana typed, and
# what follows it is what the machine printed. Quotations of Meta's documents
# carry no prompt: they are read by lab/sources.py at the commit it pins, and
# the student reads them rather than running anything.
#
# THE SETUP SECTIONS RUN ON A FRESH ~/desk, and they break the machine on
# purpose: `when-it-fails` removes zstd before Ollama's installer, stops the
# server, and runs Python without the virtual environment and without desk.env,
# each time to record the message a student meets. Everything is put back.
#
# The model's answers are llama3.2:3b's, through Ollama 0.40.0, on 2026-10-07.
# Sampling is not deterministic: a student's answer to the same question will
# differ in wording, and the lessons say so.
#
# Recorded on Ubuntu 24.04 (x86_64, 4 processors, 16 GB, no GPU),
# TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture-lib.sh

server_down() { pkill -x ollama; sleep 1; }
server_up() { setsid ollama serve > /run/ollama-lab.out 2>&1 < /dev/null & sleep 3; }

# ---- the setup, from nothing -------------------------------------------------
rm -rf /home/ana/desk

block ollama
# a machine that has never had Ollama, and has no zstd either
server_down
rm -rf /usr/local/lib/ollama /usr/local/bin/ollama /etc/systemd/system/ollama.service /root/.ollama /home/ana/.ollama
apt-get remove -y -q zstd >/dev/null 2>&1
home 'sudo apt-get install -y -q zstd > /dev/null && zstd --version'
hometty 'curl -fsSL https://ollama.com/install.sh | sh'
server_up
home 'ollama --version'
hometty 'ollama pull llama3.2:3b'
hometty "ollama run llama3.2:3b 'In one sentence: what does an online bookshop do?'"
home 'ollama list'
home 'ollama ps'

hometty 'ollama pull llama3.2:1b'
lab exec ana "ollama run llama3.2:1b 'Say hello.'" >/dev/null 2>&1 < /dev/null
home 'ollama list'
home 'ollama ps'

block desk
home 'mkdir -p desk/cases desk/prompts && cd desk'
on 'python3 -m venv .venv && . .venv/bin/activate'
on "$(grep -m1 '^ana@desk:~/desk\$ pip install ' desk.md | sed 's/^ana@desk:~\/desk\$ //')"
on "pip list | grep -iE '^(openai|anthropic|ollama|google-genai|mistralai|huggingface)'"
give desk.env desk.md sh 1
give prompts/triage.txt desk.md after 'prompts/triage.txt`:'
give prompts/extract.txt desk.md after 'prompts/extract.txt`:'
give cases/triage.jsonl desk.md json 1
give check.py desk.md after '`check.py` sends'
on 'wc -l cases/triage.jsonl'
on 'python check.py'

block when-it-fails
# the installer on a machine with no zstd
server_down
rm -rf /usr/local/lib/ollama /usr/local/bin/ollama
apt-get remove -y -q zstd >/dev/null 2>&1
hometty 'curl -fsSL https://ollama.com/install.sh | sh'
apt-get install -y -q zstd >/dev/null 2>&1
ana 'curl -fsSL https://ollama.com/install.sh | sh' >/dev/null 2>&1
# the server not running
home 'ollama run llama3.2:3b "Hello"'
on 'python check.py 2>&1 | tail -1'
server_up
# a second server on the same port
home 'ollama serve'
# a tag that does not exist
hometty 'ollama pull llama3.2:4b'
# Python without the virtual environment, and without desk.env
printf 'ana@desk:~/desk$ python3 check.py\n'
runuser -u ana -- env -i HOME=/home/ana PATH=/usr/local/bin:/usr/bin:/bin bash -c 'cd ~/desk; . ./desk.env; python3 check.py' 2>&1
printf 'ana@desk:~/desk$ python check.py\n'
runuser -u ana -- env -i HOME=/home/ana PATH=/usr/local/bin:/usr/bin:/bin bash -c 'cd ~/desk; . .venv/bin/activate; python check.py' 2>&1

# ---- the rest of the lesson, on the desk as the setup left it ----------------
lab reset >/dev/null

block pretraining
quote quote llama3.1-card "collection of pretrained|~15 trillion"

block base-and-tuned
quote quote llama3.1-prompt-format '^<.begin_of_text.>Color|^ red, orange'
quote quote llama3.1-prompt-format 'end_of_text...: Model|End of turn'

block chat-template
give template.py chat-template.md python 1
on 'python template.py'

block model-card
quote quote llama3.1-card "^\*\*supported languages|^\*\*Intended Use Cases"

block cutoff
quote quote llama3.1-card "data freshness"
