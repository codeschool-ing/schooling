---
title: O que um certificado prova
version: 1
---

A crença comum é que HTTPS quer dizer "criptografado", e que o cadeado diz que o site é seguro. As
duas coisas são metade da história. **O TLS faz dois trabalhos: criptografa a conexão e prova que o
servidor do outro lado é aquele a quem o nome pertence.** Criptografia sozinha é barata e quase não
vale nada: uma conexão criptografada com um impostor é uma conversa particular com a pessoa errada. O
certificado é a metade que descarta o impostor, e ele não diz nada sobre se o site é honesto.

Um certificado é um pequeno documento assinado. Ele contém:

- os **nomes** para os quais vale, na extensão *Subject Alternative Name*: `ipelivros.example`,
  `www.ipelivros.example`. O campo mais antigo, *Common Name*, não é mais o que os navegadores
  conferem;
- uma **chave pública**, cuja metade privada fica no servidor e nunca sai de lá;
- as **datas** entre as quais vale;
- o **emissor**, e a assinatura do emissor sobre tudo isso.

Durante o handshake, o servidor manda o certificado e prova que tem a chave privada correspondente. O
cliente confere se o nome que pediu está na lista, se hoje está entre as datas e se a assinatura é
genuína. Depois pergunta quem é o emissor.

## A cadeia

O emissor é uma **autoridade certificadora**, uma CA, e o certificado dela é assinado por outra, até a
cadeia chegar a uma **raiz**: um certificado que assina a si mesmo e que o seu sistema operacional ou
navegador traz numa lista de raízes confiáveis. O Ubuntu guarda essa lista em `/etc/ssl/certs`. Uma
raiz nunca assina diretamente o certificado de um site; ela assina uma **intermediária**, mantida
online, e a intermediária assina os sites, para que a chave da raiz possa ficar offline, onde ninguém
consegue roubá-la.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 230\" role=\"img\" aria-label=\"Três certificados numa coluna. A raiz assina a si mesma e fica no repositório de confiança do cliente. A raiz assina a intermediária. A intermediária assina o certificado do site para ipelivros.example. O servidor manda o certificado do site e a intermediária; o cliente já tem a raiz.\"><defs><marker id=\"fch-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"14\" width=\"230\" height=\"52\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"155.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">CA raiz</text><text x=\"155.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">emissor = ela mesma</text><rect x=\"40\" y=\"89\" width=\"230\" height=\"52\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"155.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">CA intermediária</text><text x=\"155.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">emissor = raiz</text><rect x=\"40\" y=\"164\" width=\"230\" height=\"52\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"155.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ipelivros.example</text><text x=\"155.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">emissor = intermediária</text><line x1=\"155\" y1=\"66\" x2=\"155\" y2=\"87\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fch-ah)\"></line><line x1=\"155\" y1=\"141\" x2=\"155\" y2=\"162\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fch-ah)\"></line><text x=\"165\" y=\"77\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">assina</text><text x=\"165\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">assina</text><rect x=\"400\" y=\"14\" width=\"270\" height=\"52\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"535.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">já está no cliente</text><text x=\"535.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">/etc/ssl/certs</text><rect x=\"400\" y=\"110\" width=\"270\" height=\"90\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"535.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">enviado pelo servidor</text><text x=\"535.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">fullchain.pem</text><text x=\"535.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">site + intermediária</text><line x1=\"272\" y1=\"40\" x2=\"398\" y2=\"40\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#fch-ah)\"></line><line x1=\"272\" y1=\"115\" x2=\"398\" y2=\"140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#fch-ah)\"></line><line x1=\"272\" y1=\"190\" x2=\"398\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#fch-ah)\"></line></svg>", "caption": "Uma cadeia de assinaturas, terminando numa raiz em que o cliente já confiava antes de a conexão começar.", "same": ["ipelivros.example"]}
```

O servidor manda o próprio certificado e as intermediárias. Não manda a raiz, porque uma raiz que o
cliente ainda não tem não provaria nada: qualquer um pode fazer um certificado que assina a si mesmo.
É exatamente isso que a próxima seção faz.

**O que uma CA como a Let's Encrypt confere antes de assinar é que você controla o nome**, e mais
nada: não quem você é, não se a empresa existe, não se o site é seguro. Esse tipo de certificado se
chama *validado por domínio*, e é o que quase todo site usa; os tipos pagos, que também conferem os
documentos de uma organização, não aparecem de forma diferente nos navegadores de hoje. Um site de
phishing num domínio parecido recebe um certificado perfeitamente válido para esse domínio. O cadeado
quer dizer "você está falando com quem controla este nome", uma promessa precisa e útil, e mais
estreita do que a maioria das pessoas lê nela.
