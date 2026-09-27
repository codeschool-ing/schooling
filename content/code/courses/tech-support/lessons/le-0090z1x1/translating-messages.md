---
title: Four messages, translated
version: 1
---

Four messages a user might read out on the phone, produced for real on `pc1`:

```
ana@pc1:~$ curl -sS -m 10 http://intranet/
curl: (6) Could not resolve host: intranet
ana@pc1:~$ sudo -u elisa cat /etc/shadow
cat: /etc/shadow: Permission denied
ana@pc1:~$ curl -sS -m 10 http://localhost:8080/
curl: (7) Failed to connect to localhost port 8080 after 31 ms: Couldn't connect to server
ana@pc1:~$ lpstat -p office
printer office disabled since Sat Sep 26 00:47:23 2026 -
        paper jam, tray 2
```

And what each one means to the person who saw it:

| the machine said | what it means to them | what you might say |
|---|---|---|
| `Could not resolve host: intranet` | the computer could not find the intranet's address | *"Your computer couldn't find where the intranet is. I'm checking why."* |
| `Permission denied` | this account is not allowed to open that file | *"Your account isn't allowed to open that file. If you need it for your work, I'll ask who can give you access."* |
| `Couldn't connect to server` | nothing answered at that address | *"The program you're trying to reach isn't answering. It isn't your computer."* |
| `disabled ... paper jam, tray 2` | the printer stopped itself | *"The printer has stopped because of a paper jam in tray 2. Once it's cleared, it'll carry on."* |

Two habits are visible in the right-hand column. **Each sentence says who is not at fault when that is
true** ("it isn't your computer"), because people assume they broke something. And **none promises what
is not known yet**: "I'm checking why" is honest where "it'll be fine in a minute" is a guess.
