---
title: Alarmes compostos, e chamar pelo sintoma
version: 1
---

A loja tem um alarme de erros, um de latência, um da profundidade de uma fila e um da CPU do banco.
Num incidente os quatro disparam em dois minutos, e quem está de plantão recebe quatro chamados por um
problema, e por um tempo não consegue dizer qual é a causa e quais são as consequências. **Um alarme
composto** combina outros alarmes com uma regra, e só o composto chama:

```
ALARM("api-errors") AND ALARM("api-latency")
```

```
ALARM("api-errors") OR (ALARM("api-latency") AND NOT ALARM("api-deploying"))
```

A linguagem de regras tem `ALARM`, `OK` e `INSUFFICIENT_DATA` como funções do nome de um alarme, unidas
com `AND`, `OR` e `NOT`. A segunda regra chama na hora por erros, e por latência só quando nenhum deploy
está rodando, porque um canário deixa as coisas mais lentas por um minuto de propósito.

## O sintoma, não a causa

Os quatro alarmes são de dois tipos. Erros e latência são **sintomas**: os clientes os sentem.
Profundidade de fila e CPU do banco são **causas**, ou candidatas: uma fila funda só importa se deixar
requisições lentas ou falhando. A regra que mantém o plantão humano é **chamar por sintomas e registrar
causas**: o composto de sintomas acorda uma pessoa; os alarmes de causa ficam no painel e na mensagem,
onde quem foi chamado olha primeiro, e não acordam ninguém sozinhos.

O hábito contrário, chamar por toda causa, chama por um banco a 80% de CPU que ninguém notou porque os
clientes não notaram, e ensina as pessoas a reconhecer chamados sem lê-los. A lição 14 conta quanto
isso custa.

## No laboratório, e na AWS

```
ana@laptop:~/aws/alarms$ aws cloudwatch put-composite-alarm --alarm-name api-down --alarm-rule 'ALARM("api-errors") AND ALARM("api-latency")' 2>&1 | grep -m1 ERROR
aws: [ERROR]: An error occurred (500) when calling the PutCompositeAlarm operation (reached max retries: 2): <!doctype html>
```

O moto não implementa alarmes compostos, então nenhuma regra acima foi executada. Na AWS, um alarme
composto também aceita um **supressor de ações**: um alarme que, enquanto está em `ALARM`, impede o
composto de avisar, com um tempo de espera em volta. Um alarme de deploy como supressor é o jeito
documentado de silenciar chamados durante uma mudança planejada sem editar alarme nenhum.

## Quanto custam os alarmes

```
ana@laptop:~/aws/alarms$ python3 price.py AmazonCloudWatch AlarmMonitorUsage
AmazonCloudWatch, sa-east-1, published 2026-10-07
  Global-CW:AlarmMonitorUsage              0.000000 USD per Alarms     Global
  SAE1-CW:AlarmMonitorUsage                0.135000 USD per Alarms     $0.135 per alarm metric month (standard resolution) - South America (Sao Paulo)
  SAE1-CW:CompositeAlarmMonitorUsage       0.675000 USD per Alarms     $0.675 per composite alarm month - South America (Sao Paulo)
  SAE1-CW:HighResAlarmMonitorUsage         0.405000 USD per Alarms     $0.405 per alarm metric month (high resolution) - South America (Sao Paulo)
  SAE1-CW:LogAlarmMonitorUsage             0.100000 USD per Alarms     $0.10 per Alarm in South America (Sao Paulo)
  SAE1-CW:PromQLAlarmMonitorUsage          0.100000 USD per Alarms     $0.10 per Alarm in South America (Sao Paulo)
```

Treze centavos e meio por mês por alarme padrão, o triplo para alta resolução, e 67,5 centavos por um
composto. Quarenta alarmes custam 5,40 USD por mês. **Alarmes são baratos; chamados não são**, e o custo
de um alarme que vale a pena é a atenção que ele toma, que as próximas lições medem.
