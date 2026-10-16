---
title: "REST APIs: resources, methods, integrations and stages"
version: 1
---

The common picture of API Gateway is a box that forwards requests to a function. It does forward
them, but **a REST API is a tree that you build and then photograph**. The tree is made of
resources, which are paths, and methods, which are the verbs on a path. Each method has an
integration, which says where the request goes. None of it answers a single request until you take
a deployment, a frozen copy of the tree, and put it on a stage. A change you make afterwards
exists in the tree and nowhere else until the next deployment.

API Gateway has three kinds of API, and this section is about the oldest. The next two sections
build an HTTP API and a WebSocket API, and the last one sets the three side by side.

## The tree

Ana's shop needs a read-only `/orders` endpoint for a partner. She creates the API first. Every
command below runs against moto, the lab from lesson 1:

```
ana@laptop:~/aws$ aws apigateway create-rest-api --name shop --endpoint-configuration types=REGIONAL --query "{id: id, name: name, apiKeySource: apiKeySource, rootResourceId: rootResourceId}"
{
    "id": "ab9jfxt6tl",
    "name": "shop",
    "apiKeySource": "HEADER",
    "rootResourceId": "53x13uqasx"
}
```

`REGIONAL` puts the API in São Paulo and nowhere else. The alternative is `EDGE`, the default for
a REST API, which puts CloudFront's edge locations in front of it. `PRIVATE` makes it reachable
only from inside a VPC, through an interface endpoint of the kind `aws-foundations` lesson 19
builds. The API arrives with one resource already in it, the root `/`. Ana keeps the ids in
shell variables and adds `/orders` under the root:

```
ana@laptop:~/aws$ API=$(aws apigateway get-rest-apis --query "items[?name==\`shop\`].id" --output text)
ana@laptop:~/aws$ ROOT=$(aws apigateway get-resources --rest-api-id "$API" --query "items[0].id" --output text)
ana@laptop:~/aws$ ORDERS=$(aws apigateway create-resource --rest-api-id "$API" --parent-id "$ROOT" --path-part orders --query id --output text)
ana@laptop:~/aws$ aws apigateway get-resources --rest-api-id "$API"
{
    "items": [
        {
            "id": "53x13uqasx",
            "path": "/"
        },
        {
            "id": "gx0thkphjd",
            "parentId": "53x13uqasx",
            "pathPart": "orders",
            "path": "/orders"
        }
    ]
}
```

**A resource is one segment of a path, and it has a parent.** `/orders/{id}` would be a third
resource with `/orders` as its parent and `{id}` as its path part, the braces marking a value the
caller fills in.

A resource with no method answers nothing. The method is the verb, with its own settings: who may
call it, and whether a key is required. The integration behind it is where the request goes.
`MOCK` answers from API Gateway itself, which is enough to see the shape. The others are `HTTP` and
`HTTP_PROXY` for a web server, `AWS` for another AWS service, and `AWS_PROXY` for the Lambda proxy
integration that lesson 15 connected to a function:

```
ana@laptop:~/aws$ aws apigateway put-method --rest-api-id "$API" --resource-id "$ORDERS" --http-method GET --authorization-type NONE --api-key-required
{
    "httpMethod": "GET",
    "authorizationType": "NONE",
    "apiKeyRequired": true,
    "methodResponses": {}
}
ana@laptop:~/aws$ aws apigateway put-integration --rest-api-id "$API" --resource-id "$ORDERS" --http-method GET --type MOCK --request-templates '{"application/json": "{\"statusCode\": 200}"}' --query type
"MOCK"
ana@laptop:~/aws$ aws apigateway put-method-response --rest-api-id "$API" --resource-id "$ORDERS" --http-method GET --status-code 200 --query statusCode
"200"
ana@laptop:~/aws$ aws apigateway put-integration-response --rest-api-id "$API" --resource-id "$ORDERS" --http-method GET --status-code 200 --response-templates '{"application/json": "{\"orders\": []}"}' --query statusCode
"200"
```

The four calls are the four boxes a REST method always has: the method request, the integration
request, the integration response and the method response. The templates are mapping templates,
written in a template language AWS calls VTL. They rewrite a request on its way in and a response
on its way out. With `AWS_PROXY` you skip all four and the function receives the whole request,
which is why most new REST APIs use it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"On the left, the REST API shop as a tree you edit: the root resource, the resource /orders under it, and on /orders the methods GET and POST, GET with a MOCK integration. An arrow labelled create-deployment leads to a frozen copy holding only GET, because POST was added after it. The stage prod points at that copy, and the stage is what answers requests.\"><defs><marker id=\"ra-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"16\" y=\"16\" width=\"330\" height=\"268\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"30\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">the API you edit</text><rect x=\"36\" y=\"56\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"96\" y=\"73\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">/</text><path d=\"M66 90 L66 118\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"36\" y=\"118\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"96\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">/orders</text><path d=\"M156 135 L176 135 L176 196 L196 196\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M176 196 L176 250 L196 250\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"196\" y=\"176\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"261\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">GET</text><text x=\"261\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">MOCK integration</text><rect x=\"196\" y=\"232\" width=\"130\" height=\"36\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"261\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">POST</text><text x=\"261\" y=\"259\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">added later</text><path d=\"M350 150 L404 150\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ra-ah)\"></path><text x=\"377\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">create-</text><text x=\"377\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">deployment</text><rect x=\"408\" y=\"86\" width=\"150\" height=\"128\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"483\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">deployment</text><text x=\"483\" y=\"121\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a frozen copy</text><text x=\"483\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/orders</text><text x=\"483\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">GET</text><text x=\"483\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">no POST</text><path d=\"M606 150 L562 150\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ra-ah)\"></path><rect x=\"608\" y=\"110\" width=\"96\" height=\"80\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"656\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">stage</text><text x=\"656\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">prod</text><text x=\"656\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">answers calls</text></svg>", "caption": "The API is a tree you edit; a deployment is a copy of it at one moment; the stage points at a deployment and is the only part that answers. POST was added after the copy was taken, so callers cannot reach it."}
```

## Deploying, and what a deployment freezes

A deployment of nothing is refused. moto makes the same check AWS makes:

```
ana@laptop:~/aws$ aws apigateway create-rest-api --name empty --query name
"empty"
ana@laptop:~/aws$ aws apigateway create-deployment --rest-api-id "$(aws apigateway get-rest-apis --query "items[?name==\`empty\`].id" --output text)" --stage-name prod

aws: [ERROR]: An error occurred (BadRequestException) when calling the CreateDeployment operation: The REST API doesn't contain any methods
```

`shop` has a method, so its deployment goes through, and the stage `prod` is created to point at
it. Ana then adds a `POST` to `/orders` and asks the stage what it serves:

```
ana@laptop:~/aws$ aws apigateway create-deployment --rest-api-id "$API" --stage-name prod --description "orders, read only" --query "{id: id, description: description}"
{
    "id": "xdx6rtrjql",
    "description": "orders, read only"
}
ana@laptop:~/aws$ aws apigateway put-method --rest-api-id "$API" --resource-id "$ORDERS" --http-method POST --authorization-type NONE --api-key-required --query httpMethod
"POST"
ana@laptop:~/aws$ aws apigateway get-stage --rest-api-id "$API" --stage-name prod --query "{stage: stageName, deployment: deploymentId}"
{
    "stage": "prod",
    "deployment": "xdx6rtrjql"
}
ana@laptop:~/aws$ aws apigateway get-deployments --rest-api-id "$API" --query "items[].[id, description]" --output text
xdx6rtrjql	orders, read only
```

**The stage still points at the deployment taken before `POST` existed.** On AWS a partner calling
`POST /orders` on `prod` would get a `403` with the message `Missing Authentication Token`, which
is what a REST API answers for a path or method it does not have. That message misleads nearly
everybody the first time, because it suggests a missing key. The fix is another
`create-deployment`, and the old deployment stays in the list, so going back is pointing the stage
at the earlier id. The stage also carries its own settings: throttling, logging, variables and
the cache that the last section of this lesson turns on.

## Usage plans and API keys

The method above requires a key. A key on its own does nothing until it is in a **usage plan**,
which ties keys to stages and gives them a rate, a burst and a quota:

```
ana@laptop:~/aws$ KEY=$(aws apigateway create-api-key --name partner-acme --enabled --query id --output text)
ana@laptop:~/aws$ aws apigateway create-usage-plan --name partners --throttle burstLimit=20,rateLimit=10 --quota limit=100000,period=MONTH --api-stages apiId="$API",stage=prod --query "{name: name, throttle: throttle, quota: quota}"
{
    "name": "partners",
    "throttle": {
        "burstLimit": 20,
        "rateLimit": 10.0
    },
    "quota": {
        "limit": 100000,
        "period": "MONTH"
    }
}
ana@laptop:~/aws$ PLAN=$(aws apigateway get-usage-plans --query "items[0].id" --output text)
ana@laptop:~/aws$ aws apigateway create-usage-plan-key --usage-plan-id "$PLAN" --key-id "$KEY" --key-type API_KEY --query "{name: name, type: type}"
{
    "name": "partner-acme",
    "type": "API_KEY"
}
```

The `--query` keeps the key's value off the screen on purpose: it is a secret the partner sends in
the `x-api-key` header, and a terminal that printed it is a terminal somebody can photograph. On
AWS, a call without the header gets a `403 Forbidden`. A partner above ten requests a second, with
twenty allowed at once, gets `429 Too Many Requests`, and so does one past 100,000 requests in a
month.

**An API key identifies a client; it does not authenticate one.** AWS's documentation says so in
as many words: the key travels in plain sight in every request, anybody who sees it can use it,
and it exists to meter and throttle. Who the caller is belongs to an authoriser: IAM, a Lambda
authoriser, or Cognito user pools.

**None of the last three paragraphs was run.** moto stored the API, the deployment, the stage, the
key and the plan exactly as AWS would, and it answers every one of these calls, but it serves
nothing at a stage address. There is no `https://ab9jfxt6tl.execute-api.sa-east-1.amazonaws.com/prod/orders`
to call, so no request ever met the method, the key check or the throttle. The `403`, the `429`
and `Missing Authentication Token` are AWS's documented answers.
