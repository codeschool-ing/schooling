---
title: Bounces and the queue
version: 1
---

A mistyped address, `brunno@example.net`, is accepted by Ana's server, which only then tries to deliver
it, and fails:

```
ana@laptop:~$ curl -sS --url smtp://mail.example.com:587/laptop.example.com --ssl-reqd --user ana:office-2026 --mail-from ana@example.com --mail-rcpt brunno@example.net -T wrong.txt && echo accepted
accepted
ana@mail:~$ sudo doveadm fetch -u ana hdr.subject subject "Undelivered"
hdr.subject: Undelivered Mail Returned to Sender
ana@mail:~$ sudo doveadm fetch -u ana body subject "Undelivered" | sed -n "/^This is the mail system/,/RCPT TO command)/p"
This is the mail system at host mail.example.com.

I'm sorry to have to inform you that your message could not
be delivered to one or more recipients. It's attached below.

For further assistance, please send mail to postmaster.

If you do so, please include this problem report. You can
delete your own text from the attached returned message.

                   The mail system

<brunno@example.net>: host mail.example.net[192.0.2.26] said: 550 5.1.1
    <brunno@example.net>: Recipient address rejected: User unknown in local
    recipient table (in reply to RCPT TO command)
```

The bounce, *Undelivered Mail Returned to Sender*, arrived in Ana's own mailbox, and **the useful part
is the last paragraph**: which server refused, with what code, and at which step. `550 5.1.1 … User
unknown … (in reply to RCPT TO command)` means `example.net`'s server has no such mailbox. A code
starting with 5 is permanent, and the server gives up at once.

A code starting with 4, or no answer at all, is temporary, and the message waits in the **queue**.
With Bruno's server stopped:

```
ana@laptop:~$ curl -sS --url smtp://mail.example.com:587/laptop.example.com --ssl-reqd --user ana:office-2026 --mail-from ana@example.com --mail-rcpt bruno@example.net -T again.txt && echo accepted
accepted
ana@mail:~$ sudo postqueue -p
-Queue ID-  --Size-- ----Arrival Time---- -Sender/Recipient-------
8C557D81C5      442 Fri Sep 25 15:47:13  ana@example.com
              (connect to mail.example.net[192.0.2.26]:25: Connection refused)
                                         bruno@example.net

-- 0 Kbytes in 1 Request.
ana@mail:~$ sudo postqueue -f
ana@mail:~$ sudo postqueue -p
Mail queue is empty
ana@mail:~$ sudo grep -oE "to=<[^>]+>.*status=[a-z]+" /var/log/mail/postfix.log
to=<bruno@example.net>, relay=mail.example.net[192.0.2.26]:25, delay=0.28, delays=0.1/0.04/0.01/0.14, dsn=2.0.0, status=sent
to=<ana@example.com>, relay=local, delay=0.15, delays=0.14/0.01/0/0, dsn=2.0.0, status=sent
to=<brunno@example.net>, relay=mail.example.net[192.0.2.26]:25, delay=0.1, delays=0.09/0/0/0.01, dsn=5.1.1, status=bounced
to=<ana@example.com>, relay=local, delay=0, delays=0/0/0/0, dsn=2.0.0, status=sent
to=<bruno@example.net>, relay=none, delay=0.09, delays=0.09/0/0/0, dsn=4.4.1, status=deferred
to=<bruno@example.net>, relay=mail.example.net[192.0.2.26]:25, delay=5.7, delays=5.5/0/0.04/0.15, dsn=2.0.0, status=sent
```

`postqueue -p`, also called `mailq`, lists what is waiting and why: `Connection refused`. Postfix
retries on its own for several days before bouncing; `postqueue -f` asks it to try now, and once
Bruno's server was back the queue emptied. The log says the same in one word per message: `sent`,
`bounced`, `deferred`, then `sent`. **A missing message is in one of three places: delivered, in a
bounce, or in a queue**, and the log says which.
