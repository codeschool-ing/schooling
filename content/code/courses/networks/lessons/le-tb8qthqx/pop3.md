---
title: POP3: download and take away
version: 1
---

**POP3** is older and simpler. On port 995, with TLS from the start:

```
ana@laptop:~$ openssl s_client -connect mail.example.com:995 -crlf -quiet
depth=2 O = Example Trust Services, CN = Example Root CA
verify return:1
depth=1 O = Example Trust Services, CN = Example Issuing CA 1
verify return:1
depth=0 CN = mail.example.com
verify return:1
+OK Dovecot (Ubuntu) ready.
USER ana
+OK
PASS office-2026
+OK Logged in.
STAT
+OK 1 1552
LIST
+OK 1 messages:
1 1552
.
QUIT
+OK Logging out.
```

`STAT` answered `+OK 1 1552`: one message, 1552 bytes. POP3 knows one mailbox and
no folders, and its model is to download the messages and, usually, delete them from the server
(`RETR` and `DELE`); `QUIT` is when the deletions happen.

**That model is what goes wrong for people with two devices**: the laptop downloads a message and
removes it, and the phone never sees it. A mail program set up for POP3 often has a box ticked to
"leave a copy on the server", which softens it. For a person, IMAP is almost always the better choice.
POP3 still fits a single program that collects mail and keeps it elsewhere, such as a ticket system
pulling from a support address.
