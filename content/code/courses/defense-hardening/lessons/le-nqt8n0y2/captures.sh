#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of defense-hardening, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash ana                  # once, on a throwaway machine
#   sudo bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB. ../../lab.sh extracts
# hostlab.sh from lesson 1 and runs it. This lesson uses admin (where the
# administrator works), jump (the one door), web and desk. ana@admin is ana on
# admin; root@web is the administrator there.
#
# What is STAGED rather than typed: nothing. The key every machine trusts is
# the one hostlab.sh made in build; the certificate authority is made here.
# web starts as hostlab.sh builds it, with the old SSH settings lesson 1
# removed, because every lesson starts from a fresh lab.
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

lab up admin jump web desk >/dev/null 2>&1

block every-door
on desk 'ssh web hostname'
on admin 'ssh web hostname'
on admin 'ssh jump hostname'

block bastion
root jump "cat > /etc/ssh/sshd_config.d/10-bastion.conf <<'EOF'
PermitTTY no
ForceCommand /usr/sbin/nologin
AllowAgentForwarding no
X11Forwarding no
PermitOpen web:22
EOF"
root jump 'sshd -t && systemctl reload ssh; echo "exit $?"'

block jump-shell
on admin 'ssh jump; echo "exit $?"'

block proxyjump
on admin 'ssh -J jump web hostname'
on admin 'ssh -J jump desk hostname; echo "exit $?"'

block config
on admin "cat >> ~/.ssh/config <<'EOF'
Host web
    ProxyJump jump
EOF"
on admin 'ssh web "hostname; echo \$SSH_CONNECTION"'

block close-web
root web "nft -f - <<'EOF'
table inet admin {
    chain input {
        type filter hook input priority filter; policy accept;
        tcp dport 22 ip saddr 192.168.60.40 accept
        tcp dport 22 counter reject with tcp reset
    }
}
EOF"
on desk 'ssh web hostname; echo "exit $?"'
on admin 'ssh web hostname'

block close-jump
root jump "nft -f - <<'EOF'
table inet admin {
    chain input {
        type filter hook input priority filter; policy accept;
        tcp dport 22 ip saddr 192.168.60.30 accept
        tcp dport 22 counter reject with tcp reset
    }
}
EOF"
on desk 'ssh -J jump web hostname; echo "exit $?"'
root web 'nft list chain inet admin input | grep counter'

block ca
on admin 'ssh-keygen -q -t ed25519 -N "" -C "jatoba user CA" -f ~/user-ca; cat ~/user-ca.pub'

block sign
on admin 'ssh-keygen -s ~/user-ca -I ana@jatoba -n ana -V +1h ~/.ssh/id_ed25519.pub'
on admin 'ssh-keygen -L -f ~/.ssh/id_ed25519-cert.pub | sed -n "4,9p"'

block trust
CA=$(lab exec admin ana 'cat ~/user-ca.pub')
root web "echo '$CA' > /etc/ssh/user-ca.pub"
root web "cat > /etc/ssh/sshd_config.d/10-ca.conf <<'EOF'
TrustedUserCAKeys /etc/ssh/user-ca.pub
AuthorizedKeysFile none
PasswordAuthentication no
LogLevel VERBOSE
EOF"
root web 'sshd -t && systemctl reload ssh; echo "exit $?"'
on admin 'ssh web hostname'

block expired
on admin 'ssh-keygen -s ~/user-ca -I ana@jatoba-yesterday -n ana -V -2h:-1h ~/.ssh/id_ed25519.pub'
on admin 'ssh -o BatchMode=yes web hostname; echo "exit $?"'

block log
root web 'journalctl -u ssh -o cat | grep -E "^(Accepted|Failed|error)" | tail -4'
