---
title: Devoluções e a fila
version: 1
---

Um endereço digitado errado, `brunno@example.net`, é aceito pelo servidor da Ana, que só então tenta
entregar, e falha:

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

A devolução, *Undelivered Mail Returned to Sender*, chegou na própria caixa da Ana, e **a parte útil é o
último parágrafo**: que servidor recusou, com que código, e em que passo. `550 5.1.1 … User unknown …
(in reply to RCPT TO command)` quer dizer que o servidor do `example.net` não tem essa caixa. Um código
que começa com 5 é permanente, e o servidor desiste na hora.

Um código que começa com 4, ou nenhuma resposta, é temporário, e a mensagem espera na **fila**. Com o
servidor do Bruno parado:

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

O `postqueue -p`, também chamado de `mailq`, lista o que está esperando e por quê: `Connection refused`.
O Postfix tenta de novo sozinho por vários dias antes de devolver; o `postqueue -f` pede que ele tente
agora, e quando o servidor do Bruno voltou a fila esvaziou. O log diz o mesmo com uma palavra por
mensagem: `sent`, `bounced`, `deferred`, e depois `sent`. **Uma mensagem sumida está num de três
lugares: entregue, numa devolução, ou numa fila**, e o log diz qual.
