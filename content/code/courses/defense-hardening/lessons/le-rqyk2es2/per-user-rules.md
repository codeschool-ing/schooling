---
title: Rules per account
version: 1
---

**On Linux, a rule can match the account that owns the socket a packet comes from.** That is the
simplest way to write a per-application rule, because on a well-run server every service runs as
an account of its own: the portal as `portal`, nginx's workers as `www-data`. A rule about the
account is a rule about the program.

The portal's job never needs a connection off the machine. It answers nginx over the loopback
interface, and that is all. So the rule is: **the portal's account may talk over loopback and
answer conversations it was part of, and nothing else.** Save this on `web` as `portal-out.nft`:

```schooling-example
{"language": "conf", "file": "portal-out.nft", "parts": [{"code": "table inet portal_out {\n\tchain output {\n\t\ttype filter hook output priority filter; policy accept;\n\t\tmeta skuid \"portal\" oif \"lo\" accept\n\t\tmeta skuid \"portal\" ct state established,related accept\n\t\tmeta skuid \"portal\" counter reject comment \"the portal starts no connection off the machine\"\n\t}\n}", "note": "`meta skuid` matches the account that owns the socket a packet comes from, so this table only ever judges what the portal's account sends. Talking to nginx over loopback is the portal's job, and so is answering a connection somebody else started. Anything else it tries to open is refused and counted. The policy stays `accept`: every other account on `web` is untouched by this table."}]}
```

Load it, then try the same connection as the portal and as yourself:

```
ana@web:~$ sudo nft -f portal-out.nft
ana@web:~$ sudo -u portal nc -zv -w2 desk 22 2>&1; echo "exit $?"
nc: connect to desk (192.168.60.20) port 22 (tcp) failed: Connection refused
exit 1
ana@web:~$ nc -zv -w2 desk 22 2>&1
Connection to desk (192.168.60.20) 22 port [tcp/ssh] succeeded!
ana@desk:~$ curl -s http://web/
Jatobá Contabilidade: client portal
ana@web:~$ sudo nft list chain inet portal_out output | grep counter
		meta skuid 999 counter packets 1 bytes 60 reject comment "the portal starts no connection off the machine"
```

The portal's account was refused at once, `Connection refused`, because `reject` answers rather
than staying silent; on the machine itself there is nobody to hide from, and an instant answer
saves the program a timeout. Your own account still reaches `desk`, because nothing in the table
mentions it. The portal still serves its page to `desk`, because that conversation is nginx's on
port 80 and the portal's over loopback. And the counter shows the one packet the rule refused.

## What the account cannot tell you

The match is on the account, so it is only as good as the separation between accounts. **Two
services sharing one account share one rule**, which is one more reason lesson 1 insisted on a
service account per service. And a program that can become another account, through `sudo` or a
flaw, leaves the rule behind with the account it left. The next section ties a rule to the
service itself, which no account change escapes.
