---
title: Lendo os cabeçalhos
version: 1
---

Todo servidor por onde uma mensagem passa acrescenta uma linha no topo. No servidor do Bruno, o `doveadm`
mostra os cabeçalhos da mensagem da Ana como ela chegou:

```
ana@netmail:~$ sudo doveadm fetch -u bruno hdr subject "Order 2231"
hdr:
Return-Path: <ana@example.com>
X-Original-To: bruno@example.net
Delivered-To: bruno@example.net
Authentication-Results: mail.example.net; dmarc=pass (p=reject dis=none) header.from=example.com
Authentication-Results: mail.example.net; spf=pass smtp.mailfrom=example.com
Authentication-Results: mail.example.net;
        dkim=pass (2048-bit key; unprotected) header.d=example.com header.i=@example.com header.a=rsa-sha256 header.s=mail header.b=IH1t6O+8;
        dkim-atps=neutral
Received: from mail.example.com (mail.example.com [192.0.2.25])
        by mail.example.net (Postfix) with ESMTPS id 3D866D8413
        for <bruno@example.net>; Fri, 25 Sep 2026 15:46:21 -0300 (-03)
DKIM-Signature: v=1; a=rsa-sha256; c=simple/simple; d=example.com; s=mail;
        t=1790361981; bh=lawu85AnluhYgscNmzIZkGFeavHNM65n9grRClx11KU=;
        h=Date:From:To:Subject;
        b=IH1t6O+8K7cNXJrxJ2YrumB3vza3JDD1dqotWZTZUuDQZxP9rwgGTrvPCyJo789/D
         2qtpkmvPe46y8myNBUoY13Vyui+sPosAzHgurQzaWXII3ZnPxzhqqe+5TWGVr8RDRs
         skAki/3SaZRzyc3GbND0dvho3HQBS3qO0ERlomI5SwJvvQmMScy6Oww+IXWjX4OVzO
         qywqLcen2gTZBvVg1SN8IdGFUccOv2T4wRXUbk3+5s9C9RzM7j3v2YExJWLKv2B2zo
         qbXsDZbsyAjJa8KVyWP9tDP61EBE0KKnyzqDDORzSAlcIAuyWx8DgIgYBk4WZGwxE3
         C7HTEVJO929ew==
Received: from laptop.example.com (office.example.com [203.0.113.2])
        by mail.example.com (Postfix) with ESMTPSA id 1C7E3D83F3
        for <bruno@example.net>; Fri, 25 Sep 2026 15:46:21 -0300 (-03)
Date: Fri, 25 Sep 2026 10:02:00 -0300
Message-ID: <order-2231@example.com>
From: Ana <ana@example.com>
To: Bruno <bruno@example.net>
Subject: Order 2231
```

**Leia as linhas `Received:` de baixo para cima**, porque cada servidor põe a sua acima das anteriores.
A de baixo é o servidor da Ana recebendo a mensagem do laptop, visto como
`office.example.com [203.0.113.2]` através do NAT, `with ESMTPSA`: o S de TLS, o A de autenticado. A de
cima é o servidor do Bruno recebendo-a de `mail.example.com`, `with ESMTPS`, por TLS entre os dois
servidores.

Bem no topo, o servidor do Bruno anotou o que conferiu: `spf=pass`, `dkim=pass` e `dmarc=pass`, os três
das seções 08 a 10. `Return-Path` é o remetente do envelope, o `MAIL FROM`. Num programa de e-mail isso
fica em *Exibir código-fonte* ou *Mostrar original*. É a primeira coisa a pedir quando alguém diz que uma
mensagem demorou horas, caiu no spam, ou veio de alguém que diz que nunca a mandou.
