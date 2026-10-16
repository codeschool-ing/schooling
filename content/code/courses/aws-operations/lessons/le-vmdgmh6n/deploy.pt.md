---
title: O deploy, o bootstrap, e o que o moto pulou
version: 1
---

`cdk deploy` é o jeito usual de mandar o template para a AWS, e precisa da conta com **bootstrap**
antes: `cdk bootstrap` cria uma stack chamada `CDKToolkit` com um bucket e um repositório para os
assets da seção anterior, e papéis que o deploy assume para enviá-los e para chamar o CloudFormation.
Ele também grava a versão do bootstrap num parâmetro, e é isso que as últimas linhas do template leem:

```
ana@laptop:~/aws/cdk$ sed -n '/^Parameters:/,$p' template.yaml
Parameters:
  BootstrapVersion:
    Type: AWS::SSM::Parameter::Value<String>
    Default: /cdk-bootstrap/hnb659fds/version
    Description: Version of the CDK Bootstrap resources in this environment, automatically retrieved from SSM Parameter Store. [cdk:skip]

```

Um parâmetro do tipo `AWS::SSM::Parameter::Value<String>` recebe o valor do Parameter Store quando a
stack é criada, a partir do nome em `Default`. **Um template do CDK pergunta se a conta passou pelo
bootstrap**, e uma stack criada onde ela não passou falha nesse parâmetro.

## Contra o moto

Nem `cdk bootstrap` nem `cdk deploy` foram executados para este curso. Os dois criam a stack do toolkit
e enviam para o bucket dela pelos papéis do próprio CDK, e o moto implementa pouco demais desse
caminho. O que o CDK entrega ao CloudFormation ainda é um template comum, então o laboratório o manda
com a linha de comando da AWS, como a lição 4 fez. Primeiro sem o parâmetro:

```
ana@laptop:~/aws/cdk$ aws cloudformation create-stack --stack-name ShopBase --template-body file://cdk.out/ShopBase.template.json --query StackId --output text

aws: [ERROR]: Unable to parse response (syntax error: line 1, column 0), invalid XML received. Further retries may succeed:
b'<!doctype html>\n<html lang=en>\n<title>500 Internal Server Error</title>\n<h1>Internal Server Error</h1>\n<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>\n'
ana@laptop:~/aws/cdk$ aws cloudformation wait stack-create-complete --stack-name ShopBase

aws: [ERROR]: Waiter StackCreateComplete failed: Waiter encountered a terminal failure state: Matched expected service error code: ValidationError
ana@laptop:~/aws/cdk$ aws cloudformation describe-stacks --stack-name ShopBase --query 'Stacks[0].[StackStatus,StackStatusReason]' --output text

aws: [ERROR]: An error occurred (ValidationError) when calling the DescribeStacks operation: Stack with id ShopBase does not exist
```

O moto falha com um erro interno onde a AWS recusaria com uma mensagem nomeando o parâmetro que falta.
Depois com o parâmetro posto onde o `cdk bootstrap` o teria posto:

```
ana@laptop:~/aws/cdk$ aws ssm put-parameter --name /cdk-bootstrap/hnb659fds/version --type String --value 30 --query Version
1
ana@laptop:~/aws/cdk$ aws cloudformation create-stack --stack-name ShopBase --template-body file://cdk.out/ShopBase.template.json --query StackId --output text
arn:aws:cloudformation:sa-east-1:123456789012:stack/ShopBase/63342bf5-29f0-4a9d-a1a8-902eb97d026e
ana@laptop:~/aws/cdk$ aws cloudformation wait stack-create-complete --stack-name ShopBase
ana@laptop:~/aws/cdk$ aws cloudformation describe-stacks --stack-name ShopBase --query 'Stacks[0].StackStatus' --output text
CREATE_COMPLETE
ana@laptop:~/aws/cdk$ aws cloudformation describe-stack-resources --stack-name ShopBase --query 'StackResources[].[LogicalResourceId,ResourceType]' --output text
Uploads4F6EB0FD	AWS::S3::Bucket
None	None
WebLogs48A7C011	AWS::Logs::LogGroup
Alerts91F83244	AWS::SNS::Topic
None	None
None	None
```

`CREATE_COMPLETE`, e três dos seis recursos estão `None`. **O moto criou o bucket, o grupo de logs e o
tópico, e pulou em silêncio a política do bucket, o alarme e os metadados**, enquanto informava a
stack como completa. A política que recusa HTTP sem TLS, a única decisão de que tratou a seção
anterior inteira, não existe no laboratório.

É a segunda vez neste curso que o moto informa sucesso sobre algo que não fez, depois do build da lição
1, e é o motivo de a próxima seção existir: **um teste que lê o template não depende do que nenhum
serviço fez com ele**.

## Numa conta real

Na AWS, o mesmo app seria implantado com dois comandos, rodados uma vez e depois a cada mudança:

```sh
cdk bootstrap aws://123456789012/sa-east-1
cdk deploy ShopBase
```

`cdk deploy` cria um change set, mostra as partes relevantes para segurança (declarações novas de IAM,
regras novas de security group) e pede confirmação antes de executá-lo. `cdk diff` mostra a diferença
do template para o que está implantado, sem mudar nada. Numa esteira, `cdk synth` roda no build e o
deploy executa o template sintetizado, com um change set e uma aprovação entre eles, exatamente como a
lição 4 descreveu.
