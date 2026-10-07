---
title: CloudFormation, onde a AWS guarda o state
version: 2
---

O Terraform roda na sua máquina, chama a API da AWS e guarda um arquivo de state para lembrar o que
fez. **O CloudFormation leva esses dois trabalhos para dentro da AWS.** É um serviço da própria AWS:
você envia um template, ele calcula as mudanças, faz as chamadas e lembra o resultado numa **stack**.
Não há nada a instalar, nenhum arquivo de state a proteger e nenhum lock a configurar. O preço é o
óbvio: ele descreve a AWS e nada mais.

## Um template

A mesma rede, escrita para o CloudFormation em YAML, em `~/shop/cfn/network.yaml`:

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Description: The shop's network, as a CloudFormation stack.

Parameters:
  VpcCidr:
    Type: String
    Default: 10.20.0.0/16

Resources:
  ShopVpc:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: !Ref VpcCidr
      Tags:
        - Key: Name
          Value: shop

  WebSubnetA:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref ShopVpc
      CidrBlock: 10.20.1.0/24
      AvailabilityZone: sa-east-1a
      Tags:
        - Key: Name
          Value: shop-web-a

  WebSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupName: web
      GroupDescription: web servers
      VpcId: !Ref ShopVpc
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 443
          ToPort: 443
          CidrIp: 0.0.0.0/0

Outputs:
  VpcId:
    Value: !Ref ShopVpc
  WebSubnetId:
    Value: !Ref WebSubnetA
```

As peças se encaixam no que você já conhece. Os `Parameters` fazem o papel das variáveis, com um
valor padrão. Cada entrada em `Resources` tem um **logical id**, `ShopVpc` ou `WebSubnetA`, que é o
nome que o template usa para ela, e um `Type` do catálogo da própria AWS. `!Ref ShopVpc` é uma
referência: dá à sub-rede o id real da VPC e ordena as duas, como `aws_vpc.shop.id` fazia na aula 2.
`Outputs` são outputs. A regra do security group aqui é uma propriedade do grupo, e não um recurso à
parte, porque é assim que esse tipo de recurso é escrito.

## Um change set é o plano

O equivalente do `terraform plan` no CloudFormation é um **change set**: as mudanças que ele faria,
calculadas e guardadas, esperando alguém executá-las. A Ana cria um para uma stack que ainda não
existe, então todo recurso é uma adição:

```
ana@laptop:~/shop/cfn$ aws cloudformation create-change-set --stack-name shop-network --change-set-name first --change-set-type CREATE --template-body file://network.yaml --query Id --output text
arn:aws:cloudformation:sa-east-1:123456789012:changeSet/first/21e6674d-630c-493a-95a3-d7f59891f4d0
ana@laptop:~/shop/cfn$ aws cloudformation wait change-set-create-complete --stack-name shop-network --change-set-name first
ana@laptop:~/shop/cfn$ aws cloudformation describe-change-set --stack-name shop-network --change-set-name first --query "Changes[].ResourceChange.[Action,LogicalResourceId,ResourceType]" --output text
Add	ShopVpc	AWS::EC2::VPC
Add	WebSubnetA	AWS::EC2::Subnet
Add	WebSecurityGroup	AWS::EC2::SecurityGroup
```

Executá-lo é o apply. O CloudFormation então percorre os recursos na ordem que as referências impõem,
e a stack avisa quando termina:

```
ana@laptop:~/shop/cfn$ aws cloudformation execute-change-set --stack-name shop-network --change-set-name first
ana@laptop:~/shop/cfn$ aws cloudformation wait stack-create-complete --stack-name shop-network
ana@laptop:~/shop/cfn$ aws cloudformation describe-stacks --stack-name shop-network --query "Stacks[0].StackStatus" --output text
CREATE_COMPLETE
```

O `aws cloudformation deploy` faz os dois passos num comando só, e é o que a maioria das pessoas
digita; os dois comandos separados deixam o passo de revisão visível.

## A stack é o state

O que o Terraform guarda no `terraform.tfstate`, o vínculo entre um nome no arquivo e um id na nuvem,
o CloudFormation guarda na stack e mostra quando pedem:

```
ana@laptop:~/shop/cfn$ aws cloudformation describe-stack-resources --stack-name shop-network --query "StackResources[].[LogicalResourceId,PhysicalResourceId]" --output text
ShopVpc	vpc-629e2ba218332e0f6
WebSubnetA	subnet-a3d42d49d2d9bda8a
WebSecurityGroup	sg-d4bba50dd9be56af4
```

Você não tem como perder esse arquivo, deixá-lo num bucket que qualquer um lê ou editá-lo à mão,
porque não existe arquivo. E a stack é dona do que criou, então apagar a stack apaga a rede:

```
ana@laptop:~/shop/cfn$ aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].VpcId" --output text | wc -w
1
ana@laptop:~/shop/cfn$ aws cloudformation delete-stack --stack-name shop-network
ana@laptop:~/shop/cfn$ aws cloudformation wait stack-delete-complete --stack-name shop-network
ana@laptop:~/shop/cfn$ aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].VpcId" --output text | wc -w
0
```

Dois hábitos diferem dos do Terraform. **Quando um recurso falha durante a criação de uma stack, o
CloudFormation faz rollback** e remove o que já tinha feito, enquanto o Terraform mantém a metade que
deu certo e a completa no apply seguinte (aula 9). E o CloudFormation tem **detecção de drift**
embutida: compara cada recurso com o template e aponta o que alguém mudou à mão, o trabalho que o
`terraform plan -refresh-only` fez na aula 7.

## O que o laboratório não consegue mostrar

O moto emula o CloudFormation o bastante para criar e apagar uma stack, e não mais que isso. Pedindo
detecção de drift, ele falha com um erro interno próprio. Pedindo um change set para uma stack que
**já existe**, ele lista todo recurso como `Add`, o que um change set de verdade nunca faria para
recursos que já existem. Por isso esta seção para na criação e na remoção. Numa conta real, o change
set de uma atualização marca cada recurso como `Modify` ou `Remove`, e diz se uma modificação exige
substituição, a mesma pergunta que o `-/+` responde num plano do Terraform.
