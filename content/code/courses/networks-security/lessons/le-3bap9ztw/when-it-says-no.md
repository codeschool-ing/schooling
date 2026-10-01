---
title: When the answer is no
version: 1
---

A control is proved by the case it refuses. `visitor` has a certificate, but one it signed itself, as
anything not issued by the company would:

```
root@visitor:~# openssl x509 -in client.crt -noout -subject -issuer -enddate
subject=CN = visitor
issuer=CN = visitor
notAfter=Oct 28 21:33:52 2026 GMT
```

Subject and issuer are the same name: nobody vouches for it but itself. It goes through the same
exchange:

```
root@visitor:~# wpa_supplicant -B -D wired -i eth0 -c wpa.conf -f /var/log/lab/wpa.log -P /root/wpa.pid
root@visitor:~# grep -o "CTRL-EVENT-EAP-[A-Z-]*.*" /var/log/lab/wpa.log
CTRL-EVENT-EAP-STARTED EAP authentication started
CTRL-EVENT-EAP-PROPOSED-METHOD vendor=0 method=13
CTRL-EVENT-EAP-METHOD EAP vendor 0 method 13 (TLS) selected
CTRL-EVENT-EAP-PEER-CERT depth=2 subject='/O=Example Corp/CN=Example Corp Root CA' hash=4e468466047a2a0d3e41dea919a03f501aa8e4fbc729ca24b48b0a5958d9b6d1
CTRL-EVENT-EAP-PEER-CERT depth=1 subject='/O=Example Corp/CN=Example Corp Issuing CA' hash=0ce47ebee9d7875955b7c437837e25ef259f4cf795f8bbfbd8dbaa02bbbb67b3
CTRL-EVENT-EAP-PEER-CERT depth=0 subject='/CN=nac.corp.example.com' hash=7f9e686cbcc1c26742e54841dd6322b2ffe516642d3ee01baa205686839541cb
CTRL-EVENT-EAP-PEER-ALT depth=0 DNS:nac.corp.example.com
CTRL-EVENT-EAP-FAILURE EAP authentication failed
```

The client checked the network's certificate and was satisfied, which is right; the network is genuine.
It is the **server** that refused, and the switch's log says why:

```
root@sw:~# grep -E "^p2: |verification failed" /var/log/lab/hostapd.log
p2: interface state UNINITIALIZED->ENABLED
p2: AP-ENABLED 
p2: CTRL-EVENT-EAP-STARTED 52:54:00:a8:0a:1f
p2: CTRL-EVENT-EAP-PROPOSED-METHOD vendor=0 method=1
p2: CTRL-EVENT-EAP-PROPOSED-METHOD vendor=0 method=13
TLS: Certificate verification failed, error 18 (self-signed certificate) depth 0 for '/CN=visitor'
p2: CTRL-EVENT-EAP-FAILURE 52:54:00:a8:0a:1f
p2: STA 52:54:00:a8:0a:1f IEEE 802.1X: authentication failed - EAP type: 0 (unknown)
p2: STA 52:54:00:a8:0a:1f IEEE 802.1X: Supplicant used different EAP type: 13 (TLS)
```

`error 18 (self-signed certificate)` is the reason, and `CTRL-EVENT-EAP-FAILURE` is the verdict. The two
lines after it are hostapd's bookkeeping; the `EAP type: 0 (unknown)` in them is not a second fault.
Nothing was added to the set, so the port is as closed as it was before:

```
ana@visitor:~$ ping -c 2 -W 1 192.168.10.1
PING 192.168.10.1 (192.168.10.1) 56(84) bytes of data.

--- 192.168.10.1 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1020ms
```

The usual response to a closed port is to borrow an address that is already allowed. `visitor` stops
its supplicant and takes `newpc`'s MAC address:

```
root@visitor:~# kill $(cat wpa.pid)
root@visitor:~# ip link set eth0 down; ip link set eth0 address 52:54:00:a8:0a:1e; ip link set eth0 up
ana@visitor:~$ ip -br link show eth0
eth0@if1858      UP             52:54:00:a8:0a:1e <BROADCAST,MULTICAST,UP,LOWER_UP> 
ana@visitor:~$ ping -c 2 -W 1 192.168.10.1
PING 192.168.10.1 (192.168.10.1) 56(84) bytes of data.

--- 192.168.10.1 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1004ms

ana@newpc:~$ ping -c 2 -W 1 192.168.10.1
PING 192.168.10.1 (192.168.10.1) 56(84) bytes of data.
64 bytes from 192.168.10.1: icmp_seq=1 ttl=64 time=0.045 ms
64 bytes from 192.168.10.1: icmp_seq=2 ttl=64 time=0.062 ms

--- 192.168.10.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1022ms
rtt min/avg/max/mdev = 0.045/0.053/0.062/0.008 ms
```

Still closed, and `newpc` is unaffected, because the set holds the pair **port and address**,
`"p1" . 52:54:00:a8:0a:1e`, and `visitor` is on `p2`. A filter keyed by the MAC address alone would
have let it through.

That is also where 802.1X stops, and a defender should know the edges:

| gap | what happens | what closes it |
|---|---|---|
| a device behind an authorised port | 802.1X authenticates the port once; a small switch placed between the laptop and the wall can carry a second machine, using the laptop's address | **MACsec** (802.1AE), which encrypts and authenticates every frame on the link, not only the start of it |
| devices that cannot authenticate | printers and phones without a supplicant are often let in by MAC address alone (**MAB**, MAC authentication bypass) | a separate segment for them, with lesson 21's rules; a MAC address is written on a label and is not a secret |
| a failure that still needs somewhere to go | a refused guest or an unhealthy laptop | a **guest or quarantine VLAN** assigned by the RADIUS server, instead of a closed port |

Each gap is something to test deliberately in an audit, the way this section tested the borrowed
address. None of them requires turning 802.1X off to check.
