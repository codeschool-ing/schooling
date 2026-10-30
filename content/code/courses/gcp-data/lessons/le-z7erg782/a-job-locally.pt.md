---
title: O job noturno, rodado de verdade no seu próprio Spark
version: 1
---

**Um cluster Dataproc roda Apache Spark, e o Apache Spark roda num notebook.** Nenhum emulador
imita o Dataproc, e nenhum é preciso para a parte que faz o trabalho: o programa que um cluster roda
é um programa PySpark comum, e o **modo local** do Spark o roda num processo só, na sua própria
máquina, com uma thread por processador fazendo o papel dos executores dos workers. O que segue é o
motor, não o serviço. Nenhum cluster é criado aqui, ninguém cobra por ele, e os comandos que
entregariam o programa ao Dataproc aparecem no fim da seção e não foram rodados.

## O Spark, do PyPI

**O PySpark no PyPI traz o Spark inteiro**, as bibliotecas Java e Scala incluídas, então um único
`pip install` dá o `spark-submit` e tudo o que ele inicia. Ele precisa de Java 17 ou 21 para rodar, e
o pacote `openjdk-21-jre-headless` que a aula 1 instalou para os emuladores basta. No terminal em que
você digita, com o ambiente virtual ativo:

```sh
pip install -q pyspark==4.2.0
```

O download passa de 400 MB, e o pip o transforma num wheel na sua máquina antes de instalar, o que
leva um minuto. Depois confira o que você tem:

```
ana@laptop:~/gcp$ pip install -q pyspark==4.2.0
ana@laptop:~/gcp$ java -version 2>&1 | head -1
openjdk version "21.0.12.1" 2026-08-18
ana@laptop:~/gcp$ spark-submit --version 2>&1 | grep -E 'version [0-9]|Using Scala'
   /___/ .__/\_,_/_/ /_/\_\   version 4.2.0
Using Scala version 2.13.18, OpenJDK 64-Bit Server VM, 21.0.12.1
```

**Spark 4.2.0 sobre Java 21.** Uma imagem do Dataproc fixa uma versão própria do Spark, que pode ser
mais antiga que esta; o programa abaixo não usa nada que tenha mudado entre as duas.

## Uma noite de pedidos, gerada

Os pedidos são inventados, por um gerador curto o bastante para ler inteiro. Ele escreve um dia de
pedidos da Quitanda em CSV, com o mesmo layout de chaves que o bucket raw usa, e alimentar o gerador
aleatório com a data faz o mesmo dia dar sempre os mesmos pedidos. Salve-o como `make_orders.py`:

`make_orders.py`:

```python
import csv
import random
import sys
from pathlib import Path

dt = sys.argv[1]                       # the day, written 2026-10-29
rng = random.Random(dt)                # the same day always gives the same orders
out = Path(f'raw/orders/dt={dt}/orders.csv')
out.parent.mkdir(parents=True, exist_ok=True)

with out.open('w', newline='') as f:
    w = csv.writer(f, lineterminator='\n')
    w.writerow(['order_id', 'customer_id', 'placed_at', 'total_cents'])
    for n in range(1, 20001):
        minute = rng.randrange(24 * 60)
        w.writerow([f'ord-{dt.replace("-", "")}-{n:05d}',
                    f'c-{rng.randrange(1, 501):03d}',
                    f'{dt}T{minute // 60:02d}:{minute % 60:02d}:00-03:00',
                    rng.randrange(1500, 40000)])
print(out, out.stat().st_size, 'bytes')
```

```
ana@laptop:~/gcp$ python3 make_orders.py 2026-10-29
raw/orders/dt=2026-10-29/orders.csv 1135614 bytes
ana@laptop:~/gcp$ head -4 raw/orders/dt=2026-10-29/orders.csv
order_id,customer_id,placed_at,total_cents
ord-20261029-00001,c-334,2026-10-29T06:30:00-03:00,27139
ord-20261029-00002,c-238,2026-10-29T22:46:00-03:00,2140
ord-20261029-00003,c-460,2026-10-29T06:04:00-03:00,32246
```

**Vinte mil pedidos de quinhentos clientes, num arquivo só.** Cada pedido tem o próprio id, o
cliente que o fez, o minuto em que foi feito no horário de São Paulo e um total em centavos, o que
mantém o dinheiro fora do ponto flutuante, como em toda aula deste curso.

## O job

Este é o job noturno: ler um dia de pedidos, contar e somar por cliente e escrever o resultado em
Parquet. Salve-o como `daily_orders.py`:

```schooling-example
{"language": "python", "file": "daily_orders.py", "parts": [{"code": "import argparse\n\nfrom pyspark.sql import SparkSession, functions as F\n\nargs = argparse.ArgumentParser()\nargs.add_argument('--dt', required=True)\nargs.add_argument('--src', default='raw')\nargs.add_argument('--dst', default='curated')\na = args.parse_args()\n\n", "note": "**Onde ler e onde escrever são argumentos**, e são a única coisa que muda entre este notebook e um cluster. Aqui o padrão são dois diretórios dentro de `~/gcp`; no Dataproc são `gs://quitanda-raw-prod/raw` e `gs://quitanda-curated-prod`, lidos pelo conector do Cloud Storage que todo cluster já traz."}, {"code": "spark = SparkSession.builder.appName(f'daily-orders-{a.dt}').getOrCreate()\nspark.sparkContext.setLogLevel('ERROR')\n\n", "note": "A sessão é o ponto de contato do programa com o Spark. Nada nela fixa um master ou um número de máquinas: quem decide isso, de fora, é o `spark-submit`, e é por isso que o mesmo arquivo roda em dois processadores aqui e em quarenta num cluster."}, {"code": "orders = (spark.read.option('header', True)\n          .schema('order_id STRING, customer_id STRING, placed_at TIMESTAMP, total_cents LONG')\n          .csv(f'{a.src}/orders/dt={a.dt}/'))\n\n", "note": "**O esquema é escrito, não adivinhado.** Sem ele, o Spark lê toda coluna de CSV como texto, ou passa duas vezes pelo arquivo para deduzir os tipos, e um total em centavos lido como texto não soma nada."}, {"code": "daily = (orders.groupBy('customer_id')\n               .agg(F.count('*').alias('orders'),\n                    F.sum('total_cents').alias('total_cents')))\ndaily.write.mode('overwrite').parquet(f'{a.dst}/daily_orders/dt={a.dt}/')\n\n", "note": "Uma linha de trabalho: agrupar por cliente, contar e somar. É no `groupBy` que o Spark faz o shuffle, levando todos os pedidos de um cliente para a mesma tarefa. O `overwrite` torna seguro rodar o job duas vezes para o mesmo dia, coisa que um agendador um dia vai fazer."}, {"code": "print(orders.count(), 'orders read,', daily.count(), 'customers written')\nspark.stop()\n", "note": "Duas contagens para o log. Cada uma é um segundo job, pequeno, sobre a mesma entrada: um DataFrame do Spark é um plano, e nada é calculado até que alguém peça um resultado."}]}
```

**O `spark-submit` é como um programa Spark é iniciado**, num notebook e num cluster do mesmo jeito:
ele inicia um driver, o processo que planeja o trabalho, e pede ao master que recebe os executores
para fazê-lo. Aqui o master é `local[2]`, duas threads no próprio processo do driver. O Spark escreve
o andamento na saída de erro, então ela vai para um arquivo, e o `time` diz quanto tudo levou:

```
ana@laptop:~/gcp$ time spark-submit --master 'local[2]' daily_orders.py --dt 2026-10-29 2> spark.log
20000 orders read, 500 customers written

real	0m19.286s
user	0m22.798s
sys	0m2.458s
ana@laptop:~/gcp$ ls -a curated/daily_orders/dt=2026-10-29/
.
..
._SUCCESS.crc
.part-00000-fe268669-4205-4afd-90f8-0e02a2940427-c000.snappy.parquet.crc
_SUCCESS
part-00000-fe268669-4205-4afd-90f8-0e02a2940427-c000.snappy.parquet
ana@laptop:~/gcp$ grep -c . spark.log
50
```

**A maior parte desses segundos é o Spark iniciando, não o Spark trabalhando.** Vinte mil linhas não
são nada para ele; a máquina virtual Java, a sessão e as duas contagens do fim são o que o relógio
mediu, e as cinquenta linhas que o Spark escreveu sobre isso estão em `spark.log`. Esse custo fixo é
pago por todo job em todo cluster, e é um motivo para juntar o trabalho numa execução noturna em vez
de muitas pequenas.

**A saída é um diretório, não um arquivo.** Cada tarefa que escreveu uma parte do resultado escreve
o próprio arquivo `part-`, e aqui há um, porque a execução adaptativa do Spark viu que quinhentas
linhas não precisavam das duzentas partições de shuffle com que ele começa e as juntou antes de
escrever. O `_SUCCESS` é o marcador vazio que o Spark deixa quando todas as tarefas terminaram. Quem
lista o diretório antes de o `_SUCCESS` aparecer pode encontrar meio resultado, e é por isso que o
que vem depois deste job espera o marcador, ou o job, e não o primeiro arquivo. Os dois arquivos
cujo nome começa com ponto são checksums que o sistema de arquivos local do Hadoop escreve ao lado de
cada arquivo; são um efeito de escrever num disco, e um job que escreve em `gs://` pelo conector não
os cria.

## Confira com um segundo motor

**Um resultado merece crédito quando outra coisa concorda com ele.** O DuckDB, o motor que este curso
usa para o SQL do BigQuery, lê tanto o CSV que entrou quanto o Parquet que saiu. Salve isto como
`check_daily.py`:

`check_daily.py`:

```python
import sys

import duckdb

dt = sys.argv[1]
print(duckdb.sql(f"SELECT count(*) AS orders, sum(total_cents) AS total_cents "
                 f"FROM 'raw/orders/dt={dt}/orders.csv'"))
print(duckdb.sql(f"SELECT count(*) AS customers, sum(orders) AS orders, sum(total_cents) AS total_cents "
                 f"FROM 'curated/daily_orders/dt={dt}/*.parquet'"))
```

```
ana@laptop:~/gcp$ python3 check_daily.py 2026-10-29
┌────────┬─────────────┐
│ orders │ total_cents │
│ int64  │   int128    │
├────────┼─────────────┤
│  20000 │   412139132 │
└────────┴─────────────┘

┌───────────┬────────┬─────────────┐
│ customers │ orders │ total_cents │
│   int64   │ int128 │   int128    │
├───────────┼────────┼─────────────┤
│       500 │  20000 │   412139132 │
└───────────┴────────┴─────────────┘
```

**Os dois motores concordam até o centavo.** Os pedidos contados no Parquet somam as linhas do CSV, e
os totais também, e essa é a checagem que um pipeline deveria fazer em toda noite em que roda:
linhas que entram, linhas que saem, dinheiro que entra, dinheiro que sai.

## Onde os arquivos ficam no Dataproc

**Num cluster, a entrada e a saída são objetos no Cloud Storage.** Ponha-os onde o cluster os
encontraria, no emulador da aula 1, rodando no terminal dele:

```
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-raw-prod gs://quitanda-curated-prod --location=southamerica-east1
Creating gs://quitanda-raw-prod/...
Creating gs://quitanda-curated-prod/...
ana@laptop:~/gcp$ gcloud storage cp raw/orders/dt=2026-10-29/orders.csv gs://quitanda-raw-prod/raw/orders/dt=2026-10-29/orders.csv
Copying file://raw/orders/dt=2026-10-29/orders.csv to gs://quitanda-raw-prod/raw/orders/dt=2026-10-29/orders.csv
  

ana@laptop:~/gcp$ gcloud storage cp daily_orders.py gs://quitanda-raw-prod/jobs/daily_orders.py
Copying file://daily_orders.py to gs://quitanda-raw-prod/jobs/daily_orders.py
  

ana@laptop:~/gcp$ gcloud storage cp curated/daily_orders/dt=2026-10-29/* gs://quitanda-curated-prod/daily_orders/dt=2026-10-29/
Copying file://curated/daily_orders/dt=2026-10-29/_SUCCESS to gs://quitanda-curated-prod/daily_orders/dt=2026-10-29/_SUCCESS
Copying file://curated/daily_orders/dt=2026-10-29/part-00000-fe268669-4205-4afd-90f8-0e02a2940427-c000.snappy.parquet to gs://quitanda-curated-prod/daily_orders/dt=2026-10-29/part-00000-fe268669-4205-4afd-90f8-0e02a2940427-c000.snappy.parquet
  
.

Average throughput: 65.8kiB/s
ana@laptop:~/gcp$ gcloud storage ls -r gs://quitanda-curated-prod/
gs://quitanda-curated-prod/:

gs://quitanda-curated-prod/daily_orders/:

gs://quitanda-curated-prod/daily_orders/dt=2026-10-29/:
gs://quitanda-curated-prod/daily_orders/dt=2026-10-29/_SUCCESS
gs://quitanda-curated-prod/daily_orders/dt=2026-10-29/part-00000-fe268669-4205-4afd-90f8-0e02a2940427-c000.snappy.parquet
```

**O mesmo layout `dt=`, num bucket em vez de um diretório**, e o programa como objeto ao lado dos
dados brutos, onde um job pode citá-lo. O `*` do shell não casa com nomes que começam com ponto,
então os dois arquivos de checksum ficaram no notebook. Isso é tudo o que muda no Dataproc: o programa
recebe caminhos `gs://` em vez de diretórios, e o conector do Cloud Storage do cluster os lê e
escreve.

Entregar o programa a um cluster é um comando. **Ele não foi rodado aqui**, porque não há Dataproc
para recebê-lo, e num projeto de verdade ele precisa que o cluster das seções anteriores exista:

```sh
gcloud dataproc jobs submit pyspark gs://quitanda-raw-prod/jobs/daily_orders.py \
  --cluster=quitanda-spark --region=southamerica-east1 \
  -- --dt 2026-10-29 --src gs://quitanda-raw-prod/raw --dst gs://quitanda-curated-prod
```

**Tudo o que vem depois do `--` sozinho vai para o programa**, não para o `gcloud`, e é assim que os
três argumentos do `daily_orders.py` chegam a ele. O Dataproc roda o `spark-submit` no master com o
YARN do próprio cluster como URL do master, devolve a saída do driver ao terminal e guarda uma cópia
dela no bucket de staging do cluster. O job passa então a ter um id e um estado, `DONE` ou `ERROR`,
que o `gcloud dataproc jobs describe` lê de volta. Nada disso aparece aqui; o que esta seção mostrou
é a parte que não depende do Google: o programa e o resultado dele.
