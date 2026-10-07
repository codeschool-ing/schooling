---
title: A lei de Little com números reais
version: 1
---

A aula 3 apresentou a **lei de Little** como o motivo pelo qual limitar o trabalho em progresso encurta o tempo de ciclo. Com os números de março do time Agenda dá para conferi-la, e a conferência diz algo útil sobre o quadro.

```localised
trabalho em progresso médio = vazão média × tempo de ciclo médio
```

## Os números

Nas quatro semanas de 2 a 29 de março — **28 dias** —, o time terminou **20 itens**, uma vazão de 20 / 28, ou cerca de **0,714 item por dia**. O tempo de ciclo médio desses itens foi **7,75 dias**. A lei de Little diz que o número médio de itens em andamento nesse período deveria ter sido cerca de:

```localised
0,714 item por dia × 7,75 dias = 5,54 itens
```

Na manhã de 16 de março, o quadro da aula 3 mostrava **seis** cartões entre o ponto de compromisso e Feito: três em Desenvolvendo, dois em Revisão e um em Teste. Cinco e meio em média, seis numa manhã específica: o quadro e a lei concordam.

## Para que serve a concordância

A lei vale para qualquer sistema estável: um em que o trabalho chega e sai mais ou menos no mesmo ritmo ao longo do período, e os itens não são abandonados no meio. Quando os números concordam, como aqui, o time pode usar a lei para raciocinar sobre mudanças antes de fazê-las:

- **Para encurtar o tempo de ciclo sem mudar a vazão, mantenha menos em andamento.** Se o time Agenda trabalhasse com quatro itens em andamento em vez de cinco ou seis, com a mesma vazão, o tempo de ciclo médio cairia para cerca de 4 / 0,714, ou 5,6 dias.
- **Começar mais trabalho não aumenta a vazão por si só.** Aumenta o trabalho em progresso, e com a mesma vazão a lei diz que o tempo de ciclo sobe junto.

Quando os números **não** concordam — o quadro mostra doze itens em andamento mas a lei prevê cinco —, a causa habitual são itens que estão no quadro mas não estão de fato sendo trabalhados: bloqueados, esquecidos, esperando uma decisão. A discordância é uma descoberta, e aponta os cartões a olhar.

## Os limites dela

A lei de Little trata de **médias ao longo de um período**. Ela não prevê o tempo de ciclo de nenhum item isolado, e não vale enquanto o sistema muda rápido — nas primeiras semanas depois de uma reorganização, ou quando um lote grande de trabalho chega de uma vez. O curso `delivery-metrics` abre com ela e trabalha esses casos; aqui basta saber que os três números estão ligados, e que o trabalho em progresso é o que o time controla diretamente.
