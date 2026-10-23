---
title: Uma trilha sua, e o que o moto faz com ela
version: 1
---

**Uma trilha são três decisões: para onde vão os registros, quais eventos eles incluem e se ela está
ligada.** Esta seção toma as três para a clínica. O moto aceita a configuração inteira e responde a
toda pergunta sobre ela; o que ele não faz é gravar um único registro. O fim da seção mostra isso
claramente, em vez de deixar um bucket quieto passar por uma conta quieta.

Inicie o moto com a verificação ligada, como a aula 6 fez, porque a seção depois da próxima depende
de uma recusa:

```sh
INITIAL_NO_AUTH_ACTION_COUNT=3 moto_server -p 4567
```

As mesmas três requisições criam o `admin`, e o terminal passa para a chave do admin:

```
ana@laptop:~/aws$ aws iam create-user --user-name admin --query User.Arn --output text
arn:aws:iam::123456789012:user/admin
ana@laptop:~/aws$ aws iam attach-user-policy --user-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
ana@laptop:~/aws$ key=$(aws iam create-access-key --user-name admin)
ana@laptop:~/aws$ aws iam list-users

aws: [ERROR]: An error occurred (InvalidClientTokenId) when calling the ListUsers operation: The security token included in the request is invalid.
ana@laptop:~/aws$ export AWS_ACCESS_KEY_ID=$(echo "$key" | jq -r .AccessKey.AccessKeyId) AWS_SECRET_ACCESS_KEY=$(echo "$key" | jq -r .AccessKey.SecretAccessKey)
ana@laptop:~/aws$ aws sts get-caller-identity --query Arn --output text
arn:aws:iam::123456789012:user/admin
```

## Para onde vão os registros

Um bucket só para eles, `clinic-trail`. O CloudTrail grava nele como o serviço
`cloudtrail.amazonaws.com`, então a política do bucket precisa deixar o serviço conferir o bucket e
gravar em `AWSLogs/` com o número da conta. Esta é a política que a documentação da AWS dá, com os
nomes da clínica; salve-a como `trail-bucket-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSCloudTrailAclCheck",
      "Effect": "Allow",
      "Principal": { "Service": "cloudtrail.amazonaws.com" },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::clinic-trail",
      "Condition": {
        "StringEquals": { "aws:SourceArn": "arn:aws:cloudtrail:sa-east-1:123456789012:trail/clinic-trail" }
      }
    },
    {
      "Sid": "AWSCloudTrailWrite",
      "Effect": "Allow",
      "Principal": { "Service": "cloudtrail.amazonaws.com" },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::clinic-trail/AWSLogs/123456789012/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control",
          "aws:SourceArn": "arn:aws:cloudtrail:sa-east-1:123456789012:trail/clinic-trail"
        }
      }
    }
  ]
}
```

A condição `aws:SourceArn` é o confused deputy da aula 13 de novo: o serviço pode gravar aqui em nome
desta trilha, e não em nome de uma trilha na conta de outra pessoa que aponte para o seu bucket.

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket clinic-trail --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/clinic-trail
ana@laptop:~/aws$ aws s3api put-bucket-policy --bucket clinic-trail --policy file://trail-bucket-policy.json
```

Sem essa política, a AWS se recusa a criar a trilha, com `InsufficientS3BucketPolicyException`. O moto
a cria de qualquer jeito; essa recusa não foi executada aqui.

## Quais eventos, e ligando

Duas opções na criação importam. `--is-multi-region-trail` registra todas as regiões na mesma trilha,
então um recurso iniciado numa região que ninguém olha ainda deixa registro: as 38 redes padrão da
aula 1 são o motivo. `--enable-log-file-validation` faz o CloudTrail gravar um arquivo de *digest*
assinado a cada hora, que a seção depois da próxima usa.

```
ana@laptop:~/aws$ aws cloudtrail create-trail --name clinic-trail --s3-bucket-name clinic-trail --is-multi-region-trail --enable-log-file-validation
{
    "Name": "clinic-trail",
    "S3BucketName": "clinic-trail",
    "IncludeGlobalServiceEvents": true,
    "IsMultiRegionTrail": true,
    "TrailARN": "arn:aws:cloudtrail:sa-east-1:123456789012:trail/clinic-trail",
    "LogFileValidationEnabled": true,
    "IsOrganizationTrail": false
}
```

Só os eventos de gerenciamento responderiam quem tornou um bucket público, e não quem o leu enquanto
estava. Os eventos de dados que valem o que custam são os dos dois buckets com dados de pacientes.
Salve os seletores como `selectors.json`:

```json
[
  {
    "Name": "management",
    "FieldSelectors": [
      { "Field": "eventCategory", "Equals": ["Management"] }
    ]
  },
  {
    "Name": "patient-data",
    "FieldSelectors": [
      { "Field": "eventCategory", "Equals": ["Data"] },
      { "Field": "resources.type", "Equals": ["AWS::S3::Object"] },
      { "Field": "resources.ARN", "StartsWith": ["arn:aws:s3:::clinic-records/", "arn:aws:s3:::clinic-exports/"] }
    ]
  }
]
```

```
ana@laptop:~/aws$ aws cloudtrail put-event-selectors --trail-name clinic-trail --advanced-event-selectors file://selectors.json --query "AdvancedEventSelectors[].Name"
[
    "management",
    "patient-data"
]
ana@laptop:~/aws$ aws cloudtrail start-logging --name clinic-trail
```

## O status, e o bucket

```
ana@laptop:~/aws$ aws cloudtrail get-trail-status --name clinic-trail
{
    "IsLogging": true,
    "LatestDeliveryTime": "2026-10-23T04:05:05-03:00",
    "StartLoggingTime": "2026-10-23T04:05:05-03:00",
    "LatestDeliveryAttemptTime": "2026-10-23T04:05:05Z",
    "LatestNotificationAttemptTime": "",
    "LatestNotificationAttemptSucceeded": "",
    "LatestDeliveryAttemptSucceeded": "",
    "TimeLoggingStarted": "2026-10-23T04:05:05Z",
    "TimeLoggingStopped": ""
}
```

**`IsLogging` é `true`, e o moto ainda informa um horário de entrega. Agora olhe dentro do bucket**, e
aproveite para perguntar ao histórico de eventos da própria conta:

```
ana@laptop:~/aws$ aws s3 ls s3://clinic-trail --recursive
ana@laptop:~/aws$ aws cloudtrail lookup-events --max-results 5 2>&1 | head -2

aws: [ERROR]: An error occurred (500) when calling the LookupEvents operation (reached max retries: 2): <!doctype html>
```

O bucket está vazio e o histórico responde com um erro interno. **O moto guarda a configuração de uma
trilha e não registra evento nenhum.** Na AWS, minutos depois do `start-logging`, o bucket teria
arquivos compactados em `AWSLogs/123456789012/CloudTrail/sa-east-1/` e uma pasta por dia, e o
`lookup-events` listaria as chamadas que você acabou de fazer, entre elas o `StartLogging`. Nenhuma
das duas coisas foi executada aqui.

A lição da lacuna do moto é uma de que você precisa na AWS também: **um status dizendo que registra
não é prova de que os registros existem.** A verificação que conta é a que você acabou de fazer, abrir
o bucket e achar arquivos de hoje. A próxima seção lê registros, e como o moto não grava nenhum, eles
vêm de um arquivo que a aula entrega a você.
