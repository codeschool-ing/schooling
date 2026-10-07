#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of security-fundamentals, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo cp ../../lab.sh /var/tmp/sflab.sh          # the lab, beside course.json
#   sudo bash /path/to/captures.sh
#
# Everything happens on www, the shop's server, as the administrator: root@www
# is the prompt.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by lab.sh reset, which gives www the SSH server's configuration
# exactly as Ubuntu's openssh-server package ships it, from
# /usr/share/openssh/sshd_config, and one host key. check-ssh.sh, beside this
# script, is copied to www's /root before the first command; the lesson prints
# it as a schooling-example, cut at its blank lines into parts with notes, and
# every part is that file's text unchanged. The SSH server is never started: sshd -T only reads the
# configuration and prints the settings it would use. Every line after a
# prompt is what the command printed.
#
# Recorded on Ubuntu 24.04 with OpenSSH 9.6, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat COLUMNS=100
LAB_SH=${LAB_SH:-/var/tmp/sflab.sh}
HERE=$(cd "$(dirname "$0")" && pwd)
lab() { bash "$LAB_SH" "$@"; }
root() {  # root HOST 'command': the administrator, at a root prompt
  local h=$1; shift
  printf 'root@%s:~# %s\n' "$h" "$*"
  lab exec "$h" root "$*" 2>&1 || true
}
block() { printf '##### %s\n' "$1"; }

lab reset
install -m 755 "$HERE/check-ssh.sh" /lab/www/root/check-ssh.sh

block file
root www 'grep -n -i -E "^#?(permitrootlogin|passwordauthentication|x11forwarding|maxauthtries) " /etc/ssh/sshd_config'

block before
root www './check-ssh.sh'

block fix
root www 'printf "PermitRootLogin no\nPasswordAuthentication no\nX11Forwarding no\nMaxAuthTries 4\n" > /etc/ssh/sshd_config.d/50-shop.conf'
root www 'cat /etc/ssh/sshd_config.d/50-shop.conf'
root www 'sshd -t; echo "exit $?"'

block after
root www './check-ssh.sh'
