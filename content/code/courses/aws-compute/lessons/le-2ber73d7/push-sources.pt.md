---
title: "Origens push: uma URL, e um bucket que chama"
version: 1
---

Uma origem push precisa de duas coisas configuradas, e as pessoas configuram uma. **A origem precisa
ser instruída a chamar a função, e a função precisa permitir que a origem a chame.** A segunda é uma
declaração na política baseada em recurso da própria função, que a aula 7 de `aws-foundations`
apresentou como a outra metade do IAM: uma política presa à coisa que se quer alcançar, nomeando
quem pode alcançá-la. Esqueça dela e a origem fica perfeitamente configurada e nada nunca chega.

Duas funções servem a esta aula. Elas são criadas no moto a partir de zips feitos do jeito que a aula
14 fez o `greet`, com um role igual ao `greet-role`; `thumbs` é o handler mais abaixo nesta seção, e
`orders` é o da seção 04:

```
ana@laptop:~/aws$ aws lambda create-function --function-name thumbs --runtime python3.12 --handler thumbs.handler --role arn:aws:iam::123456789012:role/trigger-role --zip-file fileb://thumbs.zip --query FunctionArn
"arn:aws:lambda:sa-east-1:123456789012:function:thumbs"
ana@laptop:~/aws$ aws lambda create-function --function-name orders --runtime python3.12 --handler orders.handler --role arn:aws:iam::123456789012:role/trigger-role --zip-file fileb://orders.zip --query FunctionArn
"arn:aws:lambda:sa-east-1:123456789012:function:orders"
```

## Uma URL de função

O chamador síncrono mais simples é uma **URL de função**: um endereço HTTPS que pertence a uma
função, sem API nenhuma na frente.

```
ana@laptop:~/aws$ aws lambda create-function-url-config --function-name orders --auth-type AWS_IAM
{
    "FunctionUrl": "https://231a86d105a2406d9da391d40f50dfbc.lambda-url.sa-east-1.on.aws",
    "FunctionArn": "arn:aws:lambda:sa-east-1:123456789012:function:orders",
    "AuthType": "AWS_IAM",
    "CreationTime": "2026-10-16T16:50:05.000+0000",
    "InvokeMode": "Buffered"
}
```

`AWS_IAM` quer dizer que um pedido precisa ser assinado com credenciais que tenham
`lambda:InvokeFunctionUrl`, o que serve para quem chama sendo outro serviço ou programa da AWS. `NONE`
torna a URL pública, e então a política da função também precisa dizer isso, com uma declaração que
permita o principal `*`. O moto inventa o endereço e não serve nada nele. **O API Gateway é a outra
porta de entrada síncrona**, com o que falta a uma URL de função: rotas, autorizadores, limitação de
taxa e planos de uso, e a aula 19 é sobre ele. Nos dois casos, o evento que o handler recebe é a
descrição de um pedido HTTP, com método, caminho, cabeçalhos e corpo, num formato chamado payload
2.0, e o que o handler devolve vira a resposta.

## Um bucket que chama uma função

O S3 invoca de forma assíncrona, então as miniaturas da loja podem ser feitas depois de um envio sem
que quem enviou espere. A permissão vem primeiro, limitada a um bucket de uma conta:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket shop-uploads-123456789012 --create-bucket-configuration LocationConstraint=sa-east-1 --query Location
"/shop-uploads-123456789012"
ana@laptop:~/aws$ aws lambda add-permission --function-name thumbs --statement-id s3-uploads --action lambda:InvokeFunction --principal s3.amazonaws.com --source-arn arn:aws:s3:::shop-uploads-123456789012 --source-account 123456789012 --query Statement --output text | jq .
{
  "Action": "lambda:InvokeFunction",
  "Principal": {
    "Service": "s3.amazonaws.com"
  },
  "Effect": "Allow",
  "Resource": "arn:aws:lambda:sa-east-1:123456789012:function:thumbs",
  "Sid": "s3-uploads",
  "Condition": {
    "ArnLike": {
      "AWS:SourceArn": "arn:aws:s3:::shop-uploads-123456789012"
    },
    "StringEquals": {
      "AWS:SourceAccount": "123456789012"
    }
  }
}
```

As duas condições importam. `AWS:SourceArn` limita a permissão a este bucket. `AWS:SourceAccount`
acrescenta o dono, porque o nome de um bucket é global, e um bucket com o mesmo nome em outra conta,
criado depois que o seu foi apagado, casaria com o ARN se não fosse ela. Depois, o lado do bucket,
para objetos criados em `uploads/`:

```
ana@laptop:~/aws$ aws s3api put-bucket-notification-configuration --bucket shop-uploads-123456789012 --notification-configuration '{"LambdaFunctionConfigurations": [{"LambdaFunctionArn": "arn:aws:lambda:sa-east-1:123456789012:function:thumbs", "Events": ["s3:ObjectCreated:*"], "Filter": {"Key": {"FilterRules": [{"Name": "prefix", "Value": "uploads/"}]}}}]}'
ana@laptop:~/aws$ aws s3api get-bucket-notification-configuration --bucket shop-uploads-123456789012 --query 'LambdaFunctionConfigurations[0].[LambdaFunctionArn,Events[0]]'
[
    "arn:aws:lambda:sa-east-1:123456789012:function:thumbs",
    "s3:ObjectCreated:*"
]
```

Na AWS, o S3 confere o destino quando você salva a configuração, e se a política da função não deixa
o S3 entrar, a chamada falha com `Unable to validate the following destination configurations`. **O
moto não confere**, e é fácil mostrar:

```
ana@laptop:~/aws$ aws s3api put-bucket-notification-configuration --bucket shop-uploads-123456789012 --notification-configuration '{"LambdaFunctionConfigurations": [{"LambdaFunctionArn": "arn:aws:lambda:sa-east-1:123456789012:function:no-such-function", "Events": ["s3:ObjectCreated:*"]}]}' && echo accepted
accepted
```

Uma notificação para uma função que não existe, aceita. Na AWS essa chamada é recusada; ela não foi
executada contra a AWS aqui. E o moto não roda função nenhuma, então um envio para este bucket agora
não chega a lugar nenhum.

## O que o S3 envia

Para ver o próprio evento, aponte o bucket para uma fila SQS, para a qual o moto entrega de verdade.
Na AWS uma fila como destino precisa de uma política de acesso que deixe o S3 enviar para ela; o moto
não pede. **Repare que esta segunda chamada substitui a primeira configuração em vez de somar a
ela**: `put-bucket-notification-configuration` escreve o conjunto inteiro, então a configuração do
Lambda acima sumiu, como sumiria na AWS. Depois, um envio dentro de `uploads/` e um fora dele:

```
ana@laptop:~/aws$ aws sqs create-queue --queue-name s3-witness --query QueueUrl
"http://localhost:4567/123456789012/s3-witness"
ana@laptop:~/aws$ aws s3api put-bucket-notification-configuration --bucket shop-uploads-123456789012 --notification-configuration '{"QueueConfigurations": [{"QueueArn": "arn:aws:sqs:sa-east-1:123456789012:s3-witness", "Events": ["s3:ObjectCreated:*"], "Filter": {"Key": {"FilterRules": [{"Name": "prefix", "Value": "uploads/"}]}}}]}'
ana@laptop:~/aws$ aws s3api put-object --bucket shop-uploads-123456789012 --key uploads/cat.jpg --body photo.jpg --query ETag
"\"764efa883dda1e11db47671c4a3bbd9e\""
ana@laptop:~/aws$ aws s3api put-object --bucket shop-uploads-123456789012 --key drafts/dog.jpg --body photo.jpg --query ETag
"\"764efa883dda1e11db47671c4a3bbd9e\""
ana@laptop:~/aws$ aws sqs receive-message --queue-url http://localhost:4567/123456789012/s3-witness --max-number-of-messages 10 --visibility-timeout 0 --query 'Messages[].Body' | jq -r '.[]' | cut -c1-90
{"Service": "Amazon S3", "Event": "s3:TestEvent", "Time": "2026-10-16T16:50:10.980Z", "Buc
{"Records": [{"eventVersion": "2.1", "eventSource": "aws:s3", "awsRegion": "sa-east-1", "e
```

Duas mensagens para um envio que casou. A primeira é `s3:TestEvent`, que o S3 também envia a uma fila
na AWS quando uma configuração é salva, e que todo consumidor de uma fila alimentada por um bucket
precisa esperar e ignorar; a segunda é o envio. `drafts/dog.jpg` não mandou nada, porque o filtro de
prefixo o deixou de fora. Guarde o evento de verdade num arquivo e olhe para ele:

```
ana@laptop:~/aws$ aws sqs receive-message --queue-url http://localhost:4567/123456789012/s3-witness --max-number-of-messages 10 --visibility-timeout 0 --query 'Messages[].Body' | jq -r '.[]' | grep Records > s3-event.json
ana@laptop:~/aws$ jq . s3-event.json
{
  "Records": [
    {
      "eventVersion": "2.1",
      "eventSource": "aws:s3",
      "awsRegion": "sa-east-1",
      "eventTime": "2026-10-16T16:50:11.639Z",
      "eventName": "ObjectCreated:Put",
      "s3": {
        "s3SchemaVersion": "1.0",
        "configurationId": "ak3LBhCG4mVjeCDbT1JuWHUamWefdqjeJoZ5mxR9vscRcIv71k",
        "bucket": {
          "name": "shop-uploads-123456789012",
          "arn": "arn:aws:s3:::shop-uploads-123456789012"
        },
        "object": {
          "key": "uploads%2Fcat.jpg",
          "size": 3,
          "eTag": "764efa883dda1e11db47671c4a3bbd9e"
        }
      }
    }
  ]
}
```

**Um evento pode ter vários registros**, e por isso tudo fica dentro de `Records`. A chave chega
codificada para URL, aqui `uploads%2Fcat.jpg`, e a AWS documenta a mesma codificação; um handler que
a usasse como chega procuraria um objeto com `%2F` no nome. O evento da própria AWS traz mais campos
que o do moto, entre eles quem fez o pedido e um `sequencer` para ordenar os eventos de uma chave, e o
handler deve ler só o que precisa. Este lê o bucket e a chave. Salve como `~/aws/thumbs/thumbs.py`:

```python
# thumbs.py
from urllib.parse import unquote_plus


def handler(event, context):
    done = []
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = unquote_plus(record['s3']['object']['key'])
        print(f'would resize s3://{bucket}/{key}')
        done.append(key)
    return {'resized': done}
```

e dê a ele o evento que o moto escreveu, pelo emulador da aula 14:

```
ana@laptop:~/aws$ docker run --rm -d --name thumbs -p 9000:8080 -v "$PWD/thumbs":/var/task:ro public.ecr.aws/lambda/python:3.12 thumbs.handler
06e0b07f844444689cf4c96e27dbc23e6da45e414cbf2853aeccf78405f2a0ce
ana@laptop:~/aws$ curl -s -XPOST localhost:9000/2015-03-31/functions/function/invocations -d @s3-event.json; echo
{"resized": ["uploads/cat.jpg"]}
ana@laptop:~/aws$ docker logs thumbs 2>&1 | grep resize
would resize s3://shop-uploads-123456789012/uploads/cat.jpg
ana@laptop:~/aws$ docker stop thumbs
thumbs
```

`unquote_plus` transformou a chave de volta em `uploads/cat.jpg`, uma chave que o S3 encontraria.
**Uma função de miniaturas que escreve no mesmo bucket com o mesmo prefixo chama a si mesma**, uma
vez por miniatura, enquanto alguém deixar: a saída é um evento `ObjectCreated` em `uploads/` como
qualquer outro. Escrever os resultados em outro prefixo, ou em outro bucket, é a saída comum, e a AWS
acrescentou uma verificação de recursão que interrompe alguns desses laços; ela não é motivo para
construir um.
