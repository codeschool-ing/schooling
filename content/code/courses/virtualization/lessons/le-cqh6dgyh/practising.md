---
title: Practising, and starting again
version: 1
---

Now the exercise, as a technician would work it. First, what is the service doing?

```
ana@target:~$ systemctl is-active nginx; sudo nginx -t
failed
2026/09/25 22:46:39 [emerg] 1132#1132: invalid parameter "listen" in /etc/nginx/sites-enabled/default:23
nginx: configuration file /etc/nginx/nginx.conf test failed
ana@target:~$ sudo journalctl -u nginx --no-pager | grep -m1 -i emerg
Sep 25 22:46:22 target nginx[1090]: 2026/09/25 22:46:22 [emerg] 1090#1090: invalid parameter "listen" in /etc/nginx/sites-enabled/default:23
```

`is-active` says `failed`. `nginx -t` checks the configuration without starting anything, and names the
fault: an invalid parameter on **line 23 of `/etc/nginx/sites-enabled/default`**. The journal says the
same thing, with the time it first happened. Two commands, and the ticket has a cause.

The fix puts the semicolon back, tests the configuration before restarting, and then checks from where
the user sits:

```
ana@target:~$ sudo sed -i "s/listen 80 default_server$/listen 80 default_server;/" /etc/nginx/sites-enabled/default && sudo nginx -t && sudo systemctl restart nginx && systemctl is-active nginx
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
active
ana@client:~$ curl -sS -o /dev/null -w "%{http_code}\n" http://target/
200
```

`200` from the client: fixed, and verified from the client, which is the only verification the user
cares about. Then the part that makes this a lab:

```
ana@host:~$ virsh snapshot-revert target broken
Domain snapshot broken reverted

ana@client:~$ curl -sS -m 5 http://target/
curl: (7) Failed to connect to target port 80 after 32 ms: Couldn't connect to server
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 150\" role=\"img\" aria-label=\"The practice loop, as five steps in a circle. The target is saved in a snapshot called broken. The student finds the fault, fixes it, and checks from the client that it works. Then the target is reverted to broken, and the next attempt starts from exactly the same fault.\"><defs><marker id=\"lp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">snapshot broken</text><path d=\"M142 50 L156 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><rect x=\"158\" y=\"30\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"168\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">find the fault</text><path d=\"M280 50 L294 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><rect x=\"296\" y=\"30\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"306\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">fix it</text><path d=\"M418 50 L432 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><rect x=\"434\" y=\"30\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"444\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">check from client</text><path d=\"M556 50 L570 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><rect x=\"572\" y=\"30\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"582\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">revert to broken</text><path d=\"M 632 72 C 632 130, 80 130, 80 74\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\" stroke-dasharray=\"4 3\"></path></svg>", "caption": "The snapshot is what makes the exercise repeatable: every attempt starts from the same fault, and fixing it is never lost work, because undoing the fix is one command."}
```

One revert and the target is broken again, exactly as before, ready for the next attempt or the next
person. A lab like this is how to practise a fault until finding it is quick, and how to try a fix you
are not sure of without anything to lose.
