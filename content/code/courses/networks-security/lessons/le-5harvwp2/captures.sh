#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of networks-security, as a script that produces them.
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
# draws its map. A line that starts with ana@remote ran on the machine called
# remote, a stranger on the internet; root@www is the administrator on the
# reverse proxy in the DMZ.
#
# What is STAGED rather than typed, and not shown in the lesson:
# the lab itself, built by lab.sh reset, with the company's baseline rule set
# (baseline.nft, which lesson 4 builds) loaded on fw; the application on app,
# a directory of pages served by Python, logging each request to a file; the
# proxy's configuration edited between blocks, each edit shown in the lesson as
# the file it produced.
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
quiet app ': > /var/log/lab/app.log'

block hidden
on remote 'curl -s https://www.example.com/'
on remote 'curl -s -m3 http://192.168.20.10:8080/; echo "exit $?"'
root app 'tail -1 /var/log/lab/app.log'
root www 'tail -1 /var/log/nginx/access.log'
root www 'cat /etc/nginx/sites-enabled/shop | sed -n "/listen 192.0.2.80:443/,/^}/p"'

block headers
on remote 'curl -sI https://www.example.com/ | grep -iE "^server|^HTTP"'

block refuse
quiet www 'cat > /etc/nginx/sites-enabled/shop <<"CONF"
server_tokens off;
server {
    listen 192.0.2.80:80;
    server_name www.example.com;
    return 301 https://$host$request_uri;
}
server {
    listen 192.0.2.80:443 ssl;
    server_name www.example.com;
    ssl_certificate     /etc/ssl/private/www.crt;
    ssl_certificate_key /etc/ssl/private/www.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    client_max_body_size 16k;

    location /admin/ {
        allow 192.168.10.0/24;
        deny all;
        proxy_pass http://192.168.20.10:8080;
    }
    location / {
        limit_except GET POST { deny all; }
        proxy_pass http://192.168.20.10:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $remote_addr;
    }
}
CONF'
root www 'nginx -t 2>&1 | tail -1 && nginx -s reload'
sleep 1
on remote 'curl -sI https://www.example.com/ | grep -iE "^server|^HTTP"'
on remote 'curl -s -o /dev/null -w "%{http_code}\n" https://www.example.com/admin/'
on laptop 'curl -s https://www.example.com/admin/'
on remote 'curl -s -o /dev/null -w "%{http_code}\n" -X DELETE https://www.example.com/orders/17'
on remote 'head -c 20000 /dev/zero | curl -s -o /dev/null -w "%{http_code}\n" --data-binary @- https://www.example.com/'
on remote 'curl -s -o /dev/null -w "%{http_code}\n" http://www.example.com/'

block ratelimit
quiet www 'sed -i "s|^server_tokens off;|server_tokens off;\nlimit_req_zone \$binary_remote_addr zone=perip:10m rate=5r/s;\nlimit_req_status 429;|" /etc/nginx/sites-enabled/shop'
quiet www 'sed -i "0,/limit_except GET POST/s||limit_req zone=perip burst=10 nodelay;\n        limit_except GET POST|" /etc/nginx/sites-enabled/shop'
root www 'grep -n "limit_req" /etc/nginx/sites-enabled/shop'
root www 'nginx -t 2>&1 | tail -1 && nginx -s reload'
sleep 1
on remote 'for i in $(seq 30); do curl -s -o /dev/null -w "%{http_code}\n" https://www.example.com/; done | sort | uniq -c'
on laptop 'curl -s -o /dev/null -w "%{http_code}\n" https://www.example.com/'
sleep 3
on remote 'curl -s -o /dev/null -w "%{http_code}\n" https://www.example.com/'
root www 'grep -c "limiting requests" /var/log/nginx/error.log; grep -m1 "limiting requests" /var/log/nginx/error.log | cut -d" " -f3-'

block waf
quiet www 'printf "include /etc/nginx/modsecurity.conf\ninclude /etc/modsecurity/crs/crs-setup.conf\ninclude /usr/share/modsecurity-crs/rules/*.conf\n" > /etc/nginx/waf.conf'
quiet www 'sed -i "s#^SecAuditLog .*#SecAuditLog /var/log/nginx/modsec_audit.log#" /etc/nginx/modsecurity.conf'
quiet www 'sed -i "0,/client_max_body_size 16k;/s||client_max_body_size 16k;\n    modsecurity on;\n    modsecurity_rules_file /etc/nginx/waf.conf;|" /etc/nginx/sites-enabled/shop'
quiet www 'sed -i "s/limit_req zone=perip burst=10 nodelay;/limit_req zone=perip burst=50 nodelay;/" /etc/nginx/sites-enabled/shop'
root www 'cat /etc/nginx/waf.conf; grep -E "^SecRuleEngine" /etc/nginx/modsecurity.conf; grep -n modsecurity /etc/nginx/sites-enabled/shop'
root www 'nginx -t 2>&1 | grep -o "rules loaded.*"; nginx -s reload'
sleep 2
on remote 'curl -s -o /dev/null -w "%{http_code}\n" "https://www.example.com/?q=%3Cscript%3Ealert(1)%3C/script%3E"'
root www 'grep -o "\[id \"[0-9]*\"\]\|\[msg \"[^\"]*\"\]" /var/log/nginx/modsec_audit.log'
quiet www ': > /var/log/nginx/modsec_audit.log'
quiet www 'sed -i "s/^SecRuleEngine .*/SecRuleEngine On/" /etc/nginx/modsecurity.conf'
root www 'grep -E "^SecRuleEngine" /etc/nginx/modsecurity.conf; nginx -s reload'
sleep 2
on remote 'curl -s -o /dev/null -w "%{http_code}\n" "https://www.example.com/?q=%3Cscript%3Ealert(1)%3C/script%3E"'
on remote 'curl -s -o /dev/null -w "%{http_code}\n" "https://www.example.com/?q=running+shoes"'
root www 'grep -o "\[id \"[0-9]*\"\]\|\[msg \"[^\"]*\"\]" /var/log/nginx/modsec_audit.log'

block falsepositive
quiet www ': > /var/log/nginx/modsec_audit.log'
on remote 'curl -s -o /dev/null -w "%{http_code}\n" -d "comment=select id from orders where total > 100" https://www.example.com/support'
root www 'grep -o "\[id \"[0-9]*\"\]\|\[msg \"[^\"]*\"\]\|\[data \"[^\"]*\"\]" /var/log/nginx/modsec_audit.log'

block exclusion
quiet www 'sed -i "0,/    location \/admin\/ {/s||    location /support {\n        modsecurity_rules \x27SecRuleUpdateTargetById 942100 \"!ARGS:comment\"\x27;\n        proxy_pass http://192.168.20.10:8080;\n    }\n    location /admin/ {|" /etc/nginx/sites-enabled/shop'
root www 'sed -n "/location \/support/,/}/p" /etc/nginx/sites-enabled/shop'
root www 'nginx -t 2>&1 | tail -1 && nginx -s reload'
sleep 2
on remote 'curl -s -w "%{http_code}\n" -d "comment=select id from orders where total > 100" https://www.example.com/support'
on remote 'curl -s -o /dev/null -w "%{http_code}\n" -d "comment=<script>alert(1)</script>" https://www.example.com/support'
on remote 'curl -s -o /dev/null -w "%{http_code}\n" -d "name=select id from orders where total > 100" https://www.example.com/support'
