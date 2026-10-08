---
title: An office, and two more networks
version: 2
---

To see a guest from the other side, there has to be another side. In an office it is the office's
network, and a bridged guest joins it through the host's own card. Doing that on your home network
brings the risks section 06 lists, and a laptop on Wi-Fi usually cannot do it at all, because most
wireless cards refuse to carry frames from addresses other than their own. So this lesson builds a
small office network **inside the host**, the same way on every computer. Save this as `office.sh`:

```schooling-example
{"language": "bash", "parts": [{"code": "#!/usr/bin/env bash\n# office.sh: a small office network on this computer, for lessons 11 and 15.\n# sudo bash office.sh        builds it\n# sudo bash office.sh down   takes it away\nset -euo pipefail\nif [ \"${1:-}\" = down ]; then\n  kill \"$(cat /run/office-dhcp.pid)\" 2>/dev/null || true\n  ip netns pids printer 2>/dev/null | xargs -r kill 2>/dev/null || true\n  ip netns del printer 2>/dev/null || true\n  ip link del lan0 2>/dev/null || true\n  exit\nfi\nip link show lan0 >/dev/null 2>&1 && { echo \"the office is already up\"; exit; }", "note": "Run as root, because every line changes the host's network. `down` undoes all of it, in the opposite order, and a second run while the office is up says so instead of failing halfway."}, {"code": "ip link add lan0 type bridge\nip addr add 10.0.0.1/24 dev lan0\nip link set lan0 up", "note": "The office's switch: a **bridge** called `lan0`, with the host on it at `10.0.0.1`. On a real office network this is the switch on the wall, and the host's card is plugged into it."}, {"code": "ip netns add printer\nip link add prn0 type veth peer name prn0-lan\nip link set prn0-lan master lan0 up\nip link set prn0 netns printer\nip -n printer addr add 10.0.0.50/24 dev prn0\nip -n printer link set prn0 up\nip -n printer link set lo up", "note": "The printer. A **network namespace** is a second, separate network stack inside the same kernel, with its own cards and its own addresses, which is as much of a computer as a printer needs. A **veth** pair is a cable with two ends: one goes into the namespace as the printer's card, `10.0.0.50`, and the other is plugged into `lan0`."}, {"code": "ip netns exec printer dnsmasq --interface=prn0 --bind-interfaces --port=0 \\\n  --dhcp-range=10.0.0.100,10.0.0.150,12h --dhcp-option=option:router,10.0.0.1 \\\n  --dhcp-leasefile=/run/office-dhcp.leases --pid-file=/run/office-dhcp.pid", "note": "The office's DHCP, run by the printer: addresses `10.0.0.100` to `10.0.0.150`, with the host as the way out. `dnsmasq` is the same program libvirt uses for its own networks. `--port=0` switches its DNS off, because only DHCP is wanted here, and its lease file is where lesson 11 reads who got what."}, {"code": "mkdir -p /var/tmp/office-www\necho \"office printer: ready\" > /var/tmp/office-www/index.html\nip netns exec printer setsid python3 -m http.server 80 --directory /var/tmp/office-www \\\n  >/var/log/office-http.log 2>&1 < /dev/null &\nfor i in $(seq 40); do\n  ip netns exec printer bash -c ': > /dev/tcp/127.0.0.1/80' 2>/dev/null && break\n  sleep 0.25\ndone", "note": "The printer's web page: Python's built-in web server, which writes one line per visitor to `/var/log/office-http.log`. The loop waits up to ten seconds until it answers, so the next command does not race it."}]}
```

It is a bridge called `lan0`, where host is `10.0.0.1`, and one other device on it, a **printer** at
`10.0.0.50` that answers web requests, writes down who asked, and runs the office's DHCP. One check
before running it: if `ip -br addr` on your computer already shows an address starting `10.0.0.`, your
real network uses that range, and the office would hide it. Pick another range, say `10.99.0.`, and
change it everywhere in the script and in this lesson's commands. Then `sudo bash office.sh`, and the
office is there:

```
ana@host:~$ ip -br addr show lan0
lan0             UP             10.0.0.1/24 
ana@host:~$ curl -sS http://10.0.0.50/
office printer: ready
```

Then two libvirt networks, each described in a few lines of XML. `lan` is **bridged**: it joins the
guests to `lan0` itself, the office network, with no NAT and no DHCP of libvirt's own. `isolated` has an
address and a DHCP range but **no `forward` element**, so nothing it carries goes anywhere else:

```
ana@host:~$ cat lan.xml
<network>
  <name>lan</name>
  <forward mode="bridge"/>
  <bridge name="lan0"/>
</network>
ana@host:~$ virsh net-define lan.xml && virsh net-start lan
Network lan defined from lan.xml

Network lan started

ana@host:~$ cat isolated.xml
<network>
  <name>isolated</name>
  <bridge name="virbr1"/>
  <ip address="10.10.10.1" netmask="255.255.255.0">
    <dhcp>
      <range start="10.10.10.10" end="10.10.10.50"/>
    </dhcp>
  </ip>
</network>
ana@host:~$ virsh net-define isolated.xml && virsh net-start isolated
Network isolated defined from isolated.xml

Network isolated started

ana@host:~$ virsh net-list
 Name       State    Autostart   Persistent
---------------------------------------------
 default    active   yes         yes
 isolated   active   no          yes
 lan        active   no          yes
```

On a real host, a bridged network is joined to the host's real card, and the bridge has to exist
first: Ubuntu makes one with netplan, Proxmox made `vmbr0` at installation, lesson 6. One guest was
then made on each network with `newvm.sh` from lesson 1, the network as its second argument: `vmn` on
`default`, `vmb` on `lan`, `vmi` on `isolated`. The base disk has nginx installed and switched off, so
`ssh vmn sudo systemctl start nginx`, and the same on vmb, gave two of them a web page to serve.
