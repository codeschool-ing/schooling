---
title: O script do laboratório
version: 2
---

Tudo nesta seção é digitado dentro da máquina da seção anterior. Primeiro os pacotes: a suíte de
roteamento, um servidor e um relay DHCP, o anunciador de roteador do IPv6 e as ferramentas com que as
aulas leem a rede. Todos vêm do próprio repositório do Ubuntu.

```sh
sudo apt-get update
sudo apt-get install -y iproute2 bridge-utils ethtool frr tcpdump iputils-ping iputils-arping \
    traceroute nftables conntrack isc-dhcp-server isc-dhcp-client isc-dhcp-relay radvd ndisc6 \
    ipcalc sipcalc wireguard-tools lldpd python3 curl netcat-openbsd
```

Depois, um diretório para o laboratório, e os arquivos dele. **O laboratório é um script, `netlab.sh`,
e um arquivo pequeno por rede**, cada um mostrado inteiro na aula que o usa primeiro. Copie cada um
com o botão do canto, abra o editor no caminho escrito na primeira linha dele, e cole:

```sh
mkdir -p ~/netlab
nano ~/netlab/netlab.sh
```

No `nano`, `Ctrl+O` salva e `Ctrl+X` sai. Este é o script:

```bash
# ~/netlab/netlab.sh: builds this course's networks on one Linux computer.
#
#   sudo bash ~/netlab/netlab.sh up office       build the network in ~/netlab/office.sh
#   sudo bash ~/netlab/netlab.sh on pc1          a shell on pc1, as you
#   sudo bash ~/netlab/netlab.sh on r1 root      a root shell on r1
#   sudo bash ~/netlab/netlab.sh on pc1 "$USER" 'ping -c 2 srv'   one command
#   sudo bash ~/netlab/netlab.sh down            take it all away
#   sudo bash ~/netlab/netlab.sh list            the networks it can build
#
# A device is a network namespace, a cable is a virtual Ethernet pair, a
# switch is a Linux bridge inside its own namespace, and a router is a
# namespace that forwards, running FRR for its routing protocols.
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
LAB=/run/lab

need() {
  local missing=() p
  for p in iproute2 bridge-utils ethtool frr tcpdump iputils-ping iputils-arping traceroute \
           nftables conntrack isc-dhcp-server isc-dhcp-client isc-dhcp-relay radvd ndisc6 \
           ipcalc sipcalc wireguard-tools lldpd python3 curl netcat-openbsd; do
    dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p")
  done
  [ ${#missing[@]} -eq 0 ] || { echo "install first: sudo apt install ${missing[*]}" >&2; exit 1; }
  modprobe -a 8021q bonding bridge veth wireguard
}

# The same MAC address every time: 02 marks it as chosen rather than burnt in
# by a manufacturer, and five bytes come from a hash of device and interface.
mac() { printf '02:%s' "$(printf '%s-%s' "$1" "$2" | md5sum | cut -c1-10 | sed 's/../&:/g; s/:$//')"; }

node() {  # node NAME [router]
  local n=$1
  ip netns del "$n" 2>/dev/null || true
  ip netns add "$n"
  ip -n "$n" link set lo up
  echo "$n" >> "$LAB/nodes"
  mkdir -p "/etc/netns/$n" "$LAB/$n/dhcp"
  printf '127.0.0.1 localhost\n127.0.1.1 %s\n' "$n" > "/etc/netns/$n/hosts"
  printf 'nameserver 127.0.0.1\n' > "/etc/netns/$n/resolv.conf"
  ip netns exec "$n" sysctl -qw net.ipv4.ping_group_range="0 2147483647"
  # A new IPv6 address waits until nobody else is found using it; here it
  # does not wait, so no output ever catches one "tentative".
  ip netns exec "$n" sysctl -qw net.ipv6.conf.all.accept_dad=0 net.ipv6.conf.default.accept_dad=0
  # A route over a link that is down is not used, as on a router.
  ip netns exec "$n" sysctl -qw net.ipv4.conf.all.ignore_routes_with_linkdown=1 \
    net.ipv4.conf.default.ignore_routes_with_linkdown=1
  if [ "${2:-}" = router ]; then
    ip netns exec "$n" sysctl -qw net.ipv4.ip_forward=1 net.ipv6.conf.all.forwarding=1
    # Answer a traceroute from the interface the probe came in by.
    ip netns exec "$n" sysctl -qw net.ipv4.icmp_errors_use_inbound_ifaddr=1
    # Forward a packet even when there is no route back to its source.
    ip netns exec "$n" sysctl -qw net.ipv4.conf.all.rp_filter=0 net.ipv4.conf.default.rp_filter=0
  fi
}

link() {  # link NODE1 IF1 NODE2 IF2 : one cable
  local tmp1="t$RANDOM$RANDOM" tmp2="u$RANDOM$RANDOM"
  ip link add "$tmp1" type veth peer "$tmp2"
  ip link set "$tmp1" netns "$1"; ip -n "$1" link set "$tmp1" name "$2"
  ip link set "$tmp2" netns "$3"; ip -n "$3" link set "$tmp2" name "$4"
  ip -n "$1" link set "$2" address "$(mac "$1" "$2")"
  ip -n "$3" link set "$4" address "$(mac "$3" "$4")"
  ip -n "$1" link set "$2" up
  ip -n "$3" link set "$4" up
}

addr() { ip -n "$1" addr add "$3" dev "$2"; }                    # addr NODE IF ADDRESS/PREFIX
gw()   { ip -n "$1" route add default via "$2"; }                 # gw NODE GATEWAY
host() { printf '%s %s\n' "$2" "$3" >> "/etc/netns/$1/hosts"; }   # host NODE ADDRESS NAME

switch() {  # switch NAME "PORTS" [bridge options] : a bridge br0 with these ports
  local n=$1 ports=$2; shift 2
  ip -n "$n" link add br0 type bridge "$@"
  ip -n "$n" link set br0 address "$(mac "$n" br0)"
  local p; for p in $ports; do ip -n "$n" link set "$p" master br0; done
  ip -n "$n" link set br0 up
}

daemon() {  # daemon NODE NAME COMMAND... : a program left running on a device
  local n=$1 pf=$LAB/$1/$2.pid; shift 2
  ip netns exec "$n" setsid "$@" </dev/null >"$pf.log" 2>&1 &
  echo $! > "$pf"; echo "$pf" >> "$LAB/pidfiles"
}

wait_for() {  # wait_for SECONDS COMMAND... : until it succeeds, or say so
  local t=$1; shift
  for _ in $(seq "$t"); do "$@" >/dev/null 2>&1 && return 0; sleep 1; done
  echo "netlab: waited ${t}s and this never succeeded: $*" >&2; return 1
}

frr() {  # frr NODE : FRR on a router, its configuration on stdin
  local n=$1 d
  install -d -o frr -g frr "/etc/frr/$n" "/var/run/frr/$n"
  cat > "/etc/frr/$n/frr.conf"
  : > "/etc/frr/$n/vtysh.conf"
  chown frr:frr "/etc/frr/$n/frr.conf" "/etc/frr/$n/vtysh.conf"
  local daemons="zebra staticd ${FRR_EXTRA:-}"   # FRR_EXTRA: more daemons to start
  grep -q '^router ospf'  "/etc/frr/$n/frr.conf" && daemons+=" ospfd"
  grep -q '^router rip'   "/etc/frr/$n/frr.conf" && daemons+=" ripd"
  grep -q '^router bgp'   "/etc/frr/$n/frr.conf" && daemons+=" bgpd"
  grep -q '^router eigrp' "/etc/frr/$n/frr.conf" && daemons+=" eigrpd"
  for d in $daemons; do
    ip netns exec "$n" "/usr/lib/frr/$d" -d -N "$n" -F traditional \
      -f "/etc/frr/$n/frr.conf" -i "/var/run/frr/$n/$d.pid" 2>>"$LAB/$n/frr.log"
    echo "/var/run/frr/$n/$d.pid" >> "$LAB/pidfiles"
  done
}

ospf_p2p() {  # ospf_p2p NODE ROUTER-ID "INTERFACES" : OSPF, a hello every second
  local n=$1 id=$2 i
  {
    echo "hostname $n"
    for i in $3; do
      printf 'interface %s\n ip ospf network point-to-point\n ip ospf hello-interval 1\n ip ospf dead-interval 4\n' "$i"
    done
    printf 'router ospf\n ospf router-id %s\n network 10.20.0.0/16 area 0\n' "$id"
  } | frr "$n"
}

lldp() {  # lldp NODE : an LLDP agent announcing the device to its neighbours
  daemon "$1" lldpd unshare --uts sh -c "hostname $1; exec lldpd -d -u $LAB/$1/lldpd.socket -p $LAB/$1/lldpd.pidfile"
}

web() {  # web NODE ADDRESS : a web server whose page names its machine
  mkdir -p "$LAB/$1/www"
  printf 'served by %s\n' "$1" > "$LAB/$1/www/index.html"
  daemon "$1" web python3 -m http.server 80 --bind "$2" --directory "$LAB/$1/www"
  wait_for 60 bash -c "ip netns exec $1 ss -Htln 'sport = :80' | grep -q LISTEN"
}

dhcpd_on() {  # dhcpd_on NODE IFACE CONFIG-FILE : a DHCP server
  # Ubuntu's AppArmor profile for dhcpd allows only its usual paths, so it is
  # told once that it may read and write under /run/lab too.
  if [ -d /etc/apparmor.d/local ] && ! grep -qs "$LAB/" /etc/apparmor.d/local/usr.sbin.dhcpd; then
    echo "$LAB/** rw," >> /etc/apparmor.d/local/usr.sbin.dhcpd
    apparmor_parser -r /etc/apparmor.d/usr.sbin.dhcpd
  fi
  touch "$LAB/$1/dhcp/dhcpd.leases"
  daemon "$1" dhcpd unshare --mount sh -c \
    "mount --bind $LAB/$1/dhcp /var/lib/dhcp; exec dhcpd -4 -f -d -cf $3 -pf $LAB/$1/dhcpd.pidfile $2"
}

on() {  # on HOST [USER] [COMMAND]
  local h=$1 u=${2:-${SUDO_USER:-root}} c=${3:-}
  grep -qsx "$h" "$LAB/nodes" || { echo "no device called $h" >&2; exit 1; }
  local home; home=$(getent passwd "$u" | cut -d: -f6)
  # vtysh and lldpcli talk to this device's FRR and LLDP agent, not another's
  printf 'vtysh() { command vtysh -N %s "$@"; }\nlldpcli() { command lldpcli -u %s "$@"; }\ncd\n' \
    "$h" "$LAB/$h/lldpd.socket" > "$LAB/$h/rc"
  printf '[ -f ~/.bashrc ] && . ~/.bashrc\n. %s\n' "$LAB/$h/rc" > "$LAB/$h/rc-shell"
  local run=(env -i HOME="$home" USER="$u" LOGNAME="$u" PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
             LANG=C.UTF-8 TERM="${TERM:-xterm}" COLUMNS="${COLUMNS:-100}")
  [ "$u" = root ] || run=(runuser -u "$u" -- "${run[@]}")
  if [ -n "$c" ]; then run+=(bash -c '. "$0"; eval "$1"' "$LAB/$h/rc" "$c")
  else run+=(bash --rcfile "$LAB/$h/rc-shell" -i); fi
  # its own hostname, and its own /var/lib/dhcp for the leases it is given
  ip netns exec "$h" unshare --uts bash -c \
    'hostname "$1"; mount --bind "$2" /var/lib/dhcp; shift 2; exec "$@"' _ "$h" "$LAB/$h/dhcp" "${run[@]}"
}

down() {
  local f n
  if [ -f "$LAB/pidfiles" ]; then
    while read -r f; do [ -f "$f" ] && kill "$(cat "$f")" 2>/dev/null || true; done < "$LAB/pidfiles"
    sleep 1
  fi
  if [ -f "$LAB/nodes" ]; then
    while read -r n; do ip netns pids "$n" 2>/dev/null | xargs -r kill 2>/dev/null || true; done < "$LAB/nodes"
    sleep 1
    while read -r n; do
      ip netns del "$n" 2>/dev/null || true
      rm -rf "/etc/netns/$n" "/etc/frr/$n" "/var/run/frr/$n"
    done < "$LAB/nodes"
  fi
  rm -rf "$LAB"
}

up() {  # up NAME : take down what was there, then build NAME.sh from nothing
  [ -f "$HERE/$1.sh" ] && [ "$1" != netlab ] || { echo "no network called $1; try: list" >&2; exit 1; }
  need; down
  mkdir -p "$LAB"; : > "$LAB/nodes"; : > "$LAB/pidfiles"
  . "$HERE/$1.sh"
  echo "netlab: $1 is up"
}

[ "$(id -u)" = 0 ] || [ "${1:-}" = list ] || { echo "run it with sudo" >&2; exit 1; }
case "${1:-}" in
  up)   up "${2:?which network? try: list}" ;;
  on)   shift; on "$@" ;;
  down) down ;;
  list) ls "$HERE" | sed -n 's/\.sh$//p' | grep -vx netlab ;;
  *)    sed -n '3,8p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac
```

Ele é comprido, e quase tudo nele são funções curtas que fazem uma coisa cada. **`node` cria um
dispositivo**: um namespace, o `/etc/hosts` dele e, num roteador, o encaminhamento ligado. **`link`
lança um cabo**, e a aula 7 o lê linha por linha. `addr` e `gw` dão um endereço a uma interface e a
rota padrão a um dispositivo. **`switch` cria um switch** a partir de uma bridge chamada `br0`, com as
portas que receber. `frr` sobe os daemons de roteamento num roteador, e `daemon` deixa qualquer outro
programa rodando num dispositivo, como um servidor web ou um servidor DHCP. A função `mac` dá a cada
interface o mesmo endereço MAC toda vez que uma rede é montada, e é isso que mantém os endereços MAC
das aulas iguais aos seus. `on` abre um shell num dispositivo, e `down` remove tudo o que o script criou.

A primeira rede é o escritório em que esta aula roda. Abra `nano ~/netlab/office.sh` e cole:

```bash
# ~/netlab/office.sh: four PCs on one switch, a router that is also the
# firewall and does NAT, the provider, and a load balancer in front of two
# web servers.
#
#   pc1 pc2 pc3 srv --- sw1 --- r1 === isp --- lb --- web1, web2
#   10.20.10.0/24               203.0.113.0/30   192.0.2.0/24   10.99.0.0/24
local n
for n in pc1 pc2 pc3 srv sw1 lb web1 web2; do node $n; done
node r1 router; node isp router
link pc1 eth0 sw1 p1; link pc2 eth0 sw1 p2; link pc3 eth0 sw1 p3
link srv eth0 sw1 p4; link r1 eth0 sw1 p8
switch sw1 "p1 p2 p3 p4 p8"
addr pc1 eth0 10.20.10.21/24; addr pc2 eth0 10.20.10.22/24; addr pc3 eth0 10.20.10.23/24
addr srv eth0 10.20.10.10/24; addr r1 eth0 10.20.10.1/24
for n in pc1 pc2 pc3 srv; do gw $n 10.20.10.1; done
link r1 eth1 isp eth0
addr r1 eth1 203.0.113.2/30; addr isp eth0 203.0.113.1/30; gw r1 203.0.113.1
link isp eth1 lb eth0
addr isp eth1 192.0.2.1/24; addr lb eth0 192.0.2.80/24; gw lb 192.0.2.1
link lb eth1 web1 eth0; link lb eth2 web2 eth0
addr lb eth1 10.99.0.1/28; addr web1 eth0 10.99.0.11/28
addr lb eth2 10.99.0.17/28; addr web2 eth0 10.99.0.18/28
gw web1 10.99.0.1; gw web2 10.99.0.17
ip netns exec lb sysctl -qw net.ipv4.ip_forward=1
web web1 10.99.0.11; web web2 10.99.0.18; web srv 10.20.10.10
# The router: every office machine leaves with its one public address, and
# nothing from outside starts a conversation inside.
ip netns exec r1 nft -f - <<'NFT'
table ip nat {
  chain postrouting {
    type nat hook postrouting priority srcnat;
    oifname "eth1" masquerade
  }
}
table inet filter {
  chain forward {
    type filter hook forward priority filter; policy drop;
    ct state established,related counter accept
    iifname "eth0" oifname "eth1" counter accept
    counter comment "everything else: dropped"
  }
}
NFT
# The load balancer: one public address, and each new connection goes to the
# next web server in turn.
ip netns exec lb nft -f - <<'NFT'
table ip lb {
  chain prerouting {
    type nat hook prerouting priority dstnat;
    ip daddr 192.0.2.80 tcp dport 80 dnat to numgen inc mod 2 map { 0 : 10.99.0.11, 1 : 10.99.0.18 }
  }
  chain postrouting {
    type nat hook postrouting priority srcnat;
    oifname { "eth1", "eth2" } masquerade
  }
}
NFT
for n in pc1 pc2 pc3 srv r1; do
  host $n 10.20.10.21 pc1; host $n 10.20.10.22 pc2; host $n 10.20.10.23 pc3
  host $n 10.20.10.10 srv; host $n 10.20.10.1 r1
done
```

Cada linha se lê como o desenho no topo: quatro PCs e um servidor nas portas do sw1, o roteador r1
com o provedor atrás dele, e o outro lado do provedor levando ao balanceador de carga e aos dois
servidores web dele. Os dois blocos `nft` são o firewall e o NAT no r1 e a regra do balanceador no lb,
que as últimas seções desta aula desmontam. Monte a rede:

```
ana@lab:~$ sudo bash ~/netlab/netlab.sh up office
netlab: office is up
```

`up` derruba a rede que estiver lá e monta esta do zero, então toda aula começa do mesmo estado, e não
do que a anterior deixou para trás. Depois, **`on` coloca você num dispositivo.** Com um comando, roda
esse comando lá:

```
ana@lab:~$ sudo bash ~/netlab/netlab.sh on pc1 "$USER" 'ping -c 2 srv'
PING srv (10.20.10.10) 56(84) bytes of data.
64 bytes from srv (10.20.10.10): icmp_seq=1 ttl=64 time=18.3 ms
64 bytes from srv (10.20.10.10): icmp_seq=2 ttl=64 time=0.420 ms

--- srv ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 0.420/9.344/18.269/8.924 ms
```

Sem comando, `sudo bash ~/netlab/netlab.sh on pc1` abre um shell no pc1 com o seu usuário, e o prompt
muda para dizer isso. É assim que se lê toda transcrição deste curso:

- `ana@pc1:~$` é um shell no pc1, aberto com `on pc1`;
- `root@r1:~#` é um shell de root no r1, aberto com `on r1 root`: um dispositivo sendo configurado;
- `ana@lab:~$` é a própria máquina, fora de todos os dispositivos.

`exit` sai do shell de um dispositivo, e `sudo bash ~/netlab/netlab.sh down` desfaz a rede.

Alguns passos acontecem entre uma transcrição e outra, e o texto diz quando. Para **puxar um cabo**,
derrube uma ponta dele num prompt de root daquele dispositivo, `ip link set p1 down`, e
`ip link set p1 up` o liga de volta: a outra ponta vê o sinal sumir e voltar, exatamente como com um
cabo de verdade. Para **observar um dispositivo enquanto outro faz alguma coisa**, abra um segundo
terminal na máquina e um segundo `on` nele. E para **esvaziar o que um dispositivo aprendeu**,
`ip neigh flush all` limpa a tabela de vizinhos e, num switch, `bridge fdb flush dev br0 dynamic`
limpa os endereços aprendidos.
