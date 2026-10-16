---
title: Lotes menores, de verdade ou para o gráfico
version: 1
---

A pesquisa DORA diz que lotes pequenos são bons, e o agosto do time de Billing diz a mesma coisa com números. Isso faz de "lotes menores" o disfarce mais convincente que um truque pode vestir, porque a melhora real e a falsa produzem a mesma manchete: **mais deploys, taxa de falha menor**.

## Dois times, uma manchete

O time de Billing, em agosto, deixou os lotes menores **mudando o jeito como o trabalho fluía**. Menos itens abertos fizeram cada item terminar antes, então as integrações de cada dia ficaram menos numerosas, então cada deploy levou menos mudanças. O lote ficou menor porque o trabalho ficou menor e mais rápido.

A versão "um por mudança" da seção anterior deixou os lotes menores **mudando o jeito como os deploys eram contados**. Trinta e oito execuções do pipeline viraram setenta e dois deploys. O lote ficou menor no papel e continuou exatamente do mesmo tamanho no fio.

## Os quatro testes

Coloque os dois lado a lado e quatro perguntas os distinguem, cada uma respondível a partir dos dados.

| pergunta | agosto, de verdade | um por mudança, para o gráfico |
|---|---|---|
| **o lead time de mudanças caiu?** | de cerca de 50 horas para 4,5 | não: 4,5 antes e depois |
| **o tempo para restaurar caiu?** | de cerca de 166 minutos para 52 | não: 52 antes e depois |
| **o número de execuções do pipeline cresceu?** | de 9 para 38 | não: 38 execuções, contadas como 72 |
| **algo mudou antes, no fluxo?** | o trabalho em andamento caiu para um quarto | nada |

**Uma redução real de lote move as métricas medidas nas mudanças e nas falhas, não só as medidas nos deploys.** Uma mudança espera menos pelo seu deploy, porque os deploys são frequentes; uma falha é mais rápida de desfazer, porque há menos coisa nela para desembaraçar. Um truque de contagem não consegue fingir isso, e é por isso que a aula 5 insistiu em ler as quatro juntas.

## Um lote pequeno que é real e ainda assim inútil

Há um terceiro caso, e ele não é um truque. Um time pode fazer deploy de cada mudança separadamente, de verdade, com uma execução do pipeline para cada uma, e ganhar pouco, porque suas mudanças já eram pequenas e o problema estava em outro lugar: uma fila de revisão, um backlog, uma suíte de testes lenta. Os números melhoram honestamente e o solicitante espera tanto quanto antes. Esse é o ponto da aula 6 sobre sintomas, visto pelo outro lado: **uma melhora real numa métrica não é o mesmo que uma melhora naquilo para que a métrica servia**. Confira o relógio que o cliente lê, o lead time da aula 2, antes de comemorar qualquer uma das quatro.
