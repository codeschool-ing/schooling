---
title: Amostras sistemáticas e por conglomerados
version: 1
---

Mais dois métodos aparecem na prática, cada um com uma força e uma armadilha.

## Amostragem sistemática

Uma **amostra sistemática** pega um a cada *k* membros de uma lista, depois de um começo sorteado. Para
amostrar 40 de 400 pedidos, sorteie um começo entre 1 e 10 e pegue um a cada 10 a partir dali: o 7º, o 17º,
o 27º e assim por diante.

É fácil de executar — alguém com uma lista impressa consegue — e na maioria das listas se comporta como uma
amostra aleatória simples.

**A armadilha é uma lista com ritmo.** Se os registros diários da Horta forem amostrados a cada 7 dias, todo
dia escolhido é o mesmo dia da semana. Comece numa segunda-feira e a amostra é só de segundas, e segundas
não são dias típicos para uma mercearia. Sempre que a lista tem um ciclo — dias da semana, turnos, a ordem
em que uma máquina enche sacos por dois bicos —, um passo que coincide com o ciclo produz uma amostra muito
viesada e de aparência perfeitamente organizada.

## Amostragem por conglomerados

Uma **amostra por conglomerados** sorteia grupos inteiros e depois pega membros só dos grupos sorteados. Para
pesquisar clientes pessoalmente, a Horta poderia sortear alguns bairros e visitar clientes só ali. Os custos
de deslocamento caem muito.

O preço é a variabilidade. Conglomerados costumam ser parecidos por dentro — vizinhos se parecem —, então
poucos conglomerados carregam menos informação que o mesmo número de membros espalhados pela população. Nas
120 entregas, pegar 20 de um bairro sorteado dá médias amostrais com desvio padrão de **9,22 minutos**,
contra 2,20 de uma amostra aleatória simples de 20 e 1,04 de uma estratificada.

## Estratos contra conglomerados

Os dois se parecem, já que ambos dividem a população em grupos, e funcionam de jeitos opostos.

| | estratificada | por conglomerados |
|---|---|---|
| grupos usados | todos | alguns, sorteados |
| membros tirados | alguns de cada grupo | só dos grupos sorteados |
| melhor quando os grupos são | parecidos por dentro, diferentes entre si | cada um uma cópia pequena da população |
| efeito na precisão | melhor que a aleatória simples | quase sempre pior, mas mais barata |

Grandes pesquisas nacionais costumam combinar os dois: conglomerados de áreas primeiro, estratos dentro
deles e sorteio no último passo.
