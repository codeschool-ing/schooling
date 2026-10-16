---
title: "O grupo: três números e um template"
version: 1
---

Um grupo de auto scaling costuma ser apresentado como a coisa que acrescenta servidores quando o
tráfego sobe. Acrescentar servidores é o que um grupo faz com um número que por acaso se move. **Um grupo é um laço de controle sobre uma
contagem**: ele guarda um número de instâncias, compara com as instâncias que existem, e lança ou
termina até os dois concordarem. Ele continua fazendo isso com o número parado ou não, e quando nada
está escalando ele segue substituindo o que falha.

## Do que um grupo é feito

Três números, um template e uma lista de subnets.

- **O mínimo** é o menor número de instâncias que o grupo roda, diga o que disser qualquer política.
- **O máximo** é o maior, e é um teto para a conta tanto quanto para a capacidade.
- **A capacidade desejada** é o número que o grupo está buscando agora. Ela tem de ficar entre os
  outros dois, e é o único número que as políticas de escala movem (lição 5).

O template diz o que cada instância é, e as subnets dizem onde as instâncias podem ir. Uma subnet
fica numa só Availability Zone, então a lista de subnets é também a lista de zonas que o grupo pode
usar. A Ana pega todas as subnets da VPC padrão do moto, uma por zona de São Paulo, junta os ids
com vírgulas e cria o grupo:

```
ana@laptop:~/aws$ SUBNETS=$(aws ec2 describe-subnets --query 'join(`,`, Subnets[].SubnetId)' --output text)
ana@laptop:~/aws$ echo "$SUBNETS"
subnet-a320d80c3247aca2b,subnet-fec45bdedb73af5bf,subnet-0f090c6c9427312e3
ana@laptop:~/aws$ aws autoscaling create-auto-scaling-group --auto-scaling-group-name web --launch-template 'LaunchTemplateName=web,Version=$Default' --min-size 2 --max-size 6 --desired-capacity 3 --vpc-zone-identifier "$SUBNETS"
ana@laptop:~/aws$ aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names web --query "AutoScalingGroups[].{min: MinSize, max: MaxSize, desired: DesiredCapacity, template: LaunchTemplate.Version, zones: AvailabilityZones}"
[
    {
        "min": 2,
        "max": 6,
        "desired": 3,
        "template": "$Default",
        "zones": [
            "sa-east-1a",
            "sa-east-1b",
            "sa-east-1c"
        ]
    }
]
ana@laptop:~/aws$ aws autoscaling describe-auto-scaling-instances --query "AutoScalingInstances[].[InstanceId,LifecycleState,HealthStatus,LaunchTemplate.Version]" --output table
------------------------------------------------------
|            DescribeAutoScalingInstances            |
+----------------------+-------------+----------+----+
|  i-b96143049d6fcbfd7 |  InService  |  Healthy |  1 |
|  i-1c9f5ffde740488e8 |  InService  |  Healthy |  1 |
|  i-c6669b95cfcc5be41 |  InService  |  Healthy |  1 |
+----------------------+-------------+----------+----+
```

O `create-auto-scaling-group` não imprime nada quando funciona. A descrição mostra os três números e
as três zonas que o grupo deduziu das subnets. **O template ainda aparece como `$Default` ali, mas
cada instância registra um número.** O nome é resolvido no momento de cada lançamento, e a versão de
que uma instância veio passa a ser um fato sobre ela. É por isso que a última seção desta lição tem
trabalho a fazer.

## Como o grupo marca suas instâncias

Uma instância lançada por um grupo leva as tags da versão do template, e mais três que a própria AWS
escreve:

```
ana@laptop:~/aws$ aws ec2 describe-instances --filters Name=tag:aws:autoscaling:groupName,Values=web --query "Reservations[0].Instances[0].Tags" --output table
-----------------------------------------------------------
|                    DescribeInstances                    |
+--------------------------------+------------------------+
|               Key              |         Value          |
+--------------------------------+------------------------+
|  app                           |  shop                  |
|  aws:ec2launchtemplate:id      |  lt-420bf22b86d1ab21b  |
|  aws:ec2launchtemplate:version |  1                     |
|  aws:autoscaling:groupName     |  web                   |
+--------------------------------+------------------------+
```

O prefixo `aws:` é reservado: ninguém pode escrever essas tags, então elas são um caminho confiável
de uma instância de volta ao seu grupo e à versão do template. **`aws:autoscaling:groupName` é o
filtro para "as instâncias deste grupo"**, porque os ids delas são escolhidos pelo grupo e mudam a
cada substituição. Os comandos da próxima seção o usam.

## Movendo a capacidade desejada à mão

Uma política move a capacidade desejada, e uma pessoa também pode. O `set-desired-capacity` é a
alavanca manual, e o grupo lança ou termina para acompanhar:

```
ana@laptop:~/aws$ aws autoscaling set-desired-capacity --auto-scaling-group-name web --desired-capacity 5
ana@laptop:~/aws$ aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names web --query "AutoScalingGroups[].[DesiredCapacity,length(Instances)]" --output text
5	5
ana@laptop:~/aws$ aws autoscaling set-desired-capacity --auto-scaling-group-name web --desired-capacity 8
ana@laptop:~/aws$ aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names web --query "AutoScalingGroups[].[MaxSize,DesiredCapacity,length(Instances)]" --output text
6	8	8
ana@laptop:~/aws$ aws autoscaling set-desired-capacity --auto-scaling-group-name web --desired-capacity 3
```

Cinco virou cinco. **Oito virou oito num grupo cujo máximo é seis, e isso é o moto aceitando o que a
AWS recusa.** Na AWS a mesma chamada falha com um `ValidationError`, porque a capacidade desejada tem
de ficar entre o mínimo e o máximo, e nada é lançado. O moto não confere nenhum dos dois limites. A
contagem de oito dele é um registro que ninguém paga; na AWS, um máximo que pudesse ser ultrapassado
não seria teto nenhum para a conta. A Ana volta para três.

## Quais instâncias saem quando o número cai

Quando a capacidade desejada cai, o grupo tem de escolher quem terminar, e na AWS a **política de
término padrão** escolhe, para um grupo de um só tipo de instância, numa ordem documentada:

1. a zona com mais instâncias, para o grupo continuar equilibrado entre as zonas;
2. dentro dela, instâncias lançadas a partir do launch template ou configuração mais antiga;
3. depois, a instância mais perto da próxima hora de cobrança;
4. e ao acaso entre as que sobrarem.

O segundo passo é o que faz um grupo menor se arrumar depois de uma mudança: instâncias em versões
antigas saem primeiro. Existem outras políticas (`OldestInstance`, `NewestInstance`,
`OldestLaunchTemplate`), e um grupo pode citar várias, em ordem.

Uma instância fazendo algo que não pode ser interrompido, como um job longo, pode ser protegida: a
**proteção contra scale-in** (`set-instance-protection`) a tira da escolha quando a contagem cai. Ela
não a protege de um health check com falha, que é o assunto da próxima seção. E para a instância
escolhida, um **lifecycle hook** pode segurá-la num estado de espera por alguns minutos, para ela
terminar suas requisições antes de sair. A lição 6 usa um para drenar uma instância spot.

## Duas configurações que mudam o que um grupo é

Um grupo com mínimo, desejado e máximo todos em 1 nunca escala, e ainda assim vale a pena: ele
substitui sua única instância quando ela falha. Para um servidor único que precisa voltar sozinho, é
o arranjo mais barato que a AWS oferece, desde que nada nesse servidor precise sobreviver.

Um grupo com mínimo 0 pode ser esvaziado por completo, à mão ou por um agendamento (lição 5), e não
custa nada pelas instâncias enquanto está vazio. O que continua custando é o que não pertence às
instâncias: um load balancer na frente dele cobra por hora, haja ou não instâncias atrás.
