---
title: Reading mail with IMAP
version: 1
---

Bruno answered. His reply travelled the other way, to whatever the MX of `example.com` names:

```
ana@laptop:~$ dig +short MX example.com
10 mail.example.com.
```

Ana reads her mailbox from the laptop with **IMAP**, on port 993, where TLS starts at once. By hand,
through `openssl s_client`:

```
ana@laptop:~$ openssl s_client -connect mail.example.com:993 -crlf -quiet
depth=2 O = Example Trust Services, CN = Example Root CA
verify return:1
depth=1 O = Example Trust Services, CN = Example Issuing CA 1
verify return:1
depth=0 CN = mail.example.com
verify return:1
* OK [CAPABILITY IMAP4rev1 SASL-IR LOGIN-REFERRALS ID ENABLE IDLE LITERAL+ AUTH=PLAIN AUTH=LOGIN] Dovecot (Ubuntu) ready.
a1 LOGIN ana office-2026
a1 OK [CAPABILITY IMAP4rev1 SASL-IR LOGIN-REFERRALS ID ENABLE IDLE SORT SORT=DISPLAY THREAD=REFERENCES THREAD=REFS THREAD=ORDEREDSUBJECT MULTIAPPEND URL-PARTIAL CATENATE UNSELECT CHILDREN NAMESPACE UIDPLUS LIST-EXTENDED I18NLEVEL=1 CONDSTORE QRESYNC ESEARCH ESORT SEARCHRES WITHIN CONTEXT=SEARCH LIST-STATUS BINARY MOVE SNIPPET=FUZZY PREVIEW=FUZZY PREVIEW STATUS=SIZE SAVEDATE LITERAL+ NOTIFY] Logged in
a2 SELECT INBOX
* FLAGS (\Answered \Flagged \Deleted \Seen \Draft)
* OK [PERMANENTFLAGS (\Answered \Flagged \Deleted \Seen \Draft \*)] Flags permitted.
* 1 EXISTS
* 1 RECENT
* OK [UNSEEN 1] First unseen.
* OK [UIDVALIDITY 1790362002] UIDs valid
* OK [UIDNEXT 2] Predicted next UID
a2 OK [READ-WRITE] Select completed (0.003 + 0.000 + 0.002 secs).
a3 FETCH 1 (BODY[HEADER.FIELDS (FROM SUBJECT DATE)])
* 1 FETCH (FLAGS (\Seen \Recent) BODY[HEADER.FIELDS (FROM SUBJECT DATE)] {99}
Date: Fri, 25 Sep 2026 10:15:00 -0300
From: Bruno <bruno@example.net>
Subject: Re: Order 2231

)
a3 OK Fetch completed (0.001 + 0.000 secs).
a4 FETCH 1 BODY[TEXT]
* 1 FETCH (BODY[TEXT] {32}
Confirmed, it ships on Monday.
)
a4 OK Fetch completed (0.001 + 0.000 secs).
a5 LOGOUT
* BYE Logging out
a5 OK Logout completed (0.001 + 0.000 secs).
```

Every IMAP command starts with a **tag** of the client's choosing, `a1` to `a5`, and the server's final
answer to it repeats the tag, so a program can send several at once and match the answers. `SELECT
INBOX` opened the mailbox and said what was in it: `1 EXISTS`, one message. `FETCH` read the headers
asked for, then the text.

**With IMAP the mail stays on the server.** The program shows a copy and keeps it in step: read on the
phone, it shows as read on the laptop, because the `\Seen` flag in the `FETCH` reply is kept on the
server. That is why IMAP is the default for anybody with more than one device.
