#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of servers-cache, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the server
# from `lab.sh reset 4`, which is lesson 3's end state (the site on HTTPS with
# a certificate from Pebble, port 80 redirecting, the API behind it). Every
# test in this lesson is run by the server's own administrator against the
# server's own sites. The files the lesson shows are written with sudo tee.
# The `.git` directory under the web root is planted by this script, as the
# kind of leftover the section on paths is about. Dates differ on every run.
#
# Recorded on Ubuntu 24.04 under systemd-nspawn, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
SITE=/etc/nginx/sites-available/ipelivros
apply() { quiet 'sudo nginx -t && sudo systemctl reload nginx'; sleep 1; }

lab reset 4

block leaks
run 'curl -sI https://ipelivros.example/ | grep -i ^server'
run 'curl -s https://ipelivros.example/nothing-here | grep -i nginx'
run 'curl -sI http://localhost:8001/healthz | grep -i ^server'
run 'curl -sI https://ipelivros.example/api/books/1 | grep -iE "^(server|x-served-by)"'
run "sudo sed -i 's/# server_tokens off;/server_tokens off;/' /etc/nginx/nginx.conf && grep -n server_tokens /etc/nginx/nginx.conf"
apply
run 'curl -sI https://ipelivros.example/ | grep -i ^server'
run 'curl -s https://ipelivros.example/nothing-here | grep -i nginx'

block default-server
run 'ls /etc/nginx/sites-enabled/'
run "curl -s http://127.0.0.1/ | grep -o '<title>.*</title>'"
run "curl -sk https://127.0.0.1/ | grep -o '<title>.*</title>'"
run "curl -sk -o /dev/null -w '%{http_code}\n' -H 'Host: anything.example' https://127.0.0.1/"
put /etc/nginx/sites-available/catch-all <<'EOF'
# Requests for a name this server does not serve: refuse them.
server {
    listen 80 default_server;
    listen 443 ssl default_server;
    server_name _;

    ssl_reject_handshake on;   # no certificate is shown to a stranger
    return 444;                # close the connection without an answer
}
EOF
run 'cat /etc/nginx/sites-available/catch-all'
run 'sudo rm /etc/nginx/sites-enabled/default && sudo ln -s ../sites-available/catch-all /etc/nginx/sites-enabled/catch-all'
apply
run 'curl -sS http://127.0.0.1/'
run 'curl -sSk https://127.0.0.1/'
run "curl -sS -o /dev/null -w '%{http_code}\n' https://ipelivros.example/"

put /etc/nginx/snippets/security-headers.conf <<'EOF'
add_header Strict-Transport-Security "max-age=31536000" always;
add_header X-Content-Type-Options    "nosniff" always;
add_header Referrer-Policy           "strict-origin-when-cross-origin" always;
add_header Permissions-Policy        "camera=(), microphone=(), geolocation=()" always;
add_header Content-Security-Policy   "default-src 'self'; img-src 'self' data:; frame-ancestors 'none'; base-uri 'self'; form-action 'self'" always;
EOF

block headers
run 'curl -sI https://ipelivros.example/ | grep -ciE "^(strict-transport|content-security|x-content-type|referrer-policy|permissions-policy)"'
run 'cat /etc/nginx/snippets/security-headers.conf'
run "sudo sed -i 's|    include snippets/ipelivros-tls.conf;|    include snippets/ipelivros-tls.conf;\n    include snippets/security-headers.conf;|' $SITE && grep -n 'include snippets' $SITE"
apply
run 'curl -sI https://ipelivros.example/ | grep -iE "^(strict-transport|content-security|x-content-type|referrer-policy|permissions-policy)"'
run 'curl -sI http://ipelivros.example/ | grep -iE "^(HTTP|strict-transport)"'

block inheritance
run "sudo sed -i 's|        proxy_read_timeout 10s;|        proxy_read_timeout 10s;\n        add_header Cache-Control \"no-store\";|' $SITE && grep -n 'add_header' $SITE"
apply
run 'curl -sI https://ipelivros.example/api/books/1 | grep -iE "^(cache-control|strict-transport|content-security)"'
run "sudo sed -i 's|        add_header Cache-Control \"no-store\";|        add_header Cache-Control \"no-store\";\n        include snippets/security-headers.conf;|' $SITE && grep -n 'add_header\|security-headers' $SITE"
apply
run 'curl -sI https://ipelivros.example/api/books/1 | grep -iE "^(cache-control|strict-transport|content-security)"'

block paths
quiet 'sudo mkdir -p /var/www/ipe/.git && printf "[core]\n\trepositoryformatversion = 0\n[remote \"origin\"]\n\turl = git@git.example:ipe/site.git\n" | sudo tee /var/www/ipe/.git/config >/dev/null'
run 'ls -A /var/www/ipe'
run "curl -s -o /dev/null -w '%{http_code}\n' https://ipelivros.example/.git/config"
run "sudo sed -i '0,/    location \\/ {/s||    location ~ /\\\\.(?!well-known/) {\n        return 404;\n    }\n\n    location / {|' $SITE && grep -n -A2 'location ~' $SITE"
apply
run "curl -s -o /dev/null -w '%{http_code}\n' https://ipelivros.example/.git/config"
run "curl -s -o /dev/null -w '%{http_code}\n' http://ipelivros.example/.well-known/acme-challenge/test"
run "for m in GET PUT DELETE TRACE; do printf '%-6s ' \$m; curl -s -o /dev/null -w '%{http_code}\n' -X \$m -d '{\"price_cents\": 4990}' https://ipelivros.example/api/books/1; done"
run "sudo sed -i 's|        proxy_pass http://shop;|        limit_except GET HEAD PUT { deny all; }\n        proxy_pass http://shop;|' $SITE"
apply
run "for m in GET PUT DELETE TRACE; do printf '%-6s ' \$m; curl -s -o /dev/null -w '%{http_code}\n' -X \$m -d '{\"price_cents\": 4990}' https://ipelivros.example/api/books/1; done"

put /etc/nginx/conf.d/limits.conf <<'EOF'
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req_status 429;
client_header_timeout 5s;
client_body_timeout   5s;
EOF

block rate-limit
run 'cat /etc/nginx/conf.d/limits.conf'
run "sudo sed -i 's|        limit_except GET HEAD PUT { deny all; }|        limit_except GET HEAD PUT { deny all; }\n        limit_req zone=api burst=20 nodelay;|' $SITE && grep -n 'limit_' $SITE"
apply
run "for i in \$(seq 60); do curl -s -o /dev/null -w '%{http_code}\n' https://ipelivros.example/api/echo; done | sort | uniq -c"
run 'grep -c "limiting requests" /var/log/nginx/ipelivros.error.log; grep "limiting requests" /var/log/nginx/ipelivros.error.log | tail -n 1 | cut -c 1-130'
run "sleep 2; curl -s -o /dev/null -w '%{http_code}\n' https://ipelivros.example/api/echo"

block slow-client
run "time (exec 3<>/dev/tcp/127.0.0.1/80; printf 'GET / HTTP/1.1\\r\\nHost: ipelivros.example\\r\\n' >&3; cat <&3)"
run "sudo grep -h '\" 408 ' /var/log/nginx/*.log | tail -n 1"

block privilege
run 'ps -o user,pid,cmd -C nginx | head -n 3; ps -o user,pid,cmd -C python3'
run 'sudo -u www-data touch /var/www/ipe/defaced.html'
run "sudo ss -ltn | awk 'NR>1 {print \$4}' | sort"
run 'systemd-analyze security shop@1.service --no-pager | tail -n 1'
quiet 'sudo mkdir -p /etc/systemd/system/shop@.service.d'
put /etc/systemd/system/shop@.service.d/hardening.conf <<'EOF'
[Service]
NoNewPrivileges=yes
ProtectSystem=strict
ReadWritePaths=/var/lib/shop
ProtectHome=yes
PrivateTmp=yes
PrivateDevices=yes
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
RestrictNamespaces=yes
LockPersonality=yes
SystemCallArchitectures=native
CapabilityBoundingSet=
EOF
run 'cat /etc/systemd/system/shop@.service.d/hardening.conf'
run 'sudo systemctl daemon-reload && sudo systemctl restart shop@1 shop@2 && systemctl is-active shop@1 shop@2'
run 'systemd-analyze security shop@1.service --no-pager | tail -n 1'
run "curl -s -X PUT -d '{\"price_cents\": 5290}' https://ipelivros.example/api/books/1 | jq -c '{id, price_cents}'"
run "sudo -u shop touch /opt/shop/shop.py"
run "sudo systemd-run --wait --pipe -p ProtectSystem=strict -p ReadWritePaths=/var/lib/shop sh -c 'touch /var/lib/shop/ok && echo wrote /var/lib/shop/ok; touch /opt/shop/x' 2>&1 | head -n 3"
