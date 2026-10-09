#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of soc-response, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from one run of it, block by block, into the lesson.
#
#   sudo bash captures.sh OUTDIR
#
# The machine is the one lesson 1 prepares, with soclab.sh (the lab.sh beside
# course.json) in root's home folder. Commands at the root@soc prompt run as
# root and those at ana@soc as ana, each with a clean environment.
#
# STAGED, NOT TYPED: the lab is torn down and built again at the start, and
# /root/www, web.pcap and ana's copy of it are removed first. The web server
# on outside is stopped at the end. Source ports, sequence numbers and times
# differ from run to run; the lesson quotes them only as this run's.
#
# Recorded on Ubuntu 24.04 with tcpdump 4.99.4 and TShark 4.2.2, TZ=America/Sao_Paulo.

set -uo pipefail
OUT=${1:?outdir}; mkdir -p "$OUT"
HERE=$(cd "$(dirname "$0")" && pwd)
ENV='HOME=/root PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TZ=America/Sao_Paulo LANG=C.UTF-8 COLUMNS=100'
root() { printf 'root@soc:~# %s\n' "$*"; (cd /root && env -i $ENV bash -c "$*") 2>&1; }
ana()  { printf 'ana@soc:~$ %s\n' "$*"; runuser -u ana -- env -i ${ENV/HOME=\/root/HOME=/home/ana} bash -c "cd; $*" 2>&1; }
block() { exec >"$OUT/$1.txt"; }
quiet() { (cd /root && env -i $ENV bash -c "$*") >/dev/null 2>&1; }

install -m 755 "$HERE/../../lab.sh" /root/soclab.sh
quiet 'bash soclab.sh down; rm -rf /root/www /root/web.pcap /home/ana/web.pcap /home/ana/objects'
quiet 'bash soclab.sh up'
sleep 2

block setup
root 'mkdir www; for i in $(seq 1 3000); do echo "item-$i,$((i * 37 % 900)).90"; done > www/price-list.csv'
root 'ls -l www'
root 'ip netns exec outside python3 -m http.server 8080 --directory www >/dev/null 2>&1 &'
sleep 2

block capture
root 'ip netns exec fw tcpdump -i eth0 -w web.pcap host 192.168.20.10 2>tcpdump.err &'
sleep 2
root 'ip netns exec files curl -s -o /dev/null -w "%{http_code} %{size_download}\n" http://203.0.113.200:8080/price-list.csv'
sleep 1
root 'pkill -x tcpdump; sleep 1; cat tcpdump.err'
root 'install -o ana -m 600 web.pcap /home/ana/'

block read
ana 'tcpdump -nn -r web.pcap 2>/dev/null | head -4'
ana 'tcpdump -nn -r web.pcap 2>/dev/null | wc -l'

block conv
ana 'tshark -r web.pcap -q -z conv,tcp'

block http
ana 'tshark -r web.pcap -Y http -T fields -e frame.number -e ip.src -e ip.dst -e http.request.method -e http.request.uri -e http.response.code -e http.content_length'

block follow
ana 'tshark -r web.pcap -q -z follow,tcp,ascii,0 | head -22'

block export
ana 'tshark -r web.pcap -q --export-objects http,objects'
ana 'ls -l objects'
root 'sha256sum www/price-list.csv /home/ana/objects/price-list.csv'

quiet 'ip netns pids outside | xargs -r kill'
