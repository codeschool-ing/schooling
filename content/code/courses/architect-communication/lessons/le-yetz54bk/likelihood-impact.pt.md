---
title: Probabilidade e impacto
version: 1
---

**Todo risco são dois números: a chance de acontecer num período e quanto custa quando acontece.**
Um risco descrito com só um deles não pode ser comparado com nada. "Pode derrubar o checkout" é um
impacto sem probabilidade; "acontece toda sexta" é uma probabilidade sem impacto. Quem decide
precisa dos dois, porque eles se multiplicam.

## Perda esperada

O produto dos dois é a **perda esperada**: quanto o risco custa em média, por período, se nada for
feito.

```localised
perda esperada por ano = vezes que acontece por ano × custo de cada vez
```

Um risco que acontece duas vezes por ano e custa R$ 50.000 a cada vez tem uma perda esperada de
R$ 100.000 por ano. Um que acontece cinquenta vezes por ano e custa R$ 2.000 a cada vez também. No
papel, têm o mesmo tamanho. Na prática, parecem diferentes, e essa diferença importa para a próxima
seção: o pequeno e frequente em geral já aparece nos números de alguém, enquanto o raro e grande
nunca aconteceu e é fácil de deixar de lado.

## Dois tipos de risco num mesmo problema

O problema do banco de dados nas sextas da Marola tem os dois tipos, e a primeira proposta de Lívia
misturou os dois:

- **Uma perda crônica, que está acontecendo agora.** Cerca de 180 checkouts falham toda sexta à
  noite. A probabilidade não é um palpite: são 52 sextas por ano, e os dados já existem.
- **Um risco de cauda, que ainda não aconteceu.** Numa sexta ruim o bastante, o banco fica sem
  conexões de vez, e o checkout para para todo mundo até alguém intervir. A probabilidade é um
  julgamento, e o impacto é muito maior.

Os dois pedem frases diferentes. A perda crônica é dita como medição, com a fonte. O risco de cauda
é dito como estimativa, com o raciocínio, e a última seção desta aula mostra como.

## A matriz de risco

A maioria das empresas desenha os riscos numa grade de probabilidade contra impacto, colorida do
verde ao vermelho. Ela serve para uma coisa: **pôr um risco técnico na mesma figura que os riscos de
negócio que o conselho já olha**, onde ele pode ser comparado em vez de discutido.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Uma grade de três por três: probabilidade em um ano, improvável, possível e certo, contra impacto, menor, moderado e grave. Três riscos da Marola estão nela: 180 checkouts com falha toda sexta é certo e moderado; o checkout parar para todo mundo é possível e grave; o atraso da réplica deixar rotas defasadas por alguns segundos é possível e menor.\"><defs><marker id=\"riskgrid-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"150\" y=\"20\" width=\"174\" height=\"74\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"330\" y=\"20\" width=\"174\" height=\"74\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"510\" y=\"20\" width=\"174\" height=\"74\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"150\" y=\"100\" width=\"174\" height=\"74\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"330\" y=\"100\" width=\"174\" height=\"74\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"510\" y=\"100\" width=\"174\" height=\"74\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"150\" y=\"180\" width=\"174\" height=\"74\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"330\" y=\"180\" width=\"174\" height=\"74\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"510\" y=\"180\" width=\"174\" height=\"74\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"237.0\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">improvável</text><text x=\"417.0\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">possível</text><text x=\"597.0\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">certo</text><text x=\"138\" y=\"57.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">grave</text><text x=\"138\" y=\"137.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">moderado</text><text x=\"138\" y=\"217.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">menor</text><text x=\"420\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">probabilidade em um ano →</text><text x=\"20\" y=\"294\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">impacto ↑</text><circle cx=\"527.0\" cy=\"137.0\" r=\"5\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"537.0\" y=\"129.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">180 checkouts com falha</text><text x=\"537.0\" y=\"145.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">toda sexta</text><circle cx=\"347.0\" cy=\"57.0\" r=\"5\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"357.0\" y=\"49.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o checkout para</text><text x=\"357.0\" y=\"65.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">para todo mundo</text><circle cx=\"347.0\" cy=\"217.0\" r=\"5\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"357.0\" y=\"209.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">atraso da réplica:</text><text x=\"357.0\" y=\"225.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">rotas defasadas</text></svg>", "caption": "A grade põe um risco técnico na mesma figura dos riscos de negócio que o conselho já lê. Ela mostra onde o risco fica; a conta diz o tamanho dele."}
```

Ela tem dois pontos fracos conhecidos, e quem a lê deveria conhecê-los. As faixas são grosseiras,
então dois riscos com perdas esperadas cem vezes diferentes podem cair no mesmo quadrado. E os
rótulos ("possível", "grave") significam coisas diferentes para pessoas diferentes. **Use a grade
para mostrar onde um risco está, e os números por trás dela para dizer o tamanho dele.** Um
quadrado sozinho provoca a pergunta "por que está vermelho?", e a resposta é a conta da próxima
seção.

## Impacto é mais do que dinheiro

Alguns impactos não se convertem bem em reais, e fingir que se convertem enfraquece o argumento:

- **A confiança de um cliente.** O contrato da Boa Praça renova em setembro. Ninguém consegue pôr
  preço em "a diretora de operações da rede teve de explicar ao próprio conselho uma sexta de
  entregas atrasadas", mas isso entra na lista.
- **Pessoas.** Um engenheiro acionado três sextas seguidas é um risco de pedido de demissão.
- **Regulação e dados.** Um incidente que expõe dados de clientes tem um custo definido pela lei e
  pelo noticiário, não pelo tamanho da cesta.

Diga esses impactos em palavras, ao lado dos números, sem convertê-los em números inventados. **Um
valor preciso para um impacto que não tem preço é a falsa precisão da aula 1**, e um diretor que
pega um número inventado vai duvidar dos números reais ao lado dele.
