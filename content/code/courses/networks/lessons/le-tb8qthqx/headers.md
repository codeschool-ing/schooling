---
title: Reading the headers
version: 1
---

Every server a message passes through adds a line at the top. On Bruno's server, `doveadm` shows the
headers of Ana's message as they arrived:

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

**Read the `Received:` lines from the bottom up**, because each server puts its own above the ones
before it. The lower one is Ana's server taking the message from the laptop, seen as
`office.example.com [203.0.113.2]` through NAT, `with ESMTPSA`: the S for TLS, the A for
authenticated. The upper one is Bruno's server taking it from `mail.example.com`, `with ESMTPS`, over
TLS between the two servers.

At the very top, Bruno's server wrote down what it checked: `spf=pass`, `dkim=pass` and `dmarc=pass`,
the three of sections 08 to 10. `Return-Path` is the envelope sender, `MAIL FROM`. In a mail program
this is behind *View source* or *Show original*. It is the first thing to ask for when somebody says a
message took hours, went to spam, or came from somebody who says they never sent it.
