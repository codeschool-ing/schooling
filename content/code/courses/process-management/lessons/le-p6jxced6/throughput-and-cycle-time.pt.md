---
title: Vazão e tempo de ciclo, como par
version: 1
---

A aula 3 calculou dois números a partir do quadro do time Agenda: a **vazão**, o número de itens terminados por semana, e o **tempo de ciclo**, quanto cada item levou do ponto de compromisso até feito. Eles são a base da medição de fluxo, e são mais úteis lidos juntos.

## O que cada um diz

A vazão responde **quanto**. O time Agenda terminou 4, 6, 5 e 5 itens nas quatro semanas de março, uns cinco por semana. É o número para prever quando a pergunta é *quantos destes trinta itens estarão prontos até junho?*

O tempo de ciclo responde **quanto tempo para um**. A mediana foi 7 dias e o percentil 85, 11,6. É o número a dar quando a pergunta é *quando este item fica pronto, agora que começamos?*

## Por que ler os dois juntos

Qualquer um dos dois sozinho pode ser melhorado de um jeito que esconde um problema.

**A vazão pode subir enquanto as coisas pioram.** Quebre todo item em três e a vazão triplica, com o mesmo trabalho entregue. Contando só quantos itens terminam, um time pode parecer mais rápido cortando itens menores sem terminar nada antes.

**O tempo de ciclo pode cair enquanto as coisas pioram.** Pare de começar itens difíceis, e os que começam terminam rápido; o trabalho difícil espera na fila de entrada, fora do relógio. O tempo de ciclo parece excelente enquanto o estoque de itens difíceis cresce.

Lidos juntos, os truques aparecem. Mais itens terminando com o mesmo tempo de ciclo é mais trabalho feito; os mesmos itens terminando mais rápido é uma espera menor para cada um. Um time que muda um sem o outro em geral mudou o jeito de contar.

## O gráfico de dispersão, e os itens envelhecendo

A figura isolada mais útil do fluxo é a que a aula 3 desenhou: um ponto por item terminado, na data em que terminou e nos dias que levou, com a linha do percentil 85 atravessando. Dois hábitos a transformam numa ferramenta de gestão:

- **Olhe os pontos acima da linha** em toda revisão. Cada um é um item que esperou em algum lugar, e perguntar onde é mais barato que qualquer mudança de processo.
- **Observe os itens ainda em andamento** contra a mesma linha. Um item que está em Desenvolvendo há dez dias, num time cujo percentil 85 é 11,6, está para virar um dos pontos acima da linha. A medida do Kanban para isso, a **idade do item**, é a única das quatro que avisa antes de o item atrasar e não depois. O curso `delivery-metrics` lhe dedica uma aula própria, a terceira.
