---
title: Steps, e o cluster que vive uma noite
version: 1
---

**Um step é uma unidade de trabalho entregue a um cluster**: um programa Spark para submeter, um
script do Hive, um comando para rodar no nó primário. O cluster roda os steps na ordem em que
chegam, um de cada vez salvo instrução em contrário, e cada um carrega o que fazer se falhar. Um step
é como o trabalho chega a um cluster sem ninguém entrar nele, e é isso que deixa um cluster ser
criado por um agendador às três da manhã e sumir às quatro.

O trabalho desta seção é o job noturno da Quitanda: ler um dia de pedidos do bucket raw, somá-los
por cliente e escrever o resultado em Parquet no bucket curated. Como programa PySpark ele é curto.
Ele aparece para que o step abaixo tenha algo a apontar, e **não roda neste laboratório**, que não
tem Spark; no EMR ele seria enviado para `s3://quitanda-raw-prod/jobs/daily_orders.py`.

```python
import sys
from pyspark.sql import SparkSession, functions as F

dt = sys.argv[sys.argv.index('--dt') + 1]
spark = SparkSession.builder.appName(f'daily-orders-{dt}').getOrCreate()

orders = spark.read.option('header', True).csv(f's3://quitanda-raw-prod/raw/orders/dt={dt}/')
daily = (orders.groupBy('customer_id')
               .agg(F.count('*').alias('orders'),
                    F.sum(F.col('total_cents').cast('long')).alias('total_cents')))
daily.write.mode('overwrite').parquet(f's3://quitanda-curated-prod/daily_orders/dt={dt}/')
```

Entregue-o como step ao cluster de longa duração da seção anterior:

```
ana@laptop:~/aws$ aws emr add-steps --cluster-id j-F34XLF93AZT13 --steps Type=Spark,Name=daily-orders,ActionOnFailure=CONTINUE,Args=[s3://quitanda-raw-prod/jobs/daily_orders.py,--dt,2026-10-15]
{
    "StepIds": [
        "s-XTL8VVC6SSGYA"
    ]
}
ana@laptop:~/aws$ aws emr list-steps --cluster-id j-F34XLF93AZT13
{
    "Steps": [
        {
            "Id": "s-XTL8VVC6SSGYA",
            "Name": "daily-orders",
            "Config": {
                "Jar": "command-runner.jar",
                "Properties": {},
                "Args": [
                    "spark-submit",
                    "s3://quitanda-raw-prod/jobs/daily_orders.py",
                    "--dt",
                    "2026-10-15"
                ]
            },
            "ActionOnFailure": "CONTINUE",
            "Status": {
                "State": "RUNNING",
                "StateChangeReason": {},
                "Timeline": {
                    "CreationDateTime": "2026-10-16T12:49:37.372000-03:00"
                }
            }
        }
    ]
}
ana@laptop:~/aws$ aws s3 ls s3://quitanda-raw-prod/jobs/

aws: [ERROR]: An error occurred (NoSuchBucket) when calling the ListObjectsV2 operation: The specified bucket does not exist
```

**`Type=Spark` virou `command-runner.jar` rodando `spark-submit`** com o programa e os seus dois
argumentos. É isso que um step Spark é no EMR: um comando rodado no nó primário, que submete o
programa ao YARN. `ActionOnFailure=CONTINUE` diz que, se ele falhar, o cluster segue para o próximo
step; as outras duas opções são `CANCEL_AND_WAIT`, que cancela os steps enfileirados atrás dele e
espera, e `TERMINATE_CLUSTER`, que encerra o cluster, e o cluster transitório abaixo usa essa.

**O último comando é o que vale lembrar.** Não existe bucket chamado `quitanda-raw-prod` neste moto,
então não há programa nem pedidos, e o step está `RUNNING` mesmo assim. Vai continuar `RUNNING`: o
moto nunca liga o Spark, nunca lê o programa e nunca move um step para `COMPLETED` ou `FAILED`. Na
AWS este step falharia assim que o `spark-submit` procurasse o arquivo, e o log que o EMR copia para
`--log-uri` diria isso; nada aqui consegue mostrar esse log.

## Transitório e de longa duração

**Um cluster de longa duração espera por trabalho; um cluster transitório é criado para o seu
trabalho e acaba junto com ele.** A diferença é uma flag. O cluster acima foi criado com
`--no-auto-terminate`, então, com os steps terminados, ele fica em `WAITING`, cobrado por segundo.
Um cluster transitório é criado com os seus steps e `--auto-terminate`, e na AWS ele se encerra
sozinho depois do último:

```
ana@laptop:~/aws$ aws emr create-cluster --name quitanda-nightly-2026-10-15 --release-label emr-7.9.0 --applications Name=Spark --instance-groups InstanceGroupType=MASTER,InstanceType=m7i.xlarge,InstanceCount=1 InstanceGroupType=CORE,InstanceType=m7i.xlarge,InstanceCount=2 --service-role EMR_DefaultRole --ec2-attributes InstanceProfile=EMR_EC2_DefaultRole --steps Type=Spark,Name=daily-orders,ActionOnFailure=TERMINATE_CLUSTER,Args=[s3://quitanda-raw-prod/jobs/daily_orders.py,--dt,2026-10-15] --auto-terminate
{
    "ClusterId": "j-0QNKSD17XUPEO",
    "ClusterArn": "arn:aws:elasticmapreduce:us-east-1:123456789012:cluster/j-0QNKSD17XUPEO"
}
ana@laptop:~/aws$ aws emr describe-cluster --cluster-id j-0QNKSD17XUPEO --query 'Cluster.[Status.State,AutoTerminate]' --output text
WAITING	True
ana@laptop:~/aws$ aws emr list-steps --cluster-id j-0QNKSD17XUPEO --query 'Steps[].[Name,ActionOnFailure,Status.State]' --output text
daily-orders	TERMINATE_CLUSTER	RUNNING
```

**Na AWS esse cluster estaria `TERMINATED` assim que o único step terminasse, ou assim que falhasse,
porque o step diz `TERMINATE_CLUSTER`.** No moto ele espera para sempre com o step rodando, e esse é
o limite honesto de um programa que não roda nada: ele não tem um momento em que o step termina,
então não tem um momento em que o cluster deveria terminar. Leia a requisição, não o resultado.

Um cluster de longa duração tem uma proteção contra o esquecimento, a **política de encerramento
automático**: um tempo ocioso, em segundos, depois do qual o EMR encerra um cluster que não rodou
nada. Ela é definida com `--auto-termination-policy IdleTimeout=3600` na criação, e o moto 5.2.3
aceita a flag e responde `500` quando se pede para lê-la de volta, então ela aparece aqui como flag e
não como captura.

## Qual duração, para qual trabalho

**Transitório é a resposta padrão para trabalho em lote agendado**, e o job noturno da Quitanda é o
exemplo. O cluster sobe às três, roda um step e some, então a conta é a duração do job mais os
minutos que as máquinas levam para ligar e instalar, que a AWS cobra e que o moto, pronto na mesma
linha, não consegue mostrar. Nada fica ligado para ser esquecido.

**Longa duração se justifica em três casos.** Quando o trabalho chega o dia inteiro, os minutos de
inicialização são pagos uma vez em vez de a cada job. Quando pessoas trabalham no cluster de forma
interativa, um notebook ligado a ele ou um analista rodando consultas pelo Hive ou pelo Trino, não há
em torno do que agendar um cluster transitório. E quando o cluster guarda algo que levaria uma hora
para reconstruir, como uma tabela grande do HBase, pará-lo não é uma opção. Cada um desses casos
transforma um cluster de recipiente de um job em serviço com dono, e a última seção desta lição põe
preço no que isso custa quando o dono esquece.

Antes de seguir, encerre os três clusters que esta lição criou. `terminate-clusters` aceita uma
lista:

```
ana@laptop:~/aws$ aws emr terminate-clusters --cluster-ids j-F34XLF93AZT13 j-DETAZ49RVUEMK j-0QNKSD17XUPEO
ana@laptop:~/aws$ aws emr list-clusters --query 'Clusters[].[Name,Status.State]' --output text
quitanda-nightly-2026-10-15	TERMINATED
quitanda-fleets	TERMINATED
quitanda-emr	TERMINATED
```
