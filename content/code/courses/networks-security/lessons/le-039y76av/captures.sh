#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of networks-security, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash ana               # once, on a throwaway machine
#   sudo ln -sf "$(realpath ../../lab.sh)" /var/tmp/nslab.sh   # the lab, beside course.json
#   sudo bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB, built by lab.sh; lesson 1
# draws its map. A line that starts with ana@laptop ran on the machine called
# laptop; root@fw is the administrator on the firewall.
# root@app is the administrator on the application server; root@www on the
# shop's proxy.
#
# What is STAGED rather than typed, and not shown in the lesson:
# the lab itself, built by lab.sh reset, with the baseline rule set of lesson 4
# loaded on fw; three certificates issued by identities.sh, shown in the lesson, with fixed
# dates, as lesson 12 issued one: app.corp.example.com for the application's
# TLS listener, www-client for the proxy to prove who it is, and an old
# client certificate for the proxy that expired on 31 August 2026; each copied
# to the machine that uses it with its key; nginx's configuration on app,
# written before it is shown with cat, and a second nginx started on app with
# it; the proxy's configuration changed to use the new listener, shown as the
# lines that changed.
# Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100
LAB_SH=${LAB_SH:-/var/tmp/nslab.sh}
lab() { bash "$LAB_SH" "$@"; }
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
quiet() { local h=$1; shift; lab exec "$h" root "$*" >/dev/null 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }

lab reset
quiet fw 'nft -f baseline.nft'
# the three certificates, by identities.sh as the lesson shows it, extracted
# byte for byte the way the copy button gives it
python3 - "$(dirname "$(readlink -f "$0")")/inside-is-not-enough.md" > /var/tmp/nslab/identities.sh <<'PY'
import json, re, sys
for b in re.findall(r"^```schooling-example\n(.*?)\n```$", open(sys.argv[1]).read(), re.S | re.M):
    ex = json.loads(b)
    if ex.get("file") == "identities.sh":
        print("\n".join(p["code"] for p in ex["parts"]))
PY
bash /var/tmp/nslab/identities.sh
quiet app 'cat > /root/nginx-app.conf <<"CONF"
pid /var/log/lab/nginx.pid;
error_log /var/log/lab/nginx-error.log;
events {}
http {
    log_format who "$remote_addr $ssl_client_s_dn $ssl_client_verify $request_uri $status";
    access_log /var/log/lab/nginx-access.log who;
    server {
        listen 192.168.20.10:8443 ssl;
        server_name app.corp.example.com;
        ssl_certificate     /root/tls/app.crt;
        ssl_certificate_key /root/tls/app.key;
        ssl_protocols TLSv1.3;
        ssl_client_certificate /root/tls/clients-ca.crt;
        ssl_verify_client on;
        ssl_verify_depth 2;
        location / {
            if ($ssl_client_s_dn != "CN=www-client") { return 403; }
            proxy_pass http://192.168.20.10:8080;
        }
    }
}
CONF'

block perimeter
on laptop 'probe app:8080 app:8443'
on laptop 'curl -s http://192.168.20.10:8080/admin/'

block mtls-conf
root app 'cat nginx-app.conf'
root app 'nginx -c /root/nginx-app.conf -t 2>&1 | tail -1; nginx -c /root/nginx-app.conf'
root fw "nft insert rule ip filter forward index 2 oifname eth3 ip daddr 192.168.20.10 tcp dport 8443 ct state new accept comment '\"the application over TLS: identity decides, not the network\"'"
root fw 'nft -a list chain ip filter forward | grep "dport 8080" | grep -o "comment.*"'
root fw 'nft delete rule ip filter forward handle 10; nft delete rule ip filter forward handle 14'
root fw 'nft list chain ip filter forward | grep -E "dport (8080|8443)" | sed "s/^\t*//"'

block inside
on laptop 'curl -sS --resolve app.corp.example.com:8443:192.168.20.10 https://app.corp.example.com:8443/admin/ | grep -o "<title>.*</title>"'
on laptop 'probe app:8080'

block machine-identity
root www 'openssl x509 -in tls/www-client.crt -noout -subject -issuer -dates -ext extendedKeyUsage'
root www 'curl -sS --resolve app.corp.example.com:8443:192.168.20.10 --cert tls/www-client.crt --key tls/www-client.key https://app.corp.example.com:8443/health'
quiet www 'python3 - <<"PY"
p="/etc/nginx/sites-enabled/shop"
s=open(p).read()
s=s.replace("proxy_pass http://192.168.20.10:8080;","proxy_pass https://192.168.20.10:8443;\n        proxy_ssl_name app.corp.example.com;\n        proxy_ssl_server_name on;\n        proxy_ssl_verify on;\n        proxy_ssl_trusted_certificate /etc/ssl/certs/ca-certificates.crt;\n        proxy_ssl_certificate /root/tls/www-client.crt;\n        proxy_ssl_certificate_key /root/tls/www-client.key;")
open(p,"w").write(s)
PY
nginx -s reload'
sleep 1
root www 'grep -m1 -A8 "location / {" /etc/nginx/sites-enabled/shop | sed "s/^ *//"'
on remote 'curl -s https://www.example.com/health'

block every-request
root app 'cat /var/log/lab/nginx-access.log'

block expired
root www 'openssl x509 -in tls/www-client-old.crt -noout -subject -enddate'
root www 'curl -sS --resolve app.corp.example.com:8443:192.168.20.10 --cert tls/www-client-old.crt --key tls/www-client-old.key https://app.corp.example.com:8443/health | grep -o "<title>.*</title>"'
root app 'tail -1 /var/log/lab/nginx-access.log'
