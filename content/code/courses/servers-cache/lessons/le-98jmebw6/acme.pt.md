---
title: ACME, ou como uma máquina prova que controla um nome
version: 1
---

Certificados eram comprados por um ou dois anos, instalados à mão e esquecidos até o dia em que
venciam e derrubavam o site junto. O **ACME**, *Automatic Certificate Management Environment* (RFC
8555), trocou isso por um protocolo que um programa segue sozinho. A Let's Encrypt o criou, emite
certificados por ele de graça e os faz valer por 90 dias de propósito: curto o bastante para ninguém
conseguir renovar à mão, então todo mundo automatiza.

Uma conversa com um servidor ACME tem cinco passos:

1. **uma conta.** O cliente cria um par de chaves e registra a metade pública; toda requisição
   seguinte é assinada com ele.
2. **um pedido** para um ou mais nomes.
3. **um desafio por nome**, que o cliente precisa cumprir para provar que controla o nome.
4. **validação.** A CA confere o desafio pelo lado dela.
5. **finalização.** O cliente manda um pedido de assinatura de certificado com a chave pública do
   servidor, e baixa o certificado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" aria-label=\"Uma sequência entre o certbot no servidor web e o servidor ACME. O certbot registra uma conta, faz um pedido para ipelivros.example e recebe um token de desafio. Ele escreve o token sob /.well-known/acme-challenge no servidor web. O servidor ACME busca essa URL por HTTP, de fora. O certbot então manda um pedido de assinatura e baixa o certificado.\"><defs><marker id=\"fac-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"10\" width=\"200\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">certbot, no seu servidor</text><rect x=\"470\" y=\"10\" width=\"200\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">servidor ACME (CA)</text><line x1=\"130\" y1=\"50\" x2=\"130\" y2=\"290\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"570\" y1=\"50\" x2=\"570\" y2=\"290\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"132\" y1=\"75\" x2=\"568\" y2=\"75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fac-ah)\"></line><text x=\"350\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1. conta nova (chave pública)</text><line x1=\"132\" y1=\"110\" x2=\"568\" y2=\"110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fac-ah)\"></line><text x=\"350\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2. pedido novo: ipelivros.example</text><line x1=\"568\" y1=\"145\" x2=\"132\" y2=\"145\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fac-ah)\"></line><text x=\"350\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3. desafio: sirva o token T por HTTP</text><line x1=\"132\" y1=\"240\" x2=\"568\" y2=\"240\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fac-ah)\"></line><text x=\"350\" y=\"231\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">5. CSR, e depois baixar o certificado</text><rect x=\"160\" y=\"165\" width=\"160\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"240.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">/.well-known/acme-challenge/T</text><path d=\"M 568 182 L 322 182\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#fac-ah)\"></path><text x=\"445\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">4. GET pela porta 80</text><text x=\"350\" y=\"275\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a CA confere o controle do nome, e mais nada</text></svg>", "caption": "Os cinco passos de um pedido ACME com desafio HTTP-01. O passo 4 é a única verificação que a CA faz.", "same": ["/.well-known/acme-challenge/T"]}
```

## Os desafios

O desafio é o ponto inteiro, porque é a única coisa que a CA confere. Há três tipos:

| desafio | o cliente prova o controle | precisa de |
|---|---|---|
| **HTTP-01** | servindo um token dado em `http://<nome>/.well-known/acme-challenge/<token>` | a porta 80 alcançável pela internet |
| **DNS-01** | publicando um token dado num registro TXT em `_acme-challenge.<nome>` | uma API para mudar o DNS do domínio |
| **TLS-ALPN-01** | respondendo a um handshake TLS especial na porta 443 | a porta 443 alcançável, e um servidor que fale isso |

**O HTTP-01 é o padrão e o mais fácil**, e é o que esta aula usa: o servidor web já responde na porta
80 e só precisa servir mais um arquivinho. **O DNS-01 é o único que emite um curinga**,
`*.ipelivros.example`, e o único que funciona para uma máquina que ninguém na internet alcança, como um
servidor dentro da rede de uma empresa. O custo é que a máquina que pede certificados precisa de
credenciais capazes de mudar o DNS do domínio, um segredo poderoso para guardar num servidor web.

## Por que esta aula não usa a Let's Encrypt

A Let's Encrypt confere o desafio **a partir da internet**, então o nome precisa ser um domínio de
verdade, no DNS público, apontando para uma máquina que a internet alcança na porta 80. O servidor
que você montou na aula 1 é uma máquina virtual no seu computador, com nomes que só existem no
`/etc/hosts` dela. Nenhuma CA pública consegue emitir para ele, e esse é o sistema funcionando como
deve.

Então as próximas seções usam o **Pebble**, que a Let's Encrypt escreveu para testar clientes ACME.
Ele fala o mesmo protocolo, o `certbot` conversa com ele sem mudança, e ele confere o desafio
conectando-se ao nome exatamente como a Let's Encrypt faria; a diferença é que a raiz dele não é
confiável para ninguém até você dizer à sua máquina que confie. Tudo nesta aula funciona igual contra
a Let's Encrypt com um domínio de verdade, sem um ou dois argumentos, e cada seção que usa um deles
avisa.
