#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of networks-availability, as a
# script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash ana     # once, on a throwaway machine,
#                                        # with passwordless sudo for ana
#   sudo cp ../../lab.sh /var/tmp/lab.sh  # the lab, beside course.json
#   sudo -u ana -i bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB, built by lab.sh: a head
# office (hq), a branch, a home behind its own NAT, an ISP and a small data
# centre, as network namespaces on one Linux computer.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by lab.sh reset; the swanctl.conf files on hq, branch and
# remote, written below as root (the lesson shows hq's with cat); the charon
# daemon, started as root on each of the three before anything is loaded;
# and, for the wrong-key block, branch's secret replaced and reloaded, then
# put back. IPsec here is strongSwan's userspace ESP (kernel-libipsec), because
# the kernel this was recorded on has no ESP; lab.sh says why.
# Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100
LAB_SH=${LAB_SH:-/var/tmp/lab.sh}
lab() { sudo bash "$LAB_SH" "$@"; }
# on HOST 'command': what ana typed at her prompt on one machine of the lab,
# and everything it printed.
on() {
  local h=$1; shift
  printf 'ana@%s:~$ %s\n' "$h" "$*"
  lab exec "$h" ana "$*" 2>&1 || true
}
# The same, run as root and not shown: the lab's own housekeeping.
quiet() { local h=$1; shift; lab exec "$h" root "$*" >/dev/null 2>&1 || true; }
# bg HOST 'command': start a command that has to be running while something
# else happens (a capture, a server); its transcript is printed by fg.
BG=$(mktemp -d)
bg() {
  local h=$1; shift
  printf 'ana@%s:~$ %s\n' "$h" "$*" > "$BG/out"
  ( timeout -s INT 40 sudo bash "$LAB_SH" exec "$h" ana "$*" >> "$BG/out" 2>&1 || true ) &
  echo $! > "$BG/pid"
  sleep "${BG_WAIT:-1.5}"
}
fg() { wait "$(cat "$BG/pid")" 2>/dev/null || true; cat "$BG/out"; }
block() { printf '##### %s\n' "$1"; }
conf() {  # conf HOST LOCAL REMOTE LOCAL_NET REMOTE_NET MY_ID PEER_ID SECRET
  lab exec "$1" root "cat > /etc/swanctl/swanctl.conf" <<C
connections {
  offices {
    version = 2
    local_addrs = $2
    remote_addrs = $3
    mobike = no
    proposals = aes256-sha256-modp2048
    local {
      auth = psk
      id = $6
    }
    remote {
      auth = psk
      id = $7
    }
    children {
      lans {
        local_ts = $4
        remote_ts = $5
        esp_proposals = aes256gcm16
        start_action = trap
      }
    }
  }
}
secrets {
  ike-offices {
    id-1 = hq.example.com
    id-2 = branch.example.com
    secret = "$8"
  }
}
C
}
charon() { quiet "$1" 'setsid /usr/lib/ipsec/charon </dev/null >/run/charon.log 2>&1 &'; }

lab reset
KEY='Tide-Lantern-Orbit-7294-Quill'
conf hq 203.0.113.2 198.51.100.2 192.168.10.0/24 192.168.20.0/24 hq.example.com branch.example.com "$KEY"
conf branch 198.51.100.2 203.0.113.2 192.168.20.0/24 192.168.10.0/24 branch.example.com hq.example.com "$KEY"
charon hq; charon branch; sleep 1

block config
on hq 'sudo cat /etc/swanctl/swanctl.conf'

block load
on hq 'sudo swanctl --load-all'
quiet branch 'swanctl --load-all'
on hq 'sudo swanctl --list-conns'

block trap
bg isp 'sudo tcpdump -n -t -i eth0 -c 4 udp port 500 or udp port 4500'
on laptop 'ping -c 3 192.168.20.30'
fg

block sas
on hq 'sudo swanctl --list-sas'

block esp
bg isp 'sudo tcpdump -n -t -v -i eth0 -c 2 esp'
lab exec laptop ana 'ping -c 1 192.168.20.30' >/dev/null 2>&1
fg

block dark
bg isp 'sudo tcpdump -l -n -t -A -i eth0 -c 10 esp | grep -c -E "GET|served"'
lab exec till ana 'curl -s http://192.168.10.10/' >/dev/null 2>&1
fg
on till 'curl -s http://192.168.10.10/'

block tshark-ike
quiet hq 'swanctl --terminate --ike offices'
sleep 1
bg isp 'tshark -n -i eth0 -c 4 -f "udp port 500"'
on laptop 'ping -c 2 192.168.20.30'
fg

block initiate
quiet hq 'swanctl --terminate --ike offices'
sleep 1
on hq 'sudo swanctl --initiate --child lans'

block wrong-key
quiet hq 'swanctl --terminate --ike offices'
conf branch 198.51.100.2 203.0.113.2 192.168.20.0/24 192.168.10.0/24 branch.example.com hq.example.com 'Tide-Lantern-Orbit-7294-Quil'
quiet branch 'swanctl --load-all'
sleep 1
on hq 'sudo swanctl --initiate --child lans'
conf branch 198.51.100.2 203.0.113.2 192.168.20.0/24 192.168.10.0/24 branch.example.com hq.example.com "$KEY"
quiet branch 'swanctl --load-all'

block selectors
quiet hq 'swanctl --terminate --ike offices'
quiet hq "sed -i 's|remote_ts = 192.168.20.0/24|remote_ts = 192.168.30.0/24|' /etc/swanctl/swanctl.conf"
quiet hq 'swanctl --load-all'
sleep 1
on hq 'sudo swanctl --initiate --child lans 2>&1 | tail -5'
quiet hq "sed -i 's|remote_ts = 192.168.30.0/24|remote_ts = 192.168.20.0/24|' /etc/swanctl/swanctl.conf"
quiet hq 'swanctl --load-all'

block nat
lab exec hq root "cat >> /etc/swanctl/swanctl.conf" <<'C'
connections {
  home {
    version = 2
    local_addrs = 203.0.113.2
    pools = homes
    local {
      auth = psk
      id = hq.example.com
    }
    remote {
      auth = psk
      id = ana@example.com
    }
    children {
      office {
        local_ts = 192.168.10.0/24
        esp_proposals = aes256gcm16
      }
    }
  }
}
pools {
  homes {
    addrs = 10.30.0.0/24
  }
}
secrets {
  ike-ana {
    id-1 = hq.example.com
    id-2 = ana@example.com
    secret = "Harbour-Violet-Candle-3381"
  }
}
C
lab exec remote root "cat > /etc/swanctl/swanctl.conf" <<'C'
connections {
  office {
    version = 2
    remote_addrs = 203.0.113.2
    vips = 0.0.0.0
    local {
      auth = psk
      id = ana@example.com
    }
    remote {
      auth = psk
      id = hq.example.com
    }
    children {
      office {
        remote_ts = 192.168.10.0/24
        esp_proposals = aes256gcm16
      }
    }
  }
}
secrets {
  ike-ana {
    id-1 = hq.example.com
    id-2 = ana@example.com
    secret = "Harbour-Violet-Candle-3381"
  }
}
C
charon remote; sleep 1
quiet hq 'swanctl --load-all'
quiet remote 'swanctl --load-all'
bg isp 'sudo tcpdump -n -t -i eth1 -c 6 udp and host 198.51.100.77'
on remote 'sudo swanctl --initiate --child office | grep -E "NAT|sending|received|virtual|established"'
lab exec remote ana 'ping -c 1 192.168.10.10' >/dev/null 2>&1
fg
on remote 'ping -c 2 192.168.10.10'
on hq 'sudo swanctl --list-sas --ike home'
