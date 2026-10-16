---
title: Respondendo "quem fez isto?"
version: 1
---

Na manhã de 16 de outubro o bucket de exportações antigas sumiu, e o security group do banco perdeu uma
regra. A pergunta não é a quem culpar; a revisão da lição 13 é sem culpa. É **o que aconteceu**, e o nome
no registro é a pessoa a quem perguntar o que ela sabia na hora.

## O histórico de eventos, que o moto não tem

Na AWS o primeiro lugar a olhar é o histórico de eventos, por um atributo:

```
ana@laptop:~/aws/trail$ aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=DeleteBucket 2>&1 | grep -m1 ERROR
aws: [ERROR]: An error occurred (500) when calling the LookupEvents operation (reached max retries: 2): <!doctype html>
```

O moto responde 500. Na AWS isto devolve os eventos `DeleteBucket` dos últimos noventa dias, do mais novo
para o mais antigo, com o registro de cada um em `CloudTrailEvent`. Um atributo por vez é o limite dele:
*toda mudança que o bruno fez naquela tarde* não é uma pergunta só para ele.

## Os arquivos da trilha

O bucket da trilha guarda os arquivos, e um dia deles é do que o laboratório precisa. O moto não entrega
nenhum, então `mk-trail.py` inventa um dia da loja no mesmo formato, uma pasta por conta, região e data, um
arquivo JSON compactado com gzip por entrega, com trinta leituras de rotina do pipeline e quatro coisas que
pessoas fizeram:

```python
# mk-trail.py: one made-up day of the shop's CloudTrail, in the layout a trail delivers
import datetime as dt
import gzip
import json
import os
import random

ACCOUNT, REGION = "123456789012", "sa-east-1"
rand = random.Random(20)


def who(role, session):
    return {
        "type": "AssumedRole",
        "arn": f"arn:aws:sts::{ACCOUNT}:assumed-role/{role}/{session}",
        "accountId": ACCOUNT,
        "sessionContext": {"sessionIssuer": {"type": "Role", "userName": role,
                                             "arn": f"arn:aws:iam::{ACCOUNT}:role/{role}"}},
    }


def record(at, identity, source, name, ip, agent, params, error=None):
    r = {"eventVersion": "1.11", "eventTime": at.strftime("%Y-%m-%dT%H:%M:%SZ"),
         "eventSource": source, "eventName": name, "awsRegion": REGION,
         "sourceIPAddress": ip, "userAgent": agent, "userIdentity": identity,
         "requestParameters": params, "eventType": "AwsApiCall",
         "readOnly": name.startswith(("Describe", "Get", "List"))}
    if error:
        r["errorCode"], r["errorMessage"] = error
    return r


start = dt.datetime(2026, 10, 15, tzinfo=dt.timezone.utc)
deploy, ana, bruno = who("shop-deploy", "pipeline"), who("shop-admin", "ana"), who("shop-admin", "bruno")
records = []
for minute in sorted(rand.sample(range(24 * 60), 30)):  # the pipeline's routine reads
    at = start + dt.timedelta(minutes=minute)
    records.append(record(at, deploy, "ecs.amazonaws.com", "DescribeServices", "codepipeline.amazonaws.com",
                          "codepipeline.amazonaws.com", {"cluster": "shop", "services": ["api"]}))
the_day = [
    (9, 12, ana, "s3.amazonaws.com", "ListBuckets", "203.0.113.24", {}, None),
    (14, 3, bruno, "ec2.amazonaws.com", "RevokeSecurityGroupIngress", "198.51.100.77",
     {"groupId": "sg-0shopdb", "ipPermissions": {"items": [{"fromPort": 5432, "toPort": 5432}]}}, None),
    (14, 5, bruno, "s3.amazonaws.com", "DeleteBucket", "198.51.100.77", {"bucketName": "shop-exports-old"}, None),
    (16, 40, ana, "kms.amazonaws.com", "ScheduleKeyDeletion", "203.0.113.24",
     {"keyId": "alias/shop-orders", "pendingWindowInDays": 7},
     ("AccessDenied", "User is not authorized to perform: kms:ScheduleKeyDeletion")),
]
for hour, minute, identity, source, name, ip, params, error in the_day:
    at = start + dt.timedelta(hours=hour, minutes=minute)
    records.append(record(at, identity, source, name, ip, "aws-cli/2.37.4", params, error))

records.sort(key=lambda r: r["eventTime"])
for hour in range(24):  # a trail delivers a file every few minutes; here, one per hour
    batch = [r for r in records if r["eventTime"][11:13] == f"{hour:02d}"]
    if not batch:
        continue
    folder = f"AWSLogs/{ACCOUNT}/CloudTrail/{REGION}/2026/10/15"
    os.makedirs(folder, exist_ok=True)
    name = f"{ACCOUNT}_CloudTrail_{REGION}_20261015T{hour:02d}00Z_lab.json.gz"
    with gzip.open(os.path.join(folder, name), "wt") as f:
        json.dump({"Records": batch}, f)
print(len(records), "records written")
```

O programa grava os arquivos localmente; copiá-los para o bucket faz o papel da entrega do CloudTrail, e
dali eles são buscados como uma investigação de verdade os busca:

```
ana@laptop:~/aws/trail$ python3 mk-trail.py
34 records written
ana@laptop:~/aws/trail$ aws s3 cp --recursive --quiet AWSLogs s3://shop-trail-123456789012/AWSLogs
ana@laptop:~/aws/trail$ aws s3 ls s3://shop-trail-123456789012 --recursive | awk 'NR <= 2'
2026-10-16 16:49:05        418 AWSLogs/123456789012/CloudTrail/sa-east-1/2026/10/15/123456789012_CloudTrail_sa-east-1_20261015T0000Z_lab.json.gz
2026-10-16 16:49:05        418 AWSLogs/123456789012/CloudTrail/sa-east-1/2026/10/15/123456789012_CloudTrail_sa-east-1_20261015T0200Z_lab.json.gz
ana@laptop:~/aws/trail$ rm -r AWSLogs && aws s3 sync --quiet s3://shop-trail-123456789012/AWSLogs AWSLogs && find AWSLogs -name "*.json.gz" | wc -l
18
```

## Quatro perguntas, um comando cada

Toda consulta é o mesmo pipe: `find` acha os arquivos, `zcat` os junta num fluxo só, e o `jq` escolhe.
**Quem apagou o bucket?**

```
ana@laptop:~/aws/trail$ find AWSLogs -name '*.json.gz' -exec zcat {} + | jq -c '.Records[] | select(.eventName == "DeleteBucket") | [.eventTime, .userIdentity.arn, .sourceIPAddress, .requestParameters.bucketName]'
["2026-10-15T14:05:00Z","arn:aws:sts::123456789012:assumed-role/shop-admin/bruno","198.51.100.77","shop-exports-old"]
```

O bruno, pela role `shop-admin`, de 198.51.100.77, às 14:05 UTC. **O que as pessoas mudaram naquele dia?**
As leituras ficam de fora com `readOnly`, o que deixa só as mudanças, cada uma com a role, o nome da sessão
e se funcionou:

```
ana@laptop:~/aws/trail$ find AWSLogs -name '*.json.gz' -exec zcat {} + | jq -r '.Records[] | select(.readOnly == false) | [.eventTime, .userIdentity.sessionContext.sessionIssuer.userName, (.userIdentity.arn | split("/")[-1]), .eventName, .errorCode // "-"] | @tsv' | sort
2026-10-15T14:03:00Z	shop-admin	bruno	RevokeSecurityGroupIngress	-
2026-10-15T14:05:00Z	shop-admin	bruno	DeleteBucket	-
2026-10-15T16:40:00Z	shop-admin	ana	ScheduleKeyDeletion	AccessDenied
```

Dois minutos antes do bucket, a mesma sessão revogou a regra da porta 5432 no security group do banco: as
duas mudanças que a manhã notou, de uma pessoa numa sessão, o que é uma conversa e não uma investigação. A
terceira linha falhou, e **vale ler uma falha**:

```
ana@laptop:~/aws/trail$ find AWSLogs -name '*.json.gz' -exec zcat {} + | jq -r '.Records[] | select(.errorCode) | .errorMessage'
User is not authorized to perform: kms:ScheduleKeyDeletion
```

A Ana tentou agendar a exclusão da chave de pedidos e foi recusada, que é a política de chave da lição 18
fazendo o seu trabalho, e uma boa pergunta para a próxima passagem de plantão. **Quem estava ocupado?**

```
ana@laptop:~/aws/trail$ find AWSLogs -name '*.json.gz' -exec zcat {} + | jq -r '.Records[] | .userIdentity.arn' | sort | uniq -c
      2 arn:aws:sts::123456789012:assumed-role/shop-admin/ana
      2 arn:aws:sts::123456789012:assumed-role/shop-admin/bruno
     30 arn:aws:sts::123456789012:assumed-role/shop-deploy/pipeline
```

Trinta chamadas do pipeline e quatro de pessoas. Numa conta real o mesmo comando, sobre um mês, é como uma
equipe acha a role de que ninguém lembra e que ainda faz chamadas a cada hora.

Na AWS as mesmas consultas rodam sem baixar nada, no **CloudTrail Lake**, que guarda eventos no próprio
armazenamento e responde SQL, ou no Athena sobre o bucket; os dois cobram por gigabyte varrido. Para uma
pergunta feita uma vez, `jq` sobre os arquivos de um dia basta.
