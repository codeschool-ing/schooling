---
title: The computer writes it down
version: 1
---

Every command in this lesson that went through `sudo` left a line in the system journal, lesson 10's
record. `grep` keeps the four quoted above:

```
ana@pc1:~$ sudo journalctl _COMM=sudo --no-pager -o cat | grep -E "COMMAND=/usr/bin/(ls|lpstat|cmp)"
     ana : PWD=/home/ana ; USER=root ; COMMAND=/usr/bin/ls /home/elisa
     ana : PWD=/home/ana ; USER=root ; COMMAND=/usr/bin/lpstat -W completed -o
     ana : PWD=/home/ana ; USER=root ; COMMAND=/usr/bin/ls -l /var/spool/cups
     ana : PWD=/home/ana ; USER=root ; COMMAND=/usr/bin/cmp /var/spool/cups/d00001-001 /home/elisa/letter-to-doctor.txt
```

The journal names the account, the folder it was in and the exact command, and it did so for every one of
them, including the listing of Elisa's folder. Whoever reads this journal later, during an audit, a
complaint or an investigation, sees what the technician looked at, in the technician's own name.

The record works in both directions. **For a technician who stayed inside the ticket, it is a defence**:
it shows that they did what the work needed and nothing else. For one who went looking, it is the
evidence. Either way, the right attitude is to work as if every command will be read later by the person
whose computer it was, because it can be.
