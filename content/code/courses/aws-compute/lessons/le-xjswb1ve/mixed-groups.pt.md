---
title: Um grupo em parte sob demanda e em parte spot
version: 1
---

O jeito errado de usar spot é trocar uma instância para spot e torcer. **A unidade certa é um grupo
que mantém um piso fixo de instâncias sob demanda e completa o resto com spot, em vários tipos de
instância**, para que uma interrupção custe uma fração da capacidade e o grupo a reponha a partir do
pool que ainda tiver espaço. Um grupo de auto scaling faz tudo isso a partir de uma configuração, a
mixed instances policy.

## A política

Ela tem duas metades: quais tipos de instância o grupo pode lançar, e como ele os divide entre sob
demanda e spot. **Copie-a com o botão e salve como `~/aws/mixed.json`.**

```schooling-example
{"language": "json", "file": "mixed.json", "parts": [{"code": "{\n  \"LaunchTemplate\": {\n    \"LaunchTemplateSpecification\": {\"LaunchTemplateName\": \"workers\", \"Version\": \"$Default\"},\n", "note": "O template de onde vem toda instância, seja qual for o tipo e a forma de compra. A imagem, o disco e as tags são os mesmos para todas; só mudam o tipo e o preço."}, {"code": "    \"Overrides\": [\n      {\"InstanceType\": \"m7i.large\"},\n      {\"InstanceType\": \"m6i.large\"},\n      {\"InstanceType\": \"m6a.large\"},\n      {\"InstanceType\": \"m5.large\"}\n    ]\n  },\n", "note": "Quatro tipos do mesmo formato, 2 vCPUs e 8 GiB cada, de três gerações e dois fabricantes de processador. Cada um é um pool separado de capacidade sobrando, e quatro pools são quatro chances de um ter espaço quando outro não tem."}, {"code": "  \"InstancesDistribution\": {\n    \"OnDemandBaseCapacity\": 2,\n    \"OnDemandPercentageAboveBaseCapacity\": 25,\n", "note": "As duas primeiras instâncias são sempre sob demanda, e acima delas um quarto é sob demanda e três quartos são spot. A base é a parte do grupo que uma interrupção nunca pode levar."}, {"code": "    \"SpotAllocationStrategy\": \"price-capacity-optimized\"\n  }\n}\n", "note": "Como a AWS escolhe entre os quatro pools para cada instância spot: os pools com menos chance de interrupção, e entre eles o mais barato. A AWS o recomenda para a maioria das cargas."}]}
```

Os tipos são a decisão que mais se erra, e a versão errada é um tipo só. **Cada tipo em cada zona é
um pool separado de capacidade sobrando**, e a AWS interrompe por pool. Um grupo que permite um tipo
em três zonas usa três pools; este usa doze. Os tipos devem ser intercambiáveis para a aplicação: os
mesmos vCPUs e memória, a mesma arquitetura de processador. Um tipo Arm como `m7g.large` pode
entrar, mas só com uma override de launch template própria que indique uma imagem `arm64`, porque
uma imagem não sobe nas duas.

## A conta da distribuição

Com capacidade desejada de dez, a base pega as duas primeiras sob demanda. As oito restantes são
divididas pela porcentagem: 25% de oito são mais duas sob demanda, e as outras seis são spot.
**Quatro sob demanda e seis em spot**, e as quatro são o piso que uma interrupção não alcança.
Conforme o grupo cresce, a base fica em dois e a divisão vale para tudo acima dela: com trinta, são
duas mais 25% de vinte e oito, então nove sob demanda e vinte e uma em spot.

A estratégia de alocação escolhe o pool de cada instância spot:

| estratégia | o que ela escolhe |
| --- | --- |
| `price-capacity-optimized` | os pools com menos chance de interrupção, e o mais barato entre eles; a recomendação da AWS |
| `capacity-optimized` | os pools com menos chance de interrupção, seja qual for o preço |
| `lowest-price` | os pools mais baratos, que muitas vezes são os com mais chance de serem tomados de volta |

## O grupo no moto

```
ana@laptop:~/aws$ aws ec2 create-launch-template --launch-template-name workers --launch-template-data '{"ImageId": "ami-0629d059c178d0eac", "InstanceType": "m7i.large"}' --query LaunchTemplate.LaunchTemplateId --output text
lt-402d88ea28bddd6cd
ana@laptop:~/aws$ SUBNETS=$(aws ec2 describe-subnets --query 'join(`,`, Subnets[].SubnetId)' --output text)
ana@laptop:~/aws$ aws autoscaling create-auto-scaling-group --auto-scaling-group-name workers --min-size 0 --max-size 20 --desired-capacity 10 --vpc-zone-identifier "$SUBNETS" --capacity-rebalance --mixed-instances-policy file://mixed.json
```

O `--capacity-rebalance` é a resposta do grupo à recomendação de rebalanceamento da seção anterior:
na AWS, quando uma das instâncias spot dele recebe uma, o grupo lança uma substituta primeiro, num
pool de menor risco, e só então termina a instância em risco. Isto é o que o moto fez do pedido
inteiro:

```
ana@laptop:~/aws$ aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names workers --query "AutoScalingGroups[].{rebalance: CapacityRebalance, distribution: MixedInstancesPolicy.InstancesDistribution, types: MixedInstancesPolicy.LaunchTemplate.Overrides[].InstanceType}"
[
    {
        "rebalance": true,
        "distribution": {
            "OnDemandBaseCapacity": 2,
            "OnDemandPercentageAboveBaseCapacity": 25,
            "SpotAllocationStrategy": "price-capacity-optimized"
        },
        "types": [
            "m7i.large",
            "m6i.large",
            "m6a.large",
            "m5.large"
        ]
    }
]
ana@laptop:~/aws$ aws ec2 describe-instances --filters Name=tag:aws:autoscaling:groupName,Values=workers --query "Reservations[].Instances[].[InstanceType,InstanceLifecycle]" --output text | sort | uniq -c
     10 m7i.large	None
```

**A descrição é fiel e as instâncias não são.** O moto guardou a distribuição, os quatro tipos e o
capacity rebalancing exatamente como foram enviados. Depois lançou dez `m7i.large`, todas sob
demanda: `None` na coluna de ciclo de vida quer dizer que não é spot. Na AWS este grupo teria quatro
instâncias sob demanda e seis spot, espalhadas pelos quatro tipos e pelas três zonas. A política pode
ser escrita e lida de volta neste laboratório, e o efeito dela é comportamento documentado da AWS.

## Segurando uma instância enquanto ela drena

Os dois minutos de uma interrupção são curtos, e um grupo que termina uma instância por redução de
escala ou rebalanceamento pode dar mais tempo a ela. Um **lifecycle hook** no término segura uma
instância de saída num estado de espera até ela dizer que terminou, ou até o timeout do hook acabar:

```
ana@laptop:~/aws$ aws autoscaling put-lifecycle-hook --auto-scaling-group-name workers --lifecycle-hook-name drain --lifecycle-transition autoscaling:EC2_INSTANCE_TERMINATING --heartbeat-timeout 120 --default-result CONTINUE
ana@laptop:~/aws$ aws autoscaling describe-lifecycle-hooks --auto-scaling-group-name workers
{
    "LifecycleHooks": [
        {
            "LifecycleHookName": "drain",
            "AutoScalingGroupName": "workers",
            "LifecycleTransition": "autoscaling:EC2_INSTANCE_TERMINATING",
            "NotificationTargetARN": "arn:aws:sqs:us-east-1:123456789012:my-queue",
            "RoleARN": "arn:aws:iam::1234567890:role/my-auto-scaling-role",
            "HeartbeatTimeout": 120,
            "GlobalTimeout": 172800,
            "DefaultResult": "CONTINUE"
        }
    ]
}
```

O hook fica guardado com timeout de 120 segundos e resultado padrão `CONTINUE`, o que quer dizer que
o término segue quando o tempo acaba. **Os dois ARNs nele são o moto inventando valores que ninguém
deu**: uma fila em `us-east-1` e um papel numa conta de número `1234567890`. Na AWS um hook criado
sem alvo de notificação não tem nenhum, e o próprio script de drenagem da instância chama
`complete-lifecycle-action` quando termina. Um hook não alonga uma interrupção spot: quando a AWS
toma a capacidade de volta, dois minutos é tudo o que há.
