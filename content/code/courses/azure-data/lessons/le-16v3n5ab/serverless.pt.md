---
title: Serverless, e o banco que pausa
version: 1
---

**Serverless é um jeito de comprar computação vCore por segundo em vez de por hora.** Um banco
provisionado tem um número fixo de vCores e é cobrado por eles toda hora do mês, usados ou não. Um
banco serverless tem uma faixa, um mínimo e um máximo, e o Azure o move dentro dela conforme a carga.
Cada segundo é cobrado pelo que o banco usou, com o mínimo como piso. E no General Purpose, um banco
serverless que fica sem conexão por um tempo definido **pausa**: a computação é liberada e cobrada a
zero até a próxima conexão acordá-lo.

**Esta seção é ensinada a partir da documentação da Microsoft; o programa nela faz contas com preços
ilustrativos, e nada nela tocou o Azure.**

## O que você declara, e o que o provider aceita

A cópia de desenvolvimento no `main.tf` da seção anterior é serverless: `GP_S_Gen5_2`, onde o `S` diz
isso e o `2` é o máximo. Mais duas configurações pertencem a ela, e o provider confere as duas:

```
ana@laptop:~/azure/tf/sql$ sed -i.bak 's/auto_pause_delay_in_minutes = 60/auto_pause_delay_in_minutes = 5/' main.tf && terraform validate -no-color 2>&1 | grep Error; mv main.tf.bak main.tf
Error: expected auto_pause_delay_in_minutes to be one of [-1], got 5
Error: expected auto_pause_delay_in_minutes to be in the range (15 - 10080), got 5
```

```
ana@laptop:~/azure/tf/sql$ sed -i.bak 's/min_capacity                = 0.5/min_capacity                = 0.1/' main.tf && terraform validate -no-color 2>&1 | grep Error; mv main.tf.bak main.tf
Error: expected min_capacity to be one of [0 0.5 0.75 1 1.25 1.5 1.75 2 2.25 2.5 3 4 5 6 8 10 12 14 16 18 20 24 32 40], got 0.100000
```

**O atraso da pausa vai de 15 minutos a uma semana, ou -1 para nunca pausar**, e o mínimo é um de uma
lista fixa de tamanhos, que a mensagem do provider imprime inteira. O mínimo importa duas vezes. É o
piso pelo qual todo segundo ligado é cobrado, e define a menor quantidade de memória que o banco
mantém: um mínimo baixo demais para o conjunto de trabalho faz cada período calmo despejar o cache que
o período cheio montou.

## Quanto custa, e quando ganha

**O que é cobrado a cada segundo é o maior entre o processador e a memória que o banco usou,
convertidos em vCores**, nunca abaixo do mínimo, e nada enquanto está pausado. O armazenamento é
cobrado toda hora, pausado ou não, porque os dados continuam lá. Então o serverless ganha quando o
banco fica ocioso por longos períodos, e perde quando fica ocupado o dia todo, se um segundo de
serverless custar mais que um segundo do mesmo vCore provisionado. Confira se custa na sua região com
o `prices.py`; este programa supõe que sim, com números redondos que dizem ser ilustrativos. Salve-o
como `~/azure/breakeven.py`:

```schooling-example
{"language": "python", "file": "breakeven.py", "parts": [{"code": "\"\"\"Two vCores provisioned against serverless, at ILLUSTRATIVE prices.\"\"\"\n\nVCORE_HOUR = 0.25            # USD per vCore per hour, provisioned\nSERVERLESS_SECOND = 0.0001   # USD per vCore per second, serverless\nHOURS = 730                  # a month, as Microsoft's calculator counts it\nDAYS = HOURS / 24\n", "note": "**Dois preços inventados, escolhidos para que um vCore-segundo serverless custe mais que a parte de uma hora de um vCore provisionado**: 0,0001 por segundo são 0,36 por hora, contra 0,25. Troque pelos reais e a forma da resposta fica; o ponto de cruzamento muda."}, {"code": "\n\ndef provisioned(vcores):\n    return vcores * VCORE_HOUR * HOURS\n\n\ndef serverless(busy_hours, busy_vcores, min_vcores=0.5, pause_after=1):\n    idle = 24 - busy_hours\n    online_idle = min(idle, pause_after)\n    per_day = busy_hours * busy_vcores + online_idle * min_vcores\n    return per_day * DAYS * 3600 * SERVERLESS_SECOND\n", "note": "Um banco provisionado é cobrado por toda hora. Um serverless, a cada dia, pelas horas ocupadas nos vCores que usou, depois pela hora que espera no mínimo antes de pausar, o `auto_pause_delay_in_minutes = 60` da declaração, e depois por nada."}, {"code": "\n\nprint(f\"{'busy hours a day':>16}{'serverless':>12}{'provisioned':>13}\")\nfor busy in (1, 2, 4, 8, 12, 16, 17, 20, 23):\n    print(f'{busy:>16}{serverless(busy, 2):>12,.2f}{provisioned(2):>13,.2f}')\n", "note": "**Um mês para cada número de horas ocupadas por dia**, os dois bancos com dois vCores enquanto ocupados."}]}
```

```
ana@laptop:~/azure$ python breakeven.py
busy hours a day  serverless  provisioned
               1       27.38       365.00
               2       49.28       365.00
               4       93.08       365.00
               8      180.68       365.00
              12      268.28       365.00
              16      355.88       365.00
              17      377.78       365.00
              20      443.48       365.00
              23      509.18       365.00
```

**A esses preços, o serverless é mais barato até o banco ficar ocupado umas 16 horas por dia**, e
depois disso os dois vCores provisionados ganham, já que custam os mesmos 365,00 por mais que sejam
usados. A cópia de desenvolvimento da Quitanda é usada num dia de trabalho de oito horas, o que dá
180,68 contra 365,00. O banco de pedidos recebe pedidos das sete da manhã à meia-noite, todo dia, e o
`GP_Gen5_2` provisionado da primeira seção é a compra certa para ele.

## O custo de acordar

**Um banco pausado não está lá na hora.** A primeira conexão depois de uma pausa começa a volta, e o
banco fica indisponível até ela terminar, então uma aplicação que não tenta de novo pode ver a primeira
conexão falhar. Isso é aceitável para um desenvolvedor abrindo o laptop às nove. Não é aceitável para
uma loja cujo primeiro cliente do dia recebe um erro, e é o motivo de o serverless com pausa
automática ser uma escolha de desenvolvimento e de relatórios muito mais vezes que de produção. Pôr o
atraso em `-1` mantém a cobrança por segundo e abre mão da pausa.
