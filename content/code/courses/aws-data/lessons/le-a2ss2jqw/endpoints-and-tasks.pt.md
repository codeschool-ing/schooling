---
title: Uma instância, dois endpoints e uma tarefa
version: 1
---

**Uma migração do DMS são quatro objetos, e cada um responde a uma pergunta.** A instância de
replicação é onde ela roda. O endpoint de origem é como chegar ao banco antigo, o endpoint de destino é
como chegar à nova casa dos dados, e a tarefa diz o que copiar de um para o outro e como. Eles são
criados nessa ordem, porque cada um cita os anteriores.

Com o moto rodando no terminal dele e as quatro linhas de "Seu laboratório, em resumo" da lição 1
digitadas neste, comece pela instância:

```
ana@laptop:~/aws$ aws dms create-replication-instance --replication-instance-identifier quitanda-cdc --replication-instance-class dms.c5.large --allocated-storage 50 --query "ReplicationInstance.[ReplicationInstanceArn,ReplicationInstanceStatus]"
[
    "arn:aws:dms:sa-east-1:123456789012:rep:quitanda-cdc",
    "creating"
]
ana@laptop:~/aws$ aws dms describe-replication-instances --query "ReplicationInstances[].[ReplicationInstanceIdentifier,ReplicationInstanceClass,ReplicationInstanceStatus]" --output text
quitanda-cdc	dms.c5.large	available
```

**`creating` na resposta, `available` na linha seguinte.** Na AWS uma instância de replicação leva
alguns minutos para subir, e o status fica `creating` o tempo todo; o moto não espera nada, como a
lição 1 avisou. `--allocated-storage 50` é o disco da própria instância, em gigabytes, onde ela guarda
logs e as mudanças que está retendo durante uma carga completa.

## A origem, sem senha na linha de comando

**O banco antigo precisa de um usuário e de uma senha, e nenhum dos dois pertence a um comando.** Uma
senha digitada depois de `--password` fica no histórico do shell e na lista de processos da máquina em
que foi digitada. O DMS pode, em vez disso, ler as credenciais do **Secrets Manager**: o segredo
guarda o usuário, a senha, o host e a porta, e o endpoint indica o segredo e um papel que o DMS pode
assumir para lê-lo. A senha do segredo abaixo é feita pelo `openssl rand` dentro do comando, então
nunca é digitada nem impressa:

```
ana@laptop:~/aws$ aws secretsmanager create-secret --name quitanda/legacy-shop --secret-string "{\"username\": \"dms_reader\", \"password\": \"$(openssl rand -hex 16)\", \"host\": \"198.51.100.20\", \"port\": 5432}" --query Name --output text
quitanda/legacy-shop
ana@laptop:~/aws$ aws dms create-endpoint --endpoint-identifier legacy-shop --endpoint-type source --engine-name postgres --database-name shop --postgre-sql-settings SecretsManagerSecretId=quitanda/legacy-shop,SecretsManagerAccessRoleArn=arn:aws:iam::123456789012:role/quitanda-dms-secrets,SlotName=dms_orders,PluginName=test-decoding --query "Endpoint.[EndpointArn,Status,PostgreSQLSettings]"
[
    "arn:aws:dms:sa-east-1:123456789012:endpoint:GE4E4H18LLSZ4S5CLI4PY4BXH3G",
    "creating",
    {
        "SlotName": "dms_orders",
        "PluginName": "test-decoding",
        "SecretsManagerAccessRoleArn": "arn:aws:iam::123456789012:role/quitanda-dms-secrets",
        "SecretsManagerSecretId": "quitanda/legacy-shop"
    }
]
```

**`SlotName` e `PluginName` são a metade do PostgreSQL no CDC**, e a seção sobre o PostgreSQL mostra
o que eles são num servidor rodando: o nome do slot de replicação de onde o DMS vai ler as mudanças, e
o plugin que transforma o write-ahead log em linhas. O moto guardou os dois, e o segredo, exatamente
como foram dados. Ele não olhou dentro do segredo e não tentou chegar a `198.51.100.20`.

## O destino, e um teste que não testa nada

O primeiro destino da Quitanda é o lake, e não outro banco: os pedidos, e toda mudança neles, como
arquivos em `s3://quitanda-raw-prod/cdc/`, onde o Glue e o Athena das lições 15 a 17 conseguem lê-los.
Um endpoint de destino S3 indica o bucket, uma pasta e um papel que o DMS assume para escrever ali.

```
ana@laptop:~/aws$ aws dms create-endpoint --endpoint-identifier lake-raw --endpoint-type target --engine-name s3 --s3-settings BucketName=quitanda-raw-prod,BucketFolder=cdc,ServiceAccessRoleArn=arn:aws:iam::123456789012:role/quitanda-dms-s3 --query "Endpoint.[EndpointArn,Status]"
[
    "arn:aws:dms:sa-east-1:123456789012:endpoint:XKD63514ZWORV4H3HTCYH492I13",
    "creating"
]
ana@laptop:~/aws$ aws dms test-connection --replication-instance-arn arn:aws:dms:sa-east-1:123456789012:rep:quitanda-cdc --endpoint-arn arn:aws:dms:sa-east-1:123456789012:endpoint:GE4E4H18LLSZ4S5CLI4PY4BXH3G --query Connection.Status
"testing"
```

**`test-connection` é o que uma pessoa cuidadosa roda antes de uma tarefa**, e na AWS ele faz a
instância de replicação abrir de fato uma conexão com o endpoint, e depois informa `successful` ou
uma falha com o motivo. No moto ele responde `testing` e para por aí: não há nada em `198.51.100.20`
com que conectar, e o moto nem tenta.

## A tarefa

**A tarefa junta os três e acrescenta as duas decisões que são só dela**: o tipo de migração da seção
anterior, e o mapeamento de tabelas, um documento JSON que diz quais tabelas levar. O mapeamento mais
simples seleciona uma tabela. Salve-o como `mappings.json`:

`mappings.json`:

```json
{
  "rules": [
    {
      "rule-type": "selection",
      "rule-id": "1",
      "rule-name": "orders",
      "object-locator": {"schema-name": "public", "table-name": "orders"},
      "rule-action": "include"
    }
  ]
}
```

```
ana@laptop:~/aws$ aws dms create-replication-task --replication-task-identifier orders-to-lake --source-endpoint-arn arn:aws:dms:sa-east-1:123456789012:endpoint:GE4E4H18LLSZ4S5CLI4PY4BXH3G --target-endpoint-arn arn:aws:dms:sa-east-1:123456789012:endpoint:XKD63514ZWORV4H3HTCYH492I13 --replication-instance-arn arn:aws:dms:sa-east-1:123456789012:rep:quitanda-cdc --migration-type full-load-and-cdc --table-mappings file://mappings.json --query 'ReplicationTask.[Status,ReplicationTaskStats]'
[
    "creating",
    {
        "FullLoadProgressPercent": 100,
        "ElapsedTimeMillis": 100,
        "TablesLoaded": 1,
        "TablesLoading": 0,
        "TablesQueued": 0,
        "TablesErrored": 0
    }
]
ana@laptop:~/aws$ aws dms start-replication-task --replication-task-arn arn:aws:dms:sa-east-1:123456789012:task:orders-to-lake --start-replication-task-type start-replication --query ReplicationTask.Status
"running"
ana@laptop:~/aws$ aws dms describe-table-statistics --replication-task-arn arn:aws:dms:sa-east-1:123456789012:task:orders-to-lake

aws: [ERROR]: An error occurred (500) when calling the DescribeTableStatistics operation (reached max retries: 2): <!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
ana@laptop:~/aws$ aws s3 ls s3://quitanda-raw-prod/cdc/

aws: [ERROR]: An error occurred (NoSuchBucket) when calling the ListObjectsV2 operation: The specified bucket does not exist
ana@laptop:~/aws$ aws dms stop-replication-task --replication-task-arn arn:aws:dms:sa-east-1:123456789012:task:orders-to-lake --query ReplicationTask.Status
"stopped"
```

**Leia as estatísticas antes de acreditar nelas.** Na criação, antes de qualquer coisa ser iniciada,
o moto informou `FullLoadProgressPercent` 100 e uma tabela carregada. Nada foi carregado: a origem não
existe, e o bucket de destino também não, como mostra o último comando. São números que o moto escreve
em toda tarefa. As estatísticas por tabela, que na AWS dizem quantas linhas cada tabela recebeu por
inserção, alteração e exclusão, dão um `500`. **O laboratório consegue criar uma tarefa, iniciá-la e
pará-la, e não consegue replicar uma única linha**; como a replicação em si se parece é a seção sobre
o PostgreSQL, que lê mudanças reais de um log real.

## E a forma serverless

**O DMS Serverless não tem instância**: uma replication config leva os endpoints, o tipo, o
mapeamento e os limites de capacidade, tudo de uma vez. O moto 5.2.3 não a implementa:

```
ana@laptop:~/aws$ aws dms create-replication-config --replication-config-identifier orders-to-lake-serverless --source-endpoint-arn arn:aws:dms:sa-east-1:123456789012:endpoint:GE4E4H18LLSZ4S5CLI4PY4BXH3G --target-endpoint-arn arn:aws:dms:sa-east-1:123456789012:endpoint:XKD63514ZWORV4H3HTCYH492I13 --replication-type full-load-and-cdc --table-mappings file://mappings.json --compute-config MinCapacityUnits=2,MaxCapacityUnits=16

aws: [ERROR]: An error occurred (500) when calling the CreateReplicationConfig operation (reached max retries: 2): <!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
```

**Esse `500` é do moto, não do seu comando.** Na AWS a config seria criada, e a replicação começaria
quando você a iniciasse, com o DMS escolhendo uma capacidade entre os limites; o formato da chamada é o
documentado pela AWS, e ele não foi rodado aqui.
