---
title: O seu laboratório
version: 1
---

Tudo o que este curso mostra numa tela aconteceu num laboratório que você mesmo pode montar, e todo
exercício parte do princípio de que você o montou. **Você precisa de um computador Linux que não se
importe de quebrar**, com Ubuntu 24.04, cerca de 2 processadores, 4 GB de memória e 25 GB de disco. Há
três caminhos para ter um:

| caminho | quanto custa para você | quando escolher |
|---|---|---|
| **uma máquina virtual** (o recomendado) | VirtualBox, VMware Workstation, UTM no Mac ou Hyper-V; Ubuntu 24.04 Server, de ubuntu.com. Cerca de 25 GB do seu disco e 4 GB da sua memória enquanto ela roda | quase sempre: um snapshot antes de cada aula desfaz qualquer erro |
| **instalado** | um computador sobrando, ou um segundo disco, com Ubuntu 24.04 | quando o seu computador é pequeno demais para hospedar uma máquina virtual |
| **online** | um servidor Ubuntu 24.04 pequeno, em qualquer provedor de nuvem, pago por hora; desligue entre as sessões | quando você não consegue instalar nada localmente |

O curso foi gravado no primeiro tipo. O WSL2 do Windows também roda Ubuntu, e namespaces de rede
funcionam nele, mas **nada neste curso foi gravado lá**, então, se um comando se comportar diferente no
WSL2, você estará por sua conta. Tome isso como motivo para usar uma máquina virtual.

Com a máquina no ar, instale de uma vez tudo o que o curso usa:

```
sudo apt update
sudo apt install -y iproute2 nftables tcpdump tshark ulogd2 nfdump openssh-server \
    moreutils sleuthkit sqlite3 jq python3-venv xxd curl
```

O `tshark` pergunta se usuários comuns podem capturar pacotes. Qualquer resposta serve aqui, porque o
laboratório roda como root. As transcrições deste curso foram gravadas por uma usuária chamada `ana`
numa máquina chamada `soc`, então o prompt é `ana@soc:~$` para ela e `root@soc:~#` para os comandos que
precisam de root. Vire root com `sudo -i`; tudo o que vem a seguir nesta aula é digitado ali.

**O laboratório é um script só**, o `soclab.sh`. Crie-o na pasta pessoal do root (`nano soclab.sh`) e
digite, ou cole, exatamente isto:

```bash
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
```

Ele monta quatro **namespaces de rede**: cópias separadas da pilha de rede dentro de um mesmo kernel,
cada uma com suas interfaces, endereços e firewall. `cable` liga duas delas com um par Ethernet virtual,
e `-` quer dizer este computador. `on` roda um programa dentro de uma delas com o nome daquela máquina,
para os logs dela dizerem `gw` e não o nome do seu computador. O resto liga as quatro coisas que escrevem
evidência: o log do firewall, pelo `ulogd`; os registros de fluxo, pelo `nfpcapd`; e dois servidores SSH
cujas linhas recebem carimbo de hora do `ts` (o `sed` antes dele tira o retorno de carro que o `sshd`
põe no fim de cada linha que escreve num terminal). Suba o laboratório e olhe:

```
root@soc:~# bash soclab.sh up
root@soc:~# ip netns list
gw (id: 2)
files (id: 3)
fw (id: 0)
outside (id: 1)
root@soc:~# ip -n fw -br addr
lo               UNKNOWN        127.0.0.1/8 
eth0@if117       UP             203.0.113.1/24 
eth1@if119       UP             198.51.100.1/24 
eth2@if121       UP             192.168.20.1/24 
eth3@if123       UP             192.168.99.1/24 
```

Nenhuma notícia do `up` é boa notícia: o script para no primeiro comando que falha, e diz qual. Quatro
máquinas existem, e o `fw` tem quatro endereços, um em cada rede. **`bash soclab.sh down` apaga tudo**,
e um `up` depois disso monta tudo de novo a partir do nada, que é o jeito de começar qualquer aula de um
estado conhecido. O laboratório não sobrevive a um reinício da máquina virtual; suba-o de novo depois de
um.
