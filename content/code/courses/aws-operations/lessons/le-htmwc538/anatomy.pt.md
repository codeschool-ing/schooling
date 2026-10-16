---
title: Um template, e o linter que o lê primeiro
version: 1
---

A lição 17 de `iac` mostrou o CloudFormation ao lado do Terraform: um template mandado para a AWS,
uma **stack** que lembra o que fez, nenhum arquivo de estado para proteger. Esta lição é sobre rodá-lo
em produção, onde as perguntas são o que uma mudança vai fazer antes de fazer, e o que mudou sem
ninguém avisar. Começa pelo arquivo.

## As quatro partes que importam

Um template é YAML (ou JSON) com até nove seções de topo, e quatro carregam quase tudo:

| seção | o que ela guarda |
|---|---|
| `Parameters` | valores escolhidos quando a stack é criada ou atualizada, com tipo e limites |
| `Resources` | a única obrigatória: cada recurso sob um **id lógico**, com um `Type` e `Properties` |
| `Outputs` | valores que a stack publica: um ARN, uma URL, para pessoas e para outras stacks |
| `Conditions` | verdadeiro ou falso, a partir de parâmetros, decidindo se um recurso é criado |

Dentro delas, **funções intrínsecas** ligam as peças. `!Ref` dá o valor de um parâmetro ou o
identificador principal de um recurso; `!GetAtt Uploads.Arn` dá um atributo de um recurso; `!Sub`
monta uma string com marcadores `${...}`. Uma referência também ordena a criação: o que é referido é
feito primeiro.

## O linter

O CloudFormation só lê um template quando ele é enviado, e um erro achado nessa hora é uma stack que
falhou e foi revertida. O **cfn-lint**, o linter de código aberto da própria AWS, o lê no seu notebook
antes, contra a especificação publicada de cada tipo de recurso. Ele vai para o mesmo ambiente virtual
do moto:

```sh
~/aws/venv/bin/pip install -q 'cfn-lint==1.57.1'
```

A stack base da loja guarda os logs web, o bucket de uploads e o tópico para onde vão os alertas. O
primeiro rascunho:

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Description: The shop's logs, uploads and alerts.

Parameters:
  Retention:
    Type: Number
    Default: 15
    Description: Days the web logs are kept.

Resources:
  WebLogs:
    Type: AWS::Logs::LogGroup
    Properties:
      LogGroupName: /shop/web
      RetentionInDays: !Ref Retention

  Uploads:
    Type: AWS::S3::Bucket
    DeletionPolicy: Retain
    Properties:
      BucketName: shop-uploads-123456789012
      VersioningConfiguration:
        Status: Enabled

  Alerts:
    Type: AWS::SNS::Topic
    Properties:
      TopicName: !Ref AlertTopicName

Outputs:
  UploadsArn:
    Value: !GetAtt Uploads.Arn
  AlertsArn:
    Value: !Ref Alerts
```

```
ana@laptop:~/aws/cfn$ cfn-lint shop.yaml; echo "exit status $?"
W1030 {'Ref': 'Retention'} is not one of [1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653] when 'Ref' is resolved at 'Resources/WebLogs/Properties/RetentionInDays'
shop.yaml:7:5

W3011 Both 'UpdateReplacePolicy' and 'DeletionPolicy' are needed to protect resource from deletion
shop.yaml:17:3

E1020 'AlertTopicName' is not one of ['Retention', 'WebLogs', 'Uploads', 'Alerts', 'AWS::AccountId', 'AWS::NoValue', 'AWS::NotificationARNs', 'AWS::Partition', 'AWS::Region', 'AWS::StackId', 'AWS::StackName', 'AWS::URLSuffix']
shop.yaml:28:7

exit status 6
```

Três achados, cada um com a linha em que está:

- **W1030**: um grupo de logs guarda logs por um de uma lista fixa de períodos, e o padrão do
  parâmetro, 15, não é um deles. É só um aviso porque o valor chega por um parâmetro, que poderia
  receber outro valor; com o padrão, a AWS recusaria o grupo de logs na criação, depois de tudo antes
  dele já ter sido feito.
- **W3011**: `DeletionPolicy: Retain` mantém o bucket quando a stack é excluída, mas não quando uma
  atualização o **substitui**; para isso precisa também de `UpdateReplacePolicy`. O template é válido
  e os dados não estão seguros.
- **E1020**: `!Ref AlertTopicName` não se refere a nada. O linter lista o que poderia ser referido.

O template corrigido define o padrão como 14, limita o parâmetro a valores que um grupo de logs aceita,
acrescenta a segunda política e dá nome ao tópico:

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Description: The shop's logs, uploads and alerts.

Parameters:
  Retention:
    Type: Number
    Default: 14
    AllowedValues: [7, 14, 30, 90]
    Description: Days the web logs are kept.

Resources:
  WebLogs:
    Type: AWS::Logs::LogGroup
    Properties:
      LogGroupName: /shop/web
      RetentionInDays: !Ref Retention

  Uploads:
    Type: AWS::S3::Bucket
    DeletionPolicy: Retain
    UpdateReplacePolicy: Retain
    Properties:
      BucketName: shop-uploads-123456789012
      VersioningConfiguration:
        Status: Enabled

  Alerts:
    Type: AWS::SNS::Topic
    Properties:
      TopicName: shop-alerts

Outputs:
  UploadsArn:
    Value: !GetAtt Uploads.Arn
  AlertsArn:
    Value: !Ref Alerts
```

```
ana@laptop:~/aws/cfn$ cfn-lint shop.yaml; echo "exit status $?"
exit status 0
```

**Status de saída 0 e nenhuma saída** é o resultado a ligar numa esteira: uma linha de buildspec
rodando `cfn-lint` antes de qualquer `deploy` transforma estes três erros num build que falhou em vez
de uma stack que falhou.
