---
title: The same questions on Windows and macOS
version: 1
---

The layers are the same on every system, and so are the questions. The commands change:

```sh
ipconfig /all                 # Windows: addresses, MAC ("Physical Address"), gateway, DNS
arp -a                        # Windows and macOS: the neighbour table
route print                   # Windows: the routing table
Get-NetAdapter                # Windows PowerShell: link state and MAC, one line per card
Get-NetIPConfiguration        # Windows PowerShell: address, gateway and DNS together
Test-NetConnection 192.0.2.80 -Port 443   # Windows PowerShell: is that port open?
tracert 192.0.2.80            # Windows: traceroute
ifconfig en0                  # macOS: the card, its MAC ("ether") and address
netstat -rn                   # macOS: the routing table
```

**None of these were run for this lesson**; the lab is Linux. The ones worth remembering:

- `ipconfig /all` is the Windows first look: the MAC is labelled *Physical Address*, and the
  addresses, the gateway and the DNS servers are in one screen. `Get-NetIPConfiguration` is the same
  in PowerShell.
- `arp -a` prints the neighbour table on both Windows and macOS, the `ip neigh` of section 03.
- `tracert` is Windows' `traceroute`. It sends ICMP where Linux's `traceroute` sends UDP by default,
  so a firewall can let one through and stop the other. Lesson 10 uses that.
- `Test-NetConnection` with `-Port` is Windows' `nc -zv`: it reports `TcpTestSucceeded : True` or
  `False`.

On a Mac, the Wi-Fi card is usually `en0`, and `ifconfig en0` shows its MAC as `ether` and its IPv4
address as `inet`. The commands differ, and the reading is the same: link, address, route, port,
name.
