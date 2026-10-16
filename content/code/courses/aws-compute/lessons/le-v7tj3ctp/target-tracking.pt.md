---
title: "Target tracking: diga um número e deixe a AWS fazer a conta"
version: 1
---

A imagem que a maioria traz é uma regra: se a CPU passar de 70%, acrescente uma instância. Isso é
uma política de escala, e do tipo mais antigo. **Target tracking é um termostato.** Você indica uma
métrica e o valor em que quer que ela fique, e o grupo calcula, toda vez que a métrica se move,
quantas instâncias a poriam de volta nesse valor. Você nunca escreve o limite nem o passo; a AWS
escreve os dois, como alarmes que ela controla.

## A conta que ele faz

A suposição por baixo é que a métrica se divide entre as instâncias: o dobro de instâncias, metade
da CPU para cada uma. Com essa suposição, a capacidade necessária é a capacidade atual vezes a
métrica sobre o alvo. Seis instâncias com média de 75% de CPU, com alvo de 50%, precisam de
6 × 75 / 50 = 9. Quando a resposta não é um número inteiro, um aumento arredonda para cima, porque
8,4 instâncias a 50% significa nove.

Essa suposição também é como escolher a métrica. **Uma boa métrica de alvo cai quando instâncias são
acrescentadas.** A CPU média cai, para um serviço cujo trabalho é computação. O
`ALBRequestCountPerTarget`, as requisições que cada instância recebe do load balancer, também cai, e
muitas vezes é a melhor para um serviço web, porque sobe com o próprio tráfego e não com um dos
efeitos dele. O tamanho de uma fila não cai: dez consumidores a mais não encurtam a fila só por
estarem lá, só trabalhando nela, então para uma fila a métrica é o backlog por instância, ao qual a
lição 21 volta. As métricas predefinidas são `ASGAverageCPUUtilization`, `ASGAverageNetworkIn`,
`ASGAverageNetworkOut` e `ALBRequestCountPerTarget`; qualquer outra é uma métrica personalizada que
você publica.

## Um grupo para escalar

O grupo desta lição é o da lição 4, criado de novo num moto vazio com máximo de doze, e com o
template escrito na linha em vez de num arquivo:

```
ana@laptop:~/aws$ aws ec2 create-launch-template --launch-template-name web --launch-template-data '{"ImageId": "ami-0629d059c178d0eac", "InstanceType": "t3.micro"}' --query LaunchTemplate.LaunchTemplateId --output text
lt-8d61d7dd4606f9a1c
ana@laptop:~/aws$ SUBNETS=$(aws ec2 describe-subnets --query 'join(`,`, Subnets[].SubnetId)' --output text)
ana@laptop:~/aws$ aws autoscaling create-auto-scaling-group --auto-scaling-group-name web --launch-template 'LaunchTemplateName=web,Version=$Default' --min-size 2 --max-size 12 --desired-capacity 2 --vpc-zone-identifier "$SUBNETS" --default-instance-warmup 180
```

A última opção, `--default-instance-warmup`, é o assunto da última seção desta lição.

## A política, e o que o moto deixa de fora

```
ana@laptop:~/aws$ aws autoscaling put-scaling-policy --auto-scaling-group-name web --policy-name cpu-50 --policy-type TargetTrackingScaling --target-tracking-configuration '{"PredefinedMetricSpecification": {"PredefinedMetricType": "ASGAverageCPUUtilization"}, "TargetValue": 50}'
ana@laptop:~/aws$ aws autoscaling describe-policies --auto-scaling-group-name web --policy-names cpu-50
{
    "ScalingPolicies": [
        {
            "AutoScalingGroupName": "web",
            "PolicyName": "cpu-50",
            "PolicyARN": "arn:aws:autoscaling:sa-east-1:123456789012:scalingPolicy:c322761b-3172-4d56-9a21-0ed9d6161d67:autoScalingGroupName/web:policyName/cpu-50",
            "PolicyType": "TargetTrackingScaling",
            "StepAdjustments": [],
            "TargetTrackingConfiguration": {
                "PredefinedMetricSpecification": {
                    "PredefinedMetricType": "ASGAverageCPUUtilization"
                },
                "TargetValue": 50.0
            },
            "PredictiveScalingConfiguration": {}
        }
    ]
}
ana@laptop:~/aws$ aws cloudwatch describe-alarms
{
    "MetricAlarms": [],
    "CompositeAlarms": []
}
```

Três respostas, e duas são do moto. **Na AWS, o `put-scaling-policy` imprime o ARN da política e uma
lista dos alarmes que criou**, e o moto não imprime nada. A descrição tem o ARN, então a política
existe. O `describe-alarms` vazio é a lacuna de verdade: a AWS cria dois alarmes do CloudWatch para
cada política de target tracking, chamados `TargetTracking-web-AlarmHigh-` e
`TargetTracking-web-AlarmLow-` seguidos de um id, e o moto não cria nenhum. **O moto também não
guarda métricas, então neste laboratório a política nunca move o grupo**: não há CPU para medir nem
alarme para disparar. Tudo daqui até o fim desta seção é comportamento documentado da AWS, não algo
que você possa ver acontecer.

Os alarmes pertencem à política, e a documentação da AWS diz para não editá-los nem apagá-los;
apagar a política os apaga. Eles não são simétricos. O alarme alto dispara depois de alguns minutos
acima do alvo, e o baixo espera muito mais tempo abaixo dele antes de o grupo remover alguma coisa,
porque remover uma instância que precisa voltar cinco minutos depois é pagar por um boot que não
atendeu ninguém.

## Quando há mais de uma

Um grupo pode ter várias políticas de target tracking, digamos CPU em 50% e requisições por
instância em 1.000. **O grupo aumenta quando qualquer uma pede mais, e só reduz quando todas
concordam com menos.** Essa regra é o que torna seguro acrescentar uma segunda política: ela só pode
deixar o grupo maior, nunca menor do que a primeira quer.

Duas configurações mudam a forma de uma política:

- `DisableScaleIn` transforma a política numa que só acrescenta. Outra coisa, um agendamento ou uma
  pessoa, decide então quando o grupo encolhe.
- O alvo é um valor, não uma faixa. Um alvo de 50% significa que o grupo vai rodar a 50% quando a
  carga está estável, e essa é a **folga** que a política mantém: a outra metade é o que absorve uma
  subida nos minutos antes de as instâncias novas atenderem.

Esse último ponto é a decisão de verdade numa política de target tracking, e é uma decisão de custo.
Acompanhar a CPU em 50% significa pagar por mais ou menos o dobro da capacidade que a carga estável
usa. Acompanhar em 80% paga um quarto a mais, e deixa o grupo saturado por todo minuto que as
instâncias novas levam para chegar. A conta do instance refresh da lição 4 tinha a mesma forma:
tempo contra capacidade, e o serviço decide de qual pode abrir mão.
