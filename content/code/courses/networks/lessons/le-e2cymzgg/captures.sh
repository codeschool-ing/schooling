#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of networks, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash -G sudo ana     # once, on a throwaway machine
#   sudo cp ../../lab.sh /var/tmp/lab.sh          # the lab, beside course.json
#   sudo -u ana -i bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB. lab.sh builds an office, an
# ISP and a small internet out of network namespaces on one Linux computer,
# with its own DNS root and its own certificate authority. Nothing reaches the
# real internet, which is why the addresses and names are the ones reserved
# for documentation. A line that starts with ana@laptop ran on the machine
# called laptop, and so on.
#
# What is STAGED rather than typed, and not shown in the lesson:
# the lab itself, built by lab.sh reset: vsftpd on www, where the hosting
# account example (password Sunflower-77) logs in to the website's own
# folder, passive ports 40000 to 40009; the scanner's account scans
# (password scanner-2026) on server, SFTP only; and, on laptop, lesson 7's
# key with its agent running, trusted by server, with office in
# ~/.ssh/config; a folder of licence texts and an archive of them to move, and a
# stand-in for a scanned page;
# and a new index.html for the site. Passwords are typed where a prompt
# asks for them and not echoed. Before ftps-forced, vsftpd restarted with
# the two force_ settings turned on.
# Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04 under systemd-nspawn, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100
LAB_SH=${LAB_SH:-/var/tmp/lab.sh}
lab() { sudo bash "$LAB_SH" "$@"; }
# on HOST 'command': what ana typed at her prompt on one machine of the lab,
# and everything it printed.
on() {
  local h=$1; shift
  printf 'ana@%s:~$ %s\n' "$h" "$*"
  lab exec "$h" ana "$*" 2>&1 || true
}
# The same, run as root and not shown: the lab's own housekeeping.
quiet() { local h=$1; shift; lab exec "$h" root "$*" >/dev/null 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }

later() {
  printf 'ana@%s:~$ %s\n' "$2" "$3" > "/tmp/later.$1"
  lab exec "$2" ana "$3" >> "/tmp/later.$1" 2>&1 &
  eval "LATER_$1=$!"
  sleep 1.5
}
collect() { eval "wait \$LATER_$1"; cat "/tmp/later.$1"; rm -f "/tmp/later.$1"; }
cat > /tmp/typed-shell.sh <<'SH'
printf 'set enable-bracketed-paste off\n' > /tmp/inputrc.$$
INPUTRC=/tmp/inputrc.$$ script -qec "env PS1='\u@\h:\w\$ ' HISTFILE=/dev/null bash --norc --noprofile -i" /dev/null
rm -f /tmp/inputrc.$$
SH
typed() {
  local h=$1 cmds; cmds=$(cat)
  { sleep 1; while IFS= read -r l; do printf '%s\n' "$l"; sleep "${PAUSE:-1.5}"; done <<< "$cmds"; printf 'exit\n'; sleep 0.5; } |
    timeout 90 sudo bash "$LAB_SH" exec "$h" ana 'bash /tmp/typed-shell.sh' | sed '$d' | sed '$d'
}

lab reset
sudo truncate -s0 /var/log/wtmp /var/log/lastlog
# Lesson 7's key, on the laptop and trusted by the server, with its agent
# running and the short name office in ~/.ssh/config.
lab exec laptop ana 'mkdir -p ~/.ssh; chmod 700 ~/.ssh; ssh-keygen -q -t ed25519 -N "blue kettle on the roof" -C ana@laptop -f ~/.ssh/id_ed25519' >/dev/null
printf '#!/bin/sh\necho "blue kettle on the roof"\n' > /tmp/askpass; chmod 755 /tmp/askpass
lab exec laptop ana 'ssh-agent -a ~/.ssh/agent.sock >/dev/null; SSH_AUTH_SOCK=~/.ssh/agent.sock SSH_ASKPASS=/tmp/askpass SSH_ASKPASS_REQUIRE=force ssh-add' >/dev/null 2>&1
lab exec laptop ana 'printf "Host office\n    HostName 192.168.10.10\n    User ana\n\nHost *\n    IdentityAgent ~/.ssh/agent.sock\n" > ~/.ssh/config; ssh-keyscan -t ed25519 192.168.10.10 > ~/.ssh/known_hosts 2>/dev/null'
lab exec server ana 'mkdir -p ~/.ssh; chmod 700 ~/.ssh' >/dev/null
sudo install -o ana -g ana -m 600 /lab/laptop/home/ana/.ssh/id_ed25519.pub /lab/server/home/ana/.ssh/authorized_keys
# Some files to move: the licences every Ubuntu carries, as a folder and as one archive.
lab exec laptop ana 'mkdir -p Documents; cp /usr/share/common-licenses/{Apache-2.0,BSD,GPL-3,LGPL-3,MPL-2.0} Documents/; tar czf licences.tar.gz -C /usr/share common-licenses'
# The new home page, written by whoever looks after the site.
lab exec laptop ana 'printf "<!doctype html>\n<title>Example Ltd</title>\n<h1>Example Ltd</h1>\n<p>Closed on 12 October for the holiday.</p>\n" > index.html'

block ftp-login
PAUSE=2 typed laptop <<'IN'
ftp www.example.com
example
Sunflower-77
pwd
ls
put index.html
bye
IN
on laptop 'curl -s https://www.example.com/ | grep Closed'

block active
on laptop 'curl -sS -v --ftp-port - -u example:Sunflower-77 ftp://www.example.com/ 2>&1 | grep -E "^[<>] (PORT|EPRT|5)|curl:"'
on laptop 'curl -sS -v -u example:Sunflower-77 ftp://www.example.com/ 2>&1 | grep -E "^[<>] (EPSV|229)|Connecting|^-rw"'

block blocked
on www 'sudo nft add table inet ftp-guard'
on www "sudo nft add chain inet ftp-guard input '{ type filter hook input priority 0; }'"
on www 'sudo nft add rule inet ftp-guard input tcp dport 40000-40009 drop'
on laptop 'time curl -sS --connect-timeout 10 -u example:Sunflower-77 ftp://www.example.com/'
on www 'sudo nft delete table inet ftp-guard'

block cleartext
later sniff isp 'sudo timeout 6 tcpdump -i eth0 -n -l "tcp port 21" 2>/dev/null | grep -oE "FTP: .*"'
lab exec laptop ana 'curl -sS -u example:Sunflower-77 ftp://www.example.com/ >/dev/null'
collect sniff

block ftps
on laptop 'curl -sS -v --ssl-reqd -u example:Sunflower-77 ftp://www.example.com/ 2>&1 | grep -E "^[<>] (AUTH|234|USER|230)|SSL connection|^-rw"'
later sniff isp 'sudo timeout 6 tcpdump -i eth0 -n -l "tcp port 21" 2>/dev/null | grep -aoE "FTP: (220|AUTH|234|USER|PASS)[ -~]*"'
lab exec laptop ana 'curl -sS --ssl-reqd -u example:Sunflower-77 ftp://www.example.com/ >/dev/null'
collect sniff

block ftps-forced
sudo sed -i "s/^force_local_logins_ssl=NO/force_local_logins_ssl=YES/; s/^force_local_data_ssl=NO/force_local_data_ssl=YES/" /lab/www/etc/vsftpd.conf
sudo pkill -x vsftpd; sleep 0.5
quiet www 'vsftpd /etc/vsftpd.conf </dev/null >/dev/null 2>&1 &'
sleep 1
on www 'grep -E "^(ssl_enable|force_local)" /etc/vsftpd.conf'
on laptop 'curl -sS -v -u example:Sunflower-77 ftp://www.example.com/ 2>&1 | grep -E "^< 530|curl:"'

block scp
on laptop 'ls -l licences.tar.gz'
on laptop 'scp licences.tar.gz office:'
on laptop 'scp -r Documents office:'
on laptop 'scp office:/etc/hostname from-server.txt && cat from-server.txt'
on server 'ls -l licences.tar.gz Documents'

block checksum
on laptop 'sha256sum licences.tar.gz'
on laptop 'ssh office sha256sum licences.tar.gz'

block sftp
PAUSE=2 typed laptop <<'IN'
sftp office
pwd
ls
cd Documents
ls -l
get MPL-2.0
put index.html
bye
IN
on laptop 'ls -l MPL-2.0'
on server 'ls -l Documents/index.html'
on laptop 'printf "cd Documents\nls\n" | sftp -b - office'

block sftp-only
on server 'tail -4 /etc/ssh/sshd_config'
on server 'ls -ld /srv/scans /srv/scans/inbox'
lab exec laptop ana 'cp /usr/share/common-licenses/MPL-2.0 scan-0001.pdf' >/dev/null
PAUSE=2 typed laptop <<'IN'
ssh scans@192.168.10.10
scanner-2026
sftp scans@192.168.10.10
scanner-2026
pwd
ls
cd /etc
cd inbox
put scan-0001.pdf
bye
IN
on server 'ls -l /srv/scans/inbox'

block rsync
on laptop 'rsync -av Documents/ office:backup/'
on laptop 'rsync -av Documents/ office:backup/'
on laptop 'echo "Reviewed on 25 September." >> Documents/MPL-2.0; rm Documents/BSD'
on laptop 'rsync -av Documents/ office:backup/'
on laptop 'rsync -avn --delete Documents/ office:backup/'

sudo pkill -x ssh-agent; sudo pkill -x ssh; sudo pkill -x vsftpd
lab down >/dev/null 2>&1
