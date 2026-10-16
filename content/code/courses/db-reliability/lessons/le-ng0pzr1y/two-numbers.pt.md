---
title: Dois números, os dois medidos em tempo
version: 1
---

Pergunte às pessoas que dependem de um banco quanto dado elas podem se dar ao luxo de perder e por
quanto tempo podem ficar sem ele, e a primeira resposta é quase sempre **nada e nada**. Essa resposta
não é um requisito. É o que alguém diz antes de qualquer pessoa mostrar o preço, e é o motivo de a
maioria das organizações não ter número de verdade nenhum: uma meta que ninguém consegue cumprir é
ignorada em silêncio, e a meta ignorada é o mesmo que meta nenhuma.

Os dois números de verdade têm nome:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Um eixo de tempo. No meio, o incidente. À esquerda, o último momento recuperável; o trecho entre os dois é o RPO, e o que foi escrito ali se perde. À direita, o momento em que as pessoas voltam a trabalhar; o trecho entre os dois é o RTO, quando ninguém consegue trabalhar.\"><defs><marker id=\"l8t-pa\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><defs><marker id=\"l8t-wi\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><path d=\"M20 100 L700 100\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8t-wi)\"></path><text x=\"700\" y=\"88\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tempo</text><path d=\"M170 70 L170 150\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"170\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">último momento recuperável</text><path d=\"M360 70 L360 150\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"360\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o incidente</text><path d=\"M560 70 L560 150\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"560\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">funcionando de novo</text><rect x=\"176\" y=\"112\" width=\"178\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"265\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">escrito aqui: perdido</text><rect x=\"366\" y=\"112\" width=\"188\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"460\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">ninguém consegue trabalhar</text><path d=\"M176 50 L354 50\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8t-pa)\" marker-start=\"url(#l8t-pa)\"></path><text x=\"265\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">RPO: quanta perda</text><path d=\"M366 50 L554 50\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8t-pa)\" marker-start=\"url(#l8t-pa)\"></path><text x=\"460\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">RTO: quanto tempo parado</text></svg>", "caption": "Os dois objetivos num eixo só. O RPO volta do incidente até o último momento que pode ser recuperado; o RTO avança até o momento em que o sistema volta a ser usável."}
```

- **RPO, o recovery point objective** (objetivo de ponto de recuperação), é quanto dado o negócio
  aceita perder, **medido em tempo**: "no máximo cinco minutos de pedidos". Ele aponta para trás, do
  incidente até o último momento que dá para recuperar. Tudo o que foi escrito depois desse momento
  se perdeu.
- **RTO, o recovery time objective** (objetivo de tempo de recuperação), é quanto tempo o negócio
  aceita ficar sem o sistema: "de volta em até duas horas". Ele aponta para a frente, do incidente até
  o momento em que as pessoas voltam a trabalhar.

Os dois são em tempo porque tempo é o que o negócio consegue avaliar. "Perdemos no máximo 300 MB de
log" não quer dizer nada para quem toca o shop; "perdemos no máximo os últimos cinco minutos de
pedidos" quer dizer um número de vendas e um pedido de desculpas para esse tanto de clientes.

## Três coisas que eles não são

- **Não são um par por empresa.** Os pedidos do shop e a lista da newsletter semanal não merecem os
  mesmos números, e pagar pelo par mais rigoroso em tudo é como os orçamentos de backup explodem. Cada
  sistema ganha o seu, e uns poucos níveis costumam cobrir tudo.
- **Não são o que o esquema entrega.** Um RPO é uma promessa; o que o arquivo da lição 4 entrega é
  uma medição. Esta lição mede a segunda para que a primeira possa ser conferida contra ela.
- **Não tratam de um tipo só de falha.** Um disco que morre, uma região que sai do ar, um `DELETE`
  com o `WHERE` errado e um ataque de ransomware (lição 10) têm, cada um, seu próprio RPO e RTO no
  mesmo esquema. Uma réplica quase não perde dado quando o disco morre e **não protege nada** contra
  o `DELETE`, que ela copia fielmente em até um segundo. Os números têm que dizer de que falha
  estão falando.
