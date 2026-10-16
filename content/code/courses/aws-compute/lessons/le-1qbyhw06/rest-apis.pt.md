---
title: "REST APIs: recursos, métodos, integrações e stages"
version: 1
---

A imagem comum do API Gateway é uma caixa que encaminha requisições a uma função. Ele as encaminha,
mas **uma REST API é uma árvore que você monta e depois fotografa**. A árvore é feita de
recursos, que são caminhos, e de métodos, que são os verbos de um caminho. Cada método tem uma
integração, que diz para onde a requisição vai. Nada disso responde a uma única requisição até
você tirar uma implantação, uma cópia congelada da árvore, e pô-la num stage. Uma mudança feita
depois existe na árvore e em nenhum outro lugar até a próxima implantação.

O API Gateway tem três tipos de API, e esta seção trata do mais antigo. As duas seções seguintes
constroem uma HTTP API e uma WebSocket API, e a última põe as três lado a lado.

## A árvore

A loja da Ana precisa de um endpoint `/orders` somente leitura para um parceiro. Ela cria a API
primeiro. Todo comando abaixo roda contra o moto, o laboratório da aula 1:

```
ana@laptop:~/aws$ aws apigateway create-rest-api --name shop --endpoint-configuration types=REGIONAL --query "{id: id, name: name, apiKeySource: apiKeySource, rootResourceId: rootResourceId}"
{
    "id": "ab9jfxt6tl",
    "name": "shop",
    "apiKeySource": "HEADER",
    "rootResourceId": "53x13uqasx"
}
```

`REGIONAL` põe a API em São Paulo e em nenhum outro lugar. A alternativa é `EDGE`, o padrão de uma
REST API, que põe os pontos de presença do CloudFront na frente dela. `PRIVATE` a torna acessível
só de dentro de uma VPC, por um interface endpoint do tipo que a aula 19 de `aws-foundations`
constrói. A API já chega com um recurso, a raiz `/`. A Ana guarda os ids em
variáveis do shell e acrescenta `/orders` abaixo da raiz:

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

**Um recurso é um segmento de um caminho, e ele tem um pai.** `/orders/{id}` seria um terceiro
recurso, com `/orders` como pai e `{id}` como parte do caminho, e as chaves marcam um valor que
quem chama preenche.

Um recurso sem método não responde nada. O método é o verbo, com seus próprios ajustes: quem pode
chamá-lo, e se uma chave é exigida. A integração por trás dele é para onde a requisição vai. `MOCK`
responde do próprio API Gateway, o que basta para ver o formato. As outras são `HTTP` e
`HTTP_PROXY` para um servidor web, `AWS` para outro serviço da AWS, e `AWS_PROXY` para a integração
proxy Lambda que a aula 15 ligou a uma função:

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

As quatro chamadas são as quatro caixas que um método REST sempre tem: a requisição do método, a
requisição da integração, a resposta da integração e a resposta do método. Os templates são
mapping templates, escritos numa linguagem de templates que a AWS chama de VTL. Eles reescrevem
uma requisição na entrada e uma resposta na saída. Com `AWS_PROXY` você pula as quatro e a função
recebe a requisição inteira, e é por isso que a maioria das REST APIs novas a usa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"À esquerda, a REST API shop como uma árvore que você edita: o recurso raiz, o recurso /orders abaixo dele, e em /orders os métodos GET e POST, o GET com uma integração MOCK. Uma seta chamada create-deployment leva a uma cópia congelada que tem só o GET, porque o POST foi acrescentado depois dela. O stage prod aponta para essa cópia, e o stage é o que responde às requisições.\"><defs><marker id=\"ra-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"16\" y=\"16\" width=\"330\" height=\"268\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"30\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">a API que você edita</text><rect x=\"36\" y=\"56\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"96\" y=\"73\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">/</text><path d=\"M66 90 L66 118\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"36\" y=\"118\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"96\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">/orders</text><path d=\"M156 135 L176 135 L176 196 L196 196\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M176 196 L176 250 L196 250\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"196\" y=\"176\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"261\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">GET</text><text x=\"261\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">integração MOCK</text><rect x=\"196\" y=\"232\" width=\"130\" height=\"36\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"261\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">POST</text><text x=\"261\" y=\"259\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">acrescentado depois</text><path d=\"M350 150 L404 150\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ra-ah)\"></path><text x=\"377\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">create-</text><text x=\"377\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">deployment</text><rect x=\"408\" y=\"86\" width=\"150\" height=\"128\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"483\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">implantação</text><text x=\"483\" y=\"121\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma cópia congelada</text><text x=\"483\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/orders</text><text x=\"483\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">GET</text><text x=\"483\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">sem POST</text><path d=\"M606 150 L562 150\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ra-ah)\"></path><rect x=\"608\" y=\"110\" width=\"96\" height=\"80\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"656\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">stage</text><text x=\"656\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">prod</text><text x=\"656\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">responde</text></svg>", "caption": "A API é uma árvore que você edita; uma implantação é uma cópia dela num momento; o stage aponta para uma implantação e é a única parte que responde. O POST foi acrescentado depois de a cópia ser tirada, então quem chama não o alcança.", "same": ["stage"]}
```

## Implantar, e o que uma implantação congela

Uma implantação de nada é recusada. O moto faz a mesma verificação que a AWS faz:

```
ana@laptop:~/aws$ aws apigateway create-rest-api --name empty --query name
"empty"
ana@laptop:~/aws$ aws apigateway create-deployment --rest-api-id "$(aws apigateway get-rest-apis --query "items[?name==\`empty\`].id" --output text)" --stage-name prod

aws: [ERROR]: An error occurred (BadRequestException) when calling the CreateDeployment operation: The REST API doesn't contain any methods
```

A `shop` tem um método, então a implantação dela passa, e o stage `prod` é criado apontando para
ela. A Ana então acrescenta um `POST` a `/orders` e pergunta ao stage o que ele serve:

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

**O stage continua apontando para a implantação tirada antes de o `POST` existir.** Na AWS, um
parceiro que chamasse `POST /orders` no `prod` receberia um `403` com a mensagem
`Missing Authentication Token`, que é o que uma REST API responde para um caminho ou método que
ela não tem. Essa mensagem engana quase todo mundo da primeira vez, porque sugere uma chave
faltando. A correção é outro `create-deployment`, e a implantação antiga fica na lista, então
voltar atrás é apontar o stage para o id anterior. O stage também carrega seus próprios ajustes:
limites, logs, variáveis e o cache que a última seção desta aula liga.

## Usage plans e chaves de API

O método acima exige uma chave. Uma chave sozinha não faz nada até estar num **usage plan**, que
liga chaves a stages e lhes dá uma taxa, um pico e uma cota:

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

O `--query` mantém o valor da chave fora da tela de propósito: é um segredo que o parceiro manda
no cabeçalho `x-api-key`, e um terminal que o imprimiu é um terminal que alguém pode fotografar.
Na AWS, uma chamada sem o cabeçalho recebe um `403 Forbidden`. Um parceiro acima de dez requisições
por segundo, com vinte permitidas de uma vez, recebe `429 Too Many Requests`, e o mesmo vale para
um que passou de 100.000 requisições no mês.

**Uma chave de API identifica um cliente; ela não o autentica.** A documentação da AWS diz isso com
todas as letras: a chave viaja à vista em toda requisição, qualquer um que a veja pode usá-la, e
ela existe para medir e limitar. Quem é quem chama pertence a um autorizador: IAM, um autorizador
Lambda, ou user pools do Cognito.

**Nada dos três últimos parágrafos foi rodado.** O moto guardou a API, a implantação, o stage, a
chave e o plano exatamente como a AWS guardaria, e responde a cada uma destas chamadas, mas não
serve nada no endereço de um stage. Não existe
`https://ab9jfxt6tl.execute-api.sa-east-1.amazonaws.com/prod/orders` para chamar, então nenhuma
requisição jamais encontrou o método, a verificação da chave ou o limite. O `403`, o `429` e o
`Missing Authentication Token` são as respostas documentadas da AWS.
