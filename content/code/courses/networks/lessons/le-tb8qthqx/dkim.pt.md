---
title: DKIM: uma assinatura na mensagem
version: 1
---

O **DKIM**, DomainKeys Identified Mail, assina a própria mensagem. O servidor da Ana acrescentou o
cabeçalho `DKIM-Signature` da seção 05 com uma chave privada que só ele tem; a metade pública fica no
DNS, sob um **seletor**, aqui `mail`:

```
ana@laptop:~$ dig +short TXT mail._domainkey.example.com | cut -c1-90
"v=DKIM1; h=sha256; k=rsa; " "p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAt70LTRYeLMru+u
ana@netmail:~$ sudo doveadm fetch -u bruno hdr.authentication-results subject "Order 2231"
hdr.authentication-results: mail.example.net; dmarc=pass (p=reject dis=none) header.from=example.com
mail.example.net; spf=pass smtp.mailfrom=example.com
mail.example.net;
        dkim=pass (2048-bit key; unprotected) header.d=example.com header.i=@example.com header.a=rsa-sha256 header.s=mail header.b=IH1t6O+8;
        dkim-atps=neutral
```

A assinatura diz quem assinou, `d=example.com`, com que chave, `s=mail`, que cabeçalhos ela cobre,
`h=Date:From:To:Subject`, e um hash do corpo, `bh=`. O servidor do Bruno buscou
`mail._domainkey.example.com`, conferiu a assinatura com ela e escreveu `dkim=pass (2048-bit key)`.

Como a assinatura viaja dentro da mensagem, **o DKIM sobrevive ao encaminhamento**, justamente onde o SPF
falha. Ela quebra se as partes assinadas mudarem no caminho, como uma lista de discussão que acrescenta um
rodapé ao texto. Um domínio pode publicar vários seletores ao mesmo tempo, um por serviço que manda por
ele, e é assim que uma empresa assina o próprio e-mail e também o do provedor da newsletter.
