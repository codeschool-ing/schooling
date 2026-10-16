---
title: "Tamanhos e preço: pagando pelo que a task reserva"
version: 1
---

No EC2 você paga pela instância, e as tasks dentro dela vão de carona até a instância encher.
**No Fargate a instância some da conta também.** Você paga pelas vCPUs e pela memória que a
definição de task reserva, por segundo, desde o momento em que a imagem começa a baixar até a task
parar. Uma task que usa um décimo do seu quarto de vCPU paga pelo quarto. Uma task que não está
rodando não paga nada.

## Os tamanhos que existem

O tamanho é o `cpu` e o `memory` da task, e o Fargate oferece pares fixos em vez de qualquer
combinação. Esta é a tabela da AWS para tasks Linux:

| cpu | vCPU | memória permitida |
|---|---|---|
| 256 | 0,25 | 512 MiB, 1 GB, 2 GB |
| 512 | 0,5 | 1 a 4 GB, de 1 em 1 GB |
| 1024 | 1 | 2 a 8 GB, de 1 em 1 GB |
| 2048 | 2 | 4 a 16 GB, de 1 em 1 GB |
| 4096 | 4 | 8 a 30 GB, de 1 em 1 GB |
| 8192 | 8 | 16 a 60 GB, de 4 em 4 GB |
| 16384 | 16 | 32 a 120 GB, de 8 em 8 GB |

**A faixa de memória sobe com a CPU**, entre dois e oito gigabytes por vCPU. Uma task que quer um
quarto de vCPU e 4 GB, digamos um cache que guarda muito e calcula pouco, não está na tabela, e
precisa comprar 0,5 vCPU para ter isso. O moto não conhece a tabela:

```
ana@laptop:~/aws$ aws ecs register-task-definition --family odd-size --network-mode awsvpc --requires-compatibilities FARGATE --cpu 256 --memory 4096 --container-definitions "[{\"name\":\"web\",\"image\":\"nginx:1.29-alpine\",\"memory\":512}]" --query "taskDefinition.[family,cpu,memory]" --output text
odd-size	256	4096
```

A AWS recusa esse registro, porque 4.096 MiB não está entre as memórias permitidas com 256 unidades
de CPU. É mais um caso em que uma definição que funciona contra o moto foi conferida na forma, não
nos valores.

## O preço, da tabela

As quatro linhas do Fargate na tabela de preços de 16 de outubro de 2026, lidas da lista de preços
da AWS como a aula 1 faz:

```
ana@laptop:~/aws$ python3 prices.py containers | sed -n 3,8p
Fargate
  vCPU, x86                                       0.0696  per hour
  memory, x86                                     0.0076  per GB-hour
  vCPU, Arm                                       0.0557  per hour
  memory, Arm                                    0.00612  per GB-hour
  ephemeral storage above 20 GB                 0.000211  per GB-hour
```

Dois medidores, um por vCPU-hora e um por GB-hora, e outros menores para Arm. Salve o programa
abaixo como `~/aws/fargate_cost.py` e rode; ele passa os dois medidores por três casos:

```schooling-example
{"language": "python", "file": "fargate_cost.py", "parts": [{"code": "# fargate_cost.py: what Fargate tasks cost in sa-east-1, from the price sheet\nHOURS = 730\n\n", "note": "730 horas é o mês que a tabela de preços e todas as aulas deste curso usam."}, {"code": "PRICE = {                      # USD, 16 October 2026\n    \"x86\": {\"vcpu\": 0.0696, \"gb\": 0.0076},\n    \"arm\": {\"vcpu\": 0.0557, \"gb\": 0.00612},\n}\n\n", "note": "As quatro linhas do Fargate do `prices.py containers`, digitadas. O Fargate tem dois medidores, um por vCPU-hora e um por GB-hora, e os de Arm são menores."}, {"code": "def per_hour(arch, vcpu, gb):\n    p = PRICE[arch]\n    return vcpu * p[\"vcpu\"] + gb * p[\"gb\"]\n\n", "note": "O preço por hora de uma task são as vCPUs dela vezes um medidor mais os gigabytes vezes o outro. Nada mais entra abaixo de 20 GB de armazenamento efêmero."}, {"code": "for arch, vcpu, gb, tasks in [(\"x86\", 0.25, 0.5, 1), (\"x86\", 1, 2, 2), (\"arm\", 1, 2, 2)]:\n    hour = per_hour(arch, vcpu, gb)\n    month = hour * tasks * HOURS\n    print(f\"{tasks} x {vcpu:>4} vCPU {gb:>3} GB {arch}:  {hour:.5f}/h each,  {month:7.2f} USD a month\")\n", "note": "Três casos: a menor task que existe, depois duas tasks de 1 vCPU e 2 GB em cada arquitetura, o formato de um serviço web pequeno mantido em duas por disponibilidade."}]}
```

```
ana@laptop:~/aws$ python3 fargate_cost.py
1 x 0.25 vCPU 0.5 GB x86:  0.02120/h each,    15.48 USD a month
2 x    1 vCPU   2 GB x86:  0.08480/h each,   123.81 USD a month
2 x    1 vCPU   2 GB arm:  0.06794/h each,    99.19 USD a month
```

**A menor task que existe, um quarto de vCPU com 512 MiB, custa 0,0212 USD por hora**, 0,25 ×
0,0696 mais 0,5 × 0,0076, e 15,48 USD num mês deixada rodando. Duas tasks de 1 vCPU e 2 GB, um
serviço web pequeno mantido em duas para que uma possa falhar, custam 123,81 USD por mês em x86 e
99,19 em Arm. O número de Arm é 20% menor para o mesmo serviço, e é por isso que a definição da
seção anterior pediu `ARM64`; o preço da mudança é uma imagem construída para `arm64`, que a aula
10 constrói e envia.

## Contra uma instância

A aula 8 calculou uma `m7i.large` em 117,27 USD por mês como container instance. Ela tem 2 vCPUs e
8 GB. As duas tasks x86 acima reservam 2 vCPUs e 4 GB juntas, e custam 123,81. **Cheia, a
instância é mais barata e tem o dobro de memória; a instância quase nunca está cheia.** Um cluster
EC2 guarda espaço de sobra: para implantações, como a figura da aula 8 mostrou, para a próxima task
a posicionar e para uma instância sendo substituída. E uma instância com um terço vazio custa o
mesmo que uma lotada. O Fargate não cobra nada por espaço que ninguém usa, nem pelo sistema
operacional, pelo agente e pelos patches que uma instância carrega, que nunca aparecem na tabela de
preços.

A conta vira de novo quando a frota cresce e fica estável: com muitas tasks rodando o mês todo, as
horas de instância saem mais baratas, e os Savings Plans, aula 22 de `aws-operations`, cortam as
duas. A aula 23 põe a mesma carga no EC2, no Fargate e no Lambda lado a lado.

Dois medidores menores fazem parte de uma conta de Fargate. **Armazenamento efêmero**: toda task
recebe 20 GB de disco sem custo, e pode receber até 200 GB. O que passa de 20 custa 0,000211 USD
por GB-hora, então 50 GB numa task são 30 × 0,000211 × 730 = 4,62 USD por mês. E **o mínimo**: o
Fargate cobra uma task Linux por segundo com mínimo de um minuto, então um trabalho de dez segundos
paga por sessenta. Isso só importa para trabalho iniciado milhares de vezes por dia, que é
território da aula 14.
