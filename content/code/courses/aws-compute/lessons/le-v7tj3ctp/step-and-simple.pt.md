---
title: "Step e simple scaling: você escreve os limites"
version: 1
---

Antes do target tracking havia políticas que fazem exatamente o que mandam. **Você escreve o alarme,
o limite e a quantidade, e a política acrescenta ou remove essa quantidade quando o alarme
dispara.** Elas dão mais trabalho e perdoam menos, e continuam sendo a ferramenta certa quando a
resposta tem de ser assimétrica de um jeito que um alvo não consegue expressar: acrescentar muito
depressa, remover uma por vez.

## Simple scaling, e o cooldown

Uma política de **simple scaling** tem um ajuste. Quando o alarme dela dispara, ela o aplica, e depois
espera o **cooldown**, 300 segundos por padrão, antes de responder a qualquer outra coisa. O cooldown
existe porque as instâncias novas levam minutos para mudar a métrica, e sem ele o mesmo alarme
dispararia de novo e de novo com base numa carga que o primeiro ajuste já respondeu.

O `execute-policy` roda uma política à mão, como se o alarme dela tivesse disparado, e este o moto
implementa:

```
ana@laptop:~/aws$ aws autoscaling put-scaling-policy --auto-scaling-group-name web --policy-name add-two --policy-type SimpleScaling --adjustment-type ChangeInCapacity --scaling-adjustment 2 --cooldown 300
ana@laptop:~/aws$ aws autoscaling execute-policy --auto-scaling-group-name web --policy-name add-two
ana@laptop:~/aws$ aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names web --query "AutoScalingGroups[].[DesiredCapacity,length(Instances)]" --output text
4	4
ana@laptop:~/aws$ aws autoscaling execute-policy --auto-scaling-group-name web --policy-name add-two --honor-cooldown
ana@laptop:~/aws$ aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names web --query "AutoScalingGroups[].[DesiredCapacity,length(Instances)]" --output text
6	6
```

De dois para quatro, como a política diz. **A segunda chamada é onde o moto e a AWS se separam.** O
`--honor-cooldown` pede à AWS que respeite o cooldown, e na AWS uma chamada até 300 segundos depois
da primeira não escalaria; o moto ignorou a opção e foi para seis. Um grupo neste laboratório pode
ser escalado por uma política simples quantas vezes você quiser, o que é um fato sobre o moto e não
sobre a política.

## Step scaling

Uma política de **step scaling** troca o ajuste único por uma tabela. Cada linha é uma faixa da
métrica, medida a partir do limite do alarme, e o número de instâncias a acrescentar nessa faixa.
Com um alarme em 60% de CPU, a política abaixo acrescenta uma instância quando a violação é de 0 a
20 pontos, e três quando é de 20 pontos ou mais. O limite inferior de uma faixa está incluído e o
superior não.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Um eixo horizontal de CPU média de 0 a 100%. Uma linha tracejada marca o limite do alarme em 60%. Abaixo dele, nenhuma ação. De 60 a 80%, uma violação de 0 a 20 pontos, o passo acrescenta uma instância. De 80% para cima, uma violação de 20 pontos ou mais, acrescenta três. Uma seta marca uma leitura de 85%, que cai no segundo passo.\"><defs><marker id=\"st-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"60.0\" y=\"70\" width=\"372.0\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"432.0\" y=\"70\" width=\"124.0\" height=\"70\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"556.0\" y=\"70\" width=\"124.0\" height=\"70\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"246.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">nenhuma ação</text><text x=\"246.0\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o alarme não está em ALARM</text><text x=\"494.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--phosphor)\" font-weight=\"600\">+1</text><text x=\"494.0\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">violação de 0 a 20</text><text x=\"618.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--amber)\" font-weight=\"600\">+3</text><text x=\"618.0\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">violação de 20 ou mais</text><path d=\"M60.0 180 L694.0 180\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah)\"></path><path d=\"M60.0 176 L60.0 184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"60.0\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0%</text><path d=\"M184.0 176 L184.0 184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"184.0\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20%</text><path d=\"M308.0 176 L308.0 184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"308.0\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">40%</text><path d=\"M432.0 176 L432.0 184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"432.0\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">60%</text><path d=\"M556.0 176 L556.0 184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"556.0\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">80%</text><path d=\"M680.0 176 L680.0 184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"680.0\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">100%</text><text x=\"694.0\" y=\"164\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">CPU</text><path d=\"M432.0 40 L432.0 176\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"432.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">limite do alarme</text><path d=\"M587.0 228 L587.0 146\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah)\"></path><text x=\"579.0\" y=\"232\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">uma leitura de 85% está 25 acima: três instâncias</text></svg>", "caption": "As duas linhas da política, desenhadas contra a métrica. As faixas são medidas a partir do limite do alarme, não do zero, então a mesma tabela acompanha o alarme se o limite mudar.", "same": ["CPU"]}
```

Então uma leitura de 85% está 25 pontos acima do limite, cai na segunda linha, e acrescenta três. O
step scaling não tem cooldown: ele responde a toda avaliação do alarme, e evita contar a mesma
subida duas vezes tratando as instâncias que ainda estão aquecendo como se já estivessem lá. Pedido
para rodar a política para uma leitura de 85, o moto desiste:

```
ana@laptop:~/aws$ aws autoscaling put-scaling-policy --auto-scaling-group-name web --policy-name cpu-steps --policy-type StepScaling --adjustment-type ChangeInCapacity --metric-aggregation-type Average --step-adjustments MetricIntervalLowerBound=0,MetricIntervalUpperBound=20,ScalingAdjustment=1 MetricIntervalLowerBound=20,ScalingAdjustment=3
ana@laptop:~/aws$ aws autoscaling execute-policy --auto-scaling-group-name web --policy-name cpu-steps --metric-value 85 --breach-threshold 60

aws: [ERROR]: Unable to parse response (syntax error: line 1, column 0), invalid XML received. Further retries may succeed:
b'<!doctype html>\n<html lang=en>\n<title>500 Internal Server Error</title>\n<h1>Internal Server Error</h1>\n<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>\n'
```

**Esse 500 é o moto falhando numa chamada que ele não implementa**, como aconteceu com o instance
refresh na lição 4. Na AWS a mesma chamada acrescentaria três instâncias, porque `--metric-value 85`
e `--breach-threshold 60` põem a violação no segundo passo.

Três tipos de ajuste decidem o que o número de uma linha significa. `ChangeInCapacity` acrescenta ou
remove essa quantidade de instâncias. `ExactCapacity` define a contagem nesse número.
`PercentChangeInCapacity` acrescenta essa fração da capacidade atual, com o `MinAdjustmentMagnitude`
como piso, para que 10% de um grupo de quatro ainda acrescente uma.

## O alarme que a move

Uma política de passos ou simples é movida por um alarme do CloudWatch que você cria e aponta para
o ARN da política. Aqui está um, posto à mão em `ALARM` para ver o que acontece:

```
ana@laptop:~/aws$ STEPS=$(aws autoscaling describe-policies --auto-scaling-group-name web --policy-names cpu-steps --query 'ScalingPolicies[0].PolicyARN' --output text)
ana@laptop:~/aws$ aws cloudwatch put-metric-alarm --alarm-name web-cpu-high --namespace AWS/EC2 --metric-name CPUUtilization --dimensions Name=AutoScalingGroupName,Value=web --statistic Average --period 60 --evaluation-periods 3 --threshold 60 --comparison-operator GreaterThanThreshold --alarm-actions "$STEPS"
ana@laptop:~/aws$ aws cloudwatch set-alarm-state --alarm-name web-cpu-high --state-value ALARM --state-reason "set by hand to see what follows"
ana@laptop:~/aws$ aws cloudwatch describe-alarms --alarm-names web-cpu-high --query "MetricAlarms[].[StateValue,StateReason]" --output text
ALARM	set by hand to see what follows
ana@laptop:~/aws$ aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names web --query "AutoScalingGroups[].[DesiredCapacity,length(Instances)]" --output text
6	6
```

O moto guardou o alarme, aceitou o novo estado e não o ligou a nada: seis antes, seis depois. **Na
AWS, um alarme cuja ação é uma política de escala chama essa política toda vez que é avaliado em
`ALARM`**, então este teria acrescentado três. Alarmes, métricas e suas dimensões são o assunto das
lições 8 a 10 de `aws-operations`; para esta lição o ponto é a ligação, que é o alarme citando a
política e não o contrário.

## Qual delas

Comece pelo target tracking. Ele escreve os próprios alarmes, reduz sozinho, e seu único número é
fácil de discutir. Recorra ao step scaling quando precisar que a resposta seja mais íngreme que
proporcional, como três instâncias de uma vez para uma subida brusca. O simple scaling é, na maior
parte, o que você encontra em configurações antigas; não há nada que ele faça que uma política de
passos de uma linha não faça melhor.
