---
title: Three ways around TLS that do not break it
version: 1
---

TLS, set up properly, is not broken by anybody sitting on the path; lessons 10 to 12 built each piece
it rests on. **What goes wrong in practice is the setup.** Each of the three failures in this lesson's
title leaves the cryptography untouched and goes around it, and each has a defence a network or an
application owner controls.

| failure | what the attacker on the path does | what makes it work | the defence |
|---|---|---|---|
| **downgrade** | persuades both ends to agree on an old, weak version or cipher | a server or client that still accepts them | offer only current versions; TLS 1.3's downgrade protection |
| **stripping** | answers the first plain-HTTP request itself and never lets the upgrade to HTTPS happen | a site reached over HTTP first, relying on a redirect | HSTS, and preloading it |
| **no validation** | presents any certificate at all, and the client accepts it | code or a tool with certificate checking turned off | never turning it off; searching code for where it was |

The attacker in every row is somebody **on the path**: the café's Wi-Fi, a compromised router, the
machine on the LAN that lesson 7 showed lying in ARP. The sections that follow check each defence
on the lab. None of them needs an attacker to be demonstrated, because each is a property of the
server or the client that can be tested directly.
