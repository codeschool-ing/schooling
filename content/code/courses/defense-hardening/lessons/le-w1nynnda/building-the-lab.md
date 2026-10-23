---
title: The script that builds the lab
version: 1
---

The whole lab is one script, `hostlab.sh`. Make a directory for it in your home on the computer you
chose, open a new file there, and paste the script into it. The copy button on the code below hands
over the whole file without the notes.

```sh
mkdir ~/hostlab && cd ~/hostlab
nano hostlab.sh
```

```schooling-example
{"language": "sh", "file": "hostlab.sh", "parts": [{"code": "#!/bin/bash\n# hostlab.sh: the course's machines, as containers on one Ubuntu 24.04 computer.\n#   sudo bash hostlab.sh build              once: the two images, from Ubuntu's archive\n#   sudo bash hostlab.sh up [MACHINE...]    fresh copies, booted; every machine if none is named\n#   sudo bash hostlab.sh down\n#   sudo bash hostlab.sh sh MACHINE         a shell on MACHINE, as you\n#   sudo bash hostlab.sh root MACHINE       a shell on MACHINE, as root\n#   sudo bash hostlab.sh exec MACHINE USER 'command'\nset -euo pipefail\n\nLAB=/var/lib/hostlab\nME=${SUDO_USER:-}\nMIRROR=http://archive.ubuntu.com/ubuntu\nexport SYSTEMD_NSPAWN_UNIFIED_HIERARCHY=1", "note": "The lab is one Linux computer pretending to be seven. Each machine is a **container**: a copy of an Ubuntu 24.04 system, booted by its own systemd, so `systemctl`, `journalctl` and the services behave as they do on a real server. Run it with `sudo`, from your own account: that account is the one you will have on every machine."}, {"code": "#        machine address        image\nMACHINES=\"\nsw      192.168.60.2   base\nweb     192.168.60.10  web\ndesk    192.168.60.20  base\nadmin   192.168.60.30  base\njump    192.168.60.40  base\ndns     192.168.60.53  base\ntrap    192.168.60.66  base\n\"\nPACKAGES=\"openssh-server sudo nftables iproute2 iputils-ping curl netcat-openbsd python3 nano\nless rsyslog cron lynis ansible-core usbguard fail2ban clamav yara firejail aide auditd acl\nunattended-upgrades unbound bind9-dnsutils inotify-tools strace file binutils wpasupplicant\nhostapd tcpdump jq socat lsof psmisc procps ca-certificates nmap snmp apt-utils git ufw\nopenscap-scanner ssg-debderived bubblewrap xxd\"\nEXTRAS=\"nginx vsftpd openbsd-inetd inetutils-telnetd rpcbind avahi-daemon snmpd\"", "note": "The whole network is this table. Every machine has one address on one segment, 192.168.60.0/24, and `sw` is the switch they are all plugged into. Two images: `base` for six machines, and `web`, which is `base` plus the portal and everything its previous administrator left behind."}, {"code": "die() { echo \"$*\" >&2; exit 1; }\nneed() {\n  [ -n \"$ME\" ] && [ \"$ME\" != root ] || die \"run it with sudo, from your own account\"\n  for c in debootstrap systemd-nspawn ip; do\n    command -v \"$c\" >/dev/null || die \"install first: sudo apt install debootstrap systemd-container iproute2\"\n  done\n}\nin_image() { systemd-nspawn -q --register=no --keep-unit --timezone=off -D \"$LAB/images/$1\" --pipe bash -c \"$2\"; }", "note": "It refuses to start without the three programs it needs, and says which packages hold them. `in_image` runs a command inside an image before anything boots it: that is how the images are filled."}, {"code": "build() {\n  need\n  rm -rf \"$LAB/images\"; mkdir -p \"$LAB/images\"\n  debootstrap --variant=minbase --include=systemd,systemd-sysv,dbus noble \"$LAB/images/base\" \"$MIRROR\"\n  local B=$LAB/images/base\n  printf 'deb %s noble main universe\\ndeb %s noble-updates main universe\\ndeb %s noble-security main universe\\n' \\\n    \"$MIRROR\" \"$MIRROR\" \"$MIRROR\" > \"$B/etc/apt/sources.list\"\n  rm -f \"$B/etc/resolv.conf\"; cp -L /etc/resolv.conf \"$B/etc/resolv.conf\"\n  ln -sf /usr/share/zoneinfo/America/Sao_Paulo \"$B/etc/localtime\"\n  in_image base \"export DEBIAN_FRONTEND=noninteractive\n    apt-get update -q && apt-get install -y -q --no-install-recommends $(echo $PACKAGES)\n    systemctl disable auditd usbguard usbguard-dbus unbound\n    useradd -m -s /bin/bash -G sudo $ME\n    echo '$ME ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$ME\n    install -d -m 700 -o $ME -g $ME /home/$ME/.ssh\n    runuser -u $ME -- ssh-keygen -q -t ed25519 -N '' -f /home/$ME/.ssh/id_ed25519\n    cp /home/$ME/.ssh/id_ed25519.pub /home/$ME/.ssh/authorized_keys\n    printf 'Host *\\n    StrictHostKeyChecking accept-new\\n    LogLevel ERROR\\n' > /home/$ME/.ssh/config\n    chown $ME: /home/$ME/.ssh/*; apt-get clean\"", "note": "`build` makes the base image: a minimal Ubuntu 24.04 from the archive, the course's packages, and your account with a key that every machine trusts. Four services are switched off: `auditd`, `usbguard` and its D-Bus companion because a container cannot run them, which lessons 8 and 5 explain, and `unbound` because only `dns` runs it, from lesson 14. It downloads about 200 MB, and took about three minutes on the computer the course was recorded on."}, {"code": "  cp -a \"$B\" \"$LAB/images/web\"\n  in_image web \"export DEBIAN_FRONTEND=noninteractive\n    apt-get install -y -q --no-install-recommends $(echo $EXTRAS) && apt-get clean\n    useradd -r -m -d /srv/portal -s /bin/bash portal\n    useradd -m -s /bin/bash estagio; echo estagio:Jatoba2019 | chpasswd\n    echo 'estagio ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/estagio\n    useradd -o -u 0 -g 0 -M -d /root -s /bin/bash suporte; echo suporte:suporte123 | chpasswd\n    printf 'PermitRootLogin yes\\nPasswordAuthentication yes\\n' > /etc/ssh/sshd_config.d/50-old.conf\n    echo 'telnet stream tcp nowait root /usr/sbin/telnetd telnetd' > /etc/inetd.conf\n    printf 'agentaddress udp:161\\nrocommunity public\\n' > /etc/snmp/snmpd.conf\n    sed -i 's/^listen=NO/listen=YES/; s/^listen_ipv6=YES/listen_ipv6=NO/' /etc/vsftpd.conf\"", "note": "The `web` image is the client portal of a small accounting firm, Jatobá Contabilidade, as it was handed over. Everything after the `apt-get` line is a decision somebody made years ago and nobody undid: an intern's account with a password and full `sudo`, a second account with user id 0, root allowed to log in with a password, telnet, and SNMP answering anybody who says `public`. Lesson 1 finds them from the outside, the way you would on a server you did not build."}, {"code": "  mkdir -p \"$LAB/images/web/opt/portal\"\n  cat > \"$LAB/images/web/opt/portal/portal.py\" <<'PY'\n#!/usr/bin/env python3\n\"\"\"Jatobá Contabilidade's client portal: one page and a health check.\"\"\"\nimport http.server\n\nclass Portal(http.server.BaseHTTPRequestHandler):\n    def do_GET(self):\n        pages = {\"/\": \"Jatobá Contabilidade: client portal\\n\", \"/healthz\": \"ok\\n\"}\n        if self.path not in pages:\n            return self.send_error(404)\n        body = pages[self.path].encode()\n        self.send_response(200)\n        self.send_header(\"Content-Type\", \"text/plain; charset=utf-8\")\n        self.end_headers()\n        self.wfile.write(body)\n\nhttp.server.ThreadingHTTPServer((\"127.0.0.1\", 8080), Portal).serve_forever()\nPY\n  printf '[Unit]\\nDescription=Jatoba client portal\\n[Service]\\nUser=portal\\nExecStart=/usr/bin/python3 /opt/portal/portal.py\\nRestart=on-failure\\n[Install]\\nWantedBy=multi-user.target\\n' \\\n    > \"$LAB/images/web/etc/systemd/system/portal.service\"\n  printf 'server {\\n    listen 80 default_server;\\n    location / { proxy_pass http://127.0.0.1:8080; }\\n}\\n' \\\n    > \"$LAB/images/web/etc/nginx/sites-available/default\"\n  printf '#!/bin/sh\\ntar czf /var/backups/portal.tgz /srv/portal\\n' > \"$LAB/images/web/opt/portal/backup.sh\"\n  chmod 777 \"$LAB/images/web/opt/portal/backup.sh\"\n  echo '30 2 * * * root /opt/portal/backup.sh' > \"$LAB/images/web/etc/cron.d/portal-backup\"\n  in_image web \"systemctl enable portal\"\n  echo \"images built: $(du -sh \"$LAB/images\" | cut -f1)\"\n}", "note": "The portal itself is under twenty lines of Python's standard library behind nginx, run as its own user. The last lines leave a backup script that root runs every night and that anybody may edit, which lesson 6 is about."}, {"code": "leader() { local p; p=$(cat \"$LAB/run/$1.pid\" 2>/dev/null) && pgrep -P \"$p\" -x systemd | head -1; }\nrunning() { [ -n \"$(leader \"$1\" 2>/dev/null)\" ]; }\ninside() { local m=$1 l; shift; l=$(leader \"$m\") || die \"$m is not running: sudo bash hostlab.sh up $m\"\n  nsenter -t \"$l\" -a env -i TERM=\"${TERM:-dumb}\" LANG=C.UTF-8 \"$@\"; }", "note": "A booted machine is a process tree with its own systemd at the top. `inside` enters that machine's namespaces, which is how `sh`, `root` and `exec` reach it without a network path from your computer."}, {"code": "down() {\n  for m in $(echo \"$MACHINES\" | awk 'NF{print $1}'); do\n    local p; p=$(cat \"$LAB/run/$m.pid\" 2>/dev/null) || continue\n    kill \"$p\" 2>/dev/null || true\n    for _ in $(seq 50); do kill -0 \"$p\" 2>/dev/null || break; sleep 0.2; done\n    rm -f \"$LAB/run/$m.pid\"\n  done\n  for n in $(ip netns list | awk '/^hostlab-/{print $1}'); do ip netns del \"$n\"; done\n}\nup() {\n  need; [ -d \"$LAB/images/web\" ] || die \"build the images first: sudo bash hostlab.sh build\"\n  local want; want=$(echo \"${*:-$(echo \"$MACHINES\" | awk 'NF{print $1}')}\" | tr ' ' '\\n' | grep -vx sw || true)\n  down; mkdir -p \"$LAB/run\" \"$LAB/machines\"\n  ip netns add hostlab-sw; ip -n hostlab-sw link set lo up\n  ip -n hostlab-sw link add br0 address 52:54:00:a8:3c:02 type bridge; ip -n hostlab-sw link set br0 up\n  ip -n hostlab-sw addr add 192.168.60.2/24 dev br0", "note": "`up` starts from nothing every time: the old machines are stopped, and the switch is a fresh network namespace with one bridge in it. Nothing in the lab is connected to your computer's own network, so nothing it runs can be reached from outside, and nothing in it can reach the internet."}, {"code": "  local hosts; hosts=$(echo \"$MACHINES\" | awk 'NF{printf \"%s\\t%s.jatoba.example %s\\n\", $2, $1, $1}')\n  for m in sw $want; do\n    local addr img; read -r addr img < <(echo \"$MACHINES\" | awk -v m=\"$m\" '$1 == m {print $2, $3}')\n    [ -n \"$addr\" ] || die \"no machine called $m\"\n    local M=$LAB/machines/$m; rm -rf \"$M\"; cp -a \"$LAB/images/$img\" \"$M\"\n    echo \"$m\" > \"$M/etc/hostname\"; : > \"$M/etc/machine-id\"\n    printf '127.0.0.1\\tlocalhost\\n127.0.1.1\\t%s\\n%s\\n' \"$m\" \"$hosts\" > \"$M/etc/hosts\"\n    rm -f \"$M/etc/resolv.conf\"; printf 'nameserver 192.168.60.53\\nsearch jatoba.example\\n' > \"$M/etc/resolv.conf\"\n    rm -f \"$M\"/etc/ssh/ssh_host_*; chroot \"$M\" ssh-keygen -A >/dev/null", "note": "Each machine is a fresh copy of its image, with its own name, its own SSH host keys and the address table in `/etc/hosts`. A lesson that breaks a machine costs nothing: the next `up` throws the copy away."}, {"code": "    if [ \"$m\" != sw ]; then\n      ip netns add \"hostlab-$m\"; ip -n \"hostlab-$m\" link set lo up\n      ip link add \"hl-$m\" type veth peer name hl-tmp\n      ip link set hl-tmp netns \"hostlab-$m\"; ip -n \"hostlab-$m\" link set hl-tmp name eth0\n      ip -n \"hostlab-$m\" link set eth0 address \"$(printf '52:54:00:a8:3c:%02x' \"${addr##*.}\")\"\n      ip -n \"hostlab-$m\" addr add \"$addr/24\" dev eth0; ip -n \"hostlab-$m\" link set eth0 up\n      ip link set \"hl-$m\" netns hostlab-sw\n      ip -n hostlab-sw link set \"hl-$m\" name \"port-$m\"; ip -n hostlab-sw link set \"port-$m\" master br0 up\n    fi", "note": "The cable: a pair of virtual network cards, one end inside the machine as `eth0`, the other on the switch as `port-web`, `port-desk` and so on. The card inside gets a fixed hardware address that ends in the last number of its IP address written in hexadecimal, `52:54:00:a8:3c:0a` for web at `.10`, so an address in a log says which machine it was. `sw` needs no cable, because it lives inside the switch's own namespace."}, {"code": "    setsid systemd-nspawn -q -b --console=passive --register=no --keep-unit --timezone=off --capability=CAP_NET_ADMIN \\\n      --network-namespace-path=\"/run/netns/hostlab-$m\" -D \"$M\" --machine \"$m\" \\\n      </dev/null >\"$LAB/run/$m.log\" 2>&1 &\n    echo $! > \"$LAB/run/$m.pid\"\n  done\n  for m in sw $want; do\n    local state=\n    for _ in $(seq 100); do\n      state=$(running \"$m\" && inside \"$m\" systemctl is-system-running --wait 2>&1) || true\n      case $state in running|degraded) break ;; esac; sleep 0.3\n    done\n    printf '%-6s %s\\n' \"$m\" \"${state:-not started}\"\n  done\n}", "note": "Then each copy is booted, with `--capability=CAP_NET_ADMIN` so that services inside a machine may change its own firewall, which `nftables` and `fail2ban` need from lesson 5 on; the network they change is the machine's own and nobody else's. `up` waits for every machine's systemd to say it has finished starting. The last thing it prints is that state per machine: `running` is what you want, and `degraded` means a service failed, which `systemctl --failed` on that machine will name."}, {"code": "case \"${1:-}\" in\n  build) build ;;\n  up) shift; up \"$@\" ;;\n  down) down ;;\n  sh) inside \"${2:?which machine?}\" su -l \"$ME\" ;;\n  root) inside \"${2:?which machine?}\" su -l root ;;\n  exec) inside \"${2:?which machine?}\" su -l \"${3:?which user?}\" -c \"${4:?which command?}\" ;;\n  *) sed -n '2,8s/^# \\{0,1\\}//p' \"$0\"; exit 1 ;;\nesac", "note": "The last lines are the commands. Run it with no argument and it prints the usage from the top of the file."}]}
```

**Check what you pasted before you run it.** A script that runs as root deserves the same look you
would give one somebody emailed you, and this one is no exception. The file the transcripts were
recorded with has this checksum and this many lines; yours should match both, and if it does not,
the copy lost or gained something:

```
$ sha256sum hostlab.sh; wc -l hostlab.sh
fb50feb0327df8a53b9cf3a8cf67c8028e0fa8083bae95630a0f936491131560  hostlab.sh
158 hostlab.sh
$ time sudo bash hostlab.sh build > build.log 2>&1; tail -1 build.log

real	3m3.545s
user	0m51.355s
sys	0m31.273s
images built: 1.8G
```

`build` runs once. It downloads about 200 MB from Ubuntu's archive and leaves two images in
`/var/lib/hostlab/images`, 1.8 GB together. Its own output is long, so the command above sends it to
`build.log` and shows the last line; when something goes wrong, the reason is near the end of that
file.

Then `up`, which you will type at the start of every lesson:

```
$ time sudo bash hostlab.sh up
sw     running
web    running
desk   running
admin  running
jump   running
dns    running
trap   running

real	1m13.080s
user	0m9.291s
sys	0m29.653s
```

Every machine says `running`. On the computer the course was recorded on, the seven of them used
under 1 GB of memory and 6.4 GB of disk between them. `up` with names, `sudo bash hostlab.sh up web
desk`, starts only those two and the switch, which is quicker and is what most lessons ask for.

**Every lesson starts with a fresh lab.** Whatever the previous lesson changed is gone after `up`,
on purpose: each lesson says what it starts from, and starting from the same place as the
transcripts is what makes your output comparable with theirs.

To work on a machine, open a shell on it. The prompt says who you are and where:

```
$ sudo bash hostlab.sh sh web
ana@web:~$ hostname; id
web
uid=1000(ana) gid=1000(ana) groups=1000(ana),27(sudo)
ana@web:~$ ping -c1 -W1 desk | head -2
PING desk.jatoba.example (192.168.60.20) 56(84) bytes of data.
64 bytes from desk.jatoba.example (192.168.60.20): icmp_seq=1 ttl=64 time=0.370 ms
ana@web:~$ exit
logout
```

`sh` gives you your own account on that machine, with `sudo`; `root` gives you a root shell
directly; `exit` brings you back to the lab computer. Your account may use `sudo` without a
password on every machine, which a real server would not allow and which this lesson's section on accounts points at. It
keeps the transcripts free of password prompts. Inside the lab the machines reach each other by
name, `ssh web` from `desk` included, with a key the script made for you in `build`.
