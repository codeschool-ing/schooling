---
title: "HTTP APIs: routes, JWT and payload 2.0"
version: 1
---

An HTTP API is often described as a cut-down REST API, and the description makes people expect a
lesser product. **It is a different, smaller design**, announced at the end of 2019 for the case that most APIs
had become: a client, a token, and a function or a web server behind a route. It drops mapping
templates, usage plans and the cache, and in exchange it is simpler to build, it deploys itself,
and it checks a JSON Web Token without any code of yours. It also costs well under half as much
per request.

## Cheaper, by how much

The sheet from lesson 1 prints both prices, as published on 16 October 2026:

```
ana@laptop:~/aws$ python3 prices.py integration | sed -n 1,7p
AWS public price list, sa-east-1, USD, excluding tax

API Gateway, first tier
  REST API                                          4.25  per million
  HTTP API                                          1.59  per million
  WebSocket, messages                               1.55  per million
  WebSocket, connection time                       0.388  per million minutes
```

At 30 million requests a month the REST API costs 30 × 4.25 = 127.50 USD and the HTTP API
30 × 1.59 = 47.70 USD, a difference of 79.80 USD every month for the same traffic. Both figures
are first-tier prices, which AWS applies to the first 333 million REST requests and the first 300
million HTTP requests of a month, so a shop of this size never leaves the tier the sheet prints.
One detail of the meter matters for large bodies: an HTTP API counts a request in steps of 512 KB,
so a 1.2 MB upload is billed as three.

## Routes instead of a tree

Where a REST API has resources and methods, an HTTP API has **routes**: one string holding a method
and a path, such as `GET /orders/{id}`. The API's route selection expression says how a request is
matched against them, and for an HTTP API it is always the method and the path:

```
ana@laptop:~/aws$ aws apigatewayv2 create-api --name shop-http --protocol-type HTTP --query "{ApiId: ApiId, ApiEndpoint: ApiEndpoint, RouteSelectionExpression: RouteSelectionExpression}"
{
    "ApiId": "dnyvvgxl",
    "ApiEndpoint": "https://dnyvvgxl.execute-api.sa-east-1.amazonaws.com",
    "RouteSelectionExpression": "$request.method $request.path"
}
ana@laptop:~/aws$ HTTP=$(aws apigatewayv2 get-apis --query "Items[?Name==\`shop-http\`].ApiId" --output text)
```

The command is `apigatewayv2`, the second version of the service's API, which builds both HTTP
and WebSocket APIs; `apigateway` builds REST APIs only. The route will go to a function. The handler
reads two things API Gateway puts in the event, the order id from the path and the caller from
the token, and returns a status, a header and a body:

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

Save it as `~/aws/app.py`. The function is created the way lesson 14 creates one, with a role it
can be assumed by, and then the API gets its four parts: an integration that points at the
function, a JWT authoriser, a route that uses both, and a stage:

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

**`$default` with auto-deploy is the stage that removes the photograph** from the previous section.
Every change to a route or an integration is deployed on its own, and the stage has no name in the
address, so the route is `https://dnyvvgxl.execute-api.sa-east-1.amazonaws.com/orders/42`. A REST
API never offers that; an HTTP API still lets you create named stages and deploy by hand when you
want the photograph back.

The last part is easy to forget. **API Gateway needs permission to invoke the function**, granted
on the function's own resource policy, and the source ARN narrows it to this API, this method and
this path:

```
ana@laptop:~/aws$ aws lambda add-permission --function-name orders --statement-id http-api --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:sa-east-1:123456789012:$HTTP/*/GET/orders/{id}" --query Statement --output text | jq .Condition
{
  "ArnLike": {
    "AWS:SourceArn": "arn:aws:execute-api:sa-east-1:123456789012:dnyvvgxl/*/GET/orders/{id}"
  }
}
```

The `*` stands for any stage. Without this statement the route exists and every call to it fails
with a `500`, because API Gateway is refused when it tries to call the function, and the function
never runs.

## What the JWT authoriser does

The authoriser above names an issuer and an audience. On AWS, a request to the route must carry
`Authorization: Bearer` and a token. API Gateway fetches the issuer's public keys from the address
its OpenID configuration publishes, checks the token's signature with them, and checks that `iss`
is the issuer, `aud` is `shop` and `exp` has not passed. A token that fails any of these gets a
`401` before the function is touched. One that passes reaches the function with its claims inside
the event. Cognito user pools issue such tokens, and so does any OpenID Connect provider.

**This was not run.** moto stored the authoriser, the route and the stage exactly as above, but it
serves nothing at the API's address, `https://auth.example.com/` is a documentation domain with no
keys behind it, and no token was ever checked.

## Payload format 2.0, run in the real runtime

What can be run is the function's half. The integration asked for payload format `2.0`, the
smaller and newer of the two shapes an HTTP API can send. This is a `GET /orders/42?fields=total`
in that shape, abridged to the fields that matter here, written by hand from AWS's documentation;
save it as `~/aws/get-order.json`:

```schooling-example
{"language": "json", "file": "get-order.json", "parts": [{"code": "{\n  \"version\": \"2.0\",\n  \"routeKey\": \"GET /orders/{id}\",\n", "note": "Which format this is, and which route matched. A route key is a method and a path template, the same string the route was created with."}, {"code": "  \"rawPath\": \"/orders/42\",\n  \"rawQueryString\": \"fields=total\",\n  \"headers\": {\n    \"accept\": \"application/json\",\n    \"user-agent\": \"curl/8.5.0\"\n  },\n  \"queryStringParameters\": {\"fields\": \"total\"},\n  \"pathParameters\": {\"id\": \"42\"},\n", "note": "The request as the client sent it, already taken apart: the path, the query string both raw and as a dictionary, the headers in lower case, and `{id}` filled in from the path."}, {"code": "  \"requestContext\": {\n    \"http\": {\"method\": \"GET\", \"path\": \"/orders/42\", \"sourceIp\": \"203.0.113.7\"},\n    \"stage\": \"$default\",\n    \"authorizer\": {\"jwt\": {\"claims\": {\"sub\": \"ana\"}, \"scopes\": null}}\n  },\n", "note": "What API Gateway knows about the request that the client did not write: the method, the caller's address and stage, and the claims of the token the JWT authoriser has already checked. The function never sees a request whose token failed."}, {"code": "  \"isBase64Encoded\": false\n}\n", "note": "Whether `body` is base64. This GET has no body at all, and in version 2.0 an absent body is simply missing from the event."}]}
```

Format `1.0` is the shape REST APIs send, with the method at the top as `httpMethod` and every
header twice, once as a string and once as a list. **An integration says which one it wants**, and
a handler written for one breaks on the other: `event["httpMethod"]` is a `KeyError` in 2.0.

The handler runs in AWS's Lambda base image with its Runtime Interface Emulator, the way lesson 14
runs one. If Docker is not on this machine yet, install it as the `docker` course does and pull the
image once:

```sh
docker pull public.ecr.aws/lambda/python:3.12
```

Then start the function and send it the event:

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

That is the function's answer, produced by the real Python 3.12 runtime. **What API Gateway does
with it was not run**: on AWS it turns `statusCode` into the HTTP status, `headers` into headers
and `body` into the body, so the client receives a `200` and `{"order": "42", "asked_by": "ana"}`.
Format 2.0 also accepts less. A handler that returns a plain dictionary with no `statusCode` gets
a `200`, a JSON content type and the dictionary as the body, which is convenient until a handler
needs to answer `404`.
