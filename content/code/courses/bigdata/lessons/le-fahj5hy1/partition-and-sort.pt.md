---
title: Que reducer recebe que chave
version: 1
---

**Com mais de uma tarefa de reduce, cada chave precisa ir para exatamente uma delas**, sempre a
mesma, ou os valores de uma chave se dividiriam entre dois reducers e cada um imprimiria metade de
um total. Quem decide é o *particionador*, e o padrão do Hadoop é o que o `buckets.py` usou na aula
1: um hash da chave, módulo o número de tarefas de reduce.

Peça duas tarefas de reduce e veja o que cada uma recebeu:

```
ana@lab:~/big$ hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-3.5.0.jar -D mapreduce.local.map.tasks.maximum=3 -files mapper.py,reducer.py -mapper 'python3 mapper.py' -combiner 'python3 reducer.py' -reducer 'python3 reducer.py' -numReduceTasks 2 -input /raw/clicks-2025.csv -output /out/kinds-two 2> two.log
ana@lab:~/big$ hdfs dfs -ls /out/kinds-two
Found 3 items
-rw-r--r--   3 ana supergroup          0 2026-10-15 22:02 /out/kinds-two/_SUCCESS
-rw-r--r--   3 ana supergroup         30 2026-10-15 22:02 /out/kinds-two/part-00000
-rw-r--r--   3 ana supergroup         28 2026-10-15 22:02 /out/kinds-two/part-00001
ana@lab:~/big$ hdfs dfs -cat /out/kinds-two/part-00000
purchase	959814
view	19199214
ana@lab:~/big$ hdfs dfs -cat /out/kinds-two/part-00001
cart	1920654
search	1920318
```

**Dois arquivos de saída, um por tarefa de reduce, e cada tipo em exatamente um deles.** Que tipo foi
para onde é decidido pelo hash e não quer dizer nada. Dentro de cada arquivo as chaves estão
ordenadas, porque a entrada de cada reducer estava; entre arquivos não estão, e um job que precisa
de uma saída única ordenada tem de pedir um particionador que divida por faixas da chave em vez de
por hash.

Duas coisas decorrem do particionador, e as duas são assunto da aula 8:

- **Uma tarefa de reduce recebe a chave inteira, por maior que ela seja.** O robô da aula 1 é uma
  chave com 960.905 eventos. Num job com o visitante como chave, uma tarefa de reduce recebe todos
  eles, e o job espera por essa tarefa enquanto as outras ficam paradas, terminadas.
- **O número de tarefas de reduce é uma escolha, e nada escolhe por você.** Poucas demais e cada uma
  fica grande; muitas demais e cada uma fica minúscula, e a saída são os arquivos pequenos da aula 3.
  O padrão do Hadoop é uma, por isso o primeiro job escreveu um `part-00000` só.
