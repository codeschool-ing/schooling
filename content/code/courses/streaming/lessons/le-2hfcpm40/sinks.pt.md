---
title: Sinks, e quais deles fazem exactly-once
version: 1
---

O console foi o sink da lição inteira porque é fácil de ler, e é o único sink que ninguém roda em
produção: ele não guarda nada, e um batch que roda duas vezes simplesmente sai impresso duas vezes.
**Para onde vão os resultados decide duas coisas que a consulta não decide sozinha**: quais modos
de saída são possíveis, e se um batch repetido depois de uma queda, o da figura da seção 06, causa
estrago.

O jeito do próprio Spark dizer isso é que o motor é exactly-once **de ponta a ponta só quando a
fonte pode ser relida e o sink é idempotente**. O Kafka é uma fonte que pode ser relida: o
checkpoint nomeia os offsets, e lê-los de novo dá os mesmos registros. O sink é a metade que varia.

| sink | modos de saída | um batch escrito duas vezes |
|---|---|---|
| console, memória | os três | impresso ou guardado duas vezes; só para teste |
| arquivos (JSON, Parquet, CSV…) | só append | ignorado: um log dos batches concluídos decide o que os leitores veem |
| Kafka | append, update | escrito duas vezes; at-least-once |
| `foreachBatch` | os três | o que a sua função fizer com o id do batch que recebe |

## Kafka

O tópico agora guarda as cem vendas da seção 07. Mande as contagens para um tópico do Kafka em vez
da tela, no modo update, com o início da janela como chave:

```
ubuntu@stream:~/work$ python spark_sales.py --sink kafka --checkpoint ~/spark/ckpt/kafka 2>spark.log
```

Nada apareceu na tela; as linhas foram para `sales-per-window`, que o Kafka criou no primeiro uso.
Leia o tópico:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic sales-per-window --from-beginning --formatter-property print.key=true --max-messages 5
```

A chave `09:05` aparece duas vezes, 20 vendas e depois 28, porque o modo update manda uma janela
cada vez que ela muda. **Para quem lê este tópico, o último registro de uma chave é a verdade**, que
é o que um tópico compactado guarda (lição 3). E se o Spark caísse depois de escrever um batch e
antes do commit, o batch rodaria de novo e os mesmos registros seriam escritos uma segunda vez.
Como cada registro leva a contagem inteira e não um incremento, uma duplicata não faz mal a um
leitor que guarda o último valor por chave, e faz mal a um que vai somando. É a escrita idempotente
da lição 8, decidida pelo formato do registro.

## Arquivos

Arquivos são o caso oposto. Peça-os no modo update e a consulta é recusada na hora:

```
ubuntu@stream:~/work$ python spark_sales.py --sink files --checkpoint ~/spark/ckpt/files 2>spark.log; tail -1 spark.log
```

Um arquivo, depois de escrito, não pode ser atualizado, então só o modo append é permitido:

```
ubuntu@stream:~/work$ python spark_sales.py --sink files --mode append --checkpoint ~/spark/ckpt/files-append 2>spark.log
```

```
ubuntu@stream:~/work$ ls ~/spark/out ~/spark/out/_spark_metadata
```

Cada batch escreveu um arquivo por partição de shuffle, alguns vazios, com um nome aleatório. **O
diretório `_spark_metadata` é o que torna este sink exactly-once**: uma entrada por batch concluído,
com os arquivos dele. Um batch que caiu no meio da escrita deixa arquivos que nenhuma entrada cita,
e o Spark, ao ler o diretório de volta, os ignora; um batch que roda de novo escreve arquivos novos
e uma entrada. Então leia o diretório com o Spark, não com `cat`, se a exatidão importa. Com `cat`
são três janelas:

```
ubuntu@stream:~/work$ cat ~/spark/out/part-*.json
```

Três, não quatro: o watermark parou em 09:15:12, três minutos antes da última venda do caixa, então
a janela de 09:15 continua esperando, como as de 09:30 e 09:35 esperaram na seção 05.

## E o resto

O `foreachBatch` entrega à sua função cada micro-batch como um DataFrame comum, com o número do
batch. É assim que uma consulta escreve num banco de dados para o qual o Spark não tem sink, e o
número do batch é o que torna isso seguro: guarde-o junto com as linhas, na mesma transação, e um
batch repetido pode ser reconhecido e pulado, o padrão de offsets no sink da lição 8.

Pare aqui e olhe a consulta inteira: uma fonte que pode ser relida, um checkpoint que diz o que foi
lido, estado que sobrevive a um reinício, um watermark que descarta o que chega tarde demais, e um
sink que ou tolera uma segunda cópia ou a recusa. **Nada disso foi escrito por você, e tudo foi
escolhido por você**, que é a troca que um motor oferece. A lição 13 faz a mesma contagem em dois
motores que escolhem diferente.
