#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of servers-cache, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the server
# from `lab.sh reset 6`, which is lesson 5's end state (HTTPS, and Nginx
# caching the API for as long as the shop's `Cache-Control: public,
# max-age=60` allows, with requests carrying credentials kept out). The files
# the lesson shows are written with sudo tee. The shop's database is slow on
# purpose (120 ms a query). Dates and times differ on every run.
#
# Recorded on Ubuntu 24.04 under systemd-nspawn, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
SITE=/etc/nginx/sites-available/ipelivros
apply() { lab as 'sudo nginx -t' >/dev/null 2>&1 || echo '!!! nginx -t FAILED'; quiet 'sudo systemctl reload nginx'; sleep 1; }
shopenv() { quiet "echo 'SHOP_CACHE_CONTROL=$1' | sudo tee /etc/shop/shop.env && sudo systemctl restart shop@1 shop@2"; sleep 1; }
U=https://ipelivros.example
price() { echo "curl -s -D /tmp/h $U/api/books/$1 | jq -c '{title, price_cents}'; grep -i x-cache-status /tmp/h"; }

lab reset 6

block stale
run "$(price 2)"
run "curl -s -X PUT -d '{\"price_cents\": 7990}' $U/api/books/2 | jq -c '{title, price_cents}'"
run "$(price 2)"
run "curl -s localhost:8001/api/books/2 | jq -c '{title, price_cents}'"

block refresh
put /etc/nginx/conf.d/refresh.conf <<'EOF'
# A request carrying this header is sent to the shop, and its answer replaces
# the cached copy. The token keeps strangers from emptying the cache at will.
map $http_x_cache_refresh $cache_refresh {
    default                    0;
    "lab-refresh-token-2026"   1;
}
EOF
run 'cat /etc/nginx/conf.d/refresh.conf'
run "sudo sed -i 's|        proxy_cache_bypass \$http_authorization;|        proxy_cache_bypass \$http_authorization \$cache_refresh;|' $SITE && grep -n 'proxy_cache_bypass' $SITE"
apply
run "curl -s -o /dev/null -D - -H 'X-Cache-Refresh: lab-refresh-token-2026' $U/api/books/2 | grep -i x-cache-status"
run "$(price 2)"
run "curl -s -o /dev/null -D - -H 'X-Cache-Refresh: guess' $U/api/books/2 | grep -i x-cache-status"

block delete
run "curl -s -X PUT -d '{\"price_cents\": 6990}' $U/api/books/2 > /dev/null; $(price 2)"
run "echo -n 'http://shop/api/books/2' | md5sum"
run "K=\$(echo -n 'http://shop/api/books/2' | md5sum | cut -c1-32); sudo ls -l /var/cache/nginx/shop/\${K: -1}/\${K: -3:2}/\$K"
run "K=\$(echo -n 'http://shop/api/books/2' | md5sum | cut -c1-32); sudo rm /var/cache/nginx/shop/\${K: -1}/\${K: -3:2}/\$K"
run "$(price 2)"

block versioned
run 'cd /var/www/ipe/css && sha256sum site.css | cut -c1-8'
run 'cd /var/www/ipe/css && sudo cp site.css site.$(sha256sum site.css | cut -c1-8).css && ls'
run "sudo sed -i 's|/css/site.css|/css/site.c867bf6d.css|' /var/www/ipe/index.html && grep stylesheet /var/www/ipe/index.html"
put /etc/nginx/snippets/versioned-assets.conf <<'EOF'
# A file whose name carries eight hex digits of its own hash never changes:
# a new version is a new name. Keep it for a year and never ask again.
location ~* "\.[0-9a-f]{8}\.(css|js)$" {
    add_header Cache-Control "public, max-age=31536000, immutable";
}
EOF
run 'cat /etc/nginx/snippets/versioned-assets.conf'
run "sudo sed -i '0,/    index index.html;/s//    index index.html;\n    include snippets\/versioned-assets.conf;/' $SITE && grep -n 'versioned' $SITE"
apply
run "curl -sI $U/css/site.c867bf6d.css | grep -iE '^(HTTP|cache-control)'"

block use-stale
shopenv 'public, max-age=5'
run "sudo sed -i 's|        proxy_cache api_cache;|        proxy_cache api_cache;\n        proxy_cache_use_stale error timeout http_500 http_502 http_503 http_504;|' $SITE && grep -n 'use_stale' $SITE"
apply
run "$(price 3)"
run 'sleep 6; sudo systemctl stop shop@1 shop@2'
run "$(price 3)"
run "curl -s -o /dev/null -w '%{http_code}\n' $U/api/books/4"
run 'sudo systemctl start shop@1 shop@2'

block background
run "sudo sed -i 's|        proxy_cache_use_stale error timeout http_500 http_502 http_503 http_504;|        proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;\n        proxy_cache_background_update on;|' $SITE && grep -n 'use_stale\|background' $SITE"
apply
run "curl -s -o /dev/null -w '%{http_code} in %{time_total} s\n' $U/api/books/5"
run "sleep 6; for i in 1 2 3; do curl -s -o /dev/null -D /tmp/h -w '%{time_total} s ' $U/api/books/5; grep -i x-cache-status /tmp/h; sleep 0.5; done"
