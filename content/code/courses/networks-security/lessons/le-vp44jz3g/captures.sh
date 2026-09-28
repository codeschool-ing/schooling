#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of networks-security, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash ana               # once, on a throwaway machine
#   sudo cp ../../lab.sh /var/tmp/nslab.sh          # the lab, beside course.json
#   sudo bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB, built by lab.sh; lesson 1
# draws its map. A line that starts with ana@laptop ran on the machine called
# laptop; root@fw is the administrator on the firewall.
# root@www is the administrator on the shop's reverse proxy.
#
# What is STAGED rather than typed, and not shown in the lesson:
# the lab itself, built by lab.sh reset, with fw routing and filtering nothing,
# so that every question in this lesson is about TLS and none about the
# firewall; the proxy's configuration edited between blocks, each edit shown
# as the lines it produced; on remote, a TLS server on port 8443 started with
# openssl s_server and a self-signed certificate claiming www.example.com,
# standing in for any machine that answers in a real server's name: a test box
# left running, a misconfigured load balancer, or something worse.
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

block versions
on laptop 'curl -s -o /dev/null -w "%{http_code}\n" https://www.example.com/'
on laptop 'openssl s_client -connect www.example.com:443 -servername www.example.com -tls1_3 </dev/null 2>/dev/null | grep "^New,"'
on laptop 'openssl s_client -connect www.example.com:443 -servername www.example.com -tls1_2 </dev/null 2>/dev/null | grep "^New,"'
on laptop 'curl -sS -o /dev/null --tls-max 1.1 https://www.example.com/; echo "exit $?"'
on laptop 'openssl s_client -connect www.example.com:443 -servername www.example.com -tls1_1 -cipher "DEFAULT:@SECLEVEL=0" </dev/null 2>&1 | grep -oE "alert protocol version|SSL alert number [0-9]+"'
root www 'grep -n ssl_protocols /etc/nginx/sites-enabled/shop'

block http-first
on laptop 'curl -sI http://www.example.com/ | head -3'
quiet www 'python3 - <<"PY"
import re
p="/etc/nginx/sites-enabled/shop"
s=open(p).read()
s=s.replace("""server {
    listen 192.0.2.80:80;
    server_name www.example.com;
    location / {
        proxy_pass http://192.168.20.10:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $remote_addr;
    }
}""","""server {
    listen 192.0.2.80:80;
    server_name www.example.com;
    return 301 https://$host$request_uri;
}""")
s=s.replace("""    ssl_protocols TLSv1.2 TLSv1.3;
""","""    ssl_protocols TLSv1.2 TLSv1.3;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
""")
open(p,"w").write(s)
PY
nginx -s reload'
sleep 1
root www 'grep -nE "return 301|Strict-Transport" /etc/nginx/sites-enabled/shop'
on laptop 'curl -sI http://www.example.com/orders | grep -iE "^HTTP|^location"'
on laptop 'curl -sI https://www.example.com/ | grep -iE "^HTTP|^strict"'

block impostor
quiet remote 'cd /root; openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -days 30 -subj "/CN=www.example.com" -keyout fake.key -out fake.crt 2>/dev/null; setsid openssl s_server -accept 8443 -cert fake.crt -key fake.key -www -quiet </dev/null >/dev/null 2>&1 &'
sleep 1
on laptop 'curl -sS -o /dev/null --connect-to www.example.com:443:203.0.113.50:8443 https://www.example.com/; echo "exit $?"'
on laptop 'openssl s_client -connect 203.0.113.50:8443 -servername www.example.com </dev/null 2>/dev/null | grep -E "^ *0 s:|^ *i:|^Verify return code"'
on laptop 'curl -sk -o /dev/null -w "%{http_code} from %{remote_ip}\n" --connect-to www.example.com:443:203.0.113.50:8443 https://www.example.com/'

block python
quiet laptop 'cat > /home/ana/fetch.py <<"PY"
import ssl, urllib.request

url = "https://www.example.com/"
ctx = ssl.create_default_context()
print("verify:", ctx.verify_mode.name, "| check_hostname:", ctx.check_hostname)
print(urllib.request.urlopen(url, context=ctx).read().decode().strip())
PY
chown ana:ana /home/ana/fetch.py'
on laptop 'python3 fetch.py'
on laptop 'grep -rnE "verify=False|CERT_NONE|_create_unverified_context|curl -k|--insecure|InsecureSkipVerify" --include=*.py --include=*.sh --include=*.go . 2>/dev/null; echo "matches: $?"'
