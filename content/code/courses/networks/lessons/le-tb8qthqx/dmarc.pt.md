---
title: DMARC: amarrando tudo à linha From
version: 1
---

O SPF prova algo sobre o envelope e o DKIM sobre um domínio que assina, e nenhum dos dois olha o `From:`
que uma pessoa lê. O DMARC olha: ele passa quando o SPF ou o DKIM passaram **para o mesmo domínio do
cabeçalho `From:`**, e o registro do domínio diz o que fazer quando isso não acontece.

```
ana@laptop:~$ dig +short TXT _dmarc.example.net
"v=DMARC1; p=reject; rua=mailto:dmarc@example.net"
ana@home:~$ swaks --to ana@example.com --from bruno@example.net --server mail.example.com --header "Subject: Invoice overdue" --body "Please pay to the new account."
=== Trying mail.example.com:25...
=== Connected to mail.example.com.
<-  220 mail.example.com ESMTP
 -> EHLO home
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
 -> MAIL FROM:<bruno@example.net>
<-  250 2.1.0 Ok
 -> RCPT TO:<ana@example.com>
<-  250 2.1.5 Ok
 -> DATA
<-  354 End data with <CR><LF>.<CR><LF>
 -> Date: Fri, 25 Sep 2026 15:47:04 -0300
 -> To: ana@example.com
 -> From: bruno@example.net
 -> Subject: Invoice overdue
 -> Message-Id: <20260925154704.101257@home>
 -> X-Mailer: swaks v20240103.0 jetmore.org/john/code/swaks/
 -> 
 -> Please pay to the new account.
 -> 
 -> 
 -> .
<** 550 5.7.1 rejected by DMARC policy for example.net
 -> QUIT
<-  221 2.0.0 Bye
=== Connection closed with remote host.
```

`p=reject` manda quem recebe recusar o que falhar. Do `home`, alguém mandou à Ana uma mensagem dizendo
ser do Bruno, pedindo que ela pagasse uma fatura numa conta nova: o envelope e o `From:` diziam os dois
`example.net`, e a conexão veio de `198.51.100.77`. O SPF falhou, porque esse endereço não é o servidor de
e-mail do `example.net`, e não havia assinatura DKIM. O DMARC falhou, e o servidor da Ana respondeu
`550 5.7.1 rejected by DMARC policy for example.net`. A mensagem nunca chegou a ela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"As três conferências que um servidor que recebe faz. Chega uma mensagem dizendo ser From bruno@example.net. O SPF pergunta se o endereço de onde ela veio tem permissão do registro SPF do example.net. O DKIM pergunta se uma assinatura nela confere com a chave pública do example.net no DNS. O DMARC pergunta se alguma das duas passou para o domínio do cabeçalho From; se uma passou, a mensagem é entregue, e se nenhuma passou, o servidor aplica a política do example.net, aqui reject, e responde 550.\"><defs><marker id=\"ck-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">chega uma mensagem dizendo From: bruno@example.net</text><rect x=\"40\" y=\"40\" width=\"640\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"56\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">SPF</text><text x=\"140\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o endereço que mandou tem permissão do example.net?</text><path d=\"M360 82 L360 96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ck-ah)\"></path><rect x=\"40\" y=\"98\" width=\"640\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"56\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">DKIM</text><text x=\"140\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">alguma assinatura confere com a chave do example.net?</text><path d=\"M360 140 L360 154\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ck-ah)\"></path><rect x=\"40\" y=\"156\" width=\"640\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"56\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">DMARC</text><text x=\"140\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">algum passou, para o domínio do From? se não, aplicar p=reject</text><path d=\"M250 208 L180 226\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ck-ah)\"></path><text x=\"170\" y=\"240\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">entregar</text><path d=\"M470 208 L540 226\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ck-ah)\"></path><text x=\"550\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">550: recusada</text></svg>", "caption": "O SPF e o DKIM provam, cada um, algo sobre um domínio; o DMARC liga essa prova à linha From que as pessoas leem, e diz o que fazer quando ela falta.", "same": ["DKIM", "DMARC", "SPF"]}
```

Um domínio chega ao `reject` em etapas: `p=none` só pede relatórios, mandados todo dia ao endereço do
`rua=`, que mostram cada servidor que manda em nome do domínio; `p=quarantine` manda as falhas para o
spam; `p=reject` as recusa. Começar pelo `reject` bloqueia o serviço de newsletter que ninguém lembrou de
pôr no SPF. Nunca publicar DMARC deixa o domínio livre para qualquer um falsificar.
