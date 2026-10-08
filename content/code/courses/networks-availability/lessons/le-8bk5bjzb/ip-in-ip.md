---
title: IP-in-IP, the smallest tunnel there is
version: 1
---

**IP-in-IP puts an IP packet directly after another IP header, with nothing between them.** It is
protocol number 4, and on an ordinary Linux router one command creates it:
`ip link add tun0 type ipip local 203.0.113.2 remote 198.51.100.2`. This course builds the same tunnel
with a small program instead, `tunnel.py`, shown whole at the end of this section. It shows that a
tunnel has nothing hidden in it, and it works on any kernel, including the one these transcripts were
recorded on, which was built without the IP-in-IP module. What it puts on the wire is standard
IP-in-IP, and `tcpdump` decodes it as such.

Save it before anything else. Copy the listing at the end of this section with its button, and on the
virtual machine itself:

```sh
nano tunnel.py                                  # paste, then Ctrl+O and Ctrl+X
sudo install -m 755 tunnel.py /usr/local/bin/
```

Every machine of the network sees the same `/usr/local/bin`, so that one copy serves both ends.

On `hq` the tunnel is a network interface like any other. It gets an address at each end, and a route
sends the branch's network into it:

```
ana@hq:~$ sudo setsid tunnel.py ipip tun0 203.0.113.2 198.51.100.2 & sleep 1; ip -br link show tun0
tun0             DOWN           <POINTOPOINT,MULTICAST,NOARP> 
ana@hq:~$ sudo ip addr add 10.0.0.1 peer 10.0.0.2 dev tun0 && sudo ip link set tun0 mtu 1480 up
ana@hq:~$ sudo ip route add 192.168.20.0/24 via 10.0.0.2
```

`POINTOPOINT` says there is exactly one machine at the other end, and `NOARP` says nobody needs to ask
for its hardware address, because there is no hardware. The `10.0.0.x` addresses belong to the tunnel
itself, and the route is the line that matters: **anything for `192.168.20.0/24` goes into `tun0`**.
`branch` gets the mirror image, typed in a shell of its own, and its routing table shows the way back:

```
ana@branch:~$ sudo setsid tunnel.py ipip tun0 198.51.100.2 203.0.113.2 & sleep 1; sudo ip addr add 10.0.0.2 peer 10.0.0.1 dev tun0 && sudo ip link set tun0 mtu 1480 up && sudo ip route add 192.168.10.0/24 via 10.0.0.1
ana@branch:~$ ip route
default via 198.51.100.1 dev eth1 
10.0.0.1 dev tun0 proto kernel scope link src 10.0.0.2 
192.168.10.0/24 via 10.0.0.1 dev tun0 
192.168.20.0/24 dev eth0 proto kernel scope link src 192.168.20.1 
198.51.100.0/24 dev eth1 proto kernel scope link src 198.51.100.2 
ana@laptop:~$ ping -c 2 192.168.20.30
PING 192.168.20.30 (192.168.20.30) 56(84) bytes of data.
64 bytes from 192.168.20.30: icmp_seq=1 ttl=62 time=2.19 ms
64 bytes from 192.168.20.30: icmp_seq=2 ttl=62 time=0.918 ms

--- 192.168.20.30 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 0.918/1.556/2.194/0.638 ms
```

The ping that failed a section ago now works, and the laptop did nothing different. The `ttl=62` is
worth a look: the reply left the till at 64 and lost one for `branch` and one for `hq`. **The ISP's
router is not counted**, because it never saw the inner packet, only the outer one.

## On the wire

From the ISP's side, capturing on the link to `hq`, both headers are visible:

```
ana@isp:~$ sudo tcpdump -n -t -i eth0 -c 2 ip proto 4
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
IP 203.0.113.2 > 198.51.100.2: IP 192.168.10.20 > 192.168.20.30: ICMP echo request, id 59233, seq 1, length 64
IP 198.51.100.2 > 203.0.113.2: IP 192.168.20.30 > 192.168.10.20: ICMP echo reply, id 59233, seq 1, length 64
2 packets captured
2 packets received by filter
0 packets dropped by kernel
ana@isp:~$ sudo tcpdump -n -t -v -i eth0 -c 1 ip proto 4
tcpdump: listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
IP (tos 0x0, ttl 64, id 63671, offset 0, flags [DF], proto IPIP (4), length 104)
    203.0.113.2 > 198.51.100.2: IP (tos 0x0, ttl 63, id 15055, offset 0, flags [DF], proto ICMP (1), length 84)
    192.168.10.20 > 192.168.20.30: ICMP echo request, id 59234, seq 1, length 64
```

Each line reads left to right as two packets, one inside the other: from `203.0.113.2` to
`198.51.100.2`, and inside it from the laptop to the till. With `-v` the byte counts appear. The inner
packet is **84 bytes**, the outer one **104**, and the difference is the one header IP-in-IP adds. The
outer header says `proto IPIP (4)`, which is how the receiving router knows to look inside.

## The program behind it

`tunnel.py` is the whole tunnel, in about fifty lines. It is here because it shows that a tunnel has no
magic in it: read a packet, put a header in front, send it; receive a packet, take the header off,
deliver it.

```schooling-example
{"language": "python", "file": "tunnel.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"A point-to-point tunnel: packets read from a TUN device leave inside an\nouter IPv4 header, and packets arriving inside one are written back to it.\n\n    tunnel.py gre|ipip NAME LOCAL REMOTE [KEY]\n\"\"\"", "note": "What it is and how it is called. The five arguments are the whole configuration: which of the two formats, the name of the device, this end's public address, the far end's, and a key for GRE."}, {"code": "import fcntl, os, select, socket, struct, sys"}, {"code": "mode, name, local, remote = sys.argv[1:5]\nkey = int(sys.argv[5]) if len(sys.argv) > 5 else None", "note": "The arguments, read in order. A key is optional, and only GRE has anywhere to put one."}, {"code": "TUNSETIFF, IFF_TUN, IFF_NO_PI = 0x400454ca, 0x0001, 0x1000\ntun = os.open(\"/dev/net/tun\", os.O_RDWR)\nfcntl.ioctl(tun, TUNSETIFF, struct.pack(\"16sH\", name.encode(), IFF_TUN | IFF_NO_PI))", "note": "Asks the kernel for a TUN device: a network interface whose other side is this program. Whatever the kernel routes into `tun0` comes out of `os.read(tun)` as a bare IP packet, and whatever is written to it goes back in as if it had arrived on a cable."}, {"code": "proto = 47 if mode == \"gre\" else 4        # the outer header's protocol field\nwire = socket.socket(socket.AF_INET, socket.SOCK_RAW, proto)\nwire.bind((local, 0))", "note": "A raw socket for one IP protocol number, 47 for GRE or 4 for IP-in-IP. The kernel writes the outer IP header itself, with this machine's address as the source, so the program never builds one."}, {"code": "def wrap(packet):\n    if mode == \"ipip\":\n        return packet                     # nothing between the two IP headers\n    flags = 0x2000 if key is not None else 0     # K bit: a key follows\n    head = struct.pack(\"!HH\", flags, 0x0800)     # 0x0800: the payload is IPv4\n    if key is not None:\n        head += struct.pack(\"!I\", key)\n    return head + packet", "note": "Going out. For IP-in-IP there is nothing to add: the packet is the payload. For GRE, four bytes of header go in front, the second two saying `0x0800`, IPv4 inside, and four more carry the key when there is one."}, {"code": "def unwrap(outer):\n    inner = outer[(outer[0] & 0x0F) * 4:]  # skip the outer IP header\n    if mode == \"ipip\":\n        return inner\n    flags, ptype = struct.unpack(\"!HH\", inner[:4])\n    if ptype != 0x0800:\n        return None\n    if flags & 0x2000:\n        if struct.unpack(\"!I\", inner[4:8])[0] != key:\n            return None                   # another tunnel's key: not ours\n        return inner[8:]\n    return None if key is not None else inner[4:]", "note": "Coming in, the reverse. A raw socket hands over the whole packet, outer header included, so its length is read from the first byte and skipped. A GRE packet with the wrong key, or with none when one is expected, is dropped: that is the check the key buys."}, {"code": "while True:\n    ready, _, _ = select.select([tun, wire], [], [])\n    try:\n        if tun in ready:\n            wire.sendto(wrap(os.read(tun, 65535)), (remote, 0))\n        if wire in ready:\n            outer, (src, _) = wire.recvfrom(65535)\n            packet = unwrap(outer) if src == remote else None\n            if packet:\n                os.write(tun, packet)\n    except OSError:\n        pass    # an ICMP error came back from the far end: this packet is\n                # lost, as it would be in the kernel's own tunnel", "note": "The whole tunnel. Wait until either side has a packet, move it across, and repeat. A packet from any address other than the far end is ignored, and an ICMP error from the far end costs one packet rather than the program."}]}
```

The kernel's own implementation does the same work without a trip to user space, which is why it is
the one a real router uses. The format on the wire is identical, which is the only thing the far end can
see.
