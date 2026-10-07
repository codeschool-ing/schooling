#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of servers-cache, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the server
# from `lab.sh reset 5`, which is lesson 3's end state (the site on HTTPS with
# a certificate from Pebble, the API behind it). Lesson 4's hardening is left
# out on purpose, so that the headers on screen are the caching ones. The
# files the lesson shows are written with sudo tee. The shop's database is
# slow on purpose (120 ms a query, see lab.sh), so times are the lab's; the
# Date header and the times differ on every run.
#
# Recorded on Ubuntu 24.04 under systemd-nspawn, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
SITE=/etc/nginx/sites-available/ipelivros
apply() { quiet 'sudo nginx -t && sudo systemctl reload nginx'; sleep 1; }
shopenv() { quiet "echo 'SHOP_CACHE_CONTROL=$1' | sudo tee /etc/shop/shop.env && sudo systemctl restart shop@1 shop@2"; sleep 1; }
resetstats() { quiet 'curl -s -X POST localhost:8001/api/stats/reset; curl -s -X POST localhost:8002/api/stats/reset'; }
U=https://ipelivros.example

lab reset 5

block heuristic
run "curl -sI $U/css/site.css | grep -iE '^(HTTP|cache-control|expires|last-modified|etag)'"
run "curl -sI $U/api/books/1 | grep -iE '^(HTTP|cache-control|expires|last-modified|etag)'"

block freshness
run "sudo sed -i '0,/    location \\/ {/s||    location ~* \\\\.(css\|js\|svg)\$ {\n        expires 1h;\n    }\n\n    location / {|' $SITE && grep -n -A2 'location ~' $SITE"
apply
run "curl -sI $U/css/site.css | grep -iE '^(date|cache-control|expires|last-modified)'"
run "echo 'SHOP_CACHE_CONTROL=max-age=60' | sudo tee /etc/shop/shop.env && sudo systemctl restart shop@1 shop@2"
quiet 'sleep 1'
run "curl -sI $U/api/books/1 | grep -iE '^(cache-control|etag|last-modified)'"

block validation
run "curl -sI $U/css/site.css | grep -i etag"
run "curl -s -o /dev/null -w '%{http_code} %{size_download} bytes\n' -H 'If-None-Match: \"6a96cc50-ed\"' $U/css/site.css"
run "curl -s -o /dev/null -w '%{http_code} %{size_download} bytes\n' -H 'If-None-Match: \"6a96cc50-ee\"' $U/css/site.css"
run "curl -s -o /dev/null -w '%{http_code} %{size_download} bytes\n' -H 'If-Modified-Since: Tue, 01 Sep 2026 13:00:00 GMT' $U/css/site.css"
run "curl -sI -H 'Accept-Encoding: gzip' $U/js/app.js | grep -iE '^(etag|content-encoding)'"

block validation-api
resetstats
run "curl -s -o /dev/null -w '%{http_code} %{size_download} bytes in %{time_total} s\n' $U/api/books/1"
run "curl -s -o /dev/null -w '%{http_code} %{size_download} bytes in %{time_total} s\n' -H 'If-None-Match: \"806121fbab2ee803\"' $U/api/books/1"
run "curl -s localhost:8001/api/stats; curl -s localhost:8002/api/stats"

put /etc/nginx/conf.d/cache.conf <<'EOF'
proxy_cache_path /var/cache/nginx/shop levels=1:2 keys_zone=api_cache:10m
                 max_size=100m inactive=10m use_temp_path=off;
EOF

block proxy-cache
run 'cat /etc/nginx/conf.d/cache.conf'
run 'sudo nginx -t'
run 'sudo mkdir -p /var/cache/nginx && sudo nginx -t'
run "sudo sed -i 's|        proxy_pass http://shop;|        proxy_pass http://shop;\n        proxy_cache api_cache;\n        add_header X-Cache-Status \$upstream_cache_status always;|' $SITE && grep -n -A2 'proxy_pass' $SITE"
apply
resetstats
run "for i in 1 2 3; do curl -s -o /dev/null -D - -w 'took %{time_total} s\n' $U/api/books/2 | grep -iE '^x-cache-status|^took'; done"
run 'for p in 8001 8002; do curl -s localhost:$p/api/stats; done'
run "sudo find /var/cache/nginx/shop -type f"
run "sudo find /var/cache/nginx/shop -type f -exec grep -a -m1 '^KEY' {} \;"

block expiry
shopenv 'max-age=5'
resetstats
run "grep SHOP /etc/shop/shop.env"
run "curl -s -o /dev/null -D - $U/api/books/3 | grep -i x-cache-status"
run "curl -s -o /dev/null -D - $U/api/books/3 | grep -i x-cache-status"
run "sleep 6; curl -s -o /dev/null -D - $U/api/books/3 | grep -i x-cache-status"
run "curl -s -o /dev/null -D - $U/api/books/3 | grep -i x-cache-status"
run 'for p in 8001 8002; do curl -s localhost:$p/api/stats; done'

block private
shopenv 'private, max-age=60'
resetstats
run "grep SHOP /etc/shop/shop.env"
run "for i in 1 2 3; do curl -s -o /dev/null -D - $U/api/books/4 | grep -iE '^(cache-control|x-cache-status)'; done"
run 'for p in 8001 8002; do curl -s localhost:$p/api/stats; done'

block key
shopenv 'public, max-age=60'
resetstats
run "for q in '' '?a=1' '?a=2' '?a=1'; do printf '%-6s ' \"\$q\"; curl -s -o /dev/null -D - \"$U/api/books/5\$q\" | grep -i x-cache-status; done"
run "curl -s -o /dev/null -D - -H 'Cache-Control: no-cache' $U/api/books/5 | grep -i x-cache-status"
run "curl -s -o /dev/null -D - -H 'Authorization: Bearer abc' $U/api/books/5 | grep -i x-cache-status"
run "sudo sed -i 's|        proxy_cache api_cache;|        proxy_cache api_cache;\n        proxy_cache_bypass \$http_authorization;\n        proxy_no_cache     \$http_authorization;|' $SITE && grep -n 'proxy_cache\|proxy_no_cache' $SITE"
apply
run "curl -s -o /dev/null -D - -H 'Authorization: Bearer abc' $U/api/books/5 | grep -i x-cache-status"
run "curl -s -o /dev/null -D - $U/api/books/5 | grep -i x-cache-status"

put /etc/nginx/conf.d/cache-log.conf <<'EOF'
log_format cache '$remote_addr [$time_local] "$request" $status '
                 'cache=$upstream_cache_status upstream_time=$upstream_response_time';
EOF

block hit-ratio
run 'cat /etc/nginx/conf.d/cache-log.conf'
run "sudo sed -i 's|    access_log /var/log/nginx/ipelivros.access.log;|    access_log /var/log/nginx/ipelivros.access.log;\n    access_log /var/log/nginx/ipelivros.cache.log cache;|' $SITE"
apply
quiet "sudo find /var/cache/nginx/shop -type f -delete"
resetstats
run "for i in \$(seq 200); do curl -s -o /dev/null $U/api/books/\$(( (i % 10) + 1 )); done; tail -n 3 /var/log/nginx/ipelivros.cache.log"
run "awk '{print \$8}' /var/log/nginx/ipelivros.cache.log | sort | uniq -c"
run 'for p in 8001 8002; do curl -s localhost:$p/api/stats; done'

block bench
run "ab -q -n 200 -c 10 http://localhost:8001/api/books/6 | grep -E 'Requests per second|Time per request.*mean\)$'"
run "ab -q -n 200 -c 10 $U/api/books/6 | grep -E 'Requests per second|Time per request.*mean\)$'"
