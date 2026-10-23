---
title: Outbound is where the damage leaves
version: 1
---

**Most host firewalls are written for what comes in and left open for what goes out.** Ubuntu's
own `ufw` ships that way, denying incoming and allowing outgoing, and so does the Windows firewall.
For a laptop that is a reasonable default. For a server it gives away the best signal a defender
has: **a server's outbound traffic is short and predictable**, so anything outside it is worth an
alert, and blocking it costs nothing.

Almost every intrusion that matters needs a way out: to fetch the next tool, to reach whoever is
controlling it, or to send the data it came for. A server that cannot open connections to the
world stops all three, and lesson 9 showed the same allow-list idea on a workstation. On `web`, the
portal's outbound needs are a name server and nothing else. Save this as `web-egress.nft`:

```schooling-example
{"language": "conf", "file": "web-egress.nft", "parts": [{"code": "table inet web_egress {\n\tchain output {\n\t\ttype filter hook output priority filter; policy drop;\n\t\toif \"lo\" accept\n\t\tct state established,related accept\n\t\tip daddr 192.168.60.53 udp dport 53 accept\n\t\tcounter comment \"web starts nothing else\"\n\t}\n}", "note": "The server's whole outbound policy in four rules: loopback, replies to conversations others started, and DNS to the firm's name server. A server is the easy case for an outbound allow-list, because nobody browses from it: everything it needs to reach can be written down, and the counter shows what tried to go anywhere else."}]}
```

Load it and try both directions:

```
ana@web:~$ sudo nft -f web-egress.nft
ana@web:~$ nc -zv -w2 desk 22 2>&1; echo "exit $?"
nc: connect to desk (192.168.60.20) port 22 (tcp) timed out: Operation now in progress
exit 1
ana@desk:~$ curl -s http://web/; ssh web hostname
Jatobá Contabilidade: client portal
web
ana@web:~$ sudo nft list chain inet web_egress output | grep counter
		counter packets 2 bytes 120 comment "web starts nothing else"
```

`web` can no longer start a connection to `desk`, and the attempt shows in the counter. But
`desk` still gets the portal and still logs into `web` over SSH, because those conversations were
started from outside and `web` only replies, which `ct state established` allows.

## What a server needs, written down

The list is short on `web` because the lab is small. On a real server it is the same exercise, done
once and kept with the server's documentation:

| need | destination |
|---|---|
| names | the firm's resolvers, port 53 |
| time | the firm's NTP servers, port 123 |
| updates | the firm's package mirror, or the distribution's mirrors |
| logs and telemetry | the log collector, the EDR console |
| the job itself | a database, an API it calls |

Everything not on the list is a question, and the counter is where the question shows up. **A
counter that is still at zero a month later is as interesting as one that climbs**: either nothing
ever tries that way out, or the rule is in the wrong place.
