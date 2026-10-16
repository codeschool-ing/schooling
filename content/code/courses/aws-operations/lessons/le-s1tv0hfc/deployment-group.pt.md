---
title: O deployment group, e o que o moto esqueceu
version: 1
---

O CodeDeploy se organiza em dois níveis. Uma **aplicação** é um nome. Um **deployment group** dentro
dela diz onde e como: qual serviço do ECS, qual balanceador e quais target groups, qual estratégia,
quais alarmes interrompem um deploy e o que acontece quando um é interrompido. O deployment group é
onde um rollback é desenhado, então vale lê-lo devagar.

```json
{
  "applicationName": "shop-api",
  "deploymentGroupName": "prod",
  "serviceRoleArn": "arn:aws:iam::123456789012:role/shop-deploy",
  "deploymentConfigName": "CodeDeployDefault.ECSCanary10Percent5Minutes",
  "deploymentStyle": {
    "deploymentType": "BLUE_GREEN",
    "deploymentOption": "WITH_TRAFFIC_CONTROL"
  },
  "ecsServices": [{ "clusterName": "shop", "serviceName": "api" }],
  "loadBalancerInfo": {
    "targetGroupPairInfoList": [{
      "targetGroups": [{ "name": "api-blue" }, { "name": "api-green" }],
      "prodTrafficRoute": { "listenerArns": ["arn:aws:elasticloadbalancing:sa-east-1:123456789012:listener/app/shop/5f2a/443a"] },
      "testTrafficRoute": { "listenerArns": ["arn:aws:elasticloadbalancing:sa-east-1:123456789012:listener/app/shop/5f2a/8443"] }
    }]
  },
  "blueGreenDeploymentConfiguration": {
    "deploymentReadyOption": { "actionOnTimeout": "CONTINUE_DEPLOYMENT" },
    "terminateBlueInstancesOnDeploymentSuccess": {
      "action": "TERMINATE",
      "terminationWaitTimeInMinutes": 60
    }
  },
  "alarmConfiguration": {
    "enabled": true,
    "alarms": [{ "name": "api-green-5xx" }, { "name": "api-green-p99" }]
  },
  "autoRollbackConfiguration": {
    "enabled": true,
    "events": ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }
}
```

As peças, na ordem em que um deploy as encontra:

- **`targetGroupPairInfoList`** nomeia os dois target groups, `api-blue` e `api-green`, e dois
  listeners. O de **produção**, na 443, é o que os clientes alcançam. O de **teste**, na 8443, chega
  só ao verde, antes de qualquer cliente, e é contra ele que um teste de fumaça roda.
- **`deploymentReadyOption`** diz o que acontece quando o verde está saudável: continuar na hora, ou
  esperar alguém apertar continuar, até um limite de tempo.
- **`deploymentConfigName`** é a estratégia da seção anterior.
- **`alarmConfiguration`** lista alarmes do CloudWatch. Se qualquer um deles entrar em `ALARM`
  durante o deploy, o CodeDeploy o interrompe.
- **`autoRollbackConfiguration`** diz que uma falha, ou uma interrupção causada por alarme, leva o
  tráfego de volta ao azul sozinha.
- **`terminationWaitTimeInMinutes`** mantém o azul rodando por uma hora depois do sucesso. Durante essa
  hora um rollback ainda é mover o listener; depois dela, o azul acabou e um rollback é um deploy novo.

## Pergunte o que foi guardado

```
ana@laptop:~/aws/deploy$ aws deploy create-application --application-name shop-api --compute-platform ECS --query applicationId --output text
2c031cba-9f6c-4da5-8236-f2caf533d918
ana@laptop:~/aws/deploy$ aws deploy create-deployment-group --cli-input-json file://deployment-group.json --query deploymentGroupId --output text
548573b0-30f3-4e71-815e-6fc08cb52c49
ana@laptop:~/aws/deploy$ aws deploy get-deployment-group --application-name shop-api --deployment-group-name prod --query 'deploymentGroupInfo.[deploymentConfigName,autoRollbackConfiguration.events,alarmConfiguration]'
[
    "CodeDeployDefault.ECSCanary10Percent5Minutes",
    [
        "DEPLOYMENT_FAILURE",
        "DEPLOYMENT_STOP_ON_ALARM"
    ],
    {}
]
```

O moto aceitou o grupo e devolveu um id, e depois, quando pedimos para lê-lo de volta, devolveu a
estratégia e os eventos de rollback e **um `alarmConfiguration` vazio**. Os dois alarmes sumiram. O
moto não guarda esse campo, e nada na resposta dele ao `create-deployment-group` disse isso.

Na AWS o mesmo erro acontece de outro jeito: um nome de alarme com erro de digitação, ou um alarme
criado em outra região, é aceito, e o grupo passa a vigiar um alarme que não existe e nunca dispara.
**De um jeito ou de outro a lição é a mesma: leia a configuração de volta e compare com o que você
quis dizer**, porque um rollback que depende de um alarme só é tão real quanto o alarme. A lição 4
transforma essa comparação num hábito, com o nome de drift.

## Um deploy

O deploy em si nomeia um **AppSpec**, que diz ao CodeDeploy qual task definition rodar e quais hooks
chamar:

```yaml
version: 0.0
Resources:
  - TargetService:
      Type: AWS::ECS::Service
      Properties:
        TaskDefinition: "arn:aws:ecs:sa-east-1:123456789012:task-definition/shop-api:42"
        LoadBalancerInfo:
          ContainerName: "api"
          ContainerPort: 8080
Hooks:
  - AfterAllowTestTraffic: "arn:aws:lambda:sa-east-1:123456789012:function:shop-smoke-test"
```

O hook `AfterAllowTestTraffic` roda uma função Lambda assim que o listener de teste alcança o verde,
e o deploy só continua se a função relatar sucesso. Esse é o teste de fumaça, rodado contra a versão
nova antes de uma única requisição de cliente chegar a ela.

```
ana@laptop:~/aws/deploy$ DEPLOYMENT=$(aws deploy create-deployment --application-name shop-api --deployment-group-name prod --revision file://revision.json --query deploymentId --output text); echo "$DEPLOYMENT"
16fc6244-e1b1-4876-b5ca-d8fbb46d84a2
ana@laptop:~/aws/deploy$ aws deploy get-deployment --deployment-id 16fc6244-e1b1-4876-b5ca-d8fbb46d84a2 --query 'deploymentInfo.[status,deploymentConfigName,deploymentOverview]'
[
    "Created",
    "CodeDeployDefault.ECSCanary10Percent5Minutes",
    {
        "Pending": 0,
        "InProgress": 0,
        "Succeeded": 0,
        "Failed": 0,
        "Skipped": 0,
        "Ready": 0
    }
]
```

`Created`, com todos os contadores em zero, e vai ficar assim: o moto registra o deploy e não executa
nada, então **nenhum tráfego mudou, nenhum hook rodou e nenhum alarme foi consultado**. Na AWS o mesmo
comando subiria o verde, rodaria o hook, passaria 10% da produção, esperaria cinco minutos e passaria
o resto.
