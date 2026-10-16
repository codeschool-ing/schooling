---
title: Três tipos de aprendizado
version: 1
---

**O aprendizado de máquina escreve um programa a partir de exemplos em vez de regras.** Um alerta de
churn por regra diz "marque um cliente em silêncio há 42 dias", uma regra que alguém escreveu na aula
13. Um alerta aprendido recebe milhares de clientes passados, cada um com o que se sabia sobre ele e
se depois saiu, e descobre a própria regra. O que diferencia os três tipos de aprendizado é o que os
exemplos contêm.

| tipo | os exemplos contêm | ele aprende | uma pergunta da Panela |
|---|---|---|---|
| **supervisionado** | entradas e a resposta certa | a prever a resposta para entradas novas | que clientes vão parar de pedir no próximo trimestre? |
| **não supervisionado** | só entradas | estrutura: grupos, pontos incomuns, descrições mais simples | que clientes se comportam parecido? (aula 15) |
| **por reforço** | os resultados das próprias ações | que ação rende mais recompensa | que página o próximo visitante deve ver? |

**O aprendizado supervisionado** se divide pelo tipo de resposta. Uma categoria, como "vai sair" ou
"vai ficar", é **classificação**; um número, como o gasto do próximo trimestre, é **regressão**. A
aula 17 faz um de cada.

**O aprendizado não supervisionado** não tem resposta certa de que aprender, o que é ao mesmo tempo a
força e a dificuldade dele: pode achar o que ninguém procurava, e nada no dado diz se o que achou é
útil. O agrupamento da aula 15 precisou de uma pessoa para nomear os grupos e decidir que quatro
valiam a pena.

**O aprendizado por reforço** aprende agindo e vendo o que acontece. Os exemplos dele são produzidos
pelas próprias escolhas, então o que ele aprende depende do que escolheu experimentar. A última seção
desta aula mostra a versão útil mais simples dele.

## Onde este curso para

::: track data-science
Na sua trilha o `machine-learning` veio logo antes deste curso e cobre tudo isso a fundo: algoritmos,
avaliação, ajuste. Estas quatro aulas são uma revisão pelo lado do BI. O que elas acrescentam é a
pergunta de negócio que cada técnica responde, e nas aulas 18 e 19 o que pode dar errado quando a saída
de um modelo decide algo sobre pessoas. Passe rápido pelo que você já sabe e gaste o seu tempo nas
partes que usam os dados da Panela.
:::

::: track bi
Na sua trilha não há curso de aprendizado de máquina, então estas quatro aulas são onde você o
encontra. Elas miram o que uma analista de BI precisa: saber que tipo de pergunta um modelo responde,
ler os resultados de um modelo sem se enganar e reconhecer quando um modelo trata algumas pessoas de
forma injusta. Construir e ajustar modelos é trabalho de especialista, e o vocabulário daqui é o que
permite trabalhar com um.
:::

::: track *
Estas quatro aulas são um panorama pelo lado do BI: que tipo de pergunta cada técnica responde, como
ler os resultados de um modelo sem se enganar, e quando as decisões de um modelo são injustas. O curso
`machine-learning` cobre os algoritmos a fundo.
:::
