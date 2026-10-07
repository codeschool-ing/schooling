#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of servers-cache, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the server
# from `lab.sh reset 3`, which is lesson 2's end state (Nginx in front of the
# shop's two instances, the static front, gzip). The files the lesson shows
# are written with sudo tee. Pebble's root and intermediate are generated
# afresh every time Pebble starts, so every serial number, fingerprint, key
# and date in a certificate differs on every run; so does the name of the
# account certbot registers, and the ACME tokens.
#
# Recorded on Ubuntu 24.04 under systemd-nspawn, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
SITE=/etc/nginx/sites-available/ipelivros
apply() { quiet 'sudo nginx -t && sudo systemctl reload nginx'; sleep 1; }

lab reset 3

block self-signed
run 'sudo mkdir -p /etc/ssl/ipelivros && cd /etc/ssl/ipelivros && sudo openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -days 30 -subj "/CN=ipelivros.example" -addext "subjectAltName=DNS:ipelivros.example,DNS:www.ipelivros.example" -keyout self.key -out self.crt 2>&1; ls -l'
run 'openssl x509 -in /etc/ssl/ipelivros/self.crt -noout -subject -issuer -dates'

put /etc/nginx/snippets/ipelivros-self.conf <<'EOF'
ssl_certificate     /etc/ssl/ipelivros/self.crt;
ssl_certificate_key /etc/ssl/ipelivros/self.key;
EOF
quiet "sudo sed -i 's/^    listen 80;/    listen 80;\n    listen 443 ssl;\n    include snippets\/ipelivros-self.conf;/' $SITE"
apply
run "sed -n '/^server {/,/root/p' $SITE"
run 'curl -sS https://ipelivros.example/ -o /dev/null'
run "curl -sSk https://ipelivros.example/ -o /dev/null -w '%{http_code}\n'"
run "curl -sS --cacert /etc/ssl/ipelivros/self.crt https://ipelivros.example/ -o /dev/null -w '%{http_code}\n'"

block pebble-setup
run 'sudo mkdir -p /etc/pebble && cd /etc/pebble && sudo openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -days 365 -subj "/CN=Lab ACME API" -addext "subjectAltName=DNS:localhost" -keyout api.key -out api.crt 2>&1; ls'
put /etc/pebble/pebble.json <<'EOF'
{
  "pebble": {
    "listenAddress": "127.0.0.1:14000",
    "managementListenAddress": "127.0.0.1:15000",
    "certificate": "/etc/pebble/api.crt",
    "privateKey": "/etc/pebble/api.key",
    "httpPort": 80,
    "tlsPort": 443,
    "ocspResponderURL": "",
    "externalAccountBindingRequired": false,
    "certificateValidityPeriod": 7776000
  }
}
EOF
put /etc/systemd/system/pebble.service <<'EOF'
[Unit]
Description=Pebble, Let's Encrypt's ACME server for testing
After=network.target

[Service]
Environment=PEBBLE_VA_NOSLEEP=1 PEBBLE_WFE_NONCEREJECT=0
ExecStart=/usr/bin/pebble -config /etc/pebble/pebble.json
User=nobody

[Install]
WantedBy=multi-user.target
EOF
run 'cat /etc/pebble/pebble.json'
run 'sudo chmod 644 /etc/pebble/api.key && sudo systemctl daemon-reload && sudo systemctl start pebble && sleep 1 && systemctl is-active pebble'
run 'curl -s --cacert /etc/pebble/api.crt https://localhost:14000/dir | jq .'
run 'curl -s --cacert /etc/pebble/api.crt https://localhost:15000/roots/0 | sudo tee /usr/local/share/ca-certificates/pebble-root.crt | openssl x509 -noout -subject'

block certbot
run 'sudo REQUESTS_CA_BUNDLE=/etc/pebble/api.crt certbot certonly --webroot -w /var/www/ipe -d ipelivros.example -d www.ipelivros.example --server https://localhost:14000/dir --agree-tos -m ana@ipelivros.example --no-eff-email --non-interactive 2>&1'
run "grep acme-challenge /var/log/nginx/ipelivros.access.log"
run 'sudo ls -l /etc/letsencrypt/live/ipelivros.example/'
run 'sudo openssl x509 -in /etc/letsencrypt/live/ipelivros.example/cert.pem -noout -subject -issuer -dates -ext subjectAltName'
run 'sudo grep -c BEGIN /etc/letsencrypt/live/ipelivros.example/fullchain.pem'

put /etc/nginx/snippets/ipelivros-tls.conf <<'EOF'
ssl_certificate     /etc/letsencrypt/live/ipelivros.example/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/ipelivros.example/privkey.pem;
ssl_protocols       TLSv1.2 TLSv1.3;
ssl_session_cache   shared:TLS:10m;
ssl_session_timeout 1d;
EOF
quiet "sudo sed -i 's/ipelivros-self.conf/ipelivros-tls.conf/' $SITE"
apply

block trusted
run 'cat /etc/nginx/snippets/ipelivros-tls.conf'
run "sudo update-ca-certificates 2>&1"
run "curl -sS https://ipelivros.example/api/books/3 -o /dev/null -w '%{http_code} %{ssl_verify_result}\n'"
run "curl -sv https://ipelivros.example/ -o /dev/null 2>&1 | grep -E '^\*  ?(SSL connection|Server certificate|subject|issuer|expire|subjectAltName|SSL certificate verify)'"
run 'echo | openssl s_client -connect ipelivros.example:443 -servername ipelivros.example 2>/dev/null | grep -E "^ ?[0-9] s:|^   i:|Verify return|Protocol|Cipher is"'
run "echo | openssl s_client -connect ipelivros.example:443 -servername ipelivros.example -tls1_1 -cipher 'DEFAULT@SECLEVEL=0' 2>&1 | grep -E 'alert|Protocol  *:'"

put $SITE.redirect <<'EOF'
server {
    listen 80;
    server_name ipelivros.example www.ipelivros.example;

    location /.well-known/acme-challenge/ {
        root /var/www/ipe;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}
EOF

block redirect
run "cat $SITE.redirect"
quiet "sudo sed -i '/^    listen 80;/d' $SITE && sudo sh -c 'cat $SITE.redirect >> $SITE' && sudo rm $SITE.redirect"
apply
run "grep -nE 'server \\{|listen|include snippets' $SITE"
run 'curl -sI http://ipelivros.example/css/site.css?v=1 | grep -E "HTTP|Location"'
run "curl -s -o /dev/null -w '%{http_code}\n' http://ipelivros.example/.well-known/acme-challenge/nothing"

block renewal
run 'sudo cat /etc/letsencrypt/renewal/ipelivros.example.conf'
run 'systemctl list-timers certbot.timer --no-pager'
run 'systemctl cat certbot.service --no-pager | grep ExecStart'
put /etc/letsencrypt/renewal-hooks/deploy/reload-nginx <<'EOF'
#!/bin/sh
# Run by certbot after every certificate it renews: load the new files.
systemctl reload nginx
EOF
run 'sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/reload-nginx && sudo cat /etc/letsencrypt/renewal-hooks/deploy/reload-nginx'
run 'sudo REQUESTS_CA_BUNDLE=/etc/pebble/api.crt certbot renew --dry-run --server https://localhost:14000/dir --no-random-sleep-on-renew 2>&1'
run 'sudo REQUESTS_CA_BUNDLE=/etc/pebble/api.crt certbot renew --force-renewal --no-random-sleep-on-renew 2>&1 | tail -n 6'
run 'echo | openssl s_client -connect ipelivros.example:443 -servername ipelivros.example 2>/dev/null | openssl x509 -noout -serial -dates'

block expiry
run 'sudo openssl x509 -in /etc/letsencrypt/live/ipelivros.example/cert.pem -noout -checkend $((30*86400)); echo "exit $?"'
run 'sudo openssl x509 -in /etc/letsencrypt/live/ipelivros.example/cert.pem -noout -checkend $((100*86400)); echo "exit $?"'
run 'openssl x509 -in /etc/ssl/ipelivros/self.crt -noout -checkend $((31*86400)); echo "exit $?"'

put /etc/caddy/Caddyfile <<'EOF'
{
	acme_ca https://localhost:14000/dir
	acme_ca_root /etc/pebble/api.crt
	email ana@ipelivros.example
}

ipelivros.example, www.ipelivros.example {
	root * /var/www/ipe
	file_server
	reverse_proxy /api/* 127.0.0.1:8001 127.0.0.1:8002
}
EOF

block caddy
run 'cat /etc/caddy/Caddyfile'
run 'sudo systemctl stop nginx && sudo systemctl start caddy && sleep 6 && systemctl is-active caddy'
run "sudo journalctl -u caddy --no-pager -o cat | grep -o '\"msg\":\"[^\"]*\"' | grep -iE 'certif|challenge|obtain|authoriz' | uniq"
run "curl -sS https://ipelivros.example/api/books/3 -o /dev/null -w '%{http_code}\n'"
run 'echo | openssl s_client -connect ipelivros.example:443 -servername ipelivros.example 2>/dev/null | openssl x509 -noout -issuer -dates'
run "curl -sI http://ipelivros.example/css/site.css | grep -E 'HTTP|Location'"
run 'sudo systemctl stop caddy && sudo systemctl start nginx && systemctl is-active nginx'
