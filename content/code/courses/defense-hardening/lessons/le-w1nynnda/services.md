---
title: Services nobody asked for
version: 1
---

**A scan from outside tells you what answers. The machine itself tells you who is answering.** `ss`
lists every socket that is waiting for a connection, and `-p` adds the process holding it, which
only root may see for other users' processes. The `awk` at the end keeps three columns, the
protocol, the address and port, and the program's name, because the full line is wider than any
screen:

```
ana@web:~$ sudo ss -Htulpn | awk '{split($7, p, "\""); print $1, $5, p[2]}'
udp 0.0.0.0:5353 avahi-daemon
udp 0.0.0.0:111 rpcbind
udp 0.0.0.0:161 snmpd
udp 0.0.0.0:52315 avahi-daemon
tcp 0.0.0.0:80 nginx
tcp 0.0.0.0:111 rpcbind
tcp 0.0.0.0:23 inetd
tcp 0.0.0.0:22 sshd
tcp 0.0.0.0:21 vsftpd
tcp 127.0.0.1:8080 python3
```

Everything the scan found is here, with a name beside it, plus two things it could not see. The
avahi daemon also holds a random high UDP port for its own queries. And `python3` listens on
`127.0.0.1:8080`, the loopback address, which only programs on `web` itself can reach: that is the
portal, and nginx on port 80 is its front door. **An address of `0.0.0.0` means every interface the
machine has**, so those services answer anybody who can reach `web` at all.

A listener belongs to a process, and on Ubuntu a process belongs to a systemd **unit**, which is
what you switch on and off. These are the services running:

```
ana@web:~$ systemctl list-units --type=service --state=running --no-legend --plain | cut -d" " -f1
avahi-daemon.service
console-getty.service
cron.service
dbus.service
fail2ban.service
inetd.service
nginx.service
portal.service
rpcbind.service
rsyslog.service
snmpd.service
ssh.service
systemd-journald.service
systemd-logind.service
unattended-upgrades.service
vsftpd.service
wpa_supplicant.service
```

Read it against the job. `nginx`, `portal` and `ssh` are the job. `cron`, `dbus`, `rsyslog`,
`systemd-journald` and `systemd-logind` are the system itself. `fail2ban` and `unattended-upgrades`
are protections Ubuntu installs, which lessons 11 and 17 put to work. `console-getty` is the login
prompt on the container's console. That leaves `avahi-daemon`, `inetd`, `rpcbind`, `snmpd` and
`vsftpd`, the five behind the eight ports, and `wpa_supplicant`, which listens on no port at all
and is the last section's business.

Two of them introduce themselves to anybody who connects, before any login:

```
ana@desk:~$ printf "quit\r\n" | nc -w2 web 21
220 (vsFTPd 3.0.5)
221 Goodbye.
ana@desk:~$ snmpget -v2c -c public web 1.3.6.1.2.1.1.5.0
iso.3.6.1.2.1.1.5.0 = STRING: "web"
ana@desk:~$ snmpwalk -v2c -c public web 1.3.6.1.2.1.25.4.2.1.2 | wc -l; snmpwalk -v2c -c public web 1.3.6.1.2.1.25.6.3.1.2 | wc -l
23
322
```

The FTP server gives its name and exact version in its first line. The SNMP agent was asked for the
machine's name with the community string `public`, the default every scanner tries first, and gave
it. The same question with other numbers returns all 23 running processes and 322 lines of installed
software, as the two counts at the end show: a map of the machine, handed to whoever asks.

## Stopping one is not always stopping it

`systemctl disable --now` stops a service and stops it starting at boot. Try it on `rpcbind`:

```
ana@web:~$ sudo systemctl disable --now rpcbind
Synchronizing state of rpcbind.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install disable rpcbind
Removed "/etc/systemd/system/sockets.target.wants/rpcbind.socket".
Removed "/etc/systemd/system/multi-user.target.wants/rpcbind.service".
Disabling 'rpcbind.service', but its triggering units are still active:
rpcbind.socket
Stopping 'rpcbind.service', but its triggering units are still active:
rpcbind.socket
ana@web:~$ sudo ss -Htulpn | grep ':111 '
udp UNCONN 0      0        0.0.0.0:111   0.0.0.0:* users:(("systemd",pid=1,fd=117))                                                                                     
tcp LISTEN 0      4096     0.0.0.0:111   0.0.0.0:* users:(("systemd",pid=1,fd=116))                                                                                     
```

The service stopped, and port 111 is still open, now held by `systemd` itself, process 1. This is
**socket activation**: the unit `rpcbind.socket` makes systemd listen on the port on the service's
behalf and start the service when the first connection arrives. systemd said so in the two warnings
above, and they are the lines people skip. Disabling the service left the socket in charge, so the
next client to knock would have started `rpcbind` again.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l01-socket\" aria-label=\"Socket activation in three steps. One: systemd, process 1, listens on port 111 on behalf of rpcbind.socket, while rpcbind.service is not running. Two: a client connects to port 111. Three: systemd starts rpcbind.service and hands it the socket. Disabling only the service leaves step one in place, so the next client starts it again.\"><defs><marker id=\"l01-socket-dh-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l01-socket-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"250.0\" y=\"40.0\" width=\"220.0\" height=\"60.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">systemd (pid 1)</text><text x=\"360.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">listens on :111 for rpcbind.socket</text><rect x=\"250.0\" y=\"170.0\" width=\"220.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"360.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">rpcbind.service</text><text x=\"360.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">disabled, not running</text><rect x=\"30.0\" y=\"50.0\" width=\"130.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"95.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a client</text><path d=\"M160.0 70.0 L250.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l01-socket-dh-ah-paper-dim)\"></path><text x=\"205.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2 connects</text><path d=\"M360.0 100.0 L360.0 170.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l01-socket-dh-ah-amber)\"></path><text x=\"372.0\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">3 starts it again,</text><text x=\"372.0\" y=\"143.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">and hands over the socket</text><text x=\"500.0\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 still enabled:</text><text x=\"500.0\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">rpcbind.socket</text></svg>", "caption": "Disabling the service left systemd holding the port. The socket has to go too."}
```

The fix is to disable the socket as well, and the same is true of avahi:

```
ana@web:~$ sudo systemctl disable --now rpcbind.socket avahi-daemon.socket avahi-daemon 2>&1 | grep -v ^Removed
Disabling 'avahi-daemon.service', but its triggering units are still active:
avahi-daemon.socket
ana@web:~$ sudo ss -Htulpn | grep -cE ':(111|5353) '
0
```

`disable --now` on a socket and its service together stops both, and `grep -c` counts no listener
left on 111 or 5353. The warning that remains is printed while `systemctl` disables the service,
when the socket beside it in the same command has not been stopped yet.

## Disabled, masked, or gone

There are three strengths of "off", and each fits a different case.

| | what it does | undone by | when |
|---|---|---|---|
| `disable` | the unit no longer starts at boot | `enable` | you may want it back, or a package needs it installed |
| `mask` | the unit is linked to `/dev/null`, so nothing can start it, not even another unit that depends on it | `unmask` | it must stay installed and must never run |
| `apt-get purge` | the package and its configuration are removed from the machine | installing it again | nobody needs it here |

**On a server, removing is the strongest and the simplest.** A disabled service is still a binary
on disk that an update keeps patching, a configuration file that may be wrong, and one `enable`
away from running. A removed one is none of those. Purge the five:

```
ana@web:~$ sudo apt-get purge -y -q vsftpd openbsd-inetd inetutils-telnetd rpcbind avahi-daemon snmpd 2>&1 | grep -E "^(Removing|Purging)" | cut -d" " -f1,2
Removing avahi-daemon
Removing inetutils-telnetd
Removing openbsd-inetd
Removing rpcbind
Removing snmpd
Removing vsftpd
Purging configuration
Purging configuration
Purging configuration
Purging configuration
Purging configuration
Purging configuration
ana@web:~$ sudo ss -Htulpn | awk '{split($7, p, "\""); print $1, $5, p[2]}'
tcp 127.0.0.1:8080 python3
tcp 0.0.0.0:80 nginx
tcp 0.0.0.0:22 sshd
```

Six packages went, with their configuration: `inetd` and the telnet server it ran were two. The
machine now listens on exactly what the job needs, SSH on 22, nginx on 80, and the portal on the
loopback address behind nginx.

**Purging on a machine you did not build needs one question first: who uses this?** A service that
looks idle may be the one a monthly job connects to. Here the answer is known, because the job is
known. On a real network the answer comes from the inventory of lesson 18, from the logs, or from
asking the owner, and it is worth writing down beside the change, because the next person to find
FTP missing will ask why.
