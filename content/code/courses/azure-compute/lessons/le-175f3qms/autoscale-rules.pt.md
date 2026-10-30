---
title: "Autoscale: uma regra, uma janela e um cooldown"
version: 1
---

A imagem a trocar é "quando a CPU passa de 70%, acrescente uma máquina". **Uma regra de autoscale
nunca age com base numa leitura só.** Ela lê uma métrica amostrada uma vez por minuto, combina as
amostras numa janela de vários minutos, compara esse único número com o limite, e só então age; e
depois de agir, espera. Cada um desses é um número que você escreve, e o que o scale set da loja faz no
almoço é aritmética sobre eles.

## Uma configuração, seus perfis e suas regras

O autoscale não é uma propriedade do scale set. É um recurso próprio,
`Microsoft.Insights/autoscalesettings`, que pertence ao Azure Monitor e aponta para o recurso que
escala, e um recurso tem no máximo uma configuração de autoscale. Então a da loja vai num arquivo
próprio. Salve-o como `shop-autoscale.bicep`:

```schooling-example
{"language": "bicep", "file": "shop-autoscale.bicep", "parts": [{"code": "// shop-autoscale.bicep\nparam location string = 'brazilsouth'\n\nresource vmss 'Microsoft.Compute/virtualMachineScaleSets@2024-11-01' existing = {\n  name: 'shop-vmss'\n}\n\n", "note": "Um arquivo próprio, porque uma configuração de autoscale é um recurso próprio. Ela nomeia o scale set como `existing`, então é implantada depois dele."}, {"code": "var cpuRules = [\n  {\n    metricTrigger: {\n      metricName: 'Percentage CPU'\n      metricResourceUri: vmss.id\n      timeGrain: 'PT1M'\n      statistic: 'Average'\n      timeWindow: 'PT10M'\n      timeAggregation: 'Average'\n      operator: 'GreaterThan'\n      threshold: 70\n    }\n    scaleAction: {\n      direction: 'Increase'\n      type: 'ChangeCount'\n      value: '2'\n      cooldown: 'PT10M'\n    }\n  }\n", "note": "A regra de aumento, guardada numa variável para que os dois perfis a compartilhem. A cada minuto, a média de Percentage CPU entre as instâncias; a cada execução do motor, a média dos últimos dez desses minutos; acima de 70, acrescentar duas instâncias; depois, deixar esta regra parada por dez minutos após qualquer ação de escala."}, {"code": "  {\n    metricTrigger: {\n      metricName: 'Percentage CPU'\n      metricResourceUri: vmss.id\n      timeGrain: 'PT1M'\n      statistic: 'Average'\n      timeWindow: 'PT10M'\n      timeAggregation: 'Average'\n      operator: 'LessThan'\n      threshold: 30\n    }\n    scaleAction: {\n      direction: 'Decrease'\n      type: 'ChangeCount'\n      value: '1'\n      cooldown: 'PT10M'\n    }\n  }\n]\n\n", "note": "A regra de redução, a mesma medida lida no sentido contrário: abaixo de 30, remover uma. O intervalo entre 30 e 70 é o que impede as duas regras de desfazerem uma à outra."}, {"code": "resource autoscale 'Microsoft.Insights/autoscalesettings@2022-10-01' = {\n  name: 'shop-autoscale'\n  location: location\n  properties: {\n    enabled: true\n    targetResourceUri: vmss.id\n    predictiveAutoscalePolicy: {\n      scaleMode: 'ForecastOnly'\n    }\n", "note": "Uma configuração para o scale set. `ForecastOnly` pede uma previsão sem deixar que ela aja."}, {"code": "    profiles: [\n      {\n        name: 'black-friday'\n        capacity: {\n          minimum: '6'\n          maximum: '12'\n          default: '6'\n        }\n        rules: cpuRules\n        fixedDate: {\n          timeZone: 'E. South America Standard Time'\n          start: '2026-11-27T00:00:00'\n          end: '2026-11-28T23:59:00'\n        }\n      }\n", "note": "Um perfil de data fixa para a Black Friday, com um piso mais alto. Nesses dois dias, no horário de São Paulo escrito com o nome que o Windows dá a esse fuso, ele é usado no lugar do perfil padrão."}, {"code": "      {\n        name: 'normal'\n        capacity: {\n          minimum: '3'\n          maximum: '12'\n          default: '3'\n        }\n        rules: cpuRules\n      }\n    ]\n  }\n}\n", "note": "O perfil de todos os outros dias: nunca menos de três instâncias, uma por zona, e nunca mais de doze."}]}
```

Uma configuração guarda **perfis**, até 20, e a cada execução o motor usa exatamente um. Há três
tipos. Um perfil de **data fixa** tem começo e fim, como a Black Friday da loja. Um perfil de
**recorrência** se repete em dias da semana a partir de um horário e vale até o próximo perfil
começar. O perfil **padrão** não tem nenhum dos dois e vale sempre que nenhum outro se aplica; uma
configuração tem um. Eles são testados nessa ordem, data fixa primeiro, e o primeiro que servir é o
usado.

Cada perfil traz uma **capacidade**: um mínimo e um máximo que o motor nunca ultrapassa, e um
**padrão**, que só importa quando a métrica não pode ser lida. Nesse caso, se o scale set tem menos
instâncias que o padrão, o autoscale o sobe até o padrão, e se tem mais, não reduz. O padrão de três
da loja é a contagem em que ela confia sem informação nenhuma.

Cada perfil traz também até 10 **regras**, e uma regra é um gatilho de métrica e uma ação de escala:

| parte | o valor da loja | o que quer dizer |
| --- | --- | --- |
| `timeGrain` | `PT1M` | uma amostra por minuto |
| `statistic` | `Average` | cada amostra é a média das instâncias |
| `timeWindow` | `PT10M` | olhar dez minutos para trás |
| `timeAggregation` | `Average` | a média das dez amostras |
| `operator`, `threshold` | `GreaterThan`, `70` | comparar esse número com 70 |
| `direction`, `type`, `value` | `Increase`, `ChangeCount`, `2` | acrescentar duas instâncias |
| `cooldown` | `PT10M` | esta regra espera dez minutos depois de uma ação de escala |

`type` aceita `ChangeCount`, que acrescenta ou remove essa quantidade; `PercentChangeCount`, essa
porcentagem da contagem atual; e `ExactCount`, que põe a contagem no valor. A descrição da própria API lista
um quarto, `ServiceAllowedNextValue`, que a documentação lida para esta lição não explica. O cooldown é
de cada regra: depois de qualquer ação de escala, uma regra pode agir de novo quando o próprio
cooldown tiver passado, seja qual for a regra que causou a ação.

```
ana@laptop:~/azure$ bicep build shop-autoscale.bicep
ana@laptop:~/azure$ jq -c ".resources[0].properties.profiles[] | {name, capacity, fixedDate}" shop-autoscale.json
{"name":"black-friday","capacity":{"minimum":"6","maximum":"12","default":"6"},"fixedDate":{"timeZone":"E. South America Standard Time","start":"2026-11-27T00:00:00","end":"2026-11-28T23:59:00"}}
{"name":"normal","capacity":{"minimum":"3","maximum":"12","default":"3"},"fixedDate":null}
```

Sem aviso, e os dois perfis estão lá com as capacidades. A data fixa é `null` em `normal`, e é isso
que faz dele o perfil padrão.

## O almoço, passo a passo

Suponha que as três instâncias da loja fiquem em 40% de CPU a manhã toda, e que os pedidos do almoço
cheguem às 12:00 e levem cada uma a 90%. A amostra de um minuto é a média das instâncias, então a
amostra das 12:01 é 90, e toda amostra depois dela também.

Às 12:01 a janela tem nove amostras de 40 e uma de 90: (9 × 40 + 90) / 10 = 45. Cada minuto troca um
40 por um 90 e soma 5. Às 12:06 a janela tem seis amostras de 90 e quatro de 40, que dá
(6 × 90 + 4 × 40) / 10 = 70, e 70 não é maior que 70. **Às 12:07 dá 75, e a regra dispara, sete
minutos depois de a carga chegar.** O motor roda a cada 30 a 60 segundos, o que pode somar até um
minuto, e as duas instâncias novas ainda têm de subir antes de servir qualquer coisa.

Digamos que elas sirvam a partir das 12:10. A mesma carga dividida por cinco instâncias dá
3 × 90 / 5 = 54% cada, entre os dois limites, então a loja deveria se acomodar em cinco. Se isso
acontece depende do cooldown.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Um gráfico de Percentage CPU das 11:58 às 12:22. A amostra de cada minuto é 40 até as 12:00, 90 das 12:01 às 12:09 e 54 a partir das 12:10, quando cinco instâncias dividem a carga. A média de dez minutos sobe de 40 e passa o limite de 70 às 12:07, marcando 75, quando duas instâncias são acrescentadas. Às 12:12, onde terminaria um cooldown de cinco minutos, a média ainda marca 79,2. Às 12:17, onde termina o cooldown de dez minutos, ela marca 61,2. O limite de redução, 30, nunca é alcançado.\"><defs><marker id=\"sw-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"63.8\" y=\"160\" width=\"14\" height=\"80\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"85.4\" y=\"160\" width=\"14\" height=\"80\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"107\" y=\"160\" width=\"14\" height=\"80\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"128.6\" y=\"60\" width=\"14\" height=\"180\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"150.2\" y=\"60\" width=\"14\" height=\"180\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"171.8\" y=\"60\" width=\"14\" height=\"180\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"193.4\" y=\"60\" width=\"14\" height=\"180\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"215\" y=\"60\" width=\"14\" height=\"180\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"236.6\" y=\"60\" width=\"14\" height=\"180\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"258.2\" y=\"60\" width=\"14\" height=\"180\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"279.8\" y=\"60\" width=\"14\" height=\"180\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"301.4\" y=\"60\" width=\"14\" height=\"180\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"323\" y=\"132\" width=\"14\" height=\"108\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"344.6\" y=\"132\" width=\"14\" height=\"108\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"366.2\" y=\"132\" width=\"14\" height=\"108\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"387.8\" y=\"132\" width=\"14\" height=\"108\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"409.4\" y=\"132\" width=\"14\" height=\"108\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"431\" y=\"132\" width=\"14\" height=\"108\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"452.6\" y=\"132\" width=\"14\" height=\"108\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"474.2\" y=\"132\" width=\"14\" height=\"108\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"495.8\" y=\"132\" width=\"14\" height=\"108\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"517.4\" y=\"132\" width=\"14\" height=\"108\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"539\" y=\"132\" width=\"14\" height=\"108\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"560.6\" y=\"132\" width=\"14\" height=\"108\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"582.2\" y=\"132\" width=\"14\" height=\"108\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M60 240 L608 240\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sw-ah)\"></path><path d=\"M60 240 L60 40\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"54\" y=\"240\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"54\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">50</text><text x=\"54\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100</text><path d=\"M114 240 L114 245\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"114\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">12:00</text><path d=\"M222 240 L222 245\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"222\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">12:05</text><path d=\"M330 240 L330 245\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"330\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">12:10</text><path d=\"M438 240 L438 245\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"438\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">12:15</text><path d=\"M546 240 L546 245\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"546\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">12:20</text><path d=\"M60 100 L600 100\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"606\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">sobe acima de 70</text><path d=\"M60 180 L600 180\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"606\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">desce abaixo de 30</text><path d=\"M70.8 160 L92.4 160 L114 160 L135.6 150 L157.2 140 L178.8 130 L200.4 120 L222 110 L243.6 100 L265.2 90 L286.8 80 L308.4 70 L330 67.2 L351.6 74.4 L373.2 81.6 L394.8 88.8 L416.4 96 L438 103.2 L459.6 110.4 L481.2 117.6 L502.8 124.8 L524.4 132 L546 132 L567.6 132 L589.2 132\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><path d=\"M265.2 20 L265.2 55\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"265.2\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">+2 instâncias</text><circle cx=\"265.2\" cy=\"90\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><text x=\"272.2\" y=\"81\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\" font-weight=\"600\">75</text><path d=\"M373.2 32 L373.2 76.6\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"373.2\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">fim do cooldown de 5 min</text><circle cx=\"373.2\" cy=\"81.6\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><text x=\"380.2\" y=\"72.6\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\" font-weight=\"600\">79.2</text><path d=\"M481.2 44 L481.2 112.6\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"481.2\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">fim do cooldown de 10 min</text><circle cx=\"481.2\" cy=\"117.6\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><text x=\"488.2\" y=\"108.6\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\" font-weight=\"600\">61.2</text><rect x=\"70\" y=\"278\" width=\"14\" height=\"12\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"284\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a amostra de cada minuto</text><path d=\"M300 284 L322 284\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"328\" y=\"284\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a média de dez minutos</text></svg>", "caption": "O almoço da loja, minuto a minuto. A média fica atrás das amostras de propósito: chega a 70 sete minutos depois da carga, e ainda carrega os minutos de antes das instâncias novas durante quase uma janela inteira depois, e é por isso que o cooldown é tão longo quanto a janela."}
```

Com um cooldown de cinco minutos, a regra poderia agir de novo às 12:12. A janela então cobre das
12:03 às 12:12: sete amostras de 90 de antes de as instâncias novas servirem, e três de 54, o que dá
(7 × 90 + 3 × 54) / 10 = 79,2. **Isso está acima de 70, então um cooldown de cinco minutos acrescenta
mais duas instâncias para responder a uma carga que duas já tinham respondido.** Com sete instâncias,
270 / 7 = 38,6%, que não está abaixo de 30, então as duas a mais ficam até o almoço acabar. Com os dez
minutos do arquivo a regra só pode agir de novo às 12:17, quando a janela tem duas amostras de 90 e
oito de 54: 61,2, e nada acontece. O que a aritmética diz em geral é que **um cooldown de aumento pelo
menos tão longo quanto a janela impede uma regra de ler os minutos de antes da própria última ação**,
e que o tempo de boot tem de ser somado a ele. Quanto a imagem da loja leva para subir é o único
número aqui que você tem de medir.

À noite a carga cai para 120 pontos percentuais nas cinco instâncias, 24% cada. Isso está abaixo de
30, então a regra de redução remove uma: 120 / 4 = 30%, que não é *menor que* 30, e a loja fica em
quatro.

## Várias regras, e o flapping

A maioria dos perfis tem mais de uma regra, e o motor as combina de modo desigual de propósito.
**Ele aumenta se qualquer regra de aumento disparar, e só reduz se todas as regras de redução
dispararem.** Quando várias regras de aumento disparam ele fica com a maior contagem nova, e quando
as regras de redução concordam ele remove o mínimo de instâncias que qualquer uma delas pede.

**Flapping** é uma ação de escala que provoca a oposta. O exemplo da Microsoft é uma instância em 56%
de CPU, uma regra que acrescenta uma acima de 50% e outra que remove uma abaixo de 30%. Com duas
instâncias a média é 28%, abaixo de 30, e remover uma a poria de volta em 56%. Para impedir esse
vaivém, o autoscale confere toda redução antes de fazê-la: estima a métrica na contagem menor e, se
isso dispararia um aumento, pula a redução ou remove menos do que a regra pediu. Os aumentos nunca são
conferidos assim, e sempre vão adiante. O remédio é uma margem entre os limites. Os 30 e 70 da loja
estão a mais de um fator de dois um do outro, e é por isso que uma instância a mais ou a menos não
consegue levar a média de um lado para o outro.

## Autoscale preditivo

Uma previsão é o outro jeito de chegar antes da carga. **O autoscale preditivo aprende o padrão de CPU
do scale set e acrescenta instâncias antes da subida prevista**, até uma hora antes. A Microsoft
documenta os limites dele: só scale sets de máquinas virtuais, só a métrica Percentage CPU com
agregação Average, só aumento, pelo menos sete dias de histórico, e uma janela móvel de 15 dias dele.
Ele também precisa que exista uma regra comum de aumento sobre Percentage CPU, que a loja tem. O CLI
lista os modos:

```
ana@laptop:~/azure$ az monitor autoscale create --help | tr -s "[:space:]" " " | grep -o "\-\-scale-mode : [^.]*\. Allowed values: [A-Za-z, ]*\."
--scale-mode : The predictive autoscale mode. Allowed values: Disabled, Enabled, ForecastOnly.
```

O arquivo da loja começa em `ForecastOnly`, que desenha a previsão sem agir sobre ela, para que seja
comparada com o que de fato aconteceu antes de se confiar no `Enabled`. Um pico mensal ou anual não é
algo que ele aprenda, e o perfil da Black Friday está lá exatamente para isso.

## O que o compilador deixa passar

Três erros, digitados numa cópia: o cooldown escrito como um número de minutos, a janela encurtada
para dois minutos, e um mínimo de treze num perfil cujo máximo é doze:

```
ana@laptop:~/azure$ sed -e "0,/cooldown: 'PT10M'/s//cooldown: 10/" -e "0,/timeWindow: 'PT10M'/s//timeWindow: 'PT2M'/" -e "s/minimum: '3'/minimum: '13'/" shop-autoscale.bicep > autoscale-wrong.bicep
ana@laptop:~/azure$ diff shop-autoscale.bicep autoscale-wrong.bicep
15c15
<       timeWindow: 'PT10M'
---
>       timeWindow: 'PT2M'
24c24
<       cooldown: 'PT10M'
---
>       cooldown: 10
74c74
<           minimum: '3'
---
>           minimum: '13'
ana@laptop:~/azure$ bicep build autoscale-wrong.bicep
/home/ana/azure/autoscale-wrong.bicep(64,16) : Warning BCP036: The property "cooldown" expected a value of type "string" but the provided value in source declaration "cpuRules" is of type "10". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP036]
```

**O compilador pegou um dos três.** Ele acusou o cooldown na linha 64, onde `cpuRules` é usada, e não
na linha em que o `10` foi digitado, porque o que ele confere é o valor chegando a um perfil. A janela
de dois minutos e o mínimo acima do máximo compilaram sem aviso: um é uma duração bem formada, os
outros são strings bem formadas. Os intervalos estão na descrição da própria API, que viaja dentro do
pacote Python do CLI:

```
ana@laptop:~/azure$ grep -h -A2 ":ivar time_window:" venv/lib/python3.12/site-packages/azure/mgmt/monitor/models/_models_py3.py
    :ivar time_window: the range of time in which instance data is collected. This value must be
     greater than the delay in metric collection, which can vary from resource-to-resource. Must be
     between 12 hours and 5 minutes. Required.
ana@laptop:~/azure$ grep -h -A1 ":ivar cooldown:" venv/lib/python3.12/site-packages/azure/mgmt/monitor/models/_models_py3.py
    :ivar cooldown: the amount of time to wait since the last scaling action before this action
     occurs. It must be between 1 week and 1 minute in ISO 8601 format. Required.
```

Então `PT2M` está fora do que a API declara, e é no Resource Manager que seria recusado. Um mínimo
acima do máximo não aparece como regra em nada do que foi lido para esta lição, e é exatamente o tipo
de número a conferir de olho.
