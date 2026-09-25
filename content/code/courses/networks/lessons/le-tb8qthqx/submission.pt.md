---
title: Mandando como pessoa: porta 587
version: 1
---

Um servidor que entregasse qualquer coisa, para qualquer lugar, para qualquer pessoa, seria um **relay
aberto** (*open relay*), e quem manda spam acha esses em poucas horas. O servidor do escritório aceita
e-mail para o próprio domínio de qualquer um, mas só passa e-mail adiante para outros domínios para quem
entrou com senha:

```
ana@laptop:~$ swaks --to bruno@example.net --from ana@example.com --server mail.example.com --quit-after RCPT
=== Trying mail.example.com:25...
=== Connected to mail.example.com.
<-  220 mail.example.com ESMTP
 -> EHLO laptop
<-  250-mail.example.com
<-  250-PIPELINING
<-  250-SIZE 10240000
<-  250-VRFY
<-  250-ETRN
<-  250-STARTTLS
<-  250-ENHANCEDSTATUSCODES
<-  250-8BITMIME
<-  250-DSN
<-  250-SMTPUTF8
<-  250 CHUNKING
 -> MAIL FROM:<ana@example.com>
<-  250 2.1.0 Ok
 -> RCPT TO:<bruno@example.net>
<** 554 5.7.1 <bruno@example.net>: Relay access denied
 -> QUIT
<-  221 2.0.0 Bye
=== Connection closed with remote host.
```

`554 5.7.1 Relay access denied`: o laptop não tinha entrado, e o `example.net` não é domínio deste
servidor. Um programa de e-mail manda para a **porta 587**, de envio (*submission*), que é para pessoas
e não para servidores, e exige senha dentro do TLS:

```
ana@laptop:~$ cat order.txt
Date: Fri, 25 Sep 2026 10:02:00 -0300
Message-ID: <order-2231@example.com>
From: Ana <ana@example.com>
To: Bruno <bruno@example.net>
Subject: Order 2231

Hello Bruno, can you confirm order 2231?
ana@laptop:~$ curl -sS -v --url smtp://mail.example.com:587/laptop.example.com --ssl-reqd --user ana:office-2026 --mail-from ana@example.com --mail-rcpt bruno@example.net -T order.txt 2>&1 | grep -E "^[<>] " | grep -vE "^< 250-(PIPELINING|SIZE|VRFY|ETRN|ENHANCEDSTATUSCODES|8BITMIME|DSN|SMTPUTF8|CHUNKING)"
< 220 mail.example.com ESMTP
> EHLO laptop.example.com
< 250-mail.example.com
< 250-STARTTLS
< 250 CHUNKING
> STARTTLS
< 220 2.0.0 Ready to start TLS
> EHLO laptop.example.com
< 250-mail.example.com
< 250-AUTH PLAIN LOGIN
< 250 CHUNKING
> AUTH PLAIN
< 334 
> AGFuYQBvZmZpY2UtMjAyNg==
< 235 2.7.0 Authentication successful
> MAIL FROM:<ana@example.com> SIZE=202
< 250 2.1.0 Ok
> RCPT TO:<bruno@example.net>
< 250 2.1.5 Ok
> DATA
< 354 End data with <CR><LF>.<CR><LF>
< 250 2.0.0 Ok: queued as 1C7E3D83F3
ana@laptop:~$ echo AGFuYQBvZmZpY2UtMjAyNg== | base64 -d | tr "\0" " "; echo
 ana office-2026
```

`STARTTLS` e `220 Ready to start TLS` tornaram a conexão cifrada, a mesma subida do `AUTH` do FTPS. Só
então o servidor ofereceu `AUTH PLAIN LOGIN`. O curl respondeu com uma linha de base64, e o servidor
disse `235 Authentication successful`.

**Base64 é uma codificação, não uma cifra**: decodificar devolve o usuário e a senha, como o último
comando mostra. Isso não tem problema dentro do TLS e é um desastre fora dele, e é por isso que a porta
587 se recusa a autenticar antes do `STARTTLS`. A porta 465 faz o mesmo serviço com TLS desde o primeiro
byte, e muitos provedores a oferecem no lugar.
