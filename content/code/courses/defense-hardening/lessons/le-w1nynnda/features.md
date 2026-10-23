---
title: Features that came along, and the proof at the end
version: 1
---

**A package brings more than the program you wanted.** Installing one thing installs what it
depends on, and Ubuntu installs what it recommends as well. Over the years a server collects
programs that nothing uses: clients for protocols nobody speaks, tools somebody needed once, daemons
for hardware the machine does not have. None of them listens on a port, so the scan never shows
them. They still need updates, and some of them run.

`web` has 316 packages installed, and 156 of them were asked for by name; the other 160 came as
dependencies:

```
ana@web:~$ dpkg -l | grep -c ^ii; apt-mark showmanual | wc -l
316
156
ana@web:~$ apt-cache rdepends --installed wpasupplicant hostapd
wpasupplicant
Reverse Depends:
hostapd
Reverse Depends:
ana@web:~$ systemctl is-active wpa_supplicant hostapd
active
inactive
```

`apt-cache rdepends --installed` lists what installed package needs each one, and for these two
the list is empty: nothing on the machine depends on `wpasupplicant` or `hostapd`. They are the Wi-Fi
client and the Wi-Fi access point, on a server that has no radio. The lab installs one set of
packages on every machine, and `desk` and `sw` need these two in lesson 4; the portal never will.
`wpa_supplicant` is running anyway: Ubuntu enables it at boot on every machine that installs it,
radio or no radio.

Remove them, masking the running one first so that nothing starts it again while the package goes:

```
ana@web:~$ sudo systemctl mask --now wpa_supplicant 2>&1 | sed "s/ → .*//"
Created symlink /etc/systemd/system/wpa_supplicant.service
ana@web:~$ sudo apt-get purge -y -q hostapd wpasupplicant 2>&1 | grep -E "^(Removing|Purging)" | cut -d" " -f1,2
Removing hostapd
Removing wpasupplicant
Purging configuration
Purging configuration
```

**"Not needed" has to be decided per machine, and written down.** The same two packages are the
point of `desk` in lesson 4. A list of packages to remove from "all servers" is how somebody takes
the Wi-Fi client off the one laptop that needed it; what decides is the machine's job.

## What the services say about themselves

Some features are not packages but behaviour, and the simplest is a banner. nginx names itself and
its exact version in every response, and so does every page of the portal:

```
ana@web:~$ curl -s -D - -o /dev/null http://localhost/ | grep -i ^server
Server: nginx/1.24.0 (Ubuntu)
ana@web:~$ sudo sed -i "s/# server_tokens off;/server_tokens off;/" /etc/nginx/nginx.conf && sudo nginx -t 2>&1 | tail -1 && sudo systemctl restart nginx
nginx: configuration file /etc/nginx/nginx.conf test is successful
ana@web:~$ curl -s -D - -o /dev/null http://localhost/ | grep -i ^server
Server: nginx
```

A version number in a header tells whoever reads it which published flaws to try first, and it
tells the defender nothing. `server_tokens off` keeps the name and drops the version. It is a small
change and it is not a fix: a server that is out of date is out of date whatever it says, and
lesson 16 is about finding out which ones are. What it removes is a free answer to the first
question.

## Measure again

The lesson started with a scan from `desk`, and it ends with the same one:

```
ana@desk:~$ nmap web
Starting Nmap 7.94SVN ( https://nmap.org ) at 2026-10-23 01:37 -03
Nmap scan report for web (192.168.60.10)
Host is up (0.000079s latency).
rDNS record for 192.168.60.10: web.jatoba.example
Not shown: 998 closed tcp ports (conn-refused)
PORT   STATE SERVICE
22/tcp open  ssh
80/tcp open  http

Nmap done: 1 IP address (1 host up) scanned in 0.06 seconds
ana@desk:~$ sudo nmap -sU -p 111,161,5353 web
Starting Nmap 7.94SVN ( https://nmap.org ) at 2026-10-23 01:37 -03
Nmap scan report for web (192.168.60.10)
Host is up (0.000055s latency).
rDNS record for 192.168.60.10: web.jatoba.example

PORT     STATE  SERVICE
111/udp  closed rpcbind
161/udp  closed snmp
5353/udp closed zeroconf
MAC Address: 52:54:00:A8:3C:0A (QEMU virtual NIC)

Nmap done: 1 IP address (1 host up) scanned in 0.19 seconds
```

**Two TCP ports, the two the job needs, and every UDP port the first scan found now answers
`closed`**, which means the machine replied that nothing is there. Between the two scans, one machine lost eight listeners, the six packages behind them and two more with no reason to be there.
It also lost a
second root, two usable passwords, two shells and a `sudo` rule it should never have had, and the
two SSH settings that let anybody try a password as root.

That is the shape of every lesson in this course: a measurement, a change, and the same measurement
again. Lesson 2 replaces the eye with a guide that lists hundreds of these checks and a tool that
runs them.
