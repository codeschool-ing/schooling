---
title: The computer’s facts in one paste
version: 1
---

Some of those fields are about the computer, and they are the same questions every time. A short script
answers them in one paste:

```schooling-example
{"language": "bash", "parts": [{"code": "#!/usr/bin/env bash\n# facts.sh: what a ticket needs to know about this computer, in one paste.", "note": "Run on the user's computer, as the user, so `id -un` names them and not you."}, {"code": "echo \"when:     $(date '+%Y-%m-%d %H:%M %Z')\"", "note": "**The time, with its time zone.** A ticket's times are compared with logs, and logs from another server may be in another zone."}, {"code": "echo \"computer: $(hostname)\"\necho \"user:     $(id -un)\"", "note": "Which computer and which account: lesson 2's trap, testing as somebody else, is avoided by writing both down."}, {"code": ". /etc/os-release\necho \"system:   $PRETTY_NAME, kernel $(uname -r)\"", "note": "`/etc/os-release` holds the system's name and version as shell variables, so reading it with `.` sets `$PRETTY_NAME`."}, {"code": "echo \"up since: $(uptime -s)\"", "note": "When it last started. \"Have you restarted it?\" gets answered without asking."}, {"code": "echo \"address:  $(hostname -I | awk '{print $1}')\"", "note": "Its first address, the one another computer would use to reach it."}, {"code": "df -h --output=pcent,avail / | awk 'NR == 2 {print \"disk /:   \" $1 \" used, \" $2 \" free\"}'", "note": "How full the system disk is, because a full disk breaks so many other things, lesson 3."}]}
```

Run on Elisa's computer, as Elisa:

```
ana@pc1:~$ sudo -u elisa bash /tmp/facts.sh
when:     2026-09-26 00:51 -03
computer: pc1
user:     elisa
system:   Ubuntu 24.04.4 LTS, kernel 6.8.0-139-generic
up since: 2026-09-26 00:49:39
address:  10.30.0.76
disk /:   10% used, 6.1G free
```

Seven lines, and each one would otherwise be a question to her or a guess in the ticket. A script like
this is also where a support team starts to share its habits: the same facts, in the same order, from
every technician.
