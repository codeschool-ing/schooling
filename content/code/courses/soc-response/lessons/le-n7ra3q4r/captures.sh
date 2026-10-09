#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of soc-response, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from one run of it, block by block, into the lesson.
#
#   sudo bash captures.sh OUTDIR
#
# The machine is the one lesson 1 prepares, with soclab.sh (the lab.sh beside
# course.json) in root's home folder. Commands at the root@soc prompt run as
# root, each with a clean environment.
#
# STAGED, NOT TYPED: the lab is torn down and built again at the start, so the
# firewall chain holds only soclab.sh's logging rule and every rule handle
# starts from the same number. Nothing else: the backup provider's address and
# the small web server on outside are commands the lesson prints and the
# student types.
#
# Recorded on Ubuntu 24.04 with nftables 1.0.9, curl 8.5.0, TZ=America/Sao_Paulo.

set -uo pipefail
OUT=${1:?outdir}; mkdir -p "$OUT"
HERE=$(cd "$(dirname "$0")" && pwd)
ENV='HOME=/root PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TZ=America/Sao_Paulo LANG=C.UTF-8 COLUMNS=100'
root() { printf 'root@soc:~# %s\n' "$*"; (cd /root && env -i $ENV bash -c "$*") 2>&1; }
block() { exec >"$OUT/$1.txt"; }
quiet() { (cd /root && env -i $ENV bash -c "$*") >/dev/null 2>&1; }

install -m 755 "$HERE/../../lab.sh" /root/soclab.sh
quiet 'bash soclab.sh down; rm -rf /var/log/soclab /root/ir'
quiet 'bash soclab.sh up'
sleep 2

block collect
root 'mkdir ir'
root 'date -Is > ir/when.txt; for h in gw files; do ip netns exec $h ss -tan > ir/$h-ss.txt; done'
root 'cat ir/when.txt ir/files-ss.txt'
root 'sha256sum ir/*'

block setup
root 'ip -n outside addr add 203.0.113.150/24 dev eth0'
root 'ip netns exec outside python3 -m http.server 8080 >/dev/null 2>&1 &'
sleep 2

block before
root 'ip netns exec files curl -s -o /dev/null -w "%{http_code}\n" http://203.0.113.200:8080/'
root 'ip netns exec files curl -s -o /dev/null -w "%{http_code}\n" http://203.0.113.150:8080/'

block egress
root "ip netns exec fw nft add rule ip fw forward ip saddr 192.168.20.10 oifname eth0 ip daddr != 203.0.113.150 counter drop comment '\"INC-2026-014 files egress\"'"
root 'ip netns exec fw nft -a list chain ip fw forward'

block after
root 'ip netns exec files curl -s -m 5 -o /dev/null -w "%{http_code}\n" http://203.0.113.200:8080/; echo "exit $?"'
root 'ip netns exec files curl -s -m 5 -o /dev/null -w "%{http_code}\n" http://203.0.113.150:8080/'
root 'ip netns exec files nc -z -w 3 198.51.100.22 22; echo "exit $?"'
root 'ip netns exec fw nft list chain ip fw forward | grep files'
root "grep 'DST=203.0.113.200' /var/log/soclab/fw.log | tail -1"

block blocksrc
root 'ip netns exec outside nc -z -w 3 -s 203.0.113.66 198.51.100.22 22; echo "exit $?"'
root "ip netns exec fw nft insert rule ip fw forward ip saddr 203.0.113.66 counter drop comment '\"INC-2026-014 source\"'"
root 'ip netns exec outside nc -z -w 3 -s 203.0.113.66 198.51.100.22 22; echo "exit $?"'
root 'ip netns exec outside nc -z -w 3 -s 203.0.113.200 198.51.100.22 22; echo "exit $?"'

block undo
root 'ip netns exec fw nft -a list chain ip fw forward'
root 'ip netns exec fw nft delete rule ip fw forward handle 4'
root 'ip netns exec outside nc -z -w 3 -s 203.0.113.66 198.51.100.22 22; echo "exit $?"'

quiet 'ip netns pids outside | xargs -r kill'
