---
title: "O laboratório, parte 1: os fios e as máquinas"
version: 1
---

O primeiro arquivo monta a rede em si: treze máquinas, os cabos entre elas e as rotas que levam um
pacote do escritório até o servidor web. Ele faz isso com três recursos do kernel Linux, e vale a pena
conhecê-los pelo nome, porque as transcrições das aulas 1 e 2 os deixam aparecer.

- Um **namespace de rede** é uma cópia separada da parte de rede do kernel: interfaces, endereços,
  tabela de rotas e firewall próprios. Um programa iniciado dentro de um vê só essa cópia. Cada
  máquina do desenho é um namespace, então `laptop` e `www` são dois namespaces no mesmo computador, e
  nenhum vê as interfaces do outro.
- Um **par veth** é um cabo virtual: duas interfaces ligadas uma na outra, de modo que um quadro
  mandado numa sai pela outra. Uma ponta vai para dentro de uma máquina e é renomeada `eth0`; a outra
  é a ponta de lá do cabo.
- Uma **bridge** é um switch em software. As pontas de lá dos três cabos do escritório se ligam numa
  bridge chamada `br-office`, e a bridge encaminha quadros entre elas pelo endereço MAC, como a
  seção 10 descreve. As quatro bridges ficam num décimo quarto namespace chamado `wire`, que não é a
  máquina de ninguém.

Leia o arquivo de cima para baixo. `LINKS` é o desenho em forma de tabela, um cabo por linha: qual
segmento de rede, qual máquina, o nome da interface e o endereço dela. `ROUTES` dá a cada máquina o
seu gateway padrão. `build_net` transforma as duas em namespaces, cabos e rotas, liga o encaminhamento
nas três máquinas que roteiam e dá ao roteador do escritório uma regra de tradução de endereços, que a
aula 2 seção 05 explica.

Uma máquina precisa de mais que uma rede para ser uma máquina. **`overlay` e `exec_on` fazem um
comando rodar "em" uma delas**: `ip netns exec` o põe no namespace da máquina e põe os arquivos de
`/etc/netns/laptop/` por cima de `/etc` para aquele comando, o que dá a cada máquina o seu próprio
`/etc/hosts` e o seu `/etc/resolv.conf`; `unshare --uts` lhe dá um hostname próprio; e `overlay`
estende as pastas da máquina, de `/lab/laptop/`, por cima de `/home`, `/etc/nginx` e o resto, para que
cada máquina tenha sua pasta pessoal e a configuração dos seus servidores. A última parte, de `daemon`
em diante, inicia os servidores nas suas máquinas e dá ao arquivo os seus comandos: `up`, `down`,
`reset`, `shell`, `exec` e `plug`, que a aula 10 usa para ligar mais um aparelho.

Crie uma pasta para o laboratório e abra o primeiro arquivo num editor:

```sh
mkdir -p ~/netlab
nano ~/netlab/netlab
```

Cole o arquivo inteiro abaixo, salve com Ctrl+O e Enter, e saia com Ctrl+X. O botão de copiar do
bloco leva tudo.

```bash
#!/usr/bin/env bash
# ~/netlab/netlab: the network every lesson of this course runs on.
#
# IT IS ONE LINUX COMPUTER. Each machine below is a network namespace: its own
# interfaces, addresses, routes and firewall, its own hostname, and its own
# copy of the few directories a machine is told apart by (a home folder, a
# daemon's configuration). The cables are virtual Ethernet pairs plugged into
# bridges, and they add no delay, so every round trip is one computer talking
# to itself, a fraction of a millisecond.
#
# NOTHING HERE REACHES THE REAL INTERNET. The lab has its own DNS root, its own
# top-level domains and its own certificate authorities, so every answer comes
# from these servers. The addresses and names are the ones reserved for
# documentation and testing (RFC 5737, RFC 2606, RFC 6761): 192.0.2.0/24,
# 198.51.100.0/24, 203.0.113.0/24, example.com, example.net and .test.
#
#   sudo bash ~/netlab/netlab up                 build it (does nothing if it is up)
#   sudo bash ~/netlab/netlab reset              tear it down and build it again
#   sudo bash ~/netlab/netlab down               tear it down
#   sudo bash ~/netlab/netlab shell HOST [USER]  a shell on one machine, as ana by default
#   sudo bash ~/netlab/netlab exec HOST USER 'command'
#
# The servers are built by dns.sh, web.sh and services.sh, in the same folder.
# Written for Ubuntu 24.04.
set -euo pipefail

NETLAB=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
LAB=/lab
TZ_LAB=America/Sao_Paulo
#        segment  host     iface address/prefix
LINKS="
office   laptop   eth0 192.168.10.20/24
office   server   eth0 192.168.10.10/24
office   router   eth0 192.168.10.1/24
wan      router   eth1 203.0.113.2/24
wan      isp      eth0 203.0.113.1/24
backbone isp      eth1 198.51.100.1/24
backbone resolver eth0 198.51.100.53/24
backbone home     eth0 198.51.100.77/24
backbone core     eth0 198.51.100.254/24
hosting  core     eth1 192.0.2.1/24
hosting  rootns   eth0 192.0.2.10/24
hosting  tldns    eth0 192.0.2.20/24
hosting  ns1      eth0 192.0.2.53/24
hosting  www      eth0 192.0.2.80/24
hosting  mail     eth0 192.0.2.25/24
hosting  netmail  eth0 192.0.2.26/24
"
#            host      gateway
ROUTES="
laptop   192.168.10.1
server   192.168.10.1
router   203.0.113.1
resolver 198.51.100.1
home     198.51.100.1
core     198.51.100.1
rootns   192.0.2.1
tldns    192.0.2.1
ns1      192.0.2.1
www      192.0.2.1
mail     192.0.2.1
netmail  192.0.2.1
"
HOSTS=$(echo "$LINKS" | awk 'NF{print $2}' | sort -u)
ROUTERS="router isp core"

need() {
  local missing=()
  for p in iproute2 bind9 bind9-dnsutils unbound nginx openssl tcpdump traceroute mtr-tiny \
           netcat-openbsd curl openssh-server nftables vsftpd tnftp rsync \
           postfix dovecot-imapd dovecot-pop3d opendkim opendkim-tools opendmarc swaks \
           iputils-ping iputils-tracepath net-tools strace python3; do
    dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p")
  done
  [ ${#missing[@]} -eq 0 ] || { echo "install first: ${missing[*]}" >&2; exit 1; }
}

mac() {  # 52:54:00 and the last three bytes of the address, so a MAC says whose it is
  local a=${1%/*}; IFS=. read -r _ b c d <<< "$a"
  printf '52:54:00:%02x:%02x:%02x' "$b" "$c" "$d"
}

# ------------------------------------------------------------------ the wires
build_net() {
  ip netns add wire
  ip -n wire link set lo up
  for seg in $(echo "$LINKS" | awk 'NF{print $1}' | sort -u); do
    ip -n wire link add "br-$seg" type bridge
    ip -n wire link set "br-$seg" up
  done
  for h in $HOSTS; do
    ip netns add "$h"
    ip -n "$h" link set lo up
    # IPv6 is off in every machine, as it is in the whole computer once lesson 1
    # has switched it off; the line only matters if that step was skipped.
    [ -e /proc/sys/net/ipv6 ] && ip netns exec "$h" sysctl -qw net.ipv6.conf.all.disable_ipv6=1 net.ipv6.conf.default.disable_ipv6=1
    # ping sends ICMP without privileges, as it does on the machine itself
    ip netns exec "$h" sysctl -qw net.ipv4.ping_group_range="0 2147483647"
  done
  local n=0
  echo "$LINKS" | while read -r seg h ifc addr; do
    [ -n "$seg" ] || continue
    local peer="${seg:0:1}-$h"
    n=$((n + 1))
    ip link add "$peer" type veth peer name "lab-tmp$n"
    ip link set "lab-tmp$n" netns "$h"
    ip -n "$h" link set "lab-tmp$n" name "$ifc"
    ip -n "$h" link set "$ifc" address "$(mac "$addr")"
    ip -n "$h" addr add "$addr" dev "$ifc"
    ip -n "$h" link set "$ifc" up
    ip link set "$peer" netns wire
    ip -n wire link set "$peer" master "br-$seg"
    ip -n wire link set "$peer" up
  done
  echo "$ROUTES" | while read -r h gw; do
    [ -n "$h" ] || continue
    ip -n "$h" route add default via "$gw"
  done
  for r in $ROUTERS; do ip netns exec "$r" sysctl -qw net.ipv4.ip_forward=1; done
  ip -n isp route add 192.0.2.0/24 via 198.51.100.254
  ip -n core route add 203.0.113.0/24 via 198.51.100.1
  # The office has one public address, and every machine inside borrows it.
  ip netns exec router nft -f - <<'NFT'
table ip nat {
  chain postrouting {
    type nat hook postrouting priority srcnat;
    oifname "eth1" masquerade
  }
}
NFT
}

# ------------------------------------------------- a machine's own directories
# ip netns exec already mounts /etc/netns/HOST/* over /etc/*. The rest of what
# tells one machine from another lives under /lab/HOST and is mounted over the
# real path when something runs "on" that host.
OVERLAY="home etc/bind var/cache/bind run/named etc/unbound etc/nginx var/www var/log/nginx etc/ssh var/log/ssh etc/ssl/private etc/vsftpd.conf etc/postfix var/spool/postfix var/lib/postfix etc/dovecot etc/opendkim etc/opendkim.conf etc/opendmarc.conf var/log/mail"
overlay() {
  local h=$1 p
  for p in $OVERLAY; do
    [ -e "$LAB/$h/$p" ] && [ -e "/$p" ] && mount --bind "$LAB/$h/$p" "/$p"
  done
  return 0
}

exec_on() {  # exec_on HOST USER COMMAND
  local h=$1 u=$2 c=$3
  ip netns exec "$h" unshare --uts bash -c '
    '"$(declare -f overlay)"'; LAB='"$LAB"'; OVERLAY="'"$OVERLAY"'"
    hostname "$1"; overlay "$1"
    if [ "$2" = root ]; then cd /root; exec env -i HOME=/root USER=root LOGNAME=root PATH=/usr/sbin:/usr/bin:/sbin:/bin TZ='"$TZ_LAB"' LANG=C.UTF-8 TERM=xterm COLUMNS=100 bash -c "$3"
    else exec runuser -u "$2" -- env -i HOME=/home/"$2" USER="$2" LOGNAME="$2" PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin TZ='"$TZ_LAB"' LANG=C.UTF-8 TERM=xterm COLUMNS=100 bash -c "cd; $3"
    fi' _ "$h" "$u" "$c"
}

hostfiles() {
  for h in $HOSTS; do
    mkdir -p "/etc/netns/$h" "$LAB/$h/home/ana"
    printf '127.0.0.1 localhost\n127.0.1.1 %s\n' "$h" > "/etc/netns/$h/hosts"
    printf 'nameserver 198.51.100.53\n' > "/etc/netns/$h/resolv.conf"
    printf '%s\n' "$h" > "/etc/netns/$h/hostname"
    cp -a /etc/skel/. "$LAB/$h/home/ana/"
    chown -R ana:ana "$LAB/$h/home/ana"; chmod 750 "$LAB/$h/home/ana"
  done
  # The resolver asks the root, not itself.
  printf 'nameserver 127.0.0.1\n' > /etc/netns/resolver/resolv.conf
}

# --------------------------------------------------------------------- start
daemon() {  # daemon HOST COMMAND
  exec_on "$1" root "$2 </dev/null >/dev/null 2>&1 &"
}
start() {
  for h in rootns tldns ns1; do daemon "$h" "named -u bind -c /etc/bind/named.conf"; done
  daemon resolver "unbound -c /etc/unbound/unbound.conf"
  daemon www "nginx"
  mkdir -p /run/sshd
  daemon server "/usr/sbin/sshd -f /etc/ssh/sshd_config -E /var/log/ssh/sshd.log"
  daemon www "/usr/sbin/sshd -f /etc/ssh/sshd_config -E /var/log/ssh/sshd.log"
  daemon server "python3 -m http.server --bind 127.0.0.1 --directory /var/www/admin 8080"
  daemon www "vsftpd /etc/vsftpd.conf"
  for h in mail netmail; do
    daemon "$h" "opendkim -x /etc/opendkim.conf -f"
    daemon "$h" "opendmarc -c /etc/opendmarc.conf -f"
    daemon "$h" "dovecot -F -c /etc/dovecot/dovecot.conf"
    exec_on "$h" root "postfix start" >/dev/null 2>&1
  done
  # Wait until the resolver can answer, so the first lesson line is not a timeout.
  for _ in $(seq 50); do
    exec_on laptop ana 'dig +short +time=1 +tries=1 www.example.com' 2>/dev/null | grep -q . && break
    sleep 0.2
  done
}

down() {
  for h in $(ip netns list | awk '{print $1}'); do
    ip netns pids "$h" 2>/dev/null | xargs -r kill 2>/dev/null || true
  done
  sleep 0.5
  for h in $(ip netns list | awk '{print $1}'); do
    ip netns pids "$h" 2>/dev/null | xargs -r kill -9 2>/dev/null || true
    ip netns del "$h"
  done
  for h in $HOSTS; do rm -rf "/etc/netns/$h"; done
  rm -f /usr/local/share/ca-certificates/example-root-ca.crt /usr/local/share/ca-certificates/example-office-ca.crt
  update-ca-certificates --fresh >/dev/null 2>&1 || true
  rm -rf "$LAB"
}

up() {
  if ip netns list | grep -qw wire; then return 0; fi
  need
  # ana is who you are inside the lab: the office's support technician.
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash -G sudo ana
  mkdir -p "$LAB"
  build_net
  hostfiles
  build_dns
  build_tls
  build_web
  build_ssh
  build_files
  build_mail
  start
}

# A device plugged into a segment of a running lab, with a MAC given by hand
# rather than derived from its address: lesson 10's printer, which takes an
# address somebody else already has.
plug() {  # plug HOST SEGMENT ADDRESS/PREFIX MAC
  local h=$1 seg=$2 addr=$3 m=$4 peer="${2:0:1}-$1"
  ip netns add "$h"
  ip -n "$h" link set lo up
  ip link add "$peer" type veth peer name lab-plug
  ip link set lab-plug netns "$h"
  ip -n "$h" link set lab-plug name eth0
  ip -n "$h" link set eth0 address "$m"
  ip -n "$h" addr add "$addr" dev eth0
  ip -n "$h" link set eth0 up
  ip link set "$peer" netns wire
  ip -n wire link set "$peer" master "br-$seg"
  ip -n wire link set "$peer" up
}

if [ "$(id -u)" != 0 ]; then
  echo "netlab builds and removes network devices for the whole machine: run it with sudo" >&2
  exit 1
fi

source "$NETLAB/dns.sh"
source "$NETLAB/web.sh"
source "$NETLAB/services.sh"

case "${1:-}" in
  up) up ;;
  down) down ;;
  reset) down; up ;;
  exec) shift; exec_on "$@" ;;
  shell) exec_on "$2" "${3:-ana}" 'exec bash -i' ;;
  plug) shift; plug "$@" ;;
  *) echo "usage: netlab up|down|reset|shell HOST [USER]|exec HOST USER COMMAND|plug HOST SEGMENT ADDRESS MAC" >&2; exit 2 ;;
esac
```

Perto do fim, três linhas leem os outros três arquivos, `dns.sh`, `web.sh` e `services.sh`, da mesma
pasta. Eles são as próximas três seções, e **o laboratório não sobe enquanto os quatro arquivos não
estiverem salvos.**
