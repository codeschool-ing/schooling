---
title: Para que serve uma linha de base
version: 1
---

**Uma nota sozinha não diz nada.** "O modelo tem 94% de acurácia" soa como resultado, e a aula 1 já
mostrou que um modelo que nunca prevê um cancelamento tira exatamente isso nestes dados. Um número só
vira resultado ao lado do número que algo mais simples teria tirado, nas mesmas linhas, medido do
mesmo jeito. Essa coisa mais simples é a **linha de base**, e ela é construída antes do modelo, não
depois.

A ordem importa. Uma linha de base feita depois do modelo é feita por alguém que já sabe para quem
ela tem de perder, e é escolhida, sem ninguém querer, para perder. Feita antes, ela é uma pergunta
de boa-fé: **até onde o óbvio chega?**

## Três tipos de linha de base, em esforço crescente

| linha de base | o que é | o que superá-la prova |
|---|---|---|
| **uma constante** | a mesma resposta para toda linha: a classe mais comum, ou a média | que o modelo usa as variáveis |
| **uma regra prática** | uma condição que uma pessoa escreveria: *pulou três caixas, manda o crédito* | que o modelo acha algo que a frase de um especialista não acha |
| **a prática atual** | o que a empresa faz hoje, mesmo que seja uma planilha e um palpite | que mudar alguma coisa vale o trabalho |

A Feira em Casa não tem prática atual, porque o crédito é novo. Então a barra são os outros dois:
**a constante**, que aqui quer dizer *não mandar a ninguém* e vale exatamente R$ 0, e **a melhor
regra que uma pessoa conseguiria escrever** com as mesmas colunas que o modelo lê.

## Por que uma linha de base é um modelo como qualquer outro

Uma regra precisa ser escolhida, e escolher é aprender. Se a Ana testa cinco regras e fica com a que
foi melhor nos meses em que depois vai testar, a regra viu o teste, e a nota dela fica inflada do
mesmo jeito que a de um modelo sobreajustado. **Então a linha de base obedece a toda regra que um
modelo obedece**: é escolhida nos meses de que pode aprender e medida em meses que nunca viu. Esta
aula faz exatamente isso, e a regra escolhida acaba não valendo nada nos meses que não viu, que é a
coisa mais útil que uma linha de base pode ensinar.

## O que "superá-la" tem de querer dizer

Um modelo que fica um pouco acima da regra num conjunto de teste pode ter tido sorte com os
assinantes que caíram nele. A seção 07 desta aula mede essa sorte reamostrando, com a inferência que
o `statistics` ensinou, e a resposta decide se a diferença é um achado ou uma coincidência.
