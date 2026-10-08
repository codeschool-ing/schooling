#!/usr/bin/env bash
# soclab.sh: a small company inside one Linux machine.
#   bash soclab.sh up      build it (as root)
#   bash soclab.sh down    take it all away again
set -euo pipefail
LOG=/var/log/soclab
export TZ=America/Sao_Paulo

cable() {  # cable NS1 IF1 ADDR1 NS2 IF2 ADDR2, where "-" means this computer
  ip link add tmp1 type veth peer name tmp2
  for end in "$1 $2 $3 tmp1" "$4 $5 $6 tmp2"; do
    set -- $end
    if [ "$1" = - ]; then
      ip link set "$4" name "$2"; ip addr add "$3" dev "$2"; ip link set "$2" up
    else
      ip link set "$4" netns "$1"; ip -n "$1" link set "$4" name "$2"
      ip -n "$1" addr add "$3" dev "$2"; ip -n "$1" link set "$2" up
    fi
  done
}

on() {  # on HOST COMMAND...: run a command inside a machine, under its own name
  local h=$1; shift
  ip netns exec "$h" unshare --uts sh -c "hostname $h; exec \"\$@\"" _ "$@"
}

sshd_on() {  # sshd_on HOST ADDRESS: an SSH server whose log lines carry time and name
  on "$1" sh -c "/usr/sbin/sshd -D -e -o ListenAddress=$2 2>&1 | sed -u 's/\\r$//' |
    ts '%Y-%m-%dT%H:%M:%S%z $1 sshd:' >> $LOG/$1-auth.log" &
}

up() {
  mkdir -p "$LOG/flows" /run/sshd
  for h in fw outside gw files; do ip netns add "$h"; ip -n "$h" link set lo up; done
  cable fw eth0 203.0.113.1/24   outside eth0 203.0.113.66/24
  cable fw eth1 198.51.100.1/24  gw      eth0 198.51.100.22/24
  cable fw eth2 192.168.20.1/24  files   eth0 192.168.20.10/24
  cable fw eth3 192.168.99.1/24  -       soc0 192.168.99.10/24
  ip -n outside addr add 203.0.113.200/24 dev eth0
  ip netns exec fw sysctl -qw net.ipv4.ip_forward=1
  ip -n outside route add default via 203.0.113.1
  ip -n gw      route add default via 198.51.100.1
  ip -n files   route add default via 192.168.20.1
  for net in 203.0.113.0/24 198.51.100.0/24 192.168.20.0/24; do
    ip route add "$net" via 192.168.99.1
  done

  # fw writes one line for every new connection it forwards
  ip netns exec fw nft -f - <<'NFT'
table ip fw {
  chain forward {
    type filter hook forward priority filter; policy accept;
    ct state new log group 1 prefix "fw-new "
  }
}
NFT
  cat > "$LOG/ulogd.conf" <<CONF
[global]
logfile="$LOG/ulogd.err"
stack=log1:NFLOG,base1:BASE,ifi1:IFINDEX,ip2str1:IP2STR,print1:PRINTPKT,emu1:LOGEMU
[log1]
group=1
[emu1]
file="$LOG/fw.log"
sync=1
CONF
  on fw /usr/sbin/ulogd -d -c "$LOG/ulogd.conf"

  # fw also turns every conversation that crosses its internet side, eth0,
  # into a flow record: who talked to whom, for how long, how many bytes
  on fw nfpcapd -i eth0 -w "$LOG/flows" -t 60 -e 60,15 >"$LOG/nfpcapd.out" 2>&1 &

  # gw is how staff reach the company from home; files keeps its files
  sshd_on gw 198.51.100.22
  sshd_on files 192.168.20.10
}

down() {
  for h in fw outside gw files; do
    ip netns pids "$h" 2>/dev/null | xargs -r kill
    ip netns del "$h" 2>/dev/null || true
  done
  sleep 1
  ip link del soc0 2>/dev/null || true
}

"$1"
