#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of defense-hardening, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash ana                  # once, on a throwaway machine
#   echo 'ana ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/ana
#   sudo bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB. ../../lab.sh extracts
# hostlab.sh from this lesson's section "The script that builds the lab" and
# runs it: seven Ubuntu 24.04 containers on one isolated segment. A line that
# starts with ana@web ran on the machine called web, as ana; root@web is the
# administrator there; a bare $ is the lab computer itself, in ~/hostlab.
#
# What is STAGED rather than typed: nothing beyond what hostlab.sh builds. The
# weaknesses lesson 1 finds on web are written in the script itself, which the
# lesson shows whole.
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
SCRIPT=$(lab path)
install -d -o ana -g ana /home/ana/hostlab
install -o ana -g ana -m 644 "$SCRIPT" /home/ana/hostlab/hostlab.sh
host() { printf '$ %s\n' "$1"; runuser -u ana -- bash -c "cd ~/hostlab && $1" 2>&1 || true; }
shell() {  # shell 'sh web' 'command' ...: an interactive shell on a machine
  local how=$1; shift
  printf '$ sudo bash hostlab.sh %s\n' "$how"
  printf '%s\n' "$@" exit | runuser -u ana -- script -qec "cd ~/hostlab && sudo bash hostlab.sh $how" /dev/null \
    | sed -e 's/\x1b\[?2004[hl]//g; s/\x1b\]0;[^\x07]*\x07//g; s/\r//g' | sed -n '/^[a-z]*@[a-z]*:~[$#] /,$p'
}

block build
lab down >/dev/null 2>&1
host 'sha256sum hostlab.sh; wc -l hostlab.sh'
host 'time sudo bash hostlab.sh build > build.log 2>&1; tail -1 build.log'

block up
host 'time sudo bash hostlab.sh up'

block shell
shell 'sh web' 'hostname; id' 'ping -c1 -W1 desk | head -2'

block not-running
lab down >/dev/null 2>&1
host 'sudo bash hostlab.sh sh web; echo "exit $?"'

block no-sudo
host 'bash hostlab.sh up; echo "exit $?"'

block crlf
runuser -u ana -- bash -c 'cd ~/hostlab && sed "s/$/\r/" hostlab.sh > windows.sh'
host 'sudo bash windows.sh up 2>&1 | cat -v | head -3; file windows.sh'
host 'sed -i "s/\r$//" windows.sh; cmp windows.sh hostlab.sh && echo same'
runuser -u ana -- rm -f /home/ana/hostlab/windows.sh

# The concept sections, in the order the lesson walks them, on one lab.
lab up >/dev/null 2>&1

block outside
on desk 'nmap web'
on desk 'sudo nmap -sU -p 111,161,5353 web'

block listeners
on web "sudo ss -Htulpn | awk '{split(\$7, p, \"\\\"\"); print \$1, \$5, p[2]}'"

block units
on web 'systemctl list-units --type=service --state=running --no-legend --plain | cut -d" " -f1'

block banners
on desk 'printf "quit\r\n" | nc -w2 web 21'
on desk 'snmpget -v2c -c public web 1.3.6.1.2.1.1.5.0'
on desk 'snmpwalk -v2c -c public web 1.3.6.1.2.1.25.4.2.1.2 | wc -l; snmpwalk -v2c -c public web 1.3.6.1.2.1.25.6.3.1.2 | wc -l'

block socket
on web 'sudo systemctl disable --now rpcbind'
on web "sudo ss -Htulpn | grep ':111 '"

block disable
on web 'sudo systemctl disable --now rpcbind.socket avahi-daemon.socket avahi-daemon 2>&1 | grep -v ^Removed'
on web "sudo ss -Htulpn | grep -cE ':(111|5353) '"

block purge
on web 'sudo apt-get purge -y -q vsftpd openbsd-inetd inetutils-telnetd rpcbind avahi-daemon snmpd 2>&1 | grep -E "^(Removing|Purging)" | cut -d" " -f1,2'
on web "sudo ss -Htulpn | awk '{split(\$7, p, \"\\\"\"); print \$1, \$5, p[2]}'"

block uid0
on web "awk -F: '\$3 == 0 {print \$1, \$6}' /etc/passwd"

block shells
on web "awk -F: '\$7 !~ /(nologin|false|sync)\$/ {print \$1, \$3, \$7}' /etc/passwd"
on web 'sudo passwd -S -a | grep -v " L "'
on web 'sudo grep -r NOPASSWD /etc/sudoers.d'

block userdel
on web 'sudo userdel suporte; echo "exit $?"'

block accounts-fix
on web 'sudo sed -i "/^suporte:/d" /etc/passwd /etc/shadow /etc/group /etc/gshadow; getent passwd 0'
on web 'sudo usermod -L -e 1 -s /usr/sbin/nologin estagio; sudo rm /etc/sudoers.d/estagio'
on web 'sudo usermod -s /usr/sbin/nologin portal; sudo systemctl restart portal; systemctl is-active portal'
on web 'sudo passwd -S estagio; sudo passwd -S portal; sudo chage -l estagio | head -4'

block keys
on web 'getent group sudo; sudo find / -xdev -name authorized_keys 2>/dev/null'

block sshd-before
on web "sudo sshd -T | grep -E '^(permitrootlogin|passwordauthentication|x11forwarding|maxauthtries) '"
on web 'cat /etc/ssh/sshd_config.d/50-old.conf; grep -n Include /etc/ssh/sshd_config'

block sshd-fix
on web 'printf "PermitRootLogin no\nPasswordAuthentication no\nX11Forwarding no\nMaxAuthTries 3\n" | sudo tee /etc/ssh/sshd_config.d/10-hardening.conf'
on web 'sudo sshd -t && sudo systemctl reload ssh; echo "exit $?"'
on web "sudo sshd -T | grep -E '^(permitrootlogin|passwordauthentication|x11forwarding|maxauthtries) '"

block sshd-test
on desk 'ssh -o PreferredAuthentications=password -o BatchMode=yes estagio@web true; echo "exit $?"'
on desk 'ssh web hostname'

block packages
on web 'dpkg -l | grep -c ^ii; apt-mark showmanual | wc -l'
on web 'apt-cache rdepends --installed wpasupplicant hostapd'
on web 'systemctl is-active wpa_supplicant hostapd'

block features-fix
on web 'sudo systemctl mask --now wpa_supplicant 2>&1 | sed "s/ → .*//"'
on web 'sudo apt-get purge -y -q hostapd wpasupplicant 2>&1 | grep -E "^(Removing|Purging)" | cut -d" " -f1,2'

block tokens
on web 'curl -s -D - -o /dev/null http://localhost/ | grep -i ^server'
on web 'sudo sed -i "s/# server_tokens off;/server_tokens off;/" /etc/nginx/nginx.conf && sudo nginx -t 2>&1 | tail -1 && sudo systemctl restart nginx'
on web 'curl -s -D - -o /dev/null http://localhost/ | grep -i ^server'

block after
on desk 'nmap web'
on desk 'sudo nmap -sU -p 111,161,5353 web'
