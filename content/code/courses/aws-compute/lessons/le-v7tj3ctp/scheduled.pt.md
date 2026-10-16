---
title: Escalando pelo relógio
version: 1
---

Todas as políticas das duas últimas seções reagem. A carga sobe, uma métrica acompanha, um alarme
dispara, e as instâncias chegam minutos depois. **Uma ação agendada não olha a carga.** Ela muda os
números do grupo num horário que você indica, e isso faz dela o único tipo de escala que consegue
agir antes de a carga chegar. Para uma carga que chega na mesma hora todo dia útil, é a correção
mais barata que existe.

## O agendamento é cron, em UTC a não ser que você diga outra coisa

O `put-scheduled-update-group-action` recebe uma expressão cron de cinco campos (minuto, hora, dia
do mês, mês, dia da semana) e os números a definir quando ela dispara. **A expressão é lida em UTC a
não ser que a ação tenha um `--time-zone`**, e é aí que ações agendadas dão errado em São Paulo. A
cidade fica três horas atrás do UTC o ano todo, desde que o Brasil parou de mudar os relógios em
2019, então 07:30 em São Paulo é 10:30 UTC:

```
ana@laptop:~/aws$ date -u -d 'TZ="America/Sao_Paulo" 2026-10-19 07:30'
Mon Oct 19 10:30:00 UTC 2026
```

Uma ação escrita como `30 7 * * 1-5` sem fuso dispararia às 04:30 de São Paulo, três horas antes de
alguém chegar. A Ana escreve as duas ações no horário da própria cidade, e deixa a AWS converter:

```
ana@laptop:~/aws$ aws autoscaling put-scheduled-update-group-action --auto-scaling-group-name web --scheduled-action-name weekday-morning --recurrence '30 7 * * 1-5' --time-zone America/Sao_Paulo --min-size 6 --desired-capacity 6
ana@laptop:~/aws$ aws autoscaling put-scheduled-update-group-action --auto-scaling-group-name web --scheduled-action-name weekday-evening --recurrence '0 19 * * 1-5' --time-zone America/Sao_Paulo --min-size 2 --desired-capacity 2
ana@laptop:~/aws$ aws autoscaling describe-scheduled-actions --auto-scaling-group-name web
{
    "ScheduledUpdateGroupActions": [
        {
            "AutoScalingGroupName": "web",
            "ScheduledActionName": "weekday-morning",
            "Recurrence": "30 7 * * 1-5",
            "MinSize": 6,
            "DesiredCapacity": 6,
            "TimeZone": "America/Sao_Paulo"
        },
        {
            "AutoScalingGroupName": "web",
            "ScheduledActionName": "weekday-evening",
            "Recurrence": "0 19 * * 1-5",
            "MinSize": 2,
            "DesiredCapacity": 2,
            "TimeZone": "America/Sao_Paulo"
        }
    ]
}
```

Todo dia útil às 07:30 o mínimo e a capacidade desejada vão para seis; às 19:00 os dois voltam para
dois. **O moto guarda as ações e nunca as executa**: ele não tem relógio que dispare nada, então o
grupo deste laboratório fica onde o último comando o deixou. Na AWS cada uma roda no seu horário e é
registrada como uma atividade de escala. O resto desta seção é comportamento da AWS.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Um dia útil no horário de São Paulo, de 00:00 a 24:00, com capacidade de 0 a 10 instâncias. Uma linha tracejada é o mínimo que o agendamento define: 2 até 07:30 (10:30 UTC), 6 até 19:00 (22:00 UTC), depois 2. Uma linha cheia é a capacidade desejada que uma política move: 6 às 07:30, subindo até 9 no fim da tarde, cortada para 2 às 19:00 pela ação da noite, depois erguida de novo para 6 minutos depois e caindo de volta a 2 até as 22:00.\"><defs><marker id=\"dy-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M60 250 L676 250\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dy-ah)\"></path><path d=\"M60 250 L60 44\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dy-ah)\"></path><text x=\"52\" y=\"250\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"52\" y=\"210\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"52\" y=\"170\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><text x=\"52\" y=\"130\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6</text><text x=\"52\" y=\"90\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">8</text><text x=\"52\" y=\"50\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><path d=\"M60 250 L60 255\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"60\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">00:00</text><path d=\"M247.5 250 L247.5 255\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"247.5\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">07:30</text><path d=\"M360 250 L360 255\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"360\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">12:00</text><path d=\"M535 250 L535 255\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"535\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">19:00</text><path d=\"M660 250 L660 255\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"660\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">24:00</text><text x=\"247.5\" y=\"282\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10:30 UTC</text><text x=\"535\" y=\"282\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">22:00 UTC</text><text x=\"676\" y=\"282\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">horário de São Paulo</text><text x=\"66\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">instâncias</text><path d=\"M60 208 L247.5 208 L247.5 128 L310 128 L310 108 L360 108 L360 88 L485 88 L485 68 L535 68 L535 208 L542.5 208 L542.5 128 L585 128 L585 168 L610 168 L610 208 L660 208\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><path d=\"M60 212 L247.5 212 L247.5 132 L535 132 L535 212 L660 212\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"372.5\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">mínimo, definido pelo agendamento</text><text x=\"385\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">desejado, movido pela política</text><text x=\"547.5\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">19:00 corta para 2; a política devolve</text><path d=\"M547.5 50 L538.75 202\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dy-ah)\"></path><text x=\"660\" y=\"16\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\" font-style=\"italic\">forma ilustrativa, carga inventada</text></svg>", "caption": "Um desenho da forma, não uma medição: a carga por trás dele é inventada. O agendamento move o piso às 07:30 e às 19:00 de São Paulo, que são 10:30 e 22:00 no UTC em que uma expressão cron é lida por padrão. A ação da noite também define a capacidade desejada, e é por isso que a política tem de devolver o que acabou de cortar."}
```

## O agendamento e as políticas dividem o mesmo grupo

Uma ação agendada define números, e uma política de target tracking continua movendo a capacidade
desejada entre eles. A ação da manhã sobe o **mínimo** para seis, então a política não consegue
reduzir abaixo de seis durante o dia por mais calmo que fique, e ainda pode subir acima. Essa é a
combinação útil: o agendamento fornece o piso que dá para prever, e a política cuida da parte que
não dá.

A ação da noite é a que merece um segundo olhar. Ela define a capacidade desejada além do mínimo.
Às 19:00, um grupo que a política tinha levado a nove numa noite movimentada é cortado para
dois, e a política acrescenta instâncias de volta alguns minutos depois, quando o alarme vê a CPU
que o corte causou. **Definir só o mínimo à noite deixa a política decidir quando encolher**, que
costuma ser o que se queria. A da manhã é diferente: definir a capacidade desejada ali é o objetivo
inteiro, porque as instâncias têm de estar subindo antes de a carga chegar.

## Quanto o agendamento custa

O piso da manhã são quatro instâncias a mais que as duas da noite, por onze horas e meia, em cerca
de 22 dias úteis por mês. Isso dá 4 × 11,5 × 22 = 1.012 horas de instância. Uma `t3.micro` em São
Paulo custa 0,0168 USD por hora sob demanda, na tabela de preços da lição 1 para 16 de outubro de
2026, então o piso custa uns 17,00 USD por mês. **Se isso é barato é uma pergunta sobre os minutos
que ele compra**: os de toda manhã de dia útil em que as políticas que reagem ainda estariam
lançando.

## Ações únicas

Uma ação agendada também pode disparar uma vez só, com `--start-time` em vez de `--recurrence`: um
mínimo de vinte a partir da noite anterior a uma promoção, com uma segunda ação devolvendo depois. Uma
promoção é o caso que as políticas que reagem tratam pior, porque a subida é íngreme demais para os
minutos de que elas precisam, e é aquele em que a data é conhecida semanas antes.
