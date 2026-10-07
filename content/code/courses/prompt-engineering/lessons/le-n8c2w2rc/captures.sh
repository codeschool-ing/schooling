#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of prompt-engineering, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# toylm, ask and corpus.txt are read out of the-workbench.md by lab.sh, so the
# programs that ran are the ones the lesson prints.
#
# THE MODEL'S REPLIES, in the blocks your-machine and workbench-ask, are
# llama3.2:3b (digest a80c4f17acd5) served by Ollama 0.40.0, at temperature 0,
# captured on 7 October 2026 on a 4-core machine with no graphics card.
#
# THE FAILURES in when-it-fails are produced, not described:
#   - the installer is run with zstd and the installed Ollama moved aside, so it
#     meets the machine a student has before the apt-get line. It runs as root
#     here; run by ana it asks sudo for her password first, and that prompt,
#     which goes to the terminal, is the only line that differs.
#   - the model server is stopped and started again around three commands.
#   - toylm loses its execute bit, and a shell starts without ~/.bashrc.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
# on 'command': what ana typed in ~/pe, and what it printed.
on() { printf 'ana@lab:~/pe$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
# home 'command': the same, typed in her home directory.
home() { printf 'ana@lab:~$ %s\n' "$*"; lab exec "cd ~ && $*" 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }
# One capture at a time: every run rebuilds ~/pe from nothing.
exec 9>/var/tmp/pe-capture.lock; flock 9
lab reset >/dev/null

block next-word
on 'toylm next "the coffee is"'
on 'toylm next "the café opens at"'

block one-at-a-time
on 'toylm generate "the café opens at" --temperature 0'
on 'toylm next "the café opens at seven"'
on 'toylm next "the cat sat on the"'
on 'toylm generate "the cat sat on the" --temperature 0'
on 'toylm generate "the coffee is" --samples 5'

block your-machine
home 'python3 --version; node --version; ollama --version'
home 'ollama list'
home 'ask "Say hello in three words." --temperature 0 --plain'
home 'ollama ps'
home 'du -sh /usr/local/lib/ollama'

# The smaller model the section offers for a weak computer. `ollama list`
# gives its size on disk and `ollama ps`, after one question, its size in
# memory: the two numbers the prose quotes. Pulled quietly first and removed
# after, so the other blocks see only the recommended model.
block your-machine-small
lab exec 'ollama pull llama3.2:1b' >/dev/null 2>&1
home 'ollama list'
home 'ASK_MODEL=llama3.2:1b ask "Say hello in three words." --temperature 0 --plain'
home 'ollama ps'
lab exec 'ollama stop llama3.2:1b; ollama rm llama3.2:1b' >/dev/null 2>&1

block workbench-toylm
on 'toylm info'
on 'head -4 corpus.txt'

block workbench-ask
on 'ask "the café opens at" --temperature 0'
on 'ask "When does a café usually open? Answer in one sentence." --temperature 0'

block when-it-fails-zstd
aside=/var/tmp/pe-aside
mkdir -p $aside
restore() {
  [ -e $aside/zstd ] && mv $aside/zstd /usr/bin/zstd
  # The installer has made an empty /usr/local/lib/ollama by the time it stops.
  if [ -e $aside/ollama-lib ]; then
    rm -rf /usr/local/lib/ollama && mv $aside/ollama-lib /usr/local/lib/ollama
  fi
  return 0
}
trap restore EXIT
mv /usr/bin/zstd $aside/zstd
mv /usr/local/lib/ollama $aside/ollama-lib
printf 'ana@lab:~$ %s\n' 'curl -fsSL https://ollama.com/install.sh | sh'
(cd /tmp && env -i PATH=/usr/local/bin:/usr/bin:/bin TERM=dumb HOME=/root \
  HTTPS_PROXY="${HTTPS_PROXY:-}" SSL_CERT_FILE="${SSL_CERT_FILE:-}" CURL_CA_BUNDLE="${CURL_CA_BUNDLE:-}" \
  bash -c 'curl -fsSL https://ollama.com/install.sh | sh' 2>&1) || true
restore

block when-it-fails-server
pkill -x ollama || true
sleep 2
home 'ollama list'
home 'ask "Say hello in three words."'
lab reset >/dev/null   # starts the server again, the way systemctl would
home 'ollama list'

block when-it-fails-model
home 'ASK_MODEL=lama3.2:3b ask "Say hello in three words."'

block when-it-fails-bits
lab exec 'chmod -x ~/pe/bin/toylm'
on 'toylm info'
on 'chmod +x ~/pe/bin/toylm'
on 'toylm info | head -1'
printf 'ana@lab:~/pe$ %s\n' 'toylm info'
runuser -u ana -- env -i HOME=/home/ana PATH=/usr/bin:/bin bash -c 'cd ~/pe && toylm info' 2>&1 || true
on 'tail -2 ~/.bashrc'
