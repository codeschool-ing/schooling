---
title: Your lab
version: 1
---

Everything this course shows on a screen happened on a lab you can build yourself, and every exercise
assumes you have built it. **You need one Linux computer that you do not mind breaking**, running Ubuntu
24.04, with about 2 processors, 4 GB of memory and 25 GB of disk. There are three ways to get one:

| path | what it costs you | when to choose it |
|---|---|---|
| **a virtual machine** (recommended) | VirtualBox, VMware Workstation, UTM on a Mac or Hyper-V; Ubuntu 24.04 Server from ubuntu.com. About 25 GB of your disk and 4 GB of your memory while it runs | almost always: a snapshot before each lesson undoes any mistake |
| **installed** | a spare computer, or a second disk, with Ubuntu 24.04 on it | when your own computer is too small to host a virtual machine |
| **online** | a small Ubuntu 24.04 server from any cloud provider, paid by the hour; switch it off between sessions | when you cannot install anything locally |

The course was recorded on the first kind. Windows' WSL2 runs Ubuntu too, and network namespaces work
in it, but **nothing in this course was recorded there**, so if a command behaves differently on WSL2
you are on your own. Treat that as a reason to use a virtual machine.

Once the machine is up, install everything the course uses, in one go:

```
sudo apt update
sudo apt install -y iproute2 nftables tcpdump tshark ulogd2 nfdump openssh-server \
    moreutils sleuthkit sqlite3 jq python3-venv xxd curl
```

`tshark` asks whether ordinary users may capture packets. Either answer works here, because the lab is
run as root. The transcripts in this course were recorded by a user called `ana` on a machine called
`soc`, so the prompt reads `ana@soc:~$` for her and `root@soc:~#` for the commands that need root. Become
root with `sudo -i`, and everything that follows in this lesson is typed there.

**The lab is one script**, `soclab.sh`. Create it in root's home folder (`nano soclab.sh`) and type, or
paste, exactly this:

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
  on "$1" sh -c "/usr/sbin/sshd -D -e -o ListenAddress=$2 2>&1 |
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

It builds four **network namespaces**: separate copies of the network stack inside one kernel, each with
its own interfaces, addresses and firewall. `cable` joins two of them with a virtual Ethernet pair, and
`-` means this computer. `on` runs a program inside one of them under that machine's name, so its logs say
`gw` rather than the name of your computer. The rest starts the four things that write evidence: the
firewall's log through `ulogd`, flow records through `nfpcapd`, and two SSH servers whose lines are
stamped by `ts`. Bring it up and look:

```
root@soc:~# bash soclab.sh up
root@soc:~# ip netns list
gw (id: 2)
files (id: 3)
fw (id: 0)
outside (id: 1)
root@soc:~# ip -n fw -br addr
lo               UNKNOWN        127.0.0.1/8 
eth0@if77        UP             203.0.113.1/24 
eth1@if79        UP             198.51.100.1/24 
eth2@if81        UP             192.168.20.1/24 
eth3@if83        UP             192.168.99.1/24 
```

No news from `up` is good news: the script stops at the first command that fails, and says which. Four
machines exist, and `fw` holds four addresses, one on each network. **`bash soclab.sh down` removes all of
it**, and `up` after that builds it again from nothing, which is the way to start any lesson from a known
state. The lab does not survive a reboot of the virtual machine; bring it up again after one.
