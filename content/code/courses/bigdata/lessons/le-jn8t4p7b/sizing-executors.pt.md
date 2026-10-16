---
title: Dimensionando executores
version: 1
---

**A memória de um executor é dividida pelas tarefas que ele roda ao mesmo tempo, uma por core.** A aula
7 mediu o que acontece quando a parte de uma tarefa é pequena demais: ela despeja em disco, e o seu
tempo sobe. As correções dela, em ordem, eram mais partições, menos colunas e mais memória por tarefa,
e a última tem um preço.

Há dois jeitos de dar mais memória a cada tarefa, e eles custam quantias diferentes. Pegue uma máquina
de 4 cores e 16 GB, com cerca de 12 GB utilizáveis pelo Spark depois do sistema operacional e das
sobrecargas:

| organização do executor | tarefas ao mesmo tempo | memória por tarefa | máquinas para 40 tarefas ao mesmo tempo | a US$ 0,20 por hora |
|---|---|---|---|---|
| 4 cores, 12 GB | 4 | 3 GB | 10 | US$ 2,00 por hora |
| 2 cores, 12 GB | 2 | 6 GB | 20 | US$ 4,00 por hora |
| 4 cores, 24 GB, numa máquina otimizada para memória a um suposto US$ 0,26 | 4 | 6 GB | 10 | US$ 2,60 por hora |

**Reduzir os cores à metade dobra a memória por tarefa e dobra a conta**, porque o mesmo trabalho
agora precisa do dobro de máquinas. Um tipo de máquina com mais memória por core dá a mesma memória por
tarefa por menos; os provedores de nuvem vendem esses tipos com um acréscimo que costuma ficar bem
abaixo do dobro, e os 30% supostos aqui são dessa ordem. O jeito mais barato de todos ainda é a primeira
correção: **mais partições não custam nada** além de algum agendamento, e uma tarefa com metade das
linhas precisa de metade da memória.

**O que medir antes de redimensionar qualquer coisa**: a coluna `spill` dos estágios, como o
`history.py` a imprime, e o tempo de tarefa ao lado. Sem spill, mais memória não compra nada. Spill em
uma tarefa de duzentas é o desbalanceamento da aula 8, e memória para toda tarefa é o jeito mais caro
de pagar por uma. Spill em toda parte, com as partições já certas, é o caso para mais memória por
tarefa, e a tabela acima é como escolher o seu preço.
