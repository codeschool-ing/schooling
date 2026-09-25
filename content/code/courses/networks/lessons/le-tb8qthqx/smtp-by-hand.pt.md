---
title: SMTP, digitado à mão
version: 1
---

O SMTP, o Simple Mail Transfer Protocol, é tão simples quanto o FTP e o HTTP: comandos, e respostas com
um código de três dígitos. Do servidor de e-mail do escritório, dá para entregar uma mensagem ao
`example.net` digitando-a, e é exatamente isso que o próprio servidor faz:

```
ana@mail:~$ nc -C mail.example.net 25
220 mail.example.net ESMTP
EHLO mail.example.com
250-mail.example.net
250-PIPELINING
250-SIZE 10240000
250-VRFY
250-ETRN
250-STARTTLS
250-ENHANCEDSTATUSCODES
250-8BITMIME
250-DSN
250-SMTPUTF8
250 CHUNKING
MAIL FROM:<ana@example.com>
250 2.1.0 Ok
RCPT TO:<bruno@example.net>
250 2.1.5 Ok
DATA
354 End data with <CR><LF>.<CR><LF>
From: Ana <ana@example.com>
To: Bruno <bruno@example.net>
Subject: Delivery on Monday

The boxes arrive on Monday.
.
250 2.0.0 Ok: queued as 4CC9CD859D
QUIT
221 2.0.0 Bye
```

O `EHLO` apresenta quem manda e recebe a lista do que o servidor suporta. `MAIL FROM` e `RCPT TO` dão o
remetente e o destinatário, e cada um recebe `250 Ok`. O `DATA` é seguido pela mensagem em si,
cabeçalhos primeiro, uma linha em branco, o texto, e uma linha só com um ponto para terminar.
`250 2.0.0 Ok: queued` quer dizer que o servidor assumiu a responsabilidade por ela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"O envelope e a carta. O envelope são os comandos SMTP: MAIL FROM, que diz para onde mandar uma devolução e é o que o SPF confere, e RCPT TO, que é onde o servidor entrega a mensagem. A carta são os cabeçalhos dentro do DATA: From, que é o que o leitor vê como remetente, e To e Subject. Os cabeçalhos são só texto, escritos por quem mandou a mensagem, e nada no próprio SMTP os obriga a concordar com o envelope.\"><defs><marker id=\"ev-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"20\" width=\"340\" height=\"190\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"22\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o envelope: comandos SMTP</text><rect x=\"370\" y=\"20\" width=\"340\" height=\"190\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"382\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a carta: cabeçalhos dentro do DATA</text><text x=\"22\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">MAIL FROM:&lt;ana@example.com&gt;</text><text x=\"22\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">para onde vai a devolução, e o que o SPF confere</text><text x=\"22\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">RCPT TO:&lt;bruno@example.net&gt;</text><text x=\"22\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">onde o servidor entrega</text><text x=\"382\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">From: Ana &lt;ana@example.com&gt;</text><text x=\"382\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que o leitor vê como remetente</text><text x=\"382\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">To: Bruno &lt;bruno@example.net&gt;</text><text x=\"382\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Subject: Order 2231</text><text x=\"382\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">só texto, escrito por quem mandou</text></svg>", "caption": "Os servidores roteiam pelo envelope; as pessoas leem a carta. Nada no SMTP obriga os dois a concordarem, e é essa brecha que SPF, DKIM e DMARC existem para fechar."}
```

**Há dois remetentes nessa sessão, e eles são coisas diferentes.** `MAIL FROM` e `RCPT TO` são o
envelope: os servidores roteiam e devolvem por eles. `From:` e `To:` dentro do `DATA` são a carta:
texto que o programa do destinatário mostra, escrito por quem mandou a mensagem. O SMTP não confere se
os dois batem, e nunca conferiu. Qualquer um que alcance um servidor de e-mail pode digitar o `From:`
que quiser, e as seções 08 a 10 são o jeito de o servidor que recebe descobrir.
