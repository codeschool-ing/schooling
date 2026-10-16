---
title: Comportamento, não testes
version: 1
---

**O desenvolvimento guiado por comportamento, BDD, nasceu do TDD quando as pessoas perceberam que a palavra
*teste* estava atrapalhando.** Dan North ensinava TDD no começo dos anos 2000 e esbarrava sempre nas mesmas
perguntas: por onde começar, o que testar, como chamar um teste, quanto testar de uma vez. Num artigo chamado
*Introducing BDD*, em 2006, ele propôs responder a todas falando de **comportamento**: o que o software deve fazer,
nesta situação, para esta pessoa?

Essa troca de palavra fez mais do que parece. "Escreva um teste para a função de cupom" é uma frase sobre a qual só
quem desenvolve consegue agir. "Descreva como um cupom deve se comportar" é uma frase que a Joana consegue
responder, e a Célia consegue corrigir. O BDD é o conjunto de hábitos que cresceu em volta disso: descrever o
comportamento em **exemplos**, numa **linguagem que o time todo divide**, antes de o código ser escrito.

## Três práticas, em ordem

Quem escreve sobre BDD costuma dividi-lo em três práticas, e a ordem importa.

| prática | o que acontece | quem |
|---|---|---|
| **descoberta** | o time percorre uma história com exemplos concretos, até a regra estar entendida e as perguntas em aberto conhecidas | dona do produto, quem desenvolve e quem testa, juntos |
| **formulação** | os exemplos que importam são escritos numa forma estruturada e legível | em geral quem testa ou quem desenvolve, relidos pela dona do produto |
| **automação** | os exemplos escritos são ligados ao código, para rodarem como verificações | quem desenvolve, muitas vezes com quem testa |

A maior parte do valor está na primeira. Um time que só automatiza tem uma ferramenta de teste com uma sintaxe
diferente. Um time que só descobre tem conversas melhores e nada para mostrar delas depois. A formulação é a ponte:
o exemplo escrito é o registro da conversa, e a automação o mantém honesto.

## Uma linguagem compartilhada

North tomou emprestada uma ideia do *Domain-Driven Design* de Eric Evans: a **linguagem ubíqua**, as palavras que
um negócio usa para as próprias coisas, usadas em todo lugar, na conversa, nos documentos e no código. No Cine
Aurora isso quer dizer *sessão*, *matinê*, *meia-entrada*, *pedido*, *cupom*. Não *transação*, não *flag de
desconto*, não *faixa de preço 2*.

Parece questão de gosto e é questão de defeitos. Na aula 8, o programa de pedidos chamava os pedidos recusados de
*pedidos* também, porque ninguém tinha perguntado o que era um pedido. Um time que tivesse combinado que pedido é
algo que um cliente pagou teria visto na hora que um pedido recusado não é um.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 200\" role=\"img\" data-fig=\"l16-three\" aria-label=\"Três práticas do BDD em ordem, da esquerda para a direita. Descoberta: conversar sobre exemplos; Joana, Rafael e Lia; produz perguntas respondidas, e a maior parte do valor. Formulação: escrever os que importam; Lia, relido pela Joana; produz um arquivo de feature. Automação: ligá-los ao código; Rafael, com a Lia; produz cenários que rodam todo dia.\"><defs><marker id=\"qa-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10.0\" y=\"20.0\" width=\"190.0\" height=\"76.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"105.0\" y=\"44.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">descoberta</text><text x=\"105.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">conversar sobre exemplos</text><text x=\"105.0\" y=\"71.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Joana, Rafael, Lia</text><path d=\"M202.0 58.0 L228.0 58.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><path d=\"M105.0 98.0 L105.0 122.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"20.0\" y=\"124.0\" width=\"170.0\" height=\"32.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">perguntas respondidas</text><rect x=\"230.0\" y=\"20.0\" width=\"190.0\" height=\"76.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"325.0\" y=\"44.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">formulação</text><text x=\"325.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">escrever os que importam</text><text x=\"325.0\" y=\"71.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Lia, relido pela Joana</text><path d=\"M422.0 58.0 L448.0 58.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><path d=\"M325.0 98.0 L325.0 122.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"240.0\" y=\"124.0\" width=\"170.0\" height=\"32.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"325.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">um arquivo de feature</text><rect x=\"450.0\" y=\"20.0\" width=\"190.0\" height=\"76.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"545.0\" y=\"44.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">automação</text><text x=\"545.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ligá-los ao código</text><text x=\"545.0\" y=\"71.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Rafael, com a Lia</text><path d=\"M545.0 98.0 L545.0 122.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"460.0\" y=\"124.0\" width=\"170.0\" height=\"32.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"545.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">cenários que rodam todo dia</text><text x=\"105.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">a maior parte do valor</text></svg>", "caption": "Descoberta, formulação, automação. Um time que só automatiza tem uma ferramenta de teste com uma sintaxe diferente.", "same": ["Joana, Rafael, Lia"]}
```

## O que quem testa traz

O BDD precisa dos hábitos de quem testa sobretudo na descoberta, que é exatamente onde os critérios de aceitação da
aula 12 e as perguntas da aula 2 já os colocavam: a borda, a combinação, a entrada que ninguém mencionou, o que
acontece depois. A diferença que o BDD faz é o destino. Essas perguntas e respostas não terminam nas anotações de
uma reunião. Terminam como cenários num arquivo, na linguagem do time, rodando contra o código todo dia.
