---
title: Combiners, ou reduzir antes do shuffle
version: 1
---

**Um *combiner* é um reducer que roda no lado do map**, sobre a saída de cada tarefa de map, antes de
qualquer coisa ser mandada aos reducers. Se uma tarefa de map emitiu `view\t1` uns dois milhões de
vezes, um combiner transforma isso num par só, `view` com o seu total, e só ele atravessa a rede.

Acrescente um argumento, `-combiner`, e use o reducer também como combiner:

```
ana@lab:~/big$ time hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-3.5.0.jar -D mapreduce.local.map.tasks.maximum=3 -files mapper.py,reducer.py -mapper 'python3 mapper.py' -combiner 'python3 reducer.py' -reducer 'python3 reducer.py' -input /raw/clicks-2025.csv -output /out/kinds-combined 2> combined.log

real	0m35.309s
user	1m33.777s
sys	0m6.410s
ana@lab:~/big$ sed -n '/mapreduce.Job: Counters/,$p' combined.log | grep -E 'Combine|Reduce shuffle bytes|Spilled'
		Combine input records=24000000
		Combine output records=40
		Reduce shuffle bytes=684
		Spilled Records=80
```

**Os bytes do shuffle foram de 223.679.952 para 684**, e o job levou cerca de metade do tempo. Cada
uma das dez tarefas de map combinou os seus 2,4 milhões de pares em quatro, e o reducer recebeu
quarenta pares em vez de 24 milhões. Os registros despejados em disco caíram de 48 milhões para 80.

**Um combiner só é correto quando o reduce pode ser feito em pedaços.** O Hadoop pode rodar o
combiner zero vezes, uma vez ou várias vezes sobre os mesmos dados, então a resposta precisa ser a
mesma em qualquer caso:

- **Somas, contagens, mínimos e máximos** combinam: a soma de somas parciais é a soma.
- **Uma média não combina**, diretamente: a média de médias erra quando os pedaços têm tamanhos
  diferentes. Emita a soma e a contagem, combine essas, e divida no fim.
- **Uma contagem de valores distintos não combina**, como mostra a pergunta da aula 1. Uma tarefa de
  map que viu o visitante `v0094455` olhar o livro 9 três vezes pode reduzir isso a uma, mas não tem
  como saber se outra tarefa viu o mesmo visitante, então as contagens parciais não se somam. Só a
  lista exata de visitantes se soma, e ela não é menor.

O `reducer.py` é uma soma, então é um combiner válido de si mesmo. Isso é comum e não é garantido, e
um combiner inválido não falha: dá um número errado.

O Spark aplica a mesma ideia sem que ninguém peça. Um `groupBy(...).count()` no Spark calcula
contagens parciais em cada tarefa antes do shuffle, e a aula 7 mostra isso nos planos como as duas
metades de uma agregação.
