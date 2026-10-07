#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of servers-cache, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the server
# from `lab.sh reset 2`, which is lesson 1's end state (Nginx running with the
# bookshop's static site on port 80, Apache and Caddy stopped) and the shop's
# two instances on 8001 and 8002. Each version of the site's configuration is
# written whole with sudo tee and shown in the lesson. The one slow request of
# the least_conn section is started in the background by this script. Dates
# and times differ on every run.
#
# Recorded on Ubuntu 24.04 under systemd-nspawn, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
SITE=/etc/nginx/sites-available/ipelivros
apply() { quiet 'sudo nginx -t && sudo systemctl reload nginx'; sleep 1; }

lab reset 2

block direct
run 'curl -s localhost:8001/api/echo'

put $SITE <<'EOF'
server {
    listen 80;
    server_name ipelivros.example www.ipelivros.example;

    root /var/www/ipe;
    index index.html;

    location /api/ {
        proxy_pass http://127.0.0.1:8001;
    }

    access_log /var/log/nginx/ipelivros.access.log;
    error_log  /var/log/nginx/ipelivros.error.log;
}
EOF
apply

block first-proxy
run "grep -A2 'location /api/' $SITE"
run 'curl -si http://ipelivros.example/api/books/3'
run 'curl -s http://ipelivros.example/api/echo'

put $SITE <<'EOF'
server {
    listen 80;
    server_name ipelivros.example www.ipelivros.example;

    root /var/www/ipe;
    index index.html;

    location /api/ {
        proxy_pass http://127.0.0.1:8001;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    access_log /var/log/nginx/ipelivros.access.log;
    error_log  /var/log/nginx/ipelivros.error.log;
}
EOF
apply

block headers
run "grep -A6 'location /api/' $SITE"
run 'curl -s http://ipelivros.example/api/echo'
run "curl -s -H 'X-Forwarded-For: 198.51.100.7' http://ipelivros.example/api/echo"
run 'cat /etc/nginx/proxy_params'

put $SITE <<'EOF'
upstream shop {
    server 127.0.0.1:8001;
    server 127.0.0.1:8002;
    keepalive 16;
}

server {
    listen 80;
    server_name ipelivros.example www.ipelivros.example;

    root /var/www/ipe;
    index index.html;

    location /api/ {
        proxy_pass http://shop;
        proxy_http_version 1.1;
        proxy_set_header Connection        "";
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    access_log /var/log/nginx/ipelivros.access.log;
    error_log  /var/log/nginx/ipelivros.error.log;
}
EOF
apply

block upstream
run "sed -n '1,5p' $SITE"
run 'for i in 1 2 3 4 5 6; do curl -s -o /dev/null -D - http://ipelivros.example/api/books/1 | grep X-Served-By; done'
run 'for i in $(seq 100); do curl -s http://ipelivros.example/api/echo | jq -r .server; done | sort | uniq -c'
run "sudo ss -Htn state established '( dport = :8001 or dport = :8002 )' | wc -l"
run "sudo sed -i 's/^upstream shop {/upstream shop {\n    zone shop 64k;/' $SITE && sed -n '1,6p' $SITE"
apply
run 'for i in 1 2 3 4 5 6; do curl -s -o /dev/null -D - http://ipelivros.example/api/books/1 | grep X-Served-By; done'

block weights
run "sudo sed -i 's/server 127.0.0.1:8001;/server 127.0.0.1:8001 weight=3;/' $SITE && sed -n '1,6p' $SITE"
apply
run 'for i in $(seq 100); do curl -s http://ipelivros.example/api/echo | jq -r .server; done | sort | uniq -c'
run "sudo sed -i 's/ weight=3;/;/' $SITE"
apply

block least-conn
run '(curl -s "http://ipelivros.example/api/slow?s=4" > /dev/null &); sleep 0.5; for i in 1 2 3 4; do curl -s http://ipelivros.example/api/echo | jq -r .server; done'
quiet 'sleep 4'
run "sudo sed -i 's/^    zone shop 64k;/    zone shop 64k;\n    least_conn;/' $SITE && sed -n '1,7p' $SITE"
apply
run '(curl -s "http://ipelivros.example/api/slow?s=4" > /dev/null &); sleep 0.5; for i in 1 2 3 4; do curl -s http://ipelivros.example/api/echo | jq -r .server; done'
quiet 'sleep 4'
run "sudo sed -i 's/    least_conn;/    hash \$remote_addr;/' $SITE && sed -n '1,7p' $SITE"
apply
run 'for i in $(seq 20); do curl -s http://ipelivros.example/api/echo | jq -r .server; done | sort | uniq -c'
run "sudo sed -i '/    hash \$remote_addr;/d' $SITE"
apply

block failure
run 'sudo systemctl stop shop@2'
run 'for i in 1 2 3 4 5 6; do curl -s -o /dev/null -w "%{http_code} " http://ipelivros.example/api/books/1; done; echo'
run 'tail -n 2 /var/log/nginx/ipelivros.error.log'
run 'sudo systemctl stop shop@1'
run 'curl -si http://ipelivros.example/api/books/1 | head -n 4'
run 'tail -n 1 /var/log/nginx/ipelivros.error.log'
run 'sudo systemctl start shop@1 shop@2'
run 'curl -s -o /dev/null -w "%{http_code}\n" http://ipelivros.example/api/books/1'
run 'sleep 10; curl -s -o /dev/null -w "%{http_code}\n" http://ipelivros.example/api/books/1'

block timeout
run "time curl -s -o /dev/null -w '%{http_code}\n' 'http://ipelivros.example/api/slow?s=5'"
run "sudo sed -i 's|        proxy_pass http://shop;|        proxy_pass http://shop;\n        proxy_read_timeout 3s;|' $SITE && grep -A2 'location /api/' $SITE"
apply
run "time curl -s -o /dev/null -w '%{http_code}\n' 'http://ipelivros.example/api/slow?s=5'"
run "tail -n 2 /var/log/nginx/ipelivros.error.log | sed -E 's/ \\[error\\].*(upstream timed out).*(upstream: \"[^\"]*\").*/ \\1, \\2/'"

put $SITE <<'EOF'
upstream shop {
    server 127.0.0.1:8001;
    server 127.0.0.1:8002;
    keepalive 16;
}

server {
    listen 80;
    server_name ipelivros.example www.ipelivros.example;

    root /var/www/ipe;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
        add_header X-Location "prefix /";
    }

    location /api/ {
        proxy_pass http://shop;
        proxy_http_version 1.1;
        proxy_set_header Connection        "";
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 10s;
        add_header X-Location "prefix /api/";
    }

    location = /healthz {
        proxy_pass http://shop;
        add_header X-Location "exact /healthz";
    }

    location ~* \.(css|js|svg)$ {
        add_header X-Location "regex static";
    }

    location /covers/ {
        alias /var/www/ipe/img/;
        add_header X-Location "prefix /covers/";
    }

    access_log /var/log/nginx/ipelivros.access.log;
    error_log  /var/log/nginx/ipelivros.error.log;
}
EOF
apply

block locations
run "for p in / /index.html /healthz /api/books/2 /css/site.css /covers/logo.svg /api/app.js /nope; do printf '%-18s ' \$p; curl -s -o /dev/null -D - http://ipelivros.example\$p | grep -iE '^(HTTP|X-Location)' | tr -d '\r' | tr '\n' ' '; echo; done"

run "sudo sed -i 's|    location /covers/ {|    location ^~ /covers/ {|' $SITE && grep -n 'covers' $SITE"
apply
run "curl -s -o /dev/null -D - http://ipelivros.example/covers/logo.svg | grep -iE '^(HTTP|X-Location)'"

block static
run "curl -s -o /dev/null -w '%{size_download} bytes\n' -H 'Accept-Encoding: gzip' http://ipelivros.example/api/books"
run "curl -sI -H 'Accept-Encoding: gzip' http://ipelivros.example/js/app.js | grep -iE 'content-(type|encoding|length)'"
run "grep -n gzip /etc/nginx/nginx.conf"
put /etc/nginx/conf.d/gzip.conf <<'EOF'
gzip_types text/css application/javascript application/json image/svg+xml;
gzip_min_length 256;
gzip_vary on;
EOF
apply
run 'cat /etc/nginx/conf.d/gzip.conf'
run "curl -sI -H 'Accept-Encoding: gzip' http://ipelivros.example/js/app.js | grep -iE 'content-(type|encoding|length)|vary'"
run "curl -s -o /dev/null -w '%{size_download} bytes\n' -H 'Accept-Encoding: gzip' http://ipelivros.example/api/books"
run "curl -s -o /dev/null -w '%{size_download} bytes\n' http://ipelivros.example/api/books"
run "head -c 2000000 /dev/zero | curl -s -o /dev/null -w '%{http_code}\n' -X PUT --data-binary @- http://ipelivros.example/api/books/1"
run 'tail -n 1 /var/log/nginx/ipelivros.error.log'
