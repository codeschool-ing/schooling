---
title: Asking, and reading the answer
version: 1
---

A machine does not look names up itself. It asks a **resolver**, and the address of the resolver is
in `/etc/resolv.conf`, usually put there by DHCP when the machine joined the network:

```
ana@laptop:~$ cat /etc/resolv.conf
nameserver 198.51.100.53
ana@laptop:~$ getent hosts www.example.com
2001:db8:10::80 www.example.com
```

The laptop's resolver is the provider's, `198.51.100.53`. `getent hosts` asks the way every program
does, and it answered with an **IPv6** address: `getent hosts` asks for IPv6 first, and
`www.example.com` has one. (The lab cannot use it, lesson 2 section 08; a real program would try it and
fall back.)

For looking at DNS itself, the tool is **`dig`**. It sends one question and prints everything that
came back:

```
ana@laptop:~$ dig www.example.com

; <<>> DiG 9.18.39-0ubuntu0.24.04.7-Ubuntu <<>> www.example.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 4669
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
;; QUESTION SECTION:
;www.example.com.               IN      A

;; ANSWER SECTION:
www.example.com.        300     IN      A       192.0.2.80

;; Query time: 0 msec
;; SERVER: 198.51.100.53#53(198.51.100.53) (UDP)
;; WHEN: Fri Sep 25 13:39:23 -03 2026
;; MSG SIZE  rcvd: 60
```

Read it top to bottom:

- **`status: NOERROR`**: the question was answered. Section 07 is the other values.
- `flags: qr rd ra`: this is a response (`qr`), recursion was desired (`rd`), and the server offers it
  (`ra`). Section 05 is about the flag that is missing.
- `QUESTION`: what was asked. `A` is the record type, an IPv4 address.
- `ANSWER`: **`www.example.com. 300 IN A 192.0.2.80`**. Name, *time to live* in seconds, class (`IN`,
  internet, always), type, value.
- `SERVER`: who answered, and over `UDP`, lesson 3's two-packet exchange.

The trailing dot in `www.example.com.` is the root, which every name ends in and nobody types.
