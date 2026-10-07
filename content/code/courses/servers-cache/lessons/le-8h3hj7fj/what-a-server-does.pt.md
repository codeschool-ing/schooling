---
title: O que um servidor web faz
version: 1
---

A imagem comum de um servidor web é uma máquina: uma caixa num rack que "é" o site. A caixa é a
parte menos interessante. **Um servidor web é um programa que escuta numa porta, lê requisições HTTP
e escreve respostas HTTP**, e tudo o que este curso configura é uma decisão sobre o que esse
programa faz entre ler e escrever.

Para cada requisição ele tem três tipos de resposta:

- **um arquivo do disco.** A requisição nomeia um caminho, o servidor o associa a um arquivo dentro
  de um diretório e envia os bytes. Uma folha de estilo, uma imagem, uma página que nunca muda. Isso
  se chama servir conteúdo **estático**, e um servidor web faz isso mais rápido do que qualquer
  coisa que você escreveria sozinho.
- **a resposta de outro programa.** A requisição pede algo que um programa precisa calcular, como um
  preço que mora num banco de dados. O servidor web passa a requisição a esse programa e devolve a
  resposta. Aqui ele está agindo como **proxy reverso**, e a aula 2 trata só disso.
- **uma resposta própria.** Um redirecionamento, um `404`, uma recusa porque a requisição era grande
  demais, uma cópia de uma resposta que ele guardou antes. A última é um **cache**, e é o assunto das
  aulas 5 a 11.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 260\" role=\"img\" aria-label=\"Uma requisição chega ao servidor web, que a responde de um de três jeitos: com um arquivo do disco, repassando-a à aplicação e devolvendo a resposta dela, ou com uma resposta própria, como um redirecionamento, um erro ou uma cópia em cache.\"><defs><marker id=\"f3a-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"100\" width=\"120\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">navegador</text><text x=\"80.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">GET /...</text><rect x=\"230\" y=\"80\" width=\"170\" height=\"96\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"315.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">servidor web</text><text x=\"315.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">nginx, apache, caddy</text><line x1=\"140\" y1=\"128\" x2=\"228\" y2=\"128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f3a-ah)\"></line><rect x=\"500\" y=\"16\" width=\"180\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um arquivo do disco</text><text x=\"590.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">/var/www/ipe/...</text><rect x=\"500\" y=\"100\" width=\"180\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a aplicação</text><text x=\"590.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">127.0.0.1:8001</text><rect x=\"500\" y=\"184\" width=\"180\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"590.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">resposta própria</text><text x=\"590.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">301 · 404 · 413 · cache</text><line x1=\"400\" y1=\"104\" x2=\"498\" y2=\"44\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f3a-ah)\"></line><line x1=\"400\" y1=\"128\" x2=\"498\" y2=\"128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f3a-ah)\" marker-start=\"url(#f3a-ah)\"></line><line x1=\"400\" y1=\"152\" x2=\"498\" y2=\"212\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f3a-ah)\"></line><text x=\"450\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">estático</text><text x=\"450\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">proxy</text><text x=\"428\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">aulas 5 a 11</text></svg>", "caption": "Toda resposta de um servidor web é de um destes três tipos. A aula 1 trata do primeiro, a aula 2 do segundo, e a maior parte do curso do terceiro.", "same": ["proxy"]}
```

O programa que fica atrás do proxy costuma ser chamado de **servidor de aplicação** ou de **origem**.
Este curso tem um: a Ipê Livros, uma pequena livraria escrita para ele. O catálogo dela é um programa
em Python que responde em `127.0.0.1:8001` e `127.0.0.1:8002`, e o banco de dados é lento de
propósito, para que um cache na frente dele tenha o que economizar. Toda resposta que ele dá diz o
próprio nome num cabeçalho:

```
ana@web:~$ curl -sI localhost:8002/api/books/1
HTTP/1.1 200 OK
Server: ipe-shop/1.0
Date: Wed, 07 Oct 2026 03:11:19 GMT
X-Served-By: shop2
Content-Type: application/json
ETag: "806121fbab2ee803"
Last-Modified: Tue, 01 Sep 2026 13:00:00 GMT
Content-Length: 124
```

**Por que pôr um servidor web na frente**, se a aplicação já fala HTTP? Porque o trabalho em volta da
aplicação é o mesmo para toda aplicação, e fazê-lo bem é difícil. Manter dez mil conexões lentas
abertas, falar TLS, comprimir, recusar uma requisição com corpo de 2 GB, servir arquivos com a ajuda
do kernel, espalhar a carga entre duas cópias, manter um cache. Um servidor web faz isso uma vez, em
código testado, e a sua aplicação fica só com as perguntas que só ela sabe responder.

Esta aula instala os três servidores que você mais vai encontrar, Nginx, Apache e Caddy, e faz cada
um servir a vitrine estática da livraria. O resto do curso usa o Nginx, porque é o que você tem mais
chance de achar na frente da aplicação de outra pessoa, e aponta onde os outros dois fazem algo de
outro jeito.
