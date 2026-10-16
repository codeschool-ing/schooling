---
title: Conformance packs, conformidade como arquivo
version: 1
---

Vinte regras criadas uma a uma são vinte comandos que ninguém vai repetir igual na próxima conta. Um
**conformance pack** é o conjunto como um arquivo, um template no formato do CloudFormation, implantado
como unidade e reportado como unidade: um pack está em conformidade quando todas as suas regras estão. A
AWS publica packs de exemplo para frameworks comuns, e o de uma equipe costuma ser uma lista curta das
regras que ela de fato quer.

`shop-pack.yaml`:

```yaml
# shop-pack.yaml: the rules the shop means, deployed as one
Resources:
  S3PublicRead:
    Type: AWS::Config::ConfigRule
    Properties:
      ConfigRuleName: s3-public-read
      Source:
        Owner: AWS
        SourceIdentifier: S3_BUCKET_PUBLIC_READ_PROHIBITED
      Scope:
        ComplianceResourceTypes:
          - AWS::S3::Bucket
  RequiredOwner:
    Type: AWS::Config::ConfigRule
    Properties:
      ConfigRuleName: required-owner
      InputParameters:
        tag1Key: owner
      Source:
        Owner: AWS
        SourceIdentifier: REQUIRED_TAGS
  TrailEnabled:
    Type: AWS::Config::ConfigRule
    Properties:
      ConfigRuleName: cloudtrail-enabled
      MaximumExecutionFrequency: TwentyFour_Hours
      Source:
        Owner: AWS
        SourceIdentifier: CLOUD_TRAIL_ENABLED
```

A terceira regra é periódica: se uma trilha está ligada é um fato da conta, conferido uma vez por dia. O
ponto da lição 20, de que uma trilha que pode ser parada em silêncio não é log de auditoria, vira uma
regra que diz isso.

```
ana@laptop:~/aws/config$ aws configservice put-conformance-pack --conformance-pack-name shop-baseline --template-body file://shop-pack.yaml 2>&1 | grep -m1 ERROR
aws: [ERROR]: An error occurred (500) when calling the PutConformancePack operation (reached max retries: 2): <!doctype html>
```

O moto não tem conformance packs para uma conta só. Na AWS o mesmo comando implanta o pack, e
`describe-conformance-pack-compliance` informa cada regra; com o AWS Organizations, um **conformance pack
da organização** implanta o mesmo arquivo em todas as contas, que é como uma equipe mantém cinquenta
contas num padrão.

## Remediação, com cuidado

Uma regra pode levar uma **remediação**: um documento de Automation do Systems Manager que corrige um
recurso fora de conformidade, rodado à mão ou automaticamente. Ligar o bloqueio de acesso público de um
bucket que nunca deve ser público é um bom candidato a remediação automática. Acrescentar uma tag que falta
não é: a remediação teria de inventar o dono. **Automatize as correções cuja resposta certa não depende do
recurso**, e deixe o resto para um ticket, o segundo assunto da lição 14.
