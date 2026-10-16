---
title: O recurso de ninguém
version: 1
---

Seis recursos de quatro serviços, em `~/aws/owners` (`mkdir -p ~/aws/owners && cd ~/aws/owners`), alguns
feitos do jeito que as regras mandam e alguns feitos às pressas:

```sh
aws s3 mb s3://shop-orders
aws s3api put-bucket-tagging --bucket shop-orders --tagging 'TagSet=[{Key=owner,Value=checkout},{Key=environment,Value=prod}]'
aws s3 mb s3://tmp-test-ana
aws logs create-log-group --log-group-name /shop/api --tags owner=api,environment=prod
aws logs create-log-group --log-group-name /shop/old-batch
aws sqs create-queue --queue-name orders --tags owner=checkout
aws dynamodb create-table --table-name carts --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH --billing-mode PAY_PER_REQUEST
```

A **Resource Groups Tagging API** responde *que recursos têm esta tag* entre serviços numa chamada só, o que
a torna a ferramenta óbvia para achar donos. Ela tem um ponto cego, e o `owners.py` foi escrito em volta
dele: lista todo recurso dos quatro serviços pela API de cada serviço, e pergunta sobre cada um à API de
tags.

```python
# owners.py: every resource of four services, and which of them has no owner
import boto3

region = "sa-east-1"
account = boto3.client("sts").get_caller_identity()["Account"]

tags = {}
for page in boto3.client("resourcegroupstaggingapi").get_paginator("get_resources").paginate():
    for m in page["ResourceTagMappingList"]:
        tags[m["ResourceARN"]] = {t["Key"]: t["Value"] for t in m["Tags"]}

sqs = boto3.client("sqs")
arns = [f"arn:aws:s3:::{b['Name']}" for b in boto3.client("s3").list_buckets()["Buckets"]]
arns += [f"arn:aws:dynamodb:{region}:{account}:table/{t}"
         for t in boto3.client("dynamodb").list_tables()["TableNames"]]
arns += [sqs.get_queue_attributes(QueueUrl=u, AttributeNames=["QueueArn"])["Attributes"]["QueueArn"]
         for u in sqs.list_queues().get("QueueUrls", [])]
arns += [g["arn"].removesuffix(":*") for g in boto3.client("logs").describe_log_groups()["logGroups"]]

for arn in sorted(arns):
    known = arn in tags
    owner = tags.get(arn, {}).get("owner", "-")
    print(f"{owner:<10} {'' if known else 'not in the tagging API':<23} {arn}".rstrip())
```

```
ana@laptop:~/aws/owners$ python3 owners.py
-          not in the tagging API  arn:aws:dynamodb:sa-east-1:123456789012:table/carts
api                                arn:aws:logs:sa-east-1:123456789012:log-group:/shop/api
-          not in the tagging API  arn:aws:logs:sa-east-1:123456789012:log-group:/shop/old-batch
checkout                           arn:aws:s3:::shop-orders
-          not in the tagging API  arn:aws:s3:::tmp-test-ana
checkout                           arn:aws:sqs:sa-east-1:123456789012:orders
```

Três recursos não têm dono, e os três também **nem estão na API de tags**:

```
ana@laptop:~/aws/owners$ aws resourcegroupstaggingapi get-resources --query 'ResourceTagMappingList[].ResourceARN' --output text | tr '\t' '\n'
arn:aws:s3:::shop-orders
arn:aws:logs:sa-east-1:123456789012:log-group:/shop/api
arn:aws:sqs:sa-east-1:123456789012:orders
```

**A API de tags devolve recursos que têm tags, ou já tiveram.** Um recurso que nunca teve tag não aparece
como sem tag na resposta dela; ele está ausente. Um relatório feito só com ela, *recursos sem tag owner*,
não lista nada justamente dos recursos que existe para achar. É por isso que o `owners.py` começa pelo
inventário de cada serviço, e por isso que numa conta real o inventário melhor é o do AWS Config, da lição
21, que grava todo recurso suportado tenha ou não tag.

## Dando um dono

Alguém precisa decidir quem é dono de `carts`: a equipe de checkout, no fim. A API de tags põe tags em
recursos de qualquer serviço numa chamada:

```
ana@laptop:~/aws/owners$ aws resourcegroupstaggingapi tag-resources --resource-arn-list arn:aws:dynamodb:sa-east-1:123456789012:table/carts --tags owner=checkout,environment=prod --query FailedResourcesMap
ana@laptop:~/aws/owners$ python3 owners.py | grep carts
checkout                           arn:aws:dynamodb:sa-east-1:123456789012:table/carts
```

Os outros dois, `tmp-test-ana` e `/shop/old-batch`, são o par de sempre: um teste que alguém esqueceu, e os
restos de algo aposentado. Eles não recebem tag; recebem uma pergunta, e depois da semana de silêncio da
lição 23, são apagados.
