#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of servers-cache, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the server
# from `lab.sh reset 7`, which is lesson 5's end state (HTTPS, and Nginx
# caching the API, which this lesson leaves alone). The edge is Varnish, from
# Ubuntu's archive, on the same machine as the origin: a real CDN is hundreds
# of edges in other cities, and the lab has one, on loopback, so no time in
# these transcripts includes a network. The files the lesson shows are written
# with sudo tee. Varnish's transaction ids, ages and times differ on every run.
#
# Recorded on Ubuntu 24.04 under systemd-nspawn, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
apply() { lab as 'sudo nginx -t' >/dev/null 2>&1 || echo '!!! nginx -t FAILED'; quiet 'sudo systemctl reload nginx'; sleep 1; }
shopenv() { quiet "echo 'SHOP_CACHE_CONTROL=$1' | sudo tee /etc/shop/shop.env && sudo systemctl restart shop@1 shop@2"; sleep 1; }
E='http://localhost:6081'
H="-H 'Host: ipelivros.example'"
hdr() { echo "curl -s -o /dev/null -D - $H $E$1 | grep -iE '^(age|x-cache|x-varnish|cache-control)'"; }

lab reset 7

put /etc/nginx/sites-available/origin <<'EOF'
# The origin, as the edge sees it: plain HTTP, on an address only this
# machine can reach. Every response carries the tags the edge purges by.
server {
    listen 127.0.0.1:8080;
    server_name ipelivros.example;

    root /var/www/ipe;

    location / {
        try_files $uri $uri/ =404;
    }

    location = /healthz {
        proxy_pass http://shop;
    }

    location = /api/books {
        proxy_pass http://shop;
        add_header Surrogate-Key "listing";
    }

    location ~ ^/api/books/(\d+)$ {
        proxy_pass http://shop;
        add_header Surrogate-Key "book-$1";
    }
}
EOF

put /etc/varnish/default.vcl <<'EOF'
vcl 4.1;

# The origin: Nginx on 127.0.0.1:8080, asked every two seconds whether it is
# well, and treated as sick after two failed answers out of three.
backend origin {
    .host = "127.0.0.1";
    .port = "8080";
    .probe = {
        .url = "/healthz";
        .interval = 2s;
        .timeout = 1s;
        .window = 3;
        .threshold = 2;
    }
}

# Who may purge. On a real edge, the machines that publish content.
acl purgers {
    "127.0.0.1";
}

sub vcl_recv {
    # Tracking parameters change the URL and never the answer.
    set req.url = regsuball(req.url, "(?<=[?&])utm_[a-z]+=[^&]*&?", "");
    set req.url = regsub(req.url, "[?&]$", "");

    if (req.method == "PURGE") {
        if (client.ip !~ purgers) {
            return (synth(403, "Forbidden"));
        }
        return (purge);
    }
    if (req.method == "BAN") {
        if (client.ip !~ purgers) {
            return (synth(403, "Forbidden"));
        }
        ban("obj.http.Surrogate-Key ~ " + req.http.X-Ban-Tags);
        return (synth(200, "Banned"));
    }
}

sub vcl_backend_response {
    # Keep an expired object for an hour, to serve while the origin is
    # fetched again or while it is down.
    set beresp.grace = 1h;
}

sub vcl_deliver {
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
    } else {
        set resp.http.X-Cache = "MISS";
    }
    # The tags are for the edge, not for the public.
    unset resp.http.Surrogate-Key;
}
EOF

block origin
run 'cat /etc/nginx/sites-available/origin'
run 'sudo ln -s ../sites-available/origin /etc/nginx/sites-enabled/origin'
apply
run "curl -sI $H http://127.0.0.1:8080/api/books/2 | grep -iE '^(HTTP|cache-control|surrogate-key|x-served-by)'"

block edge
run 'sudo varnishd -C -f /etc/varnish/default.vcl > /dev/null 2>&1 && echo "VCL compiles"'
run 'sudo systemctl start varnish && systemctl is-active varnish'
quiet 'sleep 3'
run "sudo ss -ltnp | grep -E ':(6081|6082|8080) ' | awk '{print \$4, \$6}'"
run "$(hdr /api/books/2)"
run "$(hdr /api/books/2)"
run "sleep 3; $(hdr /api/books/2)"
run "curl -sI $H $E/api/books/2 | grep -iE '^(via|surrogate-key|x-served-by)'"

block cookies
run "for i in 1 2; do curl -s -o /dev/null -D - $H -H 'Cookie: session=abc' $E/api/books/3 | grep -iE '^(x-cache|x-varnish)'; done"
run "for i in 1 2; do curl -s -o /dev/null -D - $H -H 'Authorization: Bearer abc' $E/api/books/3 | grep -iE '^(x-cache|x-varnish)'; done"

block key
run "for q in '?utm_source=news' '?utm_source=ads&utm_medium=cpc' '' '?page=2'; do printf '%-34s ' \"\$q\"; curl -s -o /dev/null -D - $H \"$E/api/books/4\$q\" | grep -i x-cache; done"

block purge
run "$(hdr /api/books/5)"
run "curl -s -o /dev/null -w '%{http_code}\n' -X PURGE $H $E/api/books/5"
run "$(hdr /api/books/5)"

block ban
quiet "for p in /api/books /api/books/2 /api/books/6; do curl -s -o /dev/null $H $E\$p; done"
run "for p in /api/books /api/books/2 /api/books/6; do printf '%-14s ' \$p; curl -s -o /dev/null -D - $H $E\$p | grep -i x-cache; done"
run "curl -s -X PUT -d '{\"price_cents\": 7490}' $H $E/api/books/2 | jq -c '{title, price_cents}'"
run "curl -s -o /dev/null -w '%{http_code}\n' -X BAN -H 'X-Ban-Tags: \\b(book-2|listing)\\b' $H $E/"
run "for p in /api/books /api/books/2 /api/books/6; do printf '%-14s ' \$p; curl -s -o /dev/null -D - $H $E\$p | grep -i x-cache; done"
run "curl -s $H $E/api/books/2 | jq -c '{title, price_cents}'"
run 'sudo varnishadm ban.list'

block grace
shopenv 'public, max-age=5'
run "$(hdr /api/books/7)"
run 'sleep 6; sudo systemctl stop shop@1 shop@2; sleep 5; sudo varnishadm backend.list'
run "$(hdr /api/books/7)"
run "curl -s -o /dev/null -w '%{http_code}\n' $H $E/api/books/8"
run 'sudo systemctl start shop@1 shop@2'

block stats
quiet 'sleep 3'
run "sudo varnishstat -1 -f MAIN.cache_hit -f MAIN.cache_miss -f MAIN.cache_hitpass -f MAIN.s_pass -f MAIN.n_object -f MAIN.backend_req | awk '{print \$1, \$2}'"
