---
title: Como um servidor consegue um certificado
version: 1
---

Começa no servidor, com uma chave que nunca sai dele. Da chave sai um **pedido de assinatura de
certificado**, um CSR (*certificate signing request*): a chave pública e os nomes, assinados com a
chave privada, e é isso que vai para uma autoridade certificadora:

```
ana@server:~$ openssl req -new -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -subj "/CN=files.example.com" -keyout files.key -out files.csr 2>/dev/null; ls -l files.key files.csr
-rw-r--r-- 1 ana ana 367 Sep 25 14:03 files.csr
-rw------- 1 ana ana 241 Sep 25 14:03 files.key
ana@server:~$ openssl req -in files.csr -noout -subject -verify
Certificate request self-signature verify OK
subject=CN = files.example.com
ana@server:~$ head -1 files.key; head -1 files.csr
-----BEGIN PRIVATE KEY-----
-----BEGIN CERTIFICATE REQUEST-----
```

Dois arquivos. **O `files.key` é `-rw-------`**, legível só pelo dono, e é o que deve ser protegido; o
`files.csr` pode ser mandado para qualquer lugar. O `-verify` confere se o pedido foi assinado pela
chave que ele leva.

A autoridade então precisa conferir que quem mandou o pedido controla o nome. Para a maioria dos sites
hoje, isso é feito pelo protocolo **ACME**, inventado pela Let's Encrypt, sem pessoa nenhuma no meio:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Como um cliente ACME, como o certbot no servidor web, obtém um certificado de uma autoridade certificadora como a Let&#x27;s Encrypt. O cliente pede um certificado para www.example.com. A CA responde: prove, sirva este token. O cliente põe o token em /.well-known/acme-challenge/ no site. A CA o busca por HTTP em www.example.com, o que só funciona se o nome apontar para este servidor. O cliente manda um pedido de assinatura de certificado assinado com a chave do site. A CA devolve o certificado, válido por 90 dias. Nada disto foi rodado no laboratório.\"><defs><marker id=\"ac-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"40\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">certbot no www</text><text x=\"680\" y=\"20\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a CA, Let&#x27;s Encrypt</text><path d=\"M40 32 L40 286\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M680 32 L680 286\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M42 64 L676 72\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ac-ah)\"></path><text x=\"360\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">1  quero um certificado para www.example.com</text><path d=\"M678 104 L44 112\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ac-ah)\"></path><text x=\"360\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">2  prove: sirva este token</text><path d=\"M42 144 L676 152\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ac-ah)\"></path><text x=\"360\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">3  token posto em /.well-known/acme-challenge/</text><path d=\"M678 184 L44 192\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ac-ah)\"></path><text x=\"360\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">4  a CA busca http://www.example.com/.well-known/…</text><path d=\"M42 224 L676 232\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ac-ah)\"></path><text x=\"360\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">5  um CSR, assinado com a chave do site</text><path d=\"M678 264 L44 272\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ac-ah)\"></path><text x=\"360\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">6  o certificado, válido por 90 dias</text></svg>", "caption": "O que um certificado assim confere é o controle do nome, não a identidade. Como ninguém digita nada, dá para fazer isso a cada dois meses sem ninguém perceber, e esse é o ponto."}
```

**Nada disso foi rodado para esta aula**: o laboratório não tem uma autoridade certificadora pública, e
a CA dele assinou os certificados do laboratório diretamente. A checagem `http-01` do desenho prova que
quem pede controla o servidor web para onde o nome aponta; uma checagem `dns-01` prova que controla o
DNS do nome, publicando um registro `TXT` em `_acme-challenge.www.example.com`, e é a que funciona para
servidores que a internet não alcança.

A automação é o que torna certificados curtos suportáveis. A Let's Encrypt emite por 90 dias, como os
do laboratório, e um programa como o `certbot` os renova cerca de um mês antes do fim. O CA/Browser
Forum, onde autoridades e navegadores definem as regras, votou em 2025 encurtar o máximo de todo
certificado aos poucos, até 47 dias em 2029. **Um certificado renovado à mão uma vez por ano é o que
expira num domingo.**
