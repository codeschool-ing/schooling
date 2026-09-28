---
title: The authenticator
version: 1
---

On a real switch, 802.1X is a few lines of configuration per port and the address of a RADIUS server.
In the lab the switch is a Linux bridge, and **hostapd** plays the authenticator. The daemon is better
known for running Wi-Fi access points, and its `wired` driver does the same job on a cable. This is
the configuration for port `p1`:

```
root@sw:~# cat hostapd-p1.conf
interface=p1
driver=wired
logger_stdout=-1
logger_stdout_level=2
ieee8021x=1
eap_server=1
eap_user_file=/root/eap_user
ca_cert=/root/ca.crt
server_cert=/root/server.crt
private_key=/root/server.key
ctrl_interface=/root/hostapd-ctrl
```

The lines that matter:

- `ieee8021x=1` turns port authentication on.
- `eap_server=1` makes hostapd answer the EAP exchange itself, instead of forwarding it to RADIUS. It
  is the lab's shortcut, and the exchange a RADIUS server would run is the same one.
- `ca_cert` is the CA a client's certificate must chain to. `server_cert` and `private_key` are the
  certificate the switch presents, so the client can check it is talking to the real network.
- `eap_user_file` names the file saying which method each identity must use. Here it holds one line,
  `* TLS`: every identity must use EAP-TLS, so no password method is on offer.

hostapd decides and logs; it does not touch the packet filter. The link between the two is a short
script that hostapd's control client runs on every event:

```schooling-example
{"language": "sh", "file": "port-control.sh", "parts": [{"code": "#!/bin/bash\n# called by hostapd_cli -a: $1 interface, $2 event, $3 the client's MAC\n# the port opens for that address alone, and the line in ports.log says who\ncase $2 in", "note": "hostapd_cli calls the script with three arguments: the port, the name of the event and the client's MAC address."}, {"code": "  AP-STA-CONNECTED)\n    nft add element netdev ports authorised \"{ $1 . $3 }\"", "note": "Success opens the port for that pair, this port and this MAC, and nothing wider. The same MAC on another port is still refused."}, {"code": "    who=$(hostapd_cli -p /root/hostapd-ctrl -i \"$1\" sta \"$3\" | sed -n 's/^dot1xAuthSessionUserName=//p')\n    echo \"$(date +%FT%T%z) $1 $3 open $who\" >> /var/log/lab/ports.log ;;", "note": "It asks hostapd which identity authenticated and writes one line: when, which port, which MAC, and who."}, {"code": "  AP-STA-DISCONNECTED)\n    nft delete element netdev ports authorised \"{ $1 . $3 }\"\n    echo \"$(date +%FT%T%z) $1 $3 closed\" >> /var/log/lab/ports.log ;;\nesac", "note": "A logoff, a failed re-authentication or a lost link closes the port again, and says so in the same log."}]}
```

A commercial switch does all of this internally. Written out, it shows the order a switch follows:
the port opens **because** the authentication succeeded, and for the one address that succeeded.

The switch's administrator starts the daemon, with both ports' configurations, and one control client
per port running the script:

```
root@sw:~# hostapd -B -f /var/log/lab/hostapd.log hostapd-p1.conf hostapd-p2.conf
root@sw:~# hostapd_cli -p /root/hostapd-ctrl -i p1 -a /root/port-control.sh -B
root@sw:~# hostapd_cli -p /root/hostapd-ctrl -i p2 -a /root/port-control.sh -B
```

No output means each started and went into the background; hostapd's own messages go to
`/var/log/lab/hostapd.log`, which the next sections read.
