#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of defense-hardening, as a script that produces them.
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
# lesson 1. Every line here ran on web, the portal, as ana (ana@web), who uses
# sudo for what only root may do.
#
# What is STAGED rather than typed: the lab, `up web`, fresh. The backup script
# that root's cron runs, world-writable, is part of hostlab.sh's web image,
# which lesson 1 shows whole. Nothing else: the users, the group, the
# directory and every ACL are created by the commands in the transcripts.
# Every line after a prompt is what the command printed. The NTFS section has
# no transcript: there is no Windows machine in the lab.
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

lab up web >/dev/null 2>&1

block find
on web "sudo find / -xdev -type f -perm -0002 2>/dev/null"
on web 'ls -l /opt/portal/backup.sh; cat /etc/cron.d/portal-backup'

block who-can
on web 'sudo -u portal test -w /opt/portal/backup.sh && echo "portal may change a script root runs"'

block fix-bits
on web 'sudo chown root:root /opt/portal/backup.sh && sudo chmod 755 /opt/portal/backup.sh && ls -l /opt/portal/backup.sh'
on web 'sudo -u portal test -w /opt/portal/backup.sh || echo "portal may not change it"'

block setup
on web 'sudo groupadd contabil && for u in maria joao auditoria; do sudo useradd -M -s /usr/sbin/nologin $u; done; sudo usermod -aG contabil maria; sudo usermod -aG contabil joao; id maria; id auditoria'
on web 'sudo install -d -o root -g contabil -m 2770 /srv/clientes && ls -ld /srv/clientes'
on web 'sudo -u maria sh -c "umask 007; echo CPF 123.456.789-09, IRPF 2025 > /srv/clientes/silva.txt"; sudo ls -l /srv/clientes'

block bits-fail
on web 'sudo -u auditoria cat /srv/clientes/silva.txt'
on web 'sudo -u portal cat /srv/clientes/silva.txt'

block setfacl
on web 'sudo setfacl -m u:auditoria:rx,u:portal:rx /srv/clientes && sudo setfacl -m u:auditoria:r,u:portal:r /srv/clientes/silva.txt'
on web 'ls -ld /srv/clientes; sudo ls -l /srv/clientes'
on web 'sudo getfacl -p /srv/clientes/silva.txt'

block bits-pass
on web 'sudo -u auditoria cat /srv/clientes/silva.txt'
on web 'echo "edited" | sudo -u auditoria tee -a /srv/clientes/silva.txt'
on web 'echo "edited" | sudo -u joao tee -a /srv/clientes/silva.txt'

block mask
on web 'sudo setfacl -m u:portal:rw /srv/clientes/silva.txt && sudo getfacl -p --omit-header /srv/clientes/silva.txt'
on web 'sudo chmod 640 /srv/clientes/silva.txt && sudo getfacl -p --omit-header /srv/clientes/silva.txt'
on web 'echo "edited" | sudo -u joao tee -a /srv/clientes/silva.txt; sudo ls -l /srv/clientes/silva.txt'

block mask-back
on web 'sudo setfacl -m u:portal:r,m::rw /srv/clientes/silva.txt && sudo getfacl -p --omit-header /srv/clientes/silva.txt | grep -E "portal|group::|mask"'

block default
on web 'sudo -u joao sh -c "umask 007; echo CPF 987.654.321-00 > /srv/clientes/costa.txt"; sudo getfacl -p --omit-header /srv/clientes/costa.txt'
on web 'sudo -u auditoria cat /srv/clientes/costa.txt'

block default-set
on web 'sudo setfacl -d -m u:auditoria:r,u:portal:r,g::rw,o::- /srv/clientes && sudo getfacl -p --omit-header /srv/clientes | grep default'
on web 'sudo -u maria sh -c "umask 007; echo CPF 111.222.333-96 > /srv/clientes/souza.txt"; sudo getfacl -p --omit-header /srv/clientes/souza.txt'
on web 'sudo -u auditoria cat /srv/clientes/souza.txt'

block resolve
on web 'sudo usermod -aG contabil auditoria && id auditoria'
on web 'echo "edited" | sudo -u auditoria tee -a /srv/clientes/souza.txt'
on web 'sudo setfacl -x u:auditoria /srv/clientes/souza.txt && echo "edited" | sudo -u auditoria tee -a /srv/clientes/souza.txt'

block other
on web 'sudo -u estagio ls /srv/clientes'
