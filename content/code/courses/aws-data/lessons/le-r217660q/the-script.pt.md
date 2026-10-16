---
title: O script do Glue, e o que é um DynamicFrame
version: 1
---

**O job noturno da Quitanda são três passos: ler o CSV raw novo, deixá-lo limpo, gravá-lo como
Parquet curated.** Limpo quer dizer tipado, com cada pedido uma vez só: a exportação da loja às vezes
é enviada duas vezes, e um pedido contado duas vezes é receita que nunca aconteceu. Este é o script
que o Glue rodaria para isso.

**Ele não roda neste curso.** O Spark não está no laboratório, a biblioteca `awsglue` só existe dentro
de uma execução do Glue, e o moto não o rodaria se estivesse. Ele aparece para que você leia um
script de Glue de verdade; a próxima seção roda a mesma transformação, passo a passo, com ferramentas
que estão aqui.

```schooling-example
{"language": "python", "file": "orders_etl.py", "parts": [{"code": "import sys\n\nfrom awsglue.context import GlueContext\nfrom awsglue.dynamicframe import DynamicFrame\nfrom awsglue.job import Job\nfrom awsglue.utils import getResolvedOptions\nfrom pyspark.context import SparkContext\n\n", "note": "`awsglue` é a biblioteca do próprio Glue, e só existe dentro de uma execução do Glue: não há `pip install` que a traga para este laboratório, e esse é um dos motivos de o script não rodar aqui."}, {"code": "args = getResolvedOptions(sys.argv, ['JOB_NAME'])\nglue = GlueContext(SparkContext.getOrCreate())\njob = Job(glue)\njob.init(args['JOB_NAME'], args)\n\n", "note": "Os argumentos da execução, o contexto do Spark e o objeto do job. É no `job.init` que o Glue carrega o bookmark deste job, se houver um."}, {"code": "raw = glue.create_dynamic_frame.from_catalog(\n    database='quitanda_raw', table_name='orders', transformation_ctx='raw_orders')\n", "note": "**A origem é uma tabela do catálogo, não um caminho**: `quitanda_raw.orders` descreveria o prefixo CSV raw do jeito que a lição 16 descreveu o curated. `transformation_ctx` dá nome a esta leitura para o bookmark, para que a próxima execução leia só os arquivos que esta não leu."}, {"code": "raw = raw.resolveChoice(specs=[('total_cents', 'cast:long')])\ntyped = raw.apply_mapping([\n    ('order_id', 'string', 'order_id', 'string'),\n    ('customer_id', 'string', 'customer_id', 'string'),\n    ('hour', 'long', 'hour', 'byte'),\n    ('items', 'long', 'items', 'short'),\n    ('total_cents', 'long', 'total_cents', 'long'),\n    ('payment', 'string', 'payment', 'string'),\n    ('neighbourhood', 'string', 'neighbourhood', 'string'),\n    ('dt', 'string', 'dt', 'string'),\n])\n", "note": "Um DynamicFrame deixa uma coluna ter dois tipos ao mesmo tempo, uma *choice*, quando os arquivos discordam. `resolveChoice` resolve isso com um cast; `apply_mapping` nomeia cada coluna com o tipo na entrada e na saída, e é ali que `hour` vira byte e `items` vira short, os `tinyint` e `smallint` da tabela."}, {"code": "orders = typed.toDF().dropDuplicates(['order_id'])\n\n", "note": "`toDF` o transforma num DataFrame comum do Spark, que tem `dropDuplicates`. **As duplicatas removidas são as que estão na entrada desta execução**, que com bookmark são só os arquivos novos."}, {"code": "sink = glue.getSink(connection_type='s3', path='s3://quitanda-curated-prod/orders/',\n                    enableUpdateCatalog=True, updateBehavior='LOG',\n                    partitionKeys=['dt'], transformation_ctx='curated_orders')\nsink.setFormat('glueparquet')\nsink.setCatalogInfo(catalogDatabase='quitanda', catalogTableName='orders')\n", "note": "A saída: Parquet sob o prefixo curated, uma pasta por `dt`, e `enableUpdateCatalog` para que o próprio Glue acrescente cada partição nova a `quitanda.orders`. `updateBehavior='LOG'` é de novo a configuração de crawler da lição 16: uma mudança de esquema é relatada, não gravada na tabela."}, {"code": "sink.writeFrame(DynamicFrame.fromDF(orders, glue, 'orders'))\njob.commit()\n", "note": "`writeFrame` acrescenta arquivos sob cada pasta `dt=`; não substitui o que já está lá. `job.commit` grava o bookmark, e **só uma execução que chega a esta linha o avança**."}]}
```

## Um DynamicFrame e um DataFrame

**Um DataFrame tem um esquema, decidido antes de qualquer linha ser lida; um DynamicFrame deixa cada
registro carregar o seu.** O DataFrame do Spark é uma tabela: colunas, tipos e linhas que cabem
neles. O DynamicFrame do Glue é uma coleção de registros, cada um se descrevendo, com o esquema
calculado a partir dos registros quando alguém pede. Onde dois arquivos discordam sobre uma coluna,
um long num e uma string no outro, um DataFrame tem de falhar ou adivinhar, e um DynamicFrame guarda
os dois como uma *choice* até o script decidir, que é para isso que serve o `resolveChoice`.

É por isso que os DynamicFrames existem, e os cupons e os reais da lição 16 são o caso para o qual
foram feitos: arquivos raw de uma origem que ninguém controla, cujos tipos derivam. Todo o resto, um
join, uma janela, `dropDuplicates`, é do DataFrame, então um script de Glue costuma ler para um
DynamicFrame, acertar os tipos e transformá-lo em DataFrame com `toDF` para o trabalho. Na saída o
`DynamicFrame.fromDF` o transforma de volta, porque os sinks do Glue, os que atualizam o catálogo
enquanto gravam, recebem um DynamicFrame.

## O que este script faz errado

**O `writeFrame` acrescenta arquivos e o bookmark lê só os novos**, e juntos esses dois fazem um erro
silencioso. Suponha que a loja mande a exportação de 15 de outubro de novo na noite seguinte, num
segundo arquivo. O bookmark entrega ao script só esse arquivo, o `dropDuplicates` não acha duplicata
nenhuma dentro dele, e o sink acrescenta as linhas dele ao dia, ao lado das linhas do primeiro
arquivo. Todo pedido dele agora está duas vezes na camada curated, e nada falhou.

A cura é ler todo arquivo raw de cada dia que tem um novo, e substituir esses dias em vez de
acrescentar a eles. No Spark isso é uma sobrescrita com `partitionOverwriteMode` em `dynamic`, que
substitui as partições que uma gravação toca e deixa o resto em paz. O programa da próxima seção faz
exatamente isso, e a seção depois dela manda 15 de outubro duas vezes para mostrar a diferença.
