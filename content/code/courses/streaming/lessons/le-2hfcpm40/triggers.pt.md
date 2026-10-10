---
title: Triggers, e aquele que não é micro-batch
version: 1
---

Todas as execuções até aqui usaram `availableNow`: ler o que está no tópico, em quantos batches os
limites permitirem, e parar. Isso é um job batch escrito com código de streaming, e tem os seus
usos. **Um trigger é a configuração que decide quando começa o próximo micro-batch**, e as outras
opções são o que faz da mesma consulta um stream.

| trigger | quando um batch começa | termina |
|---|---|---|
| nenhum | assim que o anterior terminou | nunca |
| `processingTime="5 seconds"` | a cada cinco segundos pelo relógio; na hora, se um batch demorou mais | nunca |
| `availableNow=True` | na hora, até ler tudo o que existia no início | sozinho |
| `once=True` | um batch sobre tudo o que existe, ignorando limites | sozinho; obsoleto em favor do `availableNow` |
| `continuous="1 second"` | não há batches; o segundo é a frequência com que o progresso é salvo | nunca |

## Um trigger no relógio

Para ver um stream ao vivo, o tópico precisa receber vendas enquanto a consulta roda. Crie o
tópico de novo, vazio, para o relógio do caixa começar às 09:00 sem nada à frente:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --delete --topic sales
```

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 3
```

No **segundo shell**, comece a consulta com um trigger de cinco segundos e um checkpoint novo, já
que os antigos descrevem um tópico que não existe mais:

```
ubuntu@stream:~/work$ python spark_sales.py --trigger 5 --checkpoint ~/spark/ckpt/live 2>spark.log
```

No primeiro, mande cem vendas a dez por segundo, para que levem dez segundos para chegar:

```
ubuntu@stream:~/work$ python tills.py --count 100 --rate 10
```

**Os seus batches não vão bater com estes**, e esse é o ponto desta execução: o que cai em cada
batch depende de onde os tiques de cinco segundos caem em relação às vendas, e duas execuções nunca
cortam no mesmo lugar. O que não muda é a forma. Um batch rodou a cada cinco segundos e levou o que
tinha chegado desde o anterior; uma janela pôde aparecer num batch com parte das vendas e no
seguinte com mais; e quando o caixa parou, os batches pararam de imprimir linhas. Pare a consulta
com Ctrl+C quando tiver visto o suficiente.

## Quanto custa rodar

Enquanto a consulta roda, o primeiro shell consegue ver o que há na máquina. O `jps`, que veio com
o JDK, lista os programas Java, e o `ps`, quanta memória cada processo ocupa:

```
ubuntu@stream:~/work$ jps -l
```

```
ubuntu@stream:~/work$ ps -o pid,rss,comm -u ubuntu --sort=-rss | head -5
```

O `java` maior é o Spark, cerca de 600 MB, e o seguinte é o nó Kafka, cerca de 400 MB: o `RSS` está
em kilobytes. O seu programa Python, que só manda a consulta ao Spark e espera, é o `python` de 50
MB. **Cerca de um gigabyte para um broker e uma consulta de streaming**, com folga dentro dos 4 GB
da máquina virtual.

```
ubuntu@stream:~/work$ ss -ltn | grep -E "4040|9092"
```

A porta 4040 é a página web do Spark sobre a consulta em execução, e ela escuta em `127.0.0.1`, como
o nó Kafka, por causa da linha `SPARK_LOCAL_IP` da seção 03.

## Processamento contínuo

O último trigger da tabela é outro motor. **O processamento contínuo não corta o stream em batches**:
tarefas de longa duração leem cada registro e o passam adiante assim que ele chega, com latências de
poucos milissegundos em vez de centenas. O preço é o que ele consegue fazer. Ele trata consultas que
recebem uma linha e devolvem uma linha, como projeções e filtros, e recusa qualquer coisa com
estado, então a contagem desta lição é recusada antes de começar:

```
ubuntu@stream:~/work$ python spark_sales.py --trigger continuous --checkpoint ~/spark/ckpt/cont 2>spark.log; grep AnalysisException spark.log
```

O watermark é a primeira coisa contra a qual ele protesta, e a agregação seria a próxima. O
processamento contínuo também é **só at-least-once**, e o próprio guia do Spark ainda o chama de
experimental. O Spark 4.1 traz um desenho mais novo de baixa latência, um modo de tempo real, no
motor em Scala; o `trigger()` do Python 4.1.3 não tem como pedi-lo, e este curso não o roda.

Então o resumo honesto do Spark é que ele é um motor de micro-batch. **Para uma latência de um ou
dois segundos, que é o caso da maioria dos painéis, alertas e contagens de estoque, isso basta.**
Para uma resposta em milissegundos, com janelas e estado, o Flink da lição 13 foi feito para isso.
