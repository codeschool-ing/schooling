---
title: Um endereço por página
version: 1
---

**Toda página deve ter exatamente um endereço, e toda outra grafia dele deve redirecionar para lá.** Um
site alcançável como `example.com` e `www.example.com`, por `http` e `https`, com e sem barra no fim, tem
oito endereços para a página inicial. As pessoas compartilham aquele em que caíram, buscadores contam cada
um como uma página separada, e a análise de acessos divide as visitas entre eles.

A crença comum é que isso é coisa de buscador. É também de correção: cookies são definidos por host, então
uma pessoa logada em `www.example.com` está deslogada em `example.com`, e um service worker, aula 10 de
front-performance, é registrado por origem.

## Escolha um de cada

| escolha | a resposta de costume | como os outros chegam |
|---|---|---|
| `https` ou `http` | `https` | o host redireciona a porta 80, como o `host.mjs` fez com o 308 |
| apex ou `www` | qualquer um, dito uma vez | as configurações de domínio do host redirecionam o outro com um 301 |
| `/course/git` ou `/course/git/` | o que os links do app usam | uma regra, ou a normalização do próprio host |

Os quatro hosts deixam você marcar um domínio como principal e redirecionar os outros para ele. Faça isso
no dia em que o domínio for acrescentado, porque o redirecionamento é permanente e os navegadores o
lembram.

## Barras no fim

Hosts normalizam caminhos cada um do seu jeito, e vale conhecer o do seu host antes de escrever links. O
Cloudflare Pages, por exemplo, documenta que redireciona `/contact.html` para `/contact` e
`/about/index.html` para `/about/`. Um host que serve o `index.html` de uma pasta em `/about` e em
`/about/` sem redirecionar criou dois endereços para uma página.

Os links do planner nunca terminam em barra, então a tela dele para `/course/git/` é *Not found*: o app
compara o caminho exatamente. Ou o app aceita as duas grafias, ou o host redireciona uma para a outra; o
que importa é que a escolha seja feita uma vez, escrita, e aplicada em todo lugar.

## Dizendo qual é o certo

Dentro da página, `<link rel="canonical" href="https://example.com/course/git">` diz aos buscadores qual
endereço é o verdadeiro quando uma página é alcançável em vários. É uma declaração, não um
redirecionamento: não faz nada pela pessoa no navegador, e o conserto continua sendo um redirecionamento.
Use os dois onde os duplicados não podem ser removidos, como endereços com parâmetros de rastreamento.
