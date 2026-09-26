---
title: Bridged, from the office
version: 1
---

The bridged guest:

```
ana@vmb:~$ ip -br addr show enp1s0; ip route | head -1
enp1s0           UP             10.0.0.135/24 metric 100 fe80::5054:ff:fe70:310e/64 
default via 10.0.0.1 dev enp1s0 proto dhcp src 10.0.0.135 metric 100 
ana@vmb:~$ curl -sS http://10.0.0.50/
office printer: ready
ana@host:~$ tail -1 /var/log/office-http.log
10.0.0.135 - - [25/Sep/2026 21:14:31] "GET / HTTP/1.1" 200 -
ana@host:~$ sudo ip netns exec printer curl -sS -m 5 -o /dev/null -w "%{http_code}\n" http://$(getent hosts vmb | cut -d" " -f1)/
200
ana@host:~$ sudo cat /run/office-dhcp.leases
1790424636 52:54:00:70:31:0e 10.0.0.135 ubuntu ff:56:50:4d:98:00:02:00:00:ab:11:d6:1a:b5:4d:2c:a5:67:4a
```

vmb got **`10.0.0.135` from the office's DHCP**, and the last command is the office's own lease file with it
in. Its way out is the office's router. The printer's log names vmb's own address, and the printer
reached vmb's web server and got `200`. To everyone on the office network, vmb is **one more computer**.

That is what a server guest needs, and it has consequences worth saying before somebody bridges a lab
guest onto a real network:

- **It is exposed like a real computer.** Everything it runs is reachable by everyone on that network, so
  it needs the same care as one: updates, a firewall, no default passwords.
- **It can disturb the network.** A guest that runs its own DHCP server, which a lab guest being tested
  might, hands out wrong addresses to the whole office.
- **It needs an address from the office.** On a network with a fixed number of addresses, or where
  every device must be registered, a bridged guest is a request to the network's owner, not a setting.
- **Wi-Fi often refuses it.** A wireless access point expects one MAC per client, and a bridged guest is a
  second one; VirtualBox and VMware work around it, and libvirt's plain bridge usually cannot be joined
  to a Wi-Fi card at all.
