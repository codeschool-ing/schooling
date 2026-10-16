---
title: Os mesmos dois programas, rodados pelo Hadoop
version: 1
---

**O Hadoop Streaming roda como mapper ou reducer qualquer programa que leia a entrada padrão e
escreva na saída padrão.** Ele vem com o Hadoop que você instalou na aula 3, como um jar, e recebe os
dois programas, uma entrada no HDFS e um diretório de saída que ainda não pode existir:

```
ana@lab:~/big$ time hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-3.5.0.jar -D mapreduce.local.map.tasks.maximum=3 -files mapper.py,reducer.py -mapper 'python3 mapper.py' -reducer 'python3 reducer.py' -input /raw/clicks-2025.csv -output /out/kinds 2> kinds.log

real	1m1.316s
user	2m1.648s
sys	0m7.981s
```

Um minuto para 1,2 GB. O `-files` envia os dois programas para onde quer que as tarefas rodem. O
`mapreduce.local.map.tasks.maximum=3` deixa três tarefas de map rodarem ao mesmo tempo. O Hadoop
imprime centenas de linhas de progresso na saída de erro, então o `2> kinds.log` as guarda num
arquivo para ler depois. A resposta está no HDFS, num arquivo por tarefa de reduce:

```
ana@lab:~/big$ hdfs dfs -ls /out/kinds
Found 2 items
-rw-r--r--   3 ana supergroup          0 2026-10-15 22:00 /out/kinds/_SUCCESS
-rw-r--r--   3 ana supergroup         58 2026-10-15 22:00 /out/kinds/part-00000
ana@lab:~/big$ hdfs dfs -cat /out/kinds/part-00000
cart	1920654
purchase	959814
search	1920318
view	19199214
```

**Os mesmos quatro números do pipe, agora para o ano inteiro.** 19.199.214 visualizações, a mesma
contagem que o Spark imprimiu na aula 3.

**Onde isso rodou.** Uma instalação do Hadoop sem configuração para `mapreduce.framework.name` roda um
job com o *executor local* do MapReduce: cada tarefa de map e de reduce como uma thread dentro de um
processo Java, na máquina que submeteu. A entrada veio do HDFS e a saída voltou para lá, e cada passo
do modelo aconteceu: dez tarefas de map, uma por bloco, um shuffle por arquivos no disco local, uma
ordenação e um reduce. O que o executor local não faz é espalhar tarefas por máquinas. A aula 12
inicia o YARN, o gerenciador de cluster do Hadoop, e roda este mesmo comando nele.
