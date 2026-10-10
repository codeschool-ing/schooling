---
title: De visitantes a uma data
version: 1
---

Um tamanho de amostra vira uma duração pelo tráfego, e uma duração vira um plano de teste pelo
calendário.

```schooling-example
{"language": "python", "file": "duration.py", "parts": [{"code": "from math import ceil\n\nper_group = 18739\nvisitors_per_day = 2400\nshare_in_test = 1.0", "note": "O número de livro de duas seções atrás, e o tráfego do checkout da Panela. O `share_in_test` é a fração desse tráfego mandada para o experimento."}, {"code": "days = ceil(2 * per_group / (visitors_per_day * share_in_test))\nweeks = ceil(days / 7)\nprint(f\"{2 * per_group:,} visitors in total at {visitors_per_day:,} a day: {days} days\")\nprint(f\"rounded up to whole weeks: {weeks} weeks, {weeks * 7} days\")", "note": "Dois grupos de visitantes, divididos pelo tráfego diário, depois arredondados para semanas inteiras."}, {"code": "for share in (0.5, 0.2):\n    days = ceil(2 * per_group / (visitors_per_day * share))\n    print(f\"with only {share:.0%} of the traffic in the test: {days} days, {ceil(days / 7)} weeks\")", "note": "O mesmo teste com parte do tráfego, como quando vários testes dividem um site."}], "output": "37,478 visitors in total at 2,400 a day: 16 days\nrounded up to whole weeks: 3 weeks, 21 days\nwith only 50% of the traffic in the test: 32 days, 5 weeks\nwith only 20% of the traffic in the test: 79 days, 12 weeks"}
```

**16 dias de tráfego, e o teste roda por 3 semanas.** O arredondamento não é capricho. A aula 1
mostrou que as segundas da Panela têm cerca de um terço a mais de pedidos que os sábados, e os
visitantes de dias diferentes podem converter diferente também. Um teste que rodasse de uma segunda
até a terça da semana seguinte teria duas segundas e um de cada outro dia, e o resultado penderia
para o que fazem os visitantes de segunda. **Semanas inteiras dão o mesmo peso a cada dia da
semana.** Vinte e um dias é exatamente a duração do teste da Panela no `experiment.csv`, que a aula
10 lê.

Mais duas regras definem as bordas do calendário.

- **Pelo menos uma semana inteira, mesmo quando a conta diz menos.** Um teste que atinge a amostra
  em três dias viu três dias da semana e nenhum fim de semana.
- **Não muito mais longo que o necessário.** Testes longos acumulam problemas: visitantes apagam os
  cookies e voltam como novos, outras mudanças entram nas mesmas páginas, e chega um feriado.
  Planejar em volta do Carnaval ou da Black Friday, ou de propósito não, faz parte de escolher a data
  de início.

## Dividir o tráfego

Mandar só parte do tráfego para um teste o deixa mais lento na mesma proporção: metade do tráfego,
cerca do dobro do tempo, 32 dias aqui; um quinto, 79 dias. Times fazem isso para limitar o risco de
um tratamento ruim ou para rodar vários testes ao mesmo tempo. Quando o resultado fica lento demais
para ser útil, as alavancas são as da seção anterior: uma mudança maior, uma métrica mais sensível,
ou um teste só com os visitantes que a mudança pode afetar, como só os que chegam ao checkout.
