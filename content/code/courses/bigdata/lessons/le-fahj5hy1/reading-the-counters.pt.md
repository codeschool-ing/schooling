---
title: Lendo os contadores
version: 1
---

**Um job MapReduce termina imprimindo os seus *contadores***, totais mantidos por cada tarefa e
somados no fim. Eles são o primeiro lugar a olhar quando um job está lento, porque dizem quantos
dados cada passo tratou. Os que importam, do log da seção anterior:

```
ana@lab:~/big$ sed -n '/mapreduce.Job: Counters/,$p' kinds.log | grep -E 'Map (input|output) records|materialized|Reduce (shuffle bytes|input groups)|Spilled|FILE: Number of bytes written'
		FILE: Number of bytes written=1911465611
		Map input records=24000000
		Map output records=24000000
		Map output materialized bytes=223679952
		Reduce input groups=4
		Reduce shuffle bytes=223679952
		Spilled Records=48000000
```

Leia-os na ordem em que os dados fluíram:

- **Map input records, 24.000.000.** Cada evento, lido uma vez.
- **Map output records, 24.000.000.** Um par por evento: o mapper nunca filtra e nunca combina.
- **Map output materialized bytes, 223.679.952.** O que as tarefas de map gravaram nos discos locais
  para os reducers buscarem: 224 MB de `view\t1` e parentes, cada par com um pouco de moldura.
- **Reduce shuffle bytes**, os mesmos 223.679.952: tudo viajou até a única tarefa de reduce. Num
  cluster isso é tráfego de rede, de toda máquina que rodou uma tarefa de map até a que roda o
  reducer.
- **Reduce input groups, 4.** Quatro chaves diferentes, então o reducer imprimiu quatro linhas.
- **Spilled records, 48.000.000.** Cada par foi escrito em disco duas vezes, uma pelo lado do map
  quando o buffer encheu e outra pelo lado do reduce durante a mesclagem. Um registro que vai ao
  disco é um registro que não coube na memória naquele momento.
- **FILE: Number of bytes written**, uns 1,9 GB no disco local, contra uma entrada de 1,3 GB.

**224 MB movidos e 1,9 GB escritos em disco para produzir 58 bytes de resposta.** Nada disso é erro;
é o que o modelo faz quando um mapper emite um par por registro e nada os reduz cedo. A próxima seção
muda um argumento e a maior parte disso some.
