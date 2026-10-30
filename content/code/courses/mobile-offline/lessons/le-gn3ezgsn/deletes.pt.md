---
title: Deletes precisam de lápide
version: 1
---

**Uma sincronização por delta pergunta o que mudou. Uma linha apagada não está lá para ser
perguntada, então, a menos que o delete deixe algo para trás, nenhuma pergunta consegue devolvê-la.**
O que ele deixa para trás é uma **lápide** (*tombstone*): o id da linha, marcado como apagado, com um
lugar no histórico como qualquer outra escrita.

O desenho tentador apaga a linha no servidor e espera que os aparelhos percebam. Eles não conseguem.
Um aparelho que buscou `s3` semana passada a mantém, a mostra na semana e conta os 20 minutos dela.
Se o aparelho um dia a enviar de volta, uma sessão que a pessoa apagou no tablet reaparece no
servidor.

## Vendo os dois

O `DELETE` do servidor escreve uma lápide: a linha fica, com `deleted: true`, e recebe o próximo
número da sequência. O `/changed-since`, a consulta por timestamp da seção anterior, só lê linhas que
não foram apagadas, que é como uma consulta sobre linhas vivas se comporta. Reinicie o servidor,
busque as seis sessões, apague `s3` de outro celular e pergunte dos dois jeitos:

```
ana@dev:~/planner/delta$ rm planner.db
ana@dev:~/planner/delta$ node pull.ts delta
received 6 rows, 722 bytes; cursor 6; 6 sessions on the device
ana@dev:~/planner/delta$ curl -s -o /dev/null -X DELETE 'http://127.0.0.1:8011/sessions/s3?stamp=2026-10-21T10:30:00Z'
ana@dev:~/planner/delta$ curl -s 'http://127.0.0.1:8011/changed-since?t=2026-10-21T10:00:00Z'; echo
[]
ana@dev:~/planner/delta$ node pull.ts delta
received 1 row, 154 bytes; cursor 7; 5 sessions on the device
```

A consulta por timestamp respondeu uma lista vazia, o que é verdade sobre as linhas vivas e inútil
para o aparelho. A busca pelo cursor recebeu uma linha, a lápide, e o `pull.ts` apagou `s3`
localmente: cinco sessões no aparelho, como no servidor.

## Quanto tempo uma lápide vive

Uma lápide custa uma linha por delete, para sempre, a menos que o servidor a remova. Ele só pode
remover uma quando **todo aparelho que ainda possa ter a linha tiver buscado além do número da
lápide**, e um servidor não tem como saber isso sobre um celular que está numa gaveta. Então os
servidores guardam lápides por uma janela fixa, trinta dias ou noventa, e aceitam que um aparelho
ausente por mais tempo não pode ser atualizado por deltas. Esse aparelho precisa de outra coisa, e a
aula 12 é isso: a ressincronização completa, e o `410 Gone` que diz quando fazer uma.

Uma lápide também responde a uma pergunta que uma linha apagada não responde: *quem a apagou, e
quando*. Um servidor que guarda isso pode mostrar à pessoa "apagada no tablet na terça", que é o
conflito da aula 13 visto do outro lado.
