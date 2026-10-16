#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of aws-compute (API Gateway), as a
# script that produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT
# COMMITTED.
#
#   bash lessons/le-1qbyhw06/captures.sh             # everything against moto
#   LAB_HOSTS=1 bash lessons/le-1qbyhw06/captures.sh emulator
#
# Every API here is created in moto 5.2.3, which keeps the definition and
# answers every control-plane call, but serves NOTHING at a stage URL: no
# request reaches a method, an integration, an authoriser or a usage plan. The
# lesson says so where it matters and teaches the data plane from AWS's
# documentation, marked as not run.
#
# What is STAGED rather than typed:
#   - prices.py is read out of the example in lesson 1's `the-price-sheet`; its
#     cache (~/.cache/aws-prices) was filled by lesson 1's `prices` run, so this
#     run needs no network;
#   - app.py and get-order.json are read out of the section `http-apis`, so
#     the files run are the files the student copies;
#   - `emulator` runs on the machine's own network, because a port published
#     by Docker is not reachable from the lab's network namespace. The lab's
#     ~/aws is a bind mount the Docker daemon cannot see, so `docker` is given
#     the same directory under the path the daemon sees (the function `docker`
#     below, which asks findmnt for it); the image, the file and the command
#     are the student's. A short wait for the emulator to listen is not shown.
#
# Recorded 2026-10-16 on Ubuntu 24.04, no AWS account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

if [ "${1:-}" = emulator ]; then
  HOSTAWS=$(findmnt -n -o FSROOT --target /home/ana/aws)
  docker() {
    local a=() x
    for x in "$@"; do a+=("${x//\/home\/ana\/aws:/$HOSTAWS:}"); done
    command docker "${a[@]}"
  }
  from_lesson "$HERE/http-apis.md" app.py > app.py
  from_example "$HERE/http-apis.md" get-order.json > get-order.json
  quiet 'docker rm -f orders'
  block emulator
  run 'docker run -d --rm --name orders -p 9000:8080 -v "$PWD":/var/task:ro public.ecr.aws/lambda/python:3.12 app.handler'
  quiet 'for i in $(seq 40); do curl -s -o /dev/null localhost:9000 && break; sleep 0.25; done'
  run 'curl -s -XPOST localhost:9000/2015-03-31/functions/function/invocations -d @get-order.json | jq .'
  run 'docker rm -f orders'
  exit 0
fi

block rest-create
run 'aws apigateway create-rest-api --name shop --endpoint-configuration types=REGIONAL --query "{id: id, name: name, apiKeySource: apiKeySource, rootResourceId: rootResourceId}"'
run 'API=$(aws apigateway get-rest-apis --query "items[?name==\`shop\`].id" --output text)'
run 'ROOT=$(aws apigateway get-resources --rest-api-id "$API" --query "items[0].id" --output text)'
run 'ORDERS=$(aws apigateway create-resource --rest-api-id "$API" --parent-id "$ROOT" --path-part orders --query id --output text)'
run 'aws apigateway get-resources --rest-api-id "$API"'

block rest-method
run 'aws apigateway put-method --rest-api-id "$API" --resource-id "$ORDERS" --http-method GET --authorization-type NONE --api-key-required'
run 'aws apigateway put-integration --rest-api-id "$API" --resource-id "$ORDERS" --http-method GET --type MOCK --request-templates '"'"'{"application/json": "{\"statusCode\": 200}"}'"'"' --query type'
run 'aws apigateway put-method-response --rest-api-id "$API" --resource-id "$ORDERS" --http-method GET --status-code 200 --query statusCode'
run 'aws apigateway put-integration-response --rest-api-id "$API" --resource-id "$ORDERS" --http-method GET --status-code 200 --response-templates '"'"'{"application/json": "{\"orders\": []}"}'"'"' --query statusCode'

block rest-empty-deploy
run 'aws apigateway create-rest-api --name empty --query name'
run 'aws apigateway create-deployment --rest-api-id "$(aws apigateway get-rest-apis --query "items[?name==\`empty\`].id" --output text)" --stage-name prod'

block rest-deploy
run 'aws apigateway create-deployment --rest-api-id "$API" --stage-name prod --description "orders, read only" --query "{id: id, description: description}"'
run 'aws apigateway put-method --rest-api-id "$API" --resource-id "$ORDERS" --http-method POST --authorization-type NONE --api-key-required --query httpMethod'
run 'aws apigateway get-stage --rest-api-id "$API" --stage-name prod --query "{stage: stageName, deployment: deploymentId}"'
run 'aws apigateway get-deployments --rest-api-id "$API" --query "items[].[id, description]" --output text'

block usage-plan
run 'KEY=$(aws apigateway create-api-key --name partner-acme --enabled --query id --output text)'
run 'aws apigateway create-usage-plan --name partners --throttle burstLimit=20,rateLimit=10 --quota limit=100000,period=MONTH --api-stages apiId="$API",stage=prod --query "{name: name, throttle: throttle, quota: quota}"'
run 'PLAN=$(aws apigateway get-usage-plans --query "items[0].id" --output text)'
run 'aws apigateway create-usage-plan-key --usage-plan-id "$PLAN" --key-id "$KEY" --key-type API_KEY --query "{name: name, type: type}"'

block prices
from_example "$HERE/../le-ps61q5st/the-price-sheet.md" prices.py > prices.py
run 'python3 prices.py integration | sed -n 1,7p'

block http-create
run 'aws apigatewayv2 create-api --name shop-http --protocol-type HTTP --query "{ApiId: ApiId, ApiEndpoint: ApiEndpoint, RouteSelectionExpression: RouteSelectionExpression}"'
run 'HTTP=$(aws apigatewayv2 get-apis --query "Items[?Name==\`shop-http\`].ApiId" --output text)'

block http-wire
from_lesson "$HERE/http-apis.md" app.py > app.py
run 'python3 -m zipfile -c function.zip app.py'
run 'aws iam create-role --role-name orders-fn --assume-role-policy-document '"'"'{"Version": "2012-10-17", "Statement": [{"Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}'"'"' --query Role.Arn --output text'
run 'FN=$(aws lambda create-function --function-name orders --runtime python3.12 --handler app.handler --role arn:aws:iam::123456789012:role/orders-fn --zip-file fileb://function.zip --query FunctionArn --output text)'
run 'INT=$(aws apigatewayv2 create-integration --api-id "$HTTP" --integration-type AWS_PROXY --integration-uri "$FN" --payload-format-version 2.0 --query IntegrationId --output text)'
run 'AUTH=$(aws apigatewayv2 create-authorizer --api-id "$HTTP" --name users --authorizer-type JWT --identity-source '"'"'$request.header.Authorization'"'"' --jwt-configuration Audience=shop,Issuer=https://auth.example.com/ --query AuthorizerId --output text)'
run 'aws apigatewayv2 create-route --api-id "$HTTP" --route-key "GET /orders/{id}" --authorization-type JWT --authorizer-id "$AUTH" --target "integrations/$INT"'
run 'aws apigatewayv2 create-stage --api-id "$HTTP" --stage-name '"'"'$default'"'"' --auto-deploy --query "{StageName: StageName, AutoDeploy: AutoDeploy}"'
run 'aws lambda add-permission --function-name orders --statement-id http-api --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:sa-east-1:123456789012:$HTTP/*/GET/orders/{id}" --query Statement --output text | jq .Condition'

block ws
run 'aws apigatewayv2 create-api --name chat --protocol-type WEBSOCKET --route-selection-expression '"'"'$request.body.action'"'"' --query "{ApiId: ApiId, ApiEndpoint: ApiEndpoint, RouteSelectionExpression: RouteSelectionExpression}"'
run 'WS=$(aws apigatewayv2 get-apis --query "Items[?Name==\`chat\`].ApiId" --output text)'
run 'WINT=$(aws apigatewayv2 create-integration --api-id "$WS" --integration-type AWS_PROXY --integration-uri "$FN" --query IntegrationId --output text)'
run 'for r in '"'"'$connect'"'"' '"'"'$disconnect'"'"' '"'"'$default'"'"' send; do aws apigatewayv2 create-route --api-id "$WS" --route-key "$r" --target "integrations/$WINT" --query RouteKey --output text; done'
run 'aws apigatewayv2 create-stage --api-id "$WS" --stage-name prod --query StageName --output text'

block ws-post
run 'aws apigatewaymanagementapi post-to-connection --connection-id L0SM9cOFvHcCIhw= --cli-binary-format raw-in-base64-out --data '"'"'{"text": "order 42 shipped"}'"'"'; echo "exit status $?"'
run 'aws apigatewaymanagementapi get-connection --connection-id L0SM9cOFvHcCIhw= --query Identity'

block cache
run 'aws apigateway update-stage --rest-api-id "$API" --stage-name prod --patch-operations op=replace,path=/cacheClusterEnabled,value=true op=replace,path=/cacheClusterSize,value=0.5 --query "{cacheClusterEnabled: cacheClusterEnabled, cacheClusterSize: cacheClusterSize, cacheClusterStatus: cacheClusterStatus}"'
