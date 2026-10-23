#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of defense-hardening, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash ana                  # once, on a throwaway machine
#   echo 'ana ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/ana
#   sudo bash ../../lab.sh build                      # once: the images
#   sudo bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB, built by hostlab.sh from
# lesson 1. Every line here ran on desk, as ana (ana@desk).
#
# What is STAGED rather than typed: the lab, `up desk`, fresh. NO MALWARE IS
# USED, OR MADE. The only "detections" are of the EICAR test file, which every
# antivirus vendor agreed to detect precisely so that a scanner can be tested
# with a harmless file, and of three short text files the transcripts create,
# which stand for "a file the firm has decided is bad". ClamAV's official
# signature database cannot be downloaded from here (no network), so every
# signature is one the lesson writes.
# Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100
here=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
LAB="$here/../../lab.sh"
lab() { bash "$LAB" "$@"; }
on() {
  local h=$1; shift
  printf 'ana@%s:~$ %s\n' "$h" "$*"
  lab exec "$h" ana "$*" 2>&1 || true
}
block() { printf '##### %s\n' "$1"; }

lab up desk >/dev/null 2>&1
lab exec desk ana 'cat > eicar.txt' <<'EOF'
X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*
EOF
lab exec desk ana 'truncate -s 68 eicar.txt'

block nodb
on desk 'clamscan --no-summary eicar.txt; echo "exit $?"'
on desk 'ls /var/lib/clamav'

block eicar
on desk 'cat eicar.txt; echo; wc -c eicar.txt'
on desk 'sigtool --sha256 eicar.txt > lab.hsb; cat lab.hsb'
on desk 'clamscan --no-summary -d lab.hsb eicar.txt; echo "exit $?"'

block samples
on desk 'mkdir samples && printf "JATOBA-LAB-SAMPLE invoice 2026-10\n" > samples/invoice.txt && cp samples/invoice.txt samples/copy.txt && printf "JATOBA-LAB-SAMPLE invoice 2026-10 \n" > samples/changed.txt && sha256sum samples/*'

block hash-sig
on desk 'sigtool --sha256 samples/invoice.txt | sed "s/:invoice.txt$/:Jatoba.Lab.Invoice/" > lab.hsb; cat lab.hsb'
on desk 'clamscan --no-summary -d lab.hsb samples/; echo "exit $?"'

block content-sig
on desk 'printf "JATOBA-LAB-SAMPLE" | xxd -p'
on desk 'echo "Jatoba.Lab.Marker:0:*:4a41544f42412d4c41422d53414d504c45" > lab.ndb; clamscan --no-summary -d lab.ndb samples/; echo "exit $?"'

block yara
on desk 'cat > lab.yar <<"EOF"
rule jatoba_lab_marker
{
    strings:
        $marker = "JATOBA-LAB-SAMPLE"
        $word = "invoice" nocase
    condition:
        $marker and $word and filesize < 1KB
}
EOF
yara lab.yar samples/'

block false-positive
on desk 'printf "Training notes: files marked JATOBA-LAB-SAMPLE are invoice test files.\n" > notes.txt; yara lab.yar notes.txt; clamscan --no-summary -d lab.ndb notes.txt'

block quarantine
on desk 'sudo install -d -m 700 /var/quarantine && sudo clamscan --no-summary -r -d lab.ndb --move=/var/quarantine samples/; ls samples; sudo ls /var/quarantine'

block freshclam
on desk 'systemctl is-enabled clamav-freshclam; systemctl is-active clamav-freshclam; grep -E "^(DatabaseMirror|Checks)" /etc/clamav/freshclam.conf'
