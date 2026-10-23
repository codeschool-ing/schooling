#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of defense-hardening, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash ana                  # once, on a throwaway machine
#   sudo bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB. ../../lab.sh extracts
# hostlab.sh from lesson 1 and runs it. This lesson uses dns (the firm's
# resolver), desk (a workstation), trap (which plays the internet's name
# servers here) and sw (the switch). ana@desk is ana on desk; root@dns is the
# administrator there.
#
# What is STAGED rather than typed: nothing. Every file the lesson writes is
# written by the command the transcript shows. The resolver desk starts with
# is whatever systemd-nspawn copied from the computer's own /etc/resolv.conf
# when the container booted; on the recording computer that was 8.8.8.8.
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

block before
on desk 'cat /etc/resolv.conf'
on desk 'dig web.jatoba.example | tail -2'

block internet
root trap "cat > /etc/unbound/unbound.conf.d/internet.conf <<'EOF'
server:
    interface: 0.0.0.0
    access-control: 0.0.0.0/0 allow
    module-config: \"iterator\"
    local-zone: \"example.net.\" static
    local-data: \"boletos-jatoba.example.net. A 198.51.100.23\"
    local-data: \"jatoba.contabil-nuvem.example.net. A 198.51.100.80\"
    local-data: \"outro.contabil-nuvem.example.net. A 198.51.100.81\"
    local-zone: \"example.org.\" static
    local-data: \"pagamento.cobranca-urgente.example.org. A 198.51.100.66\"
EOF"
root trap 'rm /etc/unbound/unbound.conf.d/root-auto-trust-anchor-file.conf; systemctl enable --now unbound 2>&1 | tail -1; systemctl is-active unbound'

block resolver
root dns "cat > /etc/unbound/unbound.conf.d/jatoba.conf <<'EOF'
server:
    interface: 0.0.0.0
    access-control: 192.168.60.0/24 allow
    module-config: \"respip iterator\"
    log-queries: yes
    local-zone: \"jatoba.example.\" static
    local-data: \"web.jatoba.example. A 192.168.60.10\"
    local-data: \"desk.jatoba.example. A 192.168.60.20\"
    local-data: \"dns.jatoba.example. A 192.168.60.53\"
forward-zone:
    name: \".\"
    forward-addr: 192.168.60.66
EOF"
root dns 'rm /etc/unbound/unbound.conf.d/root-auto-trust-anchor-file.conf; unbound-checkconf'
root dns 'systemctl enable --now unbound 2>&1 | tail -1; systemctl is-active unbound'

block point
root desk 'printf "nameserver 192.168.60.53\nsearch jatoba.example\n" > /etc/resolv.conf'
on desk 'dig +short web.jatoba.example; dig +short boletos-jatoba.example.net'
on desk 'dig www.ubuntu.com | grep status'

block querylog
root dns 'journalctl -u unbound -o cat | grep "info: 192" | cut -d" " -f3-'

block rpz-zone
root dns "cat > /etc/unbound/feed.zone <<'EOF'
\$TTL 300
@ SOA localhost. hostmaster.jatoba.example. 1 3600 600 86400 300
@ NS localhost.
boletos-jatoba.example.net      CNAME .
*.cobranca-urgente.example.org  A     192.168.60.53
EOF"
root dns "cat >> /etc/unbound/unbound.conf.d/jatoba.conf <<'EOF'
rpz:
    name: feed.jatoba.example
    zonefile: /etc/unbound/feed.zone
    rpz-log: yes
    rpz-log-name: feed
EOF"
root dns 'unbound-checkconf && systemctl restart unbound; systemctl is-active unbound'

block rpz-test
on desk 'dig boletos-jatoba.example.net | grep status'
on desk 'dig +short pagamento.cobranca-urgente.example.org'
on desk 'dig +short web.jatoba.example'

block rpz-log
root dns 'journalctl -u unbound -o cat | grep "rpz: applied" | cut -d" " -f3-'

block sinkhole
root dns "cat > /root/sinkhole.py <<'EOF'
#!/usr/bin/env python3
\"\"\"Answers every web request with one line, and logs who asked for which name.\"\"\"
import datetime
import http.server

class Sinkhole(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        now = datetime.datetime.now().isoformat(timespec=\"seconds\")
        print(now, self.client_address[0], self.headers.get(\"Host\"), self.path, flush=True)
        self.send_response(200)
        self.send_header(\"Content-Type\", \"text/plain; charset=utf-8\")
        self.end_headers()
        self.wfile.write(b\"Blocked by Jatoba: this address is on the list of dangerous sites.\\n\")

    def log_message(self, *args):
        pass

http.server.ThreadingHTTPServer((\"0.0.0.0\", 80), Sinkhole).serve_forever()
EOF"
root dns 'systemd-run --unit=sinkhole python3 /root/sinkhole.py; sleep 1; systemctl is-active sinkhole'
on desk 'curl -s http://pagamento.cobranca-urgente.example.org/boleto.pdf'
root dns 'journalctl -u sinkhole -o cat | grep -v systemd'

block false-positive
root dns 'echo "*.contabil-nuvem.example.net    CNAME ." >> /etc/unbound/feed.zone; systemctl restart unbound'
on desk 'dig jatoba.contabil-nuvem.example.net | grep status'

block allow
root dns "cat > /etc/unbound/allow.zone <<'EOF'
\$TTL 300
@ SOA localhost. hostmaster.jatoba.example. 1 3600 600 86400 300
@ NS localhost.
jatoba.contabil-nuvem.example.net  CNAME rpz-passthru.
EOF"
root dns "sed -i 's/^rpz:\$/rpz:\n    name: allow.jatoba.example\n    zonefile: \/etc\/unbound\/allow.zone\n    rpz-log: yes\n    rpz-log-name: allow\nrpz:/' /etc/unbound/unbound.conf.d/jatoba.conf; sed -n '/^rpz:/,\$p' /etc/unbound/unbound.conf.d/jatoba.conf"
root dns 'unbound-checkconf && systemctl restart unbound; systemctl is-active unbound'
on desk 'dig +short jatoba.contabil-nuvem.example.net; dig outro.contabil-nuvem.example.net | grep status'
root dns 'journalctl -u unbound -o cat | grep "rpz: applied" | tail -2 | cut -d" " -f3-'

block bypass
on desk 'dig +short @192.168.60.66 boletos-jatoba.example.net'

block guard
root sw "nft -f - <<'EOF'
table bridge dnsguard {
    chain forward {
        type filter hook forward priority filter; policy accept;
        ip daddr 192.168.60.53 udp dport 53 accept
        ip daddr 192.168.60.53 tcp dport 53 accept
        ip saddr 192.168.60.53 ip daddr 192.168.60.66 udp dport 53 accept
        udp dport 53 counter drop
        tcp dport 53 counter drop
    }
}
EOF"
on desk 'dig +tries=1 +time=2 +short @192.168.60.66 boletos-jatoba.example.net; echo "exit $?"'
on desk 'dig +short pagamento.cobranca-urgente.example.org'
root sw 'nft list chain bridge dnsguard forward | grep counter'
