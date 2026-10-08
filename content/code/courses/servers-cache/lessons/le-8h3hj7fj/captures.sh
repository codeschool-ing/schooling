#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of servers-cache, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the server
# itself, built by `lab.sh reset 1`: `lab.sh install` already run, which
# installed every package and stopped every web server, exactly as on the
# student's machine; the shop's two instances, which lesson 2 puts behind
# nginx. The files the lesson shows (a server block, a virtual host, a
# Caddyfile) are written by this script with sudo tee. Dates, process ids and
# the Date header differ on every run.
#
# Recorded on Ubuntu 24.04 under systemd-nspawn, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"

lab reset 1

block the-server
run 'grep PRETTY /etc/os-release; nproc; free -h | head -2'
run "apt-cache policy nginx apache2 caddy | grep -E '^[a-z]|Installed'"
run 'systemctl is-active shop@1 shop@2 nginx apache2 caddy'
run 'grep ipelivros /etc/hosts'
run 'ls -l ~/work'

block origin
run 'curl -sI localhost:8002/api/books/1'
run 'curl -s localhost:8001/api/books/3'

block nginx-start
run 'sudo systemctl enable --now nginx'
run 'systemctl status nginx --no-pager --lines 0'
run "sudo ss -ltnp 'sport = :80'"
run 'curl -sI http://localhost/'

block nginx-tree
run 'ls /etc/nginx'
run 'ls -l /etc/nginx/sites-enabled/'
run "grep -Ev '^\s*(#|$)' /etc/nginx/nginx.conf"

put /etc/nginx/sites-available/ipelivros <<'EOF'
server {
    listen 80;
    server_name ipelivros.example www.ipelivros.example;

    root /var/www/ipe;
    index index.html;

    access_log /var/log/nginx/ipelivros.access.log;
    error_log  /var/log/nginx/ipelivros.error.log;
}
EOF

block nginx-site
run 'cat /etc/nginx/sites-available/ipelivros'
run 'sudo ln -s ../sites-available/ipelivros /etc/nginx/sites-enabled/ipelivros'
run 'sudo nginx -t'
run 'sudo systemctl reload nginx'
quiet 'sleep 1'
run 'curl -s http://ipelivros.example/ | head -4'
run 'curl -sI http://ipelivros.example/css/site.css'
run "curl -s -o /dev/null -w '%{http_code}\n' http://localhost/css/site.css"
run "curl -s -o /dev/null -w '%{http_code}\n' -H 'Host: www.ipelivros.example' http://localhost/css/site.css"
run "curl -s -o /dev/null -w '%{http_code}\n' http://ipelivros.example/nothing-here"

block apache-conflict
run 'sudo systemctl start apache2'
run 'sudo journalctl -u apache2 --no-pager -o cat | grep -E "AH0|Address"'

put /etc/apache2/sites-available/ipelivros.conf <<'EOF'
<VirtualHost *:8080>
    ServerName ipelivros.example
    ServerAlias www.ipelivros.example
    DocumentRoot /var/www/ipe

    ErrorLog ${APACHE_LOG_DIR}/ipelivros-error.log
    CustomLog ${APACHE_LOG_DIR}/ipelivros-access.log combined
</VirtualHost>
EOF

block apache-site
run "sudo sed -i 's/^Listen 80\$/Listen 8080/' /etc/apache2/ports.conf"
run 'cat /etc/apache2/sites-available/ipelivros.conf'
run 'sudo a2dissite 000-default && sudo a2ensite ipelivros'
run 'sudo apachectl configtest'
run 'sudo systemctl start apache2'
run 'curl -sI http://ipelivros.example:8080/css/site.css'
run 'a2query -M'
run 'ls /etc/apache2/mods-enabled/ | head -12'

put /etc/caddy/Caddyfile <<'EOF'
http://ipelivros.example:8081, http://www.ipelivros.example:8081 {
	root * /var/www/ipe
	file_server
	log {
		output file /var/log/caddy/ipelivros.access.log
	}
}
EOF

block caddy-site
run 'cat /etc/caddy/Caddyfile'
run 'caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile 2>&1 | tail -1'
run 'sudo systemctl start caddy'
run 'curl -sI http://ipelivros.example:8081/css/site.css'

block processes
run 'ps -o pid,ppid,user,nlwp,rss,cmd -C nginx'
run 'ps -o pid,ppid,user,nlwp,rss,cmd -C apache2'
run 'ps -o pid,ppid,user,nlwp,rss,cmd -C caddy'
run "sudo ss -ltnp | grep -E ':(80|8080|8081) '"

block load
run "ab -q -n 2000 -c 50 http://ipelivros.example/css/site.css | grep -E 'Requests per second|Failed|Time per request.*mean\)$'"
run "ab -q -n 2000 -c 50 http://ipelivros.example:8080/css/site.css | grep -E 'Requests per second|Failed|Time per request.*mean\)$'"
run "ab -q -n 2000 -c 50 http://ipelivros.example:8081/css/site.css | grep -E 'Requests per second|Failed|Time per request.*mean\)$'"

block logs
run 'tail -n 2 /var/log/nginx/ipelivros.access.log'
run "sudo tail -n 1 /var/log/apache2/ipelivros-access.log"
run "sudo tail -n 1 /var/log/caddy/ipelivros.access.log | jq -c '{status, uri: .request.uri, size, duration}'"
run 'curl -s -o /dev/null http://ipelivros.example/nothing-here; tail -n 1 /var/log/nginx/ipelivros.error.log'

block reload
run 'ps -o pid,cmd --ppid $(cat /run/nginx.pid) -p $(cat /run/nginx.pid)'
run 'sudo systemctl reload nginx; sleep 1; ps -o pid,cmd --ppid $(cat /run/nginx.pid) -p $(cat /run/nginx.pid)'
run "sudo sed -i 's/    root /    rooot /' /etc/nginx/sites-available/ipelivros"
run 'sudo nginx -t'
run 'sudo systemctl reload nginx; echo "exit $?"'
quiet 'sleep 1'
run 'sudo journalctl -u nginx --no-pager -o cat | tail -n 3'
run "curl -s -o /dev/null -w '%{http_code}\n' http://ipelivros.example/"
run 'sudo systemctl restart nginx; echo "exit $?"'
run "curl -s -o /dev/null -w '%{http_code}\n' http://ipelivros.example/"
run "sudo sed -i 's/    rooot /    root /' /etc/nginx/sites-available/ipelivros && sudo nginx -t && sudo systemctl start nginx"
run "curl -s -o /dev/null -w '%{http_code}\n' http://ipelivros.example/"
