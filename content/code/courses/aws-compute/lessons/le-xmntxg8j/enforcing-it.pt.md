---
title: "Exigindo o IMDSv2: por instância, por template, por conta"
version: 1
---

O IMDSv2 não protege nada enquanto o IMDSv1 continua respondendo ao lado dele. **Uma instância
com `HttpTokens` em `optional` aceita os dois, então o `GET` forjado da última seção ainda
funciona nela**, e `optional` é o que uma instância recebe quando ninguém diz o contrário e a
imagem dela também não. O trabalho desta seção é fazer de `required` o estado que ninguém precisa
lembrar, em quatro níveis, de uma instância até a organização inteira.

## Uma instância, no lançamento

`--metadata-options` recebe as três configurações que importam, e a resposta as mostra
aplicadas:

```
ana@laptop:~/aws$ aws ec2 run-instances --image-id "$AMI" --instance-type t3.micro --metadata-options HttpTokens=required,HttpPutResponseHopLimit=1,HttpEndpoint=enabled --query "Instances[0].[InstanceId,MetadataOptions]"
[
    "i-1ec13ad5f7dd6ffd8",
    {
        "State": "applied",
        "HttpTokens": "required",
        "HttpPutResponseHopLimit": 1,
        "HttpEndpoint": "enabled",
        "HttpProtocolIpv6": "disabled",
        "InstanceMetadataTags": "disabled"
    }
]
```

`HttpTokens=required` recusa qualquer leitura sem token. `HttpPutResponseHopLimit=1` mantém o
token na instância, como a última seção desenhou. `HttpEndpoint=enabled` mantém o serviço ligado;
`disabled` o desliga, o que é certo para uma instância sem role e sem uso para os próprios
metadados, e errado para quase todo o resto, já que os SDKs ficam mudos sem ele.

## Uma instância, enquanto roda

Uma instância lançada sem as opções diz `optional`, e pode ser mudada sem stop nem reboot:

```
ana@laptop:~/aws$ OLD=$(aws ec2 run-instances --image-id "$AMI" --instance-type t3.micro --query "Instances[0].InstanceId" --output text)
ana@laptop:~/aws$ aws ec2 describe-instances --instance-ids "$OLD" --query "Reservations[0].Instances[0].MetadataOptions.HttpTokens" --output text
optional
ana@laptop:~/aws$ aws ec2 modify-instance-metadata-options --instance-id "$OLD" --http-tokens required --http-endpoint enabled
{
    "InstanceId": "i-51e1cd95bf0fae843",
    "InstanceMetadataOptions": {
        "State": "applied",
        "HttpTokens": "required",
        "HttpPutResponseHopLimit": 1,
        "HttpEndpoint": "enabled"
    }
}
```

Na AWS o `State` fica em `pending` até a mudança chegar à instância e em `applied` depois; o moto
aplica na hora. **Faça isso numa frota em execução só quando souber que nada nela ainda fala
IMDSv1**, porque a chamada vale para todo programa da instância no mesmo instante. Os SDKs da AWS
falam IMDSv2 desde que ele foi lançado, em 2019, então os programas que quebram são os antigos: um
SDK de antes disso, um agente de monitoramento que ninguém atualizou, um shell script com um
`curl` sem cabeçalho. O EC2 os conta para você. Toda instância publica uma métrica do CloudWatch,
`MetadataNoToken`, com as leituras de metadados que ela respondeu sem token, e uma frota cuja
métrica ficou em zero por umas duas semanas é uma em que `required` não quebra nada. Ler essa
métrica e criar alarmes nela é a aula 8 de `aws-operations`; o moto não guarda métricas, então isso
não aparece aqui.

## Toda instância de um template

Configurar instância por instância é como uma frota acaba com uma instância que ninguém
configurou. **O lugar disso é o launch template**, para que toda instância lançada dele, por uma
pessoa ou por um grupo de auto scaling, comece com token obrigatório:

```
ana@laptop:~/aws$ aws ec2 create-launch-template --launch-template-name web --launch-template-data "{\"ImageId\":\"$AMI\",\"InstanceType\":\"t3.micro\",\"MetadataOptions\":{\"HttpTokens\":\"required\",\"HttpPutResponseHopLimit\":1}}" --query LaunchTemplate.LatestVersionNumber
1
ana@laptop:~/aws$ aws ec2 describe-launch-template-versions --launch-template-name web --query "LaunchTemplateVersions[0].LaunchTemplateData.MetadataOptions"
{
    "HttpTokens": "required",
    "HttpPutResponseHopLimit": 1
}
```

A aula 4 montou os launch templates e os grupos que os usam. Uma nova versão do template com estas
opções, distribuída por um instance refresh, é também como um grupo existente passa para o IMDSv2
sem ninguém tocar numa instância.

A imagem pode levar a mesma exigência. Uma AMI registrada com `--imds-support v2.0` dá a toda
instância lançada dela `HttpTokens` em `required`, e **as imagens do Amazon Linux 2023 são
publicadas assim**. O catálogo do moto copia os nomes das imagens da AWS, não essa marcação:

```
ana@laptop:~/aws$ aws ec2 describe-images --image-ids "$AMI" --query "Images[0].[Name,ImdsSupport]" --output text
al2023-ami-2023.12.20260727.0-kernel-6.12-x86_64	None
```

`None` é o moto sem valor para o campo. É também por isso que a `$OLD`, lançada desta mesma imagem
alguns comandos atrás, disse `optional`; na AWS teria dito `required`.

## Toda instância de uma região, e toda conta

Dois níveis ficam acima do template. **O padrão da conta** define as opções de metadados de toda
instância lançada numa região da conta que não as defina por conta própria:
`aws ec2 modify-instance-metadata-defaults --http-tokens required`. Ele não muda nada que já esteja
rodando, e um lançamento que diz as próprias opções continua valendo. O moto 5.2.3 não implementa
isso, e a chamada falha dentro do moto em vez de com um erro da AWS:

```
ana@laptop:~/aws$ aws ec2 modify-instance-metadata-defaults --http-tokens required 2>&1 | head -3 | cut -c1-100

aws: [ERROR]: Unable to parse response (syntax error: line 1, column 0), invalid XML received. Furth
b'<!doctype html>\n<html lang=en>\n<title>500 Internal Server Error</title>\n<h1>Internal Server Err
```

Esse `500 Internal Server Error` é do moto, e o comando é o que a AWS documenta; na AWS ele
responde com `"Return": true`.

**Uma política é o nível que ninguém consegue esquecer.** O IAM pode recusar o próprio lançamento
quando o pedido não exige token, pela chave de condição `ec2:MetadataHttpTokens`. Esta é a forma
que a AWS documenta. Ela é associada às pessoas e roles que lançam instâncias, ou escrita como
service control policy sobre todas as contas de uma organização:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "RequireImdsV2",
      "Effect": "Deny",
      "Action": "ec2:RunInstances",
      "Resource": "arn:aws:ec2:*:*:instance/*",
      "Condition": {
        "StringNotEquals": { "ec2:MetadataHttpTokens": "required" }
      }
    }
  ]
}
```

Um `Deny` vence qualquer `Allow`, como a aula 8 de `aws-foundations` trabalhou, então um lançamento
que deixa o token opcional é recusado seja quem for que peça. Uma segunda instrução negando
`ec2:ModifyInstanceMetadataOptions` a todos menos aos administradores impede que alguém volte
atrás depois. Esta política não foi rodada: o moto não avalia políticas IAM por padrão, e a chave
de condição não é uma que ele conheça.

## O que o moto deixa passar

O moto guarda o que recebe, e isso inclui valores que a AWS recusa:

```
ana@laptop:~/aws$ aws ec2 modify-instance-metadata-options --instance-id "$OLD" --http-put-response-hop-limit 65 --http-tokens sometimes
{
    "InstanceId": "i-51e1cd95bf0fae843",
    "InstanceMetadataOptions": {
        "State": "applied",
        "HttpTokens": "sometimes",
        "HttpPutResponseHopLimit": 65
    }
}
```

**A AWS aceita `optional` ou `required` em `HttpTokens`, e um hop limit de 1 a 64.** O moto aceitou
`sometimes` e 65 e os reportou como `applied`. Um template ou um script que funciona contra o moto
foi conferido na forma, não nos valores, e o primeiro lançamento na AWS é onde um erro de digitação
num deles aparece.
