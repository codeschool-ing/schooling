#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of defense-hardening, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash ana                  # once, on a throwaway machine
#   sudo bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB. ../../lab.sh extracts
# hostlab.sh from lesson 1 and runs it. This lesson uses desk alone. ana@desk
# is ana on desk.
#
# What is STAGED rather than typed: nothing. The two sample files are written
# by the commands shown, and both are harmless: one is a shell script that only
# prints a sentence, the other a plain text note. No online service was called;
# the lab has no internet, and the sections on VirusTotal, urlscan, the
# interactive sandboxes and WHOIS show no transcript for that reason.
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
root() {  # root HOST 'command': the administrator, at a root prompt
  local h=$1; shift
  printf 'root@%s:~# %s\n' "$h" "$*"
  lab exec "$h" root "$*" 2>&1 || true
}
block() { printf '##### %s\n' "$1"; }

lab up dns desk trap >/dev/null 2>&1

lab up desk >/dev/null 2>&1

block samples
on desk "mkdir -p ~/inbox && cd ~/inbox && cat > fatura-outubro.pdf <<'EOF'
#!/bin/sh
# A lab sample for lesson 19. It looks like a PDF by its name and is a shell script.
# It does nothing but print one sentence.
PAY_URL=http://pagamento.cobranca-urgente.example.org/boleto
echo \"This file is a harmless lab sample. It would have opened \$PAY_URL\"
EOF
printf 'Reunião com o cliente às 15h.\nLevar o contrato assinado.\n' > nota.txt; ls -l"

block file
on desk 'cd ~/inbox && file *'

block hash
on desk 'cd ~/inbox && sha256sum *'

block strings
on desk 'cd ~/inbox && strings -n 8 fatura-outubro.pdf | grep -iE "http|sh"'
on desk 'cd ~/inbox && xxd fatura-outubro.pdf | head -2'

block yara
on desk "cat > ~/disguised.yar <<'EOF'
rule script_named_like_a_document
{
    meta:
        description = \"a shell script that carries a web address, whatever its name says\"
    strings:
        \$shebang = \"#!/bin/sh\"
        \$url = /https?:\\/\\/[a-z0-9.-]+\\.[a-z]{2,}/
    condition:
        \$shebang at 0 and \$url
}
EOF
yara -s ~/disguised.yar ~/inbox"
