---
title: Uma stack, o que ela possui, e o que ela deixa para trás
version: 1
---

Uma **stack** é o registro do CloudFormation de um template aplicado: quais recursos criou, com quais
ids físicos, com quais parâmetros, e cada evento no caminho. Crie a base da loja:

```
ana@laptop:~/aws/cfn$ aws cloudformation create-stack --stack-name shop-base --template-body file://shop.yaml --query StackId --output text
arn:aws:cloudformation:sa-east-1:123456789012:stack/shop-base/5eddddae-9d49-4a3a-a355-211cbbf3188d
ana@laptop:~/aws/cfn$ aws cloudformation wait stack-create-complete --stack-name shop-base
ana@laptop:~/aws/cfn$ aws cloudformation describe-stack-resources --stack-name shop-base --query 'StackResources[].[LogicalResourceId,ResourceType,PhysicalResourceId]' --output text
WebLogs	AWS::Logs::LogGroup	/shop/web
Uploads	AWS::S3::Bucket	shop-uploads-123456789012
Alerts	AWS::SNS::Topic	arn:aws:sns:sa-east-1:123456789012:shop-alerts
ana@laptop:~/aws/cfn$ aws cloudformation describe-stacks --stack-name shop-base --query 'Stacks[0].Outputs[].[OutputKey,OutputValue]' --output text
UploadsArn	arn:aws:s3:::shop-uploads-123456789012
AlertsArn	arn:aws:sns:sa-east-1:123456789012:shop-alerts
```

O terceiro comando é o útil. `describe-stack-resources` é a ligação entre os nomes do template e os da
nuvem: `WebLogs` é o grupo de logs `/shop/web`, `Alerts` é um tópico cujo id físico é o ARN dele. **Tudo
o mais que mexe nesses recursos deve passar pela stack**, porque a stack é o único lugar que sabe que
eles pertencem um ao outro.

## Quando uma criação falha

Na AWS, um recurso que falha durante a criação faz a stack inteira ser **revertida**: o CloudFormation
apaga o que tinha feito, na ordem inversa, e a stack termina em `ROLLBACK_COMPLETE`. Uma stack nesse
estado não pode ser atualizada, só excluída e criada de novo. Os eventos, `describe-stack-events`,
trazem o motivo no primeiro recurso que falhou, e é essa linha que se lê; a dúzia de linhas
`CREATE_CANCELLED` e `DELETE_COMPLETE` depois dela são consequências.

`--disable-rollback`, ou `--on-failure DO_NOTHING`, deixa o que foi feito no lugar para ser examinado,
e vale conhecer para um template em desenvolvimento. O moto nunca falha uma criação pelos motivos que a
AWS falharia, então nenhum dos dois caminhos foi executado aqui.

## Excluindo uma stack, e o que ela guarda

```
ana@laptop:~/aws/cfn$ aws cloudformation delete-stack --stack-name shop-base
ana@laptop:~/aws/cfn$ aws cloudformation wait stack-delete-complete --stack-name shop-base
ana@laptop:~/aws/cfn$ aws logs describe-log-groups --log-group-name-prefix /shop/ --query logGroups
[]
ana@laptop:~/aws/cfn$ aws s3 ls
2026-10-16 12:46:21 shop-uploads-123456789012
```

A stack sumiu, e o grupo de logs que ela criou também. O bucket `shop-uploads-123456789012` continua
lá, porque a `DeletionPolicy` dele é `Retain`. Essa é a política para tudo que guarda dados que a
stack, no fundo, não possui: **um bucket de uploads de clientes não pode sumir porque alguém limpou uma
stack**. Agora o bucket não pertence a stack nenhuma, e esse é também o custo: nada o gerencia, e ele é
o primeiro tipo de recurso que a lição 24 chama de recurso sem dono.

Mais duas proteções, ambas documentadas e não executadas aqui, porque o moto falha na primeira:

- **proteção contra exclusão**, `update-termination-protection --enable-termination-protection`, faz
  o `delete-stack` recusar até ela ser desligada;
- **uma política de stack** nomeia recursos que uma atualização não pode substituir nem apagar, então
  uma mudança que substituiria o banco falha em vez de fazê-lo.
