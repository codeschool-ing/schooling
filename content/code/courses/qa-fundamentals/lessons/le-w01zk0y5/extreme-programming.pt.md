---
title: Programação Extrema, o método que fez do teste trabalho de quem programa
version: 1
---

**A Programação Extrema, XP, é um método ágil construído em torno de práticas de engenharia, e mais delas tratam
de teste do que em qualquer outro método.** Kent Beck a formou num projeto de folha de pagamento na Chrysler em
1996 e a descreveu em *Extreme Programming Explained* em 1999; a segunda edição, de 2004, com Cynthia Andres, é a
que a maioria dos times lê hoje.

Onde o Scrum não diz nada sobre como construir software, o XP diz muito. O nome vem de pegar práticas que todo
mundo concordava serem boas e levá-las ao máximo: se revisar código é bom, revise tudo, o tempo todo; se testar é
bom, teste antes de escrever o código.

## Cinco valores

O XP se apoia em cinco valores: **comunicação, simplicidade, feedback, coragem e respeito** (o último entrou na
segunda edição). O que explica as práticas de teste é o feedback. Cada prática do XP é um jeito de descobrir mais
cedo se algo está errado.

## As práticas que quem testa encontra

| prática | o que é | o que faz com o teste |
|---|---|---|
| **programar com o teste antes** | quem programa escreve um teste automatizado antes do código que o faz passar | existem verificações de unidade para tudo, escritas por quem escreveu o código |
| **programação em par** | duas pessoas num computador, uma digitando, outra revisando enquanto se digita | cada linha é revisada enquanto é escrita, o momento mais barato que existe |
| **integração contínua** | as mudanças de todos são juntadas e todas as verificações rodam várias vezes por dia | uma regressão é achada horas depois da mudança que a causou |
| **build de dez minutos** | o build inteiro e suas verificações terminam em dez minutos | ninguém fica tentado a pular as verificações por demorarem |
| **entregas pequenas** | o software chega aos usuários a cada poucas semanas ou antes | o uso real também é feedback |
| **testes do cliente** | o cliente, com ajuda, escreve os testes que dizem que uma história foi aceita | critérios de aceitação viram verificações que rodam todo dia |
| **time inteiro** | o cliente senta com o time, e todo mundo necessário está nele | perguntas são respondidas em minutos, não por e-mail na semana seguinte |

A aula 15 é inteira sobre programar com o teste antes, na forma em que isso cresceu: o desenvolvimento guiado por
testes.

## Feedback em laços

As práticas do XP se encaixam umas dentro das outras, cada uma um laço de duração diferente, e cada uma pega um
tipo diferente de erro. Os laços mais curtos pegam deslizes; os mais longos pegam a construção da coisa errada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 270\" role=\"img\" data-fig=\"l14-loops\" aria-label=\"Seis laços de feedback aninhados na Programação Extrema, de fora para dentro: entrega, meses; iteração, semanas; testes do cliente, dias; integração contínua, horas; testes de unidade escritos antes do código, minutos; programação em par, segundos. Os laços de fora pegam a coisa errada sendo construída; os de dentro pegam um deslize numa linha.\"><rect x=\"10.0\" y=\"10.0\" width=\"660.0\" height=\"216.0\" rx=\"12\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"22.0\" y=\"24.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">entrega</text><text x=\"658.0\" y=\"24.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">meses</text><rect x=\"56.0\" y=\"46.0\" width=\"568.0\" height=\"180.0\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"68.0\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">iteração</text><text x=\"612.0\" y=\"60.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">semanas</text><rect x=\"102.0\" y=\"82.0\" width=\"476.0\" height=\"144.0\" rx=\"12\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"114.0\" y=\"96.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">testes do cliente</text><text x=\"566.0\" y=\"96.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">dias</text><rect x=\"148.0\" y=\"118.0\" width=\"384.0\" height=\"108.0\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"160.0\" y=\"132.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">integração contínua</text><text x=\"520.0\" y=\"132.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">horas</text><rect x=\"194.0\" y=\"154.0\" width=\"292.0\" height=\"72.0\" rx=\"12\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"206.0\" y=\"168.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">testes de unidade, antes do código</text><text x=\"474.0\" y=\"168.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">minutos</text><rect x=\"240.0\" y=\"190.0\" width=\"200.0\" height=\"36.0\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"340.0\" y=\"201.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">programação em par</text><text x=\"340.0\" y=\"214.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">segundos</text><text x=\"14.0\" y=\"250.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">← construir a coisa errada</text><text x=\"666.0\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">um deslize numa linha →</text></svg>", "caption": "As práticas do XP como laços de feedback. Cada uma é um jeito de descobrir mais cedo, e cada uma pega um tamanho diferente de erro."}
```

No Cine Aurora, o Rafael e o Tomás experimentaram as práticas do XP uma de cada vez. O par veio primeiro, depois
do desconto de quarta: o Tomás tinha revisado aquela mudança sozinho um dia depois de escrita, e deixou passar o
empilhamento. Quando fizeram par no código dos cupons, o Tomás perguntou "e numa quarta?" enquanto o Rafael ainda
digitava a linha, e a combinação ficou resolvida nos cinco minutos que levou perguntar à Joana.

## Por que o XP raramente é usado inteiro

Poucos times adotam o XP inteiro. As práticas pedem muito de quem programa, e algumas, o par acima de todas, são
difíceis de vender para gerentes que contam pessoas por teclado. O que aconteceu em vez disso é que as práticas
do XP se espalharam por todo o resto: a maioria dos times Scrum usa integração contínua, testes de unidade
automatizados e alguma forma de teste de aceitação sem chamar nada disso de XP. Quem testa tem muito mais chance
de encontrar as práticas do XP do que um time que diga que faz XP.
