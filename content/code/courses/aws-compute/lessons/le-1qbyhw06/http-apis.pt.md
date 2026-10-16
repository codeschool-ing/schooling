---
title: "HTTP APIs: rotas, JWT e payload 2.0"
version: 1
---

Uma HTTP API costuma ser descrita como uma REST API reduzida, e a descrição faz as pessoas
esperarem um produto menor. **É um desenho diferente e menor**, anunciado no fim de 2019 para o
caso que a maioria das APIs tinha virado: um cliente, um token, e uma função ou um servidor web
atrás de uma rota. Ela abre mão dos mapping templates, dos usage plans e do cache, e em troca é
mais simples de montar, se implanta sozinha e verifica um JSON Web Token sem código nenhum seu.
Ela também custa bem menos da metade por requisição.

## Mais barata, quanto

A tabela da aula 1 imprime os dois preços, como publicados em 16 de outubro de 2026:

```
ana@laptop:~/aws$ python3 prices.py integration | sed -n 1,7p
AWS public price list, sa-east-1, USD, excluding tax

API Gateway, first tier
  REST API                                          4.25  per million
  HTTP API                                          1.59  per million
  WebSocket, messages                               1.55  per million
  WebSocket, connection time                       0.388  per million minutes
```

Com 30 milhões de requisições por mês, a REST API custa 30 × 4,25 = 127,50 USD e a HTTP API
30 × 1,59 = 47,70 USD, uma diferença de 79,80 USD todo mês pelo mesmo tráfego. Os dois valores
são preços da primeira faixa, que a AWS aplica às primeiras 333 milhões de requisições REST e às
primeiras 300 milhões de requisições HTTP de um mês, então uma loja deste tamanho nunca sai da
faixa que a tabela imprime. Um detalhe do medidor importa para corpos grandes: uma HTTP API conta
uma requisição em passos de 512 KB, então um upload de 1,2 MB é cobrado como três.

## Rotas em vez de uma árvore

Onde uma REST API tem recursos e métodos, uma HTTP API tem **rotas**: uma string com um método e um
caminho, como `GET /orders/{id}`. A expressão de seleção de rota da API diz como uma requisição é
comparada com elas, e numa HTTP API ela é sempre o método e o caminho:

```
ana@laptop:~/aws$ aws apigatewayv2 create-api --name shop-http --protocol-type HTTP --query "{ApiId: ApiId, ApiEndpoint: ApiEndpoint, RouteSelectionExpression: RouteSelectionExpression}"
{
    "ApiId": "dnyvvgxl",
    "ApiEndpoint": "https://dnyvvgxl.execute-api.sa-east-1.amazonaws.com",
    "RouteSelectionExpression": "$request.method $request.path"
}
ana@laptop:~/aws$ HTTP=$(aws apigatewayv2 get-apis --query "Items[?Name==\`shop-http\`].ApiId" --output text)
```

O comando é `apigatewayv2`, a segunda versão da API do serviço, que monta HTTP APIs e WebSocket
APIs; `apigateway` monta só REST APIs. A rota vai para uma função. O handler lê duas coisas que o
API Gateway põe no evento, o id do pedido no caminho e quem chama no token, e devolve um status,
um cabeçalho e um corpo:

```python
# app.py
import json


def handler(event, context):
    claims = event["requestContext"]["authorizer"]["jwt"]["claims"]
    order = event["pathParameters"]["id"]
    return {
        "statusCode": 200,
        "headers": {"content-type": "application/json"},
        "body": json.dumps({"order": order, "asked_by": claims["sub"]}),
    }
```

Salve-o como `~/aws/app.py`. A função é criada como a aula 14 cria uma, com uma role que ela pode
assumir, e então a API ganha suas quatro partes: uma integração que aponta para a função, um
autorizador JWT, uma rota que usa os dois, e um stage:

```
ana@laptop:~/aws$ python3 -m zipfile -c function.zip app.py
ana@laptop:~/aws$ aws iam create-role --role-name orders-fn --assume-role-policy-document '{"Version": "2012-10-17", "Statement": [{"Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}' --query Role.Arn --output text
arn:aws:iam::123456789012:role/orders-fn
ana@laptop:~/aws$ FN=$(aws lambda create-function --function-name orders --runtime python3.12 --handler app.handler --role arn:aws:iam::123456789012:role/orders-fn --zip-file fileb://function.zip --query FunctionArn --output text)
ana@laptop:~/aws$ INT=$(aws apigatewayv2 create-integration --api-id "$HTTP" --integration-type AWS_PROXY --integration-uri "$FN" --payload-format-version 2.0 --query IntegrationId --output text)
ana@laptop:~/aws$ AUTH=$(aws apigatewayv2 create-authorizer --api-id "$HTTP" --name users --authorizer-type JWT --identity-source '$request.header.Authorization' --jwt-configuration Audience=shop,Issuer=https://auth.example.com/ --query AuthorizerId --output text)
ana@laptop:~/aws$ aws apigatewayv2 create-route --api-id "$HTTP" --route-key "GET /orders/{id}" --authorization-type JWT --authorizer-id "$AUTH" --target "integrations/$INT"
{
    "ApiKeyRequired": false,
    "AuthorizationType": "JWT",
    "AuthorizerId": "uidypmjf",
    "RequestParameters": {},
    "RouteId": "eromjuey",
    "RouteKey": "GET /orders/{id}",
    "Target": "integrations/ffngvkdl"
}
ana@laptop:~/aws$ aws apigatewayv2 create-stage --api-id "$HTTP" --stage-name '$default' --auto-deploy --query "{StageName: StageName, AutoDeploy: AutoDeploy}"
{
    "StageName": "$default",
    "AutoDeploy": true
}
```

**`$default` com implantação automática é o stage que elimina a fotografia** da seção anterior.
Toda mudança numa rota ou numa integração é implantada sozinha, e o stage não tem nome no endereço,
então a rota é `https://dnyvvgxl.execute-api.sa-east-1.amazonaws.com/orders/42`. Uma REST API
nunca oferece isso; uma HTTP API ainda deixa você criar stages com nome e implantar à mão quando
quiser a fotografia de volta.

A última parte é fácil de esquecer. **O API Gateway precisa de permissão para invocar a função**,
concedida na própria política de recurso da função, e o ARN de origem a restringe a esta API, a
este método e a este caminho:

```
ana@laptop:~/aws$ aws lambda add-permission --function-name orders --statement-id http-api --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:sa-east-1:123456789012:$HTTP/*/GET/orders/{id}" --query Statement --output text | jq .Condition
{
  "ArnLike": {
    "AWS:SourceArn": "arn:aws:execute-api:sa-east-1:123456789012:dnyvvgxl/*/GET/orders/{id}"
  }
}
```

O `*` vale para qualquer stage. Sem essa declaração a rota existe e toda chamada a ela falha com
`500`, porque o API Gateway é recusado quando tenta chamar a função, e a função nunca roda.

## O que o autorizador JWT faz

O autorizador acima cita um emissor e uma audiência. Na AWS, uma requisição à rota precisa levar
`Authorization: Bearer` e um token. O API Gateway busca as chaves públicas do emissor no endereço
que a configuração OpenID dele publica, verifica a assinatura do token com elas, e verifica que
`iss` é o emissor, `aud` é `shop` e `exp` não passou. Um token que falha em qualquer uma dessas
recebe um `401` antes de a função ser tocada. Um que passa chega à função com as claims dentro do
evento. User pools do Cognito emitem esses tokens, e qualquer provedor OpenID Connect também.

**Isto não foi rodado.** O moto guardou o autorizador, a rota e o stage exatamente como acima, mas
não serve nada no endereço da API, `https://auth.example.com/` é um domínio de documentação sem
chaves por trás, e nenhum token foi verificado.

## Payload format 2.0, rodado no runtime de verdade

O que dá para rodar é a metade da função. A integração pediu o payload format `2.0`, o menor e mais
novo dos dois formatos que uma HTTP API pode mandar. Este é um `GET /orders/42?fields=total`
nesse formato, resumido aos campos que importam aqui, escrito à mão a partir da documentação da
AWS; salve-o como `~/aws/get-order.json`:

```schooling-example
{"language": "json", "file": "get-order.json", "parts": [{"code": "{\n  \"version\": \"2.0\",\n  \"routeKey\": \"GET /orders/{id}\",\n", "note": "Qual é o formato, e qual rota casou. Uma route key é um método e um modelo de caminho, a mesma string com que a rota foi criada."}, {"code": "  \"rawPath\": \"/orders/42\",\n  \"rawQueryString\": \"fields=total\",\n  \"headers\": {\n    \"accept\": \"application/json\",\n    \"user-agent\": \"curl/8.5.0\"\n  },\n  \"queryStringParameters\": {\"fields\": \"total\"},\n  \"pathParameters\": {\"id\": \"42\"},\n", "note": "A requisição como o cliente a mandou, já desmontada: o caminho, a query string crua e como dicionário, os cabeçalhos em minúsculas, e o `{id}` preenchido a partir do caminho."}, {"code": "  \"requestContext\": {\n    \"http\": {\"method\": \"GET\", \"path\": \"/orders/42\", \"sourceIp\": \"203.0.113.7\"},\n    \"stage\": \"$default\",\n    \"authorizer\": {\"jwt\": {\"claims\": {\"sub\": \"ana\"}, \"scopes\": null}}\n  },\n", "note": "O que o API Gateway sabe da requisição e o cliente não escreveu: o método, o endereço de quem chama, o stage, e as claims do token que o autorizador JWT já verificou. A função nunca vê uma requisição cujo token falhou."}, {"code": "  \"isBase64Encoded\": false\n}\n", "note": "Se o `body` está em base64. Este GET não tem corpo nenhum, e na versão 2.0 um corpo ausente simplesmente não aparece no evento."}]}
```

O formato `1.0` é o que as REST APIs mandam, com o método no topo como `httpMethod` e cada
cabeçalho duas vezes, uma como string e outra como lista. **Uma integração diz qual dos dois quer**,
e um handler escrito para um quebra no outro: `event["httpMethod"]` é um `KeyError` no 2.0.

O handler roda na imagem base do Lambda da AWS, com o Runtime Interface Emulator dela, do jeito
que a aula 14 roda um. Se o Docker ainda não está nesta máquina, instale-o como o curso `docker`
faz e baixe a imagem uma vez:

```sh
docker pull public.ecr.aws/lambda/python:3.12
```

Depois suba a função e mande o evento para ela:

```
ana@laptop:~/aws$ docker run -d --rm --name orders -p 9000:8080 -v "$PWD":/var/task:ro public.ecr.aws/lambda/python:3.12 app.handler
ba4ec088af26a07d9cb0b698fbc907224626a28fa0eb15413542802614927696
ana@laptop:~/aws$ curl -s -XPOST localhost:9000/2015-03-31/functions/function/invocations -d @get-order.json | jq .
{
  "statusCode": 200,
  "headers": {
    "content-type": "application/json"
  },
  "body": "{\"order\": \"42\", \"asked_by\": \"ana\"}"
}
ana@laptop:~/aws$ docker rm -f orders
orders
```

Essa é a resposta da função, produzida pelo runtime real do Python 3.12. **O que o API Gateway faz
com ela não foi rodado**: na AWS ele transforma `statusCode` no status HTTP, `headers` em
cabeçalhos e `body` no corpo, então o cliente recebe um `200` e `{"order": "42", "asked_by": "ana"}`.
O formato 2.0 também aceita menos. Um handler que devolve um dicionário simples sem `statusCode`
recebe um `200`, um content type JSON e o dicionário como corpo, o que é cômodo até o dia em que
um handler precisa responder `404`.
