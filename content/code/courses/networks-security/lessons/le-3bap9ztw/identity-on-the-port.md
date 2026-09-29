---
title: An identity on every port
version: 1
---

Once a port is open, the switch knows something no firewall rule so far has known: **who** is behind an
address. hostapd keeps it per client:

```
root@sw:~# hostapd_cli -p /root/hostapd-ctrl -i p1 sta 52:54:00:a8:0a:1e | grep -E "^flags|UserName|ReAuthPeriod|eap_type_sta"
flags=[AUTHORIZED]
dot1xAuthReAuthPeriod=3600
dot1xAuthSessionUserName=newpc.corp.example.com
last_eap_type_sta=13 (TLS)
```

`dot1xAuthSessionUserName` is the identity that authenticated. `dot1xAuthReAuthPeriod=3600` means the
switch asks again every hour. hostapd can also check revocation, with its `check_crl` option, which
this lab's configuration does not set. With it, a certificate revoked at nine stops working by ten at
the latest, and nobody touches the switch. It is lesson 21's continuous verification, done
by the port.

The control script wrote the same fact into a log:

```
root@sw:~# cat /var/log/lab/ports.log
2026-09-28T18:33:59-0300 p1 52:54:00:a8:0a:1e open newpc.corp.example.com
```

One line ties a time, a port and a MAC address to a name. Joined with the DHCP server's leases, which
tie the MAC address to an IP address, it answers the question a firewall log alone cannot: which person's
machine was `192.168.10.30` at 18:33. That join is what an NGFW's **user identity** feature, from lesson
2, is built on: the firewall learns from the authentication system which user holds which address, and
a rule can then say `finance` instead of a subnet.

Leaving is logged as well. The laptop logs off, as it would when shutting down:

```
root@newpc:~# wpa_cli -p /root/wpa-ctrl -i eth0 logoff
OK
root@sw:~# nft list set netdev ports authorised
table netdev ports {
	set authorised {
		type ifname . ether_addr
	}
}
root@sw:~# cat /var/log/lab/ports.log
2026-09-28T18:33:59-0300 p1 52:54:00:a8:0a:1e open newpc.corp.example.com
2026-09-28T18:34:11-0300 p1 52:54:00:a8:0a:1e closed
ana@newpc:~$ ping -c 2 -W 1 192.168.10.1
PING 192.168.10.1 (192.168.10.1) 56(84) bytes of data.

--- 192.168.10.1 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1031ms
```

The pair left the set, the log has its second line, and the port is closed again. A port that stayed
open after its owner left would be exactly lesson 21's session that outlived its policy.

Two cautions go with this log:

- **It is personal data.** A record of which person was at which desk, and when, is exactly what data
  protection law asks a company to justify, keep for a stated time and then delete. Lesson 23 decides
  what is worth keeping and for how long.
- **An identity is not a health check.** 802.1X proves the machine holds a valid certificate. It does
  not prove the machine is patched or free of malware. **Posture assessment**, where the NAC system
  also checks the device's state before choosing the VLAN, is the layer that adds that. This lesson
  names it so the difference is clear, and does not build it.
