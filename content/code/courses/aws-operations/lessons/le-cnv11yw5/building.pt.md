---
title: Montando o web ACL da loja
version: 1
---

Um web ACL protege alguma coisa, e neste laboratório é um balanceador de carga. O `aws-compute` montou o
da loja; no moto não existe nenhum até você criar, então o primeiro passo é uma rede com duas sub-redes e
um Application Load Balancer chamado `shop`, em `~/aws/waf`:

```sh
mkdir -p ~/aws/waf && cd ~/aws/waf
VPC=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query Vpc.VpcId --output text)
A=$(aws ec2 create-subnet --vpc-id $VPC --cidr-block 10.0.1.0/24 --availability-zone sa-east-1a --query Subnet.SubnetId --output text)
B=$(aws ec2 create-subnet --vpc-id $VPC --cidr-block 10.0.2.0/24 --availability-zone sa-east-1b --query Subnet.SubnetId --output text)
aws elbv2 create-load-balancer --name shop --subnets $A $B --query 'LoadBalancers[0].DNSName' --output text
```

## Os endereços a recusar

Um conjunto de IPs é uma lista de endereços e faixas, guardada à parte das regras para poder mudar sem
mexer nelas. O da loja tem uma faixa e um endereço que a equipe viu tentando senhas:

```
ana@laptop:~/aws/waf$ IPSET=$(aws wafv2 create-ip-set --name blocked --scope REGIONAL --ip-address-version IPV4 --addresses 203.0.113.0/24 198.51.100.7/32 --query Summary.ARN --output text); echo $IPSET
arn:aws:wafv2:sa-east-1:123456789012:regional/ipset/blocked/a14bb4e5-a7e1-40fd-8d6d-627cc261cb16
ana@laptop:~/aws/waf$ jq --arg a "$IPSET" '.Rules[0].Statement.IPSetReferenceStatement.ARN = $a' web-acl.json > shop-acl.json
```

Os endereços são das faixas reservadas para documentação, que nenhum computador real usa.

## O web ACL

O web ACL é um arquivo, `web-acl.json`, com as três regras da seção anterior. O ARN do conjunto de IPs só
é conhecido depois que o conjunto existe, então o arquivo deixa uma nota no lugar e o `jq` escreve o ARN,
como fez o segundo comando acima, em `shop-acl.json`.

`web-acl.json`:

```json
{
  "Name": "shop",
  "Scope": "REGIONAL",
  "DefaultAction": {
    "Allow": {}
  },
  "VisibilityConfig": {
    "SampledRequestsEnabled": true,
    "CloudWatchMetricsEnabled": true,
    "MetricName": "shop"
  },
  "Rules": [
    {
      "Name": "blocked-addresses",
      "Priority": 0,
      "Statement": {
        "IPSetReferenceStatement": {
          "ARN": "set by jq from the IP set"
        }
      },
      "Action": {
        "Block": {}
      },
      "VisibilityConfig": {
        "SampledRequestsEnabled": true,
        "CloudWatchMetricsEnabled": true,
        "MetricName": "blocked-addresses"
      }
    },
    {
      "Name": "login-rate",
      "Priority": 1,
      "Statement": {
        "RateBasedStatement": {
          "Limit": 100,
          "EvaluationWindowSec": 300,
          "AggregateKeyType": "IP",
          "ScopeDownStatement": {
            "ByteMatchStatement": {
              "FieldToMatch": {
                "UriPath": {}
              },
              "PositionalConstraint": "STARTS_WITH",
              "SearchString": "/login",
              "TextTransformations": [
                {
                  "Priority": 0,
                  "Type": "NONE"
                }
              ]
            }
          }
        }
      },
      "Action": {
        "Block": {}
      },
      "VisibilityConfig": {
        "SampledRequestsEnabled": true,
        "CloudWatchMetricsEnabled": true,
        "MetricName": "login-rate"
      }
    },
    {
      "Name": "aws-common",
      "Priority": 2,
      "Statement": {
        "ManagedRuleGroupStatement": {
          "VendorName": "AWS",
          "Name": "AWSManagedRulesCommonRuleSet",
          "RuleActionOverrides": [
            {
              "Name": "SizeRestrictions_BODY",
              "ActionToUse": {
                "Count": {}
              }
            }
          ]
        }
      },
      "OverrideAction": {
        "None": {}
      },
      "VisibilityConfig": {
        "SampledRequestsEnabled": true,
        "CloudWatchMetricsEnabled": true,
        "MetricName": "aws-common"
      }
    }
  ]
}
```

Toda regra, e o próprio web ACL, traz um `VisibilityConfig`: o nome da métrica do CloudWatch em que os
casamentos são contados, e se o WAF guarda uma amostra das requisições que casaram. Essas métricas são
as da lição 8, no namespace `AWS/WAFV2`, e são como a seção depois da próxima sabe o que uma regra teria
feito.

O grupo gerenciado diz `OverrideAction: None`, que quer dizer *use as ações do próprio grupo*, e depois
sobrescreve uma delas. `SizeRestrictions_BODY` bloqueia corpos de requisição acima de 8 KB, e as fotos de
produto da loja são enviadas em corpos maiores; em `Count`, essa regra informa e não recusa nada, e as
outras regras do grupo continuam bloqueando.

## A primeira recusa, da linha de comando

```
ana@laptop:~/aws/waf$ aws wafv2 create-web-acl --cli-input-json file://shop-acl.json

aws: [ERROR]: Invalid base64: "/login"
```

**Esta é da linha de comando, não do WAF.** `SearchString` é binário na API, e quando a linha de comando
lê valores binários de um JSON ela os espera em base64, então `/login` não é um valor válido. Ou o
arquivo diz `L2xvZ2lu`, que ninguém consegue revisar, ou o comando diz que o arquivo é texto puro:

```
ana@laptop:~/aws/waf$ aws wafv2 create-web-acl --cli-input-json file://shop-acl.json --cli-binary-format raw-in-base64-out --query Summary.Id --output text
1649d3ae-e59b-4d9f-a513-7fcaae2067c3
```

```
ana@laptop:~/aws/waf$ ID=$(aws wafv2 list-web-acls --scope REGIONAL --query "WebACLs[0].Id" --output text)
ana@laptop:~/aws/waf$ aws wafv2 get-web-acl --name shop --scope REGIONAL --id $ID --query 'WebACL.Rules[].[Priority,Name,keys(Action || OverrideAction)[0]]' --output text
0	blocked-addresses	Block
1	login-rate	Block
2	aws-common	None
ana@laptop:~/aws/waf$ aws wafv2 get-web-acl --name shop --scope REGIONAL --id $ID --query WebACL.Capacity
3
```

Três regras na ordem de prioridade, duas que agem e o grupo que mantém as próprias ações. A capacidade é o
número de que desconfiar: **o moto cobra uma unidade por regra**. Na AWS este web ACL custa cerca de 705
WCU, 700 deles do conjunto comum, e o comando que pergunta antes de salvar nem existe no moto:

```
ana@laptop:~/aws/waf$ aws wafv2 check-capacity --scope REGIONAL --cli-binary-format raw-in-base64-out --rules "$(jq .Rules shop-acl.json)" 2>&1 | grep -m1 ERROR
aws: [ERROR]: An error occurred (500) when calling the CheckCapacity operation (reached max retries: 2): <!doctype html>
```

## Anexando

Um web ACL não faz nada até ser associado a um recurso, e um recurso tem no máximo um web ACL:

```
ana@laptop:~/aws/waf$ ACL=$(aws wafv2 list-web-acls --scope REGIONAL --query "WebACLs[0].ARN" --output text)
ana@laptop:~/aws/waf$ LB=$(aws elbv2 describe-load-balancers --names shop --query "LoadBalancers[0].LoadBalancerArn" --output text)
ana@laptop:~/aws/waf$ aws wafv2 associate-web-acl --web-acl-arn $ACL --resource-arn $LB
ana@laptop:~/aws/waf$ aws wafv2 get-web-acl-for-resource --resource-arn $LB --query WebACL.Name
"shop"
```

Daqui em diante, na AWS, toda requisição ao balanceador passa pelas três regras. **No laboratório
nenhuma passa**: o moto guarda o web ACL e a associação e não inspeciona tráfego, então se uma regra casa
é algo para aprender na documentação da AWS e, numa conta real, nas métricas e nos logs do web ACL.
