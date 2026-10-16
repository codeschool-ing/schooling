---
title: Duzentas partições
version: 1
---

**O `spark.sql.shuffle.partitions` define quantas partições todo shuffle produz, e o padrão, 200,
quase nunca serve exatamente a um job.** É um número só para todo shuffle de toda consulta da
aplicação, decidido antes de se ver qualquer dado.

Antes da execução adaptativa, esse número era trabalho de ajuste. Poucas demais, e cada tarefa de
reduce fica grande para a memória e despeja em disco, ou falha; demais, e o job vira milhares de
tarefas lendo nada, cada uma pagando o custo fixo por tarefa, e uma escrita produz milhares de
arquivos pequenos. O conselho de costume era dimensioná-lo pelo maior shuffle do job, o que o deixava
errado para todos os outros.

O agrupamento por visitante da seção 02, com e sem execução adaptativa:

| | tarefas de reduce | shuffle lido |
|---|---|---|
| execução adaptativa ligada | 3 | 34,6 MiB |
| execução adaptativa desligada | 200 | 34,6 MiB |

**Os mesmos dados, lidos por 3 tarefas de uns 12 MiB cada ou por 200 tarefas de 0,2 MiB cada.** Com a
execução adaptativa ligada, o Spark olha o tamanho real do shuffle quando o lado do map termina e
junta partições até cada uma ter cerca de `spark.sql.adaptive.advisoryPartitionSizeInBytes`, 64 MB
por padrão, mantendo por padrão pelo menos uma partição por núcleo. A segunda linha vem do último
agrupamento do `jobs_stages.py`, que desliga a execução adaptativa de propósito.

Então a configuração virou um teto em vez de um palpite: **ajuste-a alto o bastante para o maior
shuffle que você espera, e deixe a execução adaptativa juntar para baixo.** O que a execução
adaptativa não consegue é dividir uma partição grande demais porque uma chave é grande demais. Isso é
a aula 8.
