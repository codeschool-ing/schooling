---
title: A refusal is recorded too
version: 1
---

The journal has a line for each of tec's commands, the one that ran and the one that was refused:

```
ana@pc1:~$ sudo journalctl _COMM=sudo --no-pager -o cat | grep "^ *tec :"
     tec : PWD=/home/ana ; USER=root ; COMMAND=/usr/bin/systemctl restart cups
     tec : command not allowed ; PWD=/home/ana ; USER=root ; COMMAND=/usr/sbin/useradd bruno
```

`command not allowed` sits in the same journal as everything else, with the account and the exact
command. On many organisations' servers these lines are collected and someone reviews them, because an
account trying commands it is not allowed is what a stolen account looks like.

So **"just to see if it works" is not a harmless try**. It leaves a line that someone may have to ask
about. A technician who wants to know what an account may do runs `sudo -l`, which answers without
trying anything.
