---
title: Setting up a mail program
version: 1
---

Everything above is what a mail program does behind a settings screen. For Ana's account those settings
are:

| | server | port | security | user name |
|---|---|---|---|---|
| incoming, IMAP | `mail.example.com` | 993 | SSL/TLS | `ana` |
| outgoing, SMTP | `mail.example.com` | 587 | STARTTLS | `ana`, with the password |
| incoming, POP3 | `mail.example.com` | 995 | SSL/TLS | only where IMAP is not an option |

**None of these were typed into a mail program for this lesson**; they are the values sections 04, 06 and 07 used, laid out
as Outlook, Thunderbird, Apple Mail and a phone ask for them. Most programs try to guess them from the
address, and when the guess fails, these are what to type. Two mistakes cover most calls. One is the outgoing
server on port 25, which many networks block for ordinary computers. The other is "none" chosen for
encryption, which some servers refuse and others accept, sending the password in the clear.

Companies on Microsoft 365 or Google Workspace see the same protocols under their own names, and set
SPF, DKIM and DMARC in their DNS with the values the provider's admin page gives. The headers, the bounce
and the three checks read exactly as they did here.
