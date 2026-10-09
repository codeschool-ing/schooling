---
title: The assumption Zero Trust removes
version: 1
---

Every rule in this course so far has rested on one assumption: **where a packet comes from says
something about whether to trust it**. The staff LAN may use the application because it is the staff
LAN; the proxy may reach it because it is the proxy's address. Lesson 4 drew zones on that basis, and
lesson 19 narrowed them to single addresses.

That assumption fails in three ways the course has already met. A machine inside is compromised
(lesson 9), and everything its zone may reach is now the attacker's. An address is borrowed or forged
(lesson 8). And the network stops having an inside at all: laptops at home, services in somebody
else's data centre, a branch joined by a tunnel. In your lab this lesson starts from
`sudo bash nslab.sh reset`, with the company's policy loaded on `fw` by `nft -f baseline.nft`. The
staff LAN reaches the application's admin page because the baseline says the LAN may:

```
ana@laptop:~$ probe app:8080 app:8443
app:8080               open
app:8443               blocked
ana@laptop:~$ curl -s http://192.168.20.10:8080/admin/
admin console
```

Port 8080 is open to `laptop`, and the admin console answers. Nothing asked **who** was asking; the
answer depended on **where** the request came from.

**Zero Trust** is the design that stops treating location as a credential. Its short form is *never
trust, always verify*: every request is authenticated and authorised on its own merits, whatever network
it arrives from, with the smallest access that serves it, and with the assumption that part of the
network is already hostile. The US standard that describes it, NIST SP 800-207, says in substance that
no implicit trust is granted to a user or a device because of where it sits on the network.

It is not a product and not a replacement for firewalls. It is a change in **what the decision rests
on**: from the address, which the network knows, to the identity, which has to be proved.
