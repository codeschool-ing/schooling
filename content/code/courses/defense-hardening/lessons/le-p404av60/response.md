---
title: Keep the evidence, stop it, isolate it
version: 1
---

**An alert is the start of the work, not the end of it.** What follows is response, and its order
matters more than its speed: **keep the evidence, stop the activity, contain the machine**, and only
then start repairing. Killing a process first is the instinct, and it destroys the one thing that
could say what the process was.

## Keep the evidence

While `/tmp/update` is still running, the kernel still holds everything about it:

```
ana@web:~$ pgrep -a -u portal
55 /usr/bin/python3 /opt/portal/portal.py
193 /tmp/update 600
ana@web:~$ pid=$(pgrep -f "^/tmp/update"); sudo sha256sum /proc/$pid/exe /usr/bin/sleep
4a193eb6f25eecf27bad523cb8a53ec4d40775eb498f44760b19bfc421cc90aa  /proc/193/exe
4a193eb6f25eecf27bad523cb8a53ec4d40775eb498f44760b19bfc421cc90aa  /usr/bin/sleep
ana@web:~$ pid=$(pgrep -f "^/tmp/update"); sudo cat /proc/$pid/environ | tr "\0" "\n" | grep -E "^(USER|SUDO_USER|PWD)="
SUDO_USER=ana
PWD=/home/ana
USER=portal
```

`pgrep` confirms what the alert said, and `/proc/<pid>/exe` is the running program itself, readable
even if somebody deletes the file in `/tmp` afterwards. Its SHA-256 is the evidence you keep, and
here it settles a question at once: it is identical to `/usr/bin/sleep`'s, so the "unknown program"
is a copy of a system tool. On a real incident that hash is what you would look up, which lesson 19
does with the services built for it. The process's environment says how it came to run, and here
`SUDO_USER=ana` names you, which in a real case would be the most valuable line on the screen.

To keep the program itself, copy `/proc/<pid>/exe` somewhere only root can read before stopping
anything. A responder writes down each command and its time as well, because the record of what
was done to the machine is part of the evidence about it.

## Stop it

```
ana@web:~$ sudo pkill -u portal -f "^/tmp/update"; sleep 1; pgrep -a -u portal
55 /usr/bin/python3 /opt/portal/portal.py
```

The copy is gone and the portal's own process, 55, is the only thing left running as `portal`.
Stopping a process ends this activity and nothing else: whatever made the portal run a command is
still there, which is why the next step does not wait for the cause to be found.

## Isolate the machine

**Isolation cuts a machine off the network except for the people responding to it.** It stops
whatever is on the machine from reaching anything else, and keeps the machine on, with its memory,
its processes and its logs intact, which a power cut would destroy. Every EDR product has a button
for it. Underneath, the button is a firewall, and this one is a file. Save it as `isolate.nft` in
your home on `web`:

```schooling-example
{"language": "conf", "file": "isolate.nft", "parts": [{"code": "table inet isolate {\n\tchain input {\n\t\ttype filter hook input priority -10; policy drop;\n\t\tiif \"lo\" accept\n\t\tip saddr 192.168.60.30 tcp dport 22 accept\n\t}\n\tchain output {\n\t\ttype filter hook output priority -10; policy drop;\n\t\toif \"lo\" accept\n\t\tip daddr 192.168.60.30 tcp sport 22 accept\n\t}\n}", "note": "Isolation is a firewall with one door left open. Every packet in or out is dropped except loopback and SSH with `admin`, 192.168.60.30, which is where the responder works from. In nftables a packet dropped by any chain stays dropped, so an `accept` in another table on the machine cannot let traffic past these two; priority `-10` only makes them look first."}]}
```

Load it, then try the machine from both sides:

```
ana@web:~$ sudo nft -f isolate.nft && sudo nft list tables
table inet isolate
ana@desk:~$ ping -c1 -W1 web | tail -2; curl -s -m3 http://web/; echo "exit $?"
1 packets transmitted, 0 received, 100% packet loss, time 0ms

exit 28
ana@admin:~$ ssh web "hostname; uptime -p"
web
up 16 minutes
```

From `desk`, the ping is lost and the portal's page times out: as far as the network is concerned,
`web` is gone. From `admin`, SSH still works, because that one door was left open on purpose. The
shell you are typing in on `web` was never affected either, because `hostlab.sh` reaches a machine
by entering it, not across the network, much as a product's agent keeps its own channel to its
console.

When the machine has been examined and repaired, isolation ends by deleting the table:

```
ana@web:~$ sudo nft delete table inet isolate; sudo nft list tables
ana@desk:~$ curl -s -m3 http://web/
Jatobá Contabilidade: client portal
```

The page answers `desk` again. **In real life that is the last step, not the next one**: a machine
that was running somebody else's command is reinstalled or restored from a known-good state, and
lesson 3 is about putting a machine back to the configuration it is meant to have.
