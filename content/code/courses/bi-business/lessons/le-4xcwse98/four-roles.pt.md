---
title: Quatro papéis, nomeados pelo que entregam
version: 1
---

De fora, todo mundo que trabalha com dados parece uma profissão só com quatro cargos, e os cargos
parecem uma escada: analista embaixo, cientista de dados no topo. **As duas imagens estão erradas.** Os
quatro papéis fazem trabalhos diferentes, respondem a perguntas diferentes e falham de jeitos
diferentes, e uma empresa que contrata o papel errado para o seu problema leva um ano para perceber.
O jeito mais claro de distingui-los é pelo que cada um entrega a outra pessoa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 420\" role=\"img\" aria-label=\"Um caminho da esquerda para a direita. À esquerda, os registros da empresa: os caixas das lojas, a loja online, o depósito. Uma seta para o engenheiro de dados, que entrega dados que chegam certos e no prazo, num banco de dados. Do banco saem três setas para três papéis empilhados à direita: o analista de BI, que entrega as respostas recorrentes e as definições por trás delas; o analista de dados, que entrega a resposta a uma pergunta nova; o cientista de dados, que entrega um modelo que prevê ou decide. As três terminam nas decisões.\" data-fig=\"l03-roles\"><rect x=\"16.0\" y=\"120.0\" width=\"120.0\" height=\"170.0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"76.0\" y=\"145.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">os registros</text><text x=\"76.0\" y=\"180.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">caixas das lojas</text><text x=\"76.0\" y=\"206.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">loja online</text><text x=\"76.0\" y=\"232.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">depósito</text><text x=\"76.0\" y=\"258.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">folha</text><path d=\"M138.0 205.0 L166.0 205.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M166.0 205.0 L157.9 208.9 L157.9 201.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><rect x=\"168.0\" y=\"150.0\" width=\"160.0\" height=\"110.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"248.0\" y=\"178.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">engenheiro de dados</text><text x=\"248.0\" y=\"202.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">dados que chegam</text><text x=\"248.0\" y=\"218.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">certos e no prazo</text><text x=\"248.0\" y=\"244.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">Tiago</text><rect x=\"370.0\" y=\"40.0\" width=\"220.0\" height=\"100.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"480.0\" y=\"67.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">analista de BI</text><text x=\"480.0\" y=\"91.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a mesma resposta, toda semana,</text><text x=\"480.0\" y=\"107.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">e a definição escrita dela</text><text x=\"480.0\" y=\"129.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">Lívia</text><path d=\"M330.0 205.0 L368.0 90.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M368.0 90.0 L369.2 98.9 L361.7 96.5 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M592.0 90.0 L640.0 205.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M640.0 205.0 L633.3 199.0 L640.5 196.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><rect x=\"370.0\" y=\"160.0\" width=\"220.0\" height=\"100.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"480.0\" y=\"187.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">analista de dados</text><text x=\"480.0\" y=\"211.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a resposta a uma pergunta nova,</text><text x=\"480.0\" y=\"227.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">uma vez, e talvez de novo</text><text x=\"480.0\" y=\"249.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">Lívia, de novo</text><path d=\"M330.0 205.0 L368.0 210.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M368.0 210.0 L359.5 212.8 L360.5 205.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M592.0 210.0 L640.0 205.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M640.0 205.0 L632.3 209.7 L631.5 201.9 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><rect x=\"370.0\" y=\"280.0\" width=\"220.0\" height=\"100.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"480.0\" y=\"307.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">cientista de dados</text><text x=\"480.0\" y=\"331.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um modelo que prevê</text><text x=\"480.0\" y=\"347.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ou decide sozinho</text><text x=\"480.0\" y=\"369.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">ninguém, ainda</text><path d=\"M330.0 205.0 L368.0 330.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M368.0 330.0 L361.9 323.4 L369.4 321.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M592.0 330.0 L640.0 205.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M640.0 205.0 L640.7 214.0 L633.4 211.2 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><rect x=\"642.0\" y=\"160.0\" width=\"70.0\" height=\"90.0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"677.0\" y=\"200.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">as</text><text x=\"677.0\" y=\"218.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">decisões</text><text x=\"360.0\" y=\"408.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">o nome em cada caixa: quem faz esse trabalho na Varanda em 2026</text></svg>", "caption": "Quatro papéis entre os registros e as decisões, cada um nomeado pelo que entrega. Na Varanda, um engenheiro de meio período e uma analista cobrem três deles.", "same": ["Lívia", "Tiago"]}
```

## O engenheiro de dados: dados que chegam, certos e no prazo

Os registros de uma empresa vivem nos sistemas que a fazem funcionar: os caixas das lojas, a loja
online, o depósito, a folha de pagamento. Nenhum deles foi feito para análise, e nenhum conversa com
os outros. **O engenheiro de dados constrói e mantém os pipelines que copiam esses registros para um
lugar só, onde podem ser consultados, toda noite ou toda hora, e percebe quando uma cópia falha.** Na
Varanda, esse é Tiago Ramos, prestador de serviço em meio período, e o lugar é um banco de dados que
tem as vendas, o estoque e as entregas de ontem às seis da manhã.

A pergunta que o engenheiro responde não é sobre o negócio. É "os dados chegaram, estão completos,
são iguais à origem?". Quando a resposta é sim ninguém repara, e por isso o papel é fácil de
subestimar. O curso `data-fundamentals` é sobre esse trabalho.

## O analista de BI: a resposta recorrente, sempre do mesmo jeito

**O analista de BI responde às perguntas que a empresa faz o tempo todo — vendas por loja, entrega no
prazo, estoque por categoria — e garante que sejam respondidas do mesmo jeito toda vez.** O que ele
entrega é um relatório, um painel ou um e-mail, e por trás disso algo menos visível e mais
importante: a definição escrita de cada número, para que dois diretores levem o mesmo total à mesma
reunião. Lívia foi contratada para isso, e a aula 1 foi sobre por que a Varanda precisava disso.

## O analista de dados: a pergunta nova

Algumas perguntas são feitas uma vez só. Por que outubro caiu? Clientes que compram primeiro móveis
de jardim voltam mais que os que compram primeiro utensílios de cozinha? **O analista de dados pega
uma pergunta que ninguém respondeu antes, explora os dados e entrega uma resposta com as evidências e
as dúvidas dela.** O trabalho é menos repetível e mais aberto: no começo, o analista não sabe que
tabelas ou que comparação vão importar. Quando uma resposta passa a ser necessária todo mês, ela vai
para o lado do BI e ganha uma definição.

## O cientista de dados: um modelo que prevê ou decide

**O cientista de dados constrói modelos: algo que recebe dados sobre um caso que nunca viu e prevê um
resultado, ou toma uma decisão sozinho.** Que cliente vai parar de comprar, quantas mangueiras de
jardim a loja de Contagem vai vender semana que vem, que transações parecem fraude. A entrega é um
modelo e a evidência de que ele supera uma regra simples, e o trabalho pede mais estatística e mais
programação que os outros três. A Varanda não tem cientista de dados, e nos primeiros meses de BI
ainda não precisa de um. A aula 8 mostra até onde vai uma previsão simples antes de um modelo valer o
que custa.

## Não é uma escada

Um cientista de dados não é um analista sênior. Um bom analista de BI com dez anos de experiência é
sênior em BI, e pode nunca construir um modelo nem precisar. **Os papéis diferem em natureza, não em
hierarquia.** O que os separa é a pergunta a que cada um serve:

| papel | a pergunta que responde | o que entrega |
|---|---|---|
| engenheiro de dados | os dados chegaram, completos e no prazo? | pipelines e um banco de dados confiável |
| analista de BI | o que aconteceu, medido do mesmo jeito que da última vez? | relatórios e painéis recorrentes, e as definições por trás deles |
| analista de dados | o que está acontecendo com esta pergunta nova? | uma análise, uma vez, com evidências e dúvidas |
| cientista de dados | o que vai acontecer neste caso, ou o que deve ser feito? | um modelo, e a prova de que ele supera uma regra simples |
