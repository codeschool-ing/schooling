---
title: Um app, numa linguagem com tipos e laços
version: 1
---

Um template do CloudFormation é uma lista. Vinte buckets que só diferem no nome são vinte entradas, e
uma regra de que todo bucket recusa HTTP sem TLS é uma política escrita vinte vezes. **O Cloud
Development Kit escreve a lista para você**, a partir de um programa: um laço faz os vinte buckets,
uma função guarda a regra, e o resultado é um template comum do CloudFormation. A lição 17 de `iac`
rodou o CDK uma vez; esta lição olha o que ele escreve, como chega à AWS e como testá-lo.

## Instalando o Node.js e o CDK

A linha de comando do CDK é um programa Node.js, e a biblioteca precisa do Node.js 20 ou mais novo,
enquanto o Ubuntu 24.04 traz o 18. O Node.js vem do build do próprio projeto, descompactado em
`~/.local` ao lado da linha de comando da AWS, então nada precisa de `sudo`; depois o comando `cdk`, e
a biblioteca no diretório do próprio app. As versões são as que o `iac` usou e com que as transcrições
foram gravadas:

```sh
curl -fsSL https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-x64.tar.xz | tar -xJ -C ~/.local --strip-components=1
npm install -g aws-cdk@2.1144.0
mkdir -p ~/aws/cdk && cd ~/aws/cdk
npm init -y > /dev/null
npm install aws-cdk-lib@2.272.0 constructs@10
```

Num computador Arm o arquivo é `node-v22.22.0-linux-arm64.tar.xz`. A biblioteca é a parte grande, uns
180 MB em `node_modules`.

```
ana@laptop:~/aws/cdk$ node --version
v22.22.0
ana@laptop:~/aws/cdk$ cdk --version
2.1144.0 (build b9c5274)
```

## O app

A stack base da loja de novo, a que a lição 4 escreveu como template, agora como programa em `app.js`:

```schooling-example
{"language": "javascript", "file": "app.js", "parts": [{"code": "const { App, Stack, Duration, RemovalPolicy } = require(\"aws-cdk-lib\");\nconst s3 = require(\"aws-cdk-lib/aws-s3\");\nconst sns = require(\"aws-cdk-lib/aws-sns\");\nconst logs = require(\"aws-cdk-lib/aws-logs\");\nconst cloudwatch = require(\"aws-cdk-lib/aws-cloudwatch\");\nconst actions = require(\"aws-cdk-lib/aws-cloudwatch-actions\");\n", "note": "A biblioteca é dividida por serviço, um módulo cada, todos dentro de `aws-cdk-lib`."}, {"code": "\nclass ShopBase extends Stack {\n  constructor(scope, id, props) {\n    super(scope, id, props);\n", "note": "**Uma stack é uma classe.** Tudo o que é criado dentro do construtor vira um recurso desta stack."}, {"code": "    new s3.Bucket(this, \"Uploads\", {\n      versioned: true,\n      enforceSSL: true,\n      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,\n      removalPolicy: RemovalPolicy.RETAIN,\n    });\n", "note": "O bucket de uploads, com quatro decisões que o template da lição 4 escreveu à mão: versões guardadas, HTTP sem TLS recusado, nenhum acesso público, mantido quando a stack vai embora. `enforceSSL` é uma linha aqui e uma política de bucket inteira no template."}, {"code": "    new logs.LogGroup(this, \"WebLogs\", {\n      logGroupName: \"/shop/web\",\n      retention: logs.RetentionDays.TWO_WEEKS,\n    });\n    const alerts = new sns.Topic(this, \"Alerts\", { topicName: \"shop-alerts\" });\n", "note": "O grupo de logs recebe a retenção de uma enumeração, então o valor 15 que o cfn-lint pegou na lição 4 nem pode ser escrito. O tópico fica numa variável porque o alarme precisa dele."}, {"code": "    const errors = new cloudwatch.Metric({\n      namespace: \"Shop\", metricName: \"Errors5xx\", statistic: \"Sum\", period: Duration.minutes(1),\n    });\n    const alarm = errors.createAlarm(this, \"ErrorsHigh\", {\n      threshold: 10, evaluationPeriods: 3, datapointsToAlarm: 2,\n    });\n    alarm.addAlarmAction(new actions.SnsAction(alerts));\n  }\n}\n", "note": "Um alarme sobre a contagem de erros da loja, que avisa o tópico. A lição 10 explica cada número dele; o que importa aqui é que o alarme se refere ao tópico como objeto, não por um ARN digitado à mão."}, {"code": "\nmodule.exports = { ShopBase };\n\nif (require.main === module) {\n  const app = new App();\n  new ShopBase(app, \"ShopBase\", { env: { account: \"123456789012\", region: \"sa-east-1\" } });\n}\n", "note": "Exportada para um teste poder construí-la, e um `App` só quando o arquivo roda diretamente. A conta e a região são fixas, a conta do moto e São Paulo, para o template nomeá-las."}]}
```

Cada `new` cria um **construct**. Os usados aqui são os que o CDK chama de nível 2: uma classe por
tipo de recurso, com padrões escolhidos e opções nomeadas na linguagem. Abaixo deles, os constructs de
nível 1 (`CfnBucket`, `CfnLogGroup`) são os recursos do template um para um, sem nada acrescentado;
acima deles, os de nível 3, os padrões, montam um arranjo inteiro de vários serviços a partir de uma
chamada. **O nível decide quanto a biblioteca escreve por você**, e a próxima seção conta isso.
