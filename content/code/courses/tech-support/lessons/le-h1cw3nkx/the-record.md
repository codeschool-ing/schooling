---
title: What the computer writes down
version: 1
---

Every remote session leaves a record on the computer it reached, whether or not anyone reads it:

```
ana@pc1:~$ sudo journalctl -u ssh --no-pager -o cat | grep -m1 Accepted
Accepted publickey for ana from 10.30.0.1 port 37262 ssh2: ED25519 SHA256:VYM/Ij7b9RJCG7ekEnrLId6cMoZyz7Qd0m8WhFKhdgU
ana@pc1:~$ sudo journalctl _COMM=sudo --no-pager -o cat | grep "COMMAND=/usr/bin/tmux" | head -2
     ana : PWD=/home/ana ; USER=elisa ; COMMAND=/usr/bin/tmux -S /tmp/help new -d -s help
     ana : PWD=/home/ana ; USER=elisa ; COMMAND=/usr/bin/tmux -S /tmp/help server-access -a ana
```

- The ssh server logged **who came in, from where, and with which key**: `ana`, from `10.30.0.1`, the
  technician's computer, with a key whose fingerprint identifies it exactly.
- `sudo` logged **every command run with it**, with who ran it and as whom.

Read the second part carefully, because it records something the story above left out. **It was `ana`
who ran Elisa's commands**, with `sudo -u elisa`, including the one that granted `ana` access. In the lab
the technician played Elisa's part, and the record says so plainly. On a real computer, that same line
would be the alarm: a technician who gives herself the user's consent has not been given it.

That is what logs are for in remote support: **they protect both sides**. The user can see who was on
their computer and what was done; the technician can show exactly what they did and did not do. Record
the session in the ticket too, lesson 5: when it started, what the user agreed to, and when it ended.
