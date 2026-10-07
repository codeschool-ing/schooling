---
title: Por que limitar o trabalho em progresso funciona
version: 1
---

Um limite de trabalho em progresso parece uma restrição a quanto um time consegue fazer. É uma restrição a quanto um time consegue **começar**, e a diferença é o argumento inteiro.

## As filas são para onde o tempo vai

Acompanhe um item por um quadro sem limites. Ele passa um dia em desenvolvimento, espera três dias por alguém que o revise, um dia em revisão, e espera dois dias por um testador. De sete dias de tempo de ciclo, dois foram trabalho e cinco foram espera. Essa proporção é comum, e é invisível de dentro, porque todo mundo no time estava ocupado a semana inteira — ocupado com outros itens.

Limitar o trabalho em progresso ataca a espera. Se Revisão comporta só dois itens, um desenvolvedor não pode largar um terceiro na frente dela e começar outra coisa; a fila diante da Revisão fica curta, e os itens a atravessam mais rápido.

## A lei que liga os números

Há também uma razão aritmética. Para um sistema estável, a **lei de Little** diz:

```localised
trabalho em progresso médio = vazão média × tempo de ciclo médio
```

Leia ao contrário: o tempo de ciclo médio é o trabalho em progresso dividido pela vazão. Se um time termina cinco itens por semana, faça o que fizer, então manter dez itens em andamento quer dizer que cada um leva umas duas semanas, e manter cinco quer dizer uma. **Começar mais trabalho não faz nada terminar antes**; com a mesma vazão, só faz cada item demorar mais. A aula 13 volta à lei com os números do time Agenda, e o curso `delivery-metrics` dedica a primeira aula a ela.

## Fazer várias coisas custa mais do que parece

Um desenvolvedor com quatro itens abertos não trabalha nos quatro ao mesmo tempo; ele alterna entre eles, e cada troca custa tempo gasto lembrando onde estava. A estimativa de Gerald Weinberg, em *Quality Software Management* (1992), foi que cada projeto a mais que uma pessoa equilibra consome uma parte considerável do tempo dela só em trocas. Os percentuais exatos são estimativa e não medição, mas a direção é o que todo desenvolvedor reconhece: **duas coisas terminadas uma depois da outra costumam chegar antes de duas feitas em paralelo**.

## Definindo o limite

Não existe número correto para começar. Um ponto de partida comum é o número de pessoas que trabalham numa coluna, ou um pouco mais, e depois ajustar: um limite que nunca é atingido não limita nada, e um limite que deixa pessoas paradas por dias está apertado demais. O sentido de definir um é a conversa que ele força no dia em que é atingido — *por que a Revisão está cheia, e quem pode ajudar?* —, que é exatamente a conversa que um time sem limites nunca tem.
