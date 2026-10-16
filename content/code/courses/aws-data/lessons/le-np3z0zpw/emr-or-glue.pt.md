---
title: Quando o EMR vence o Glue, e quando não vence
version: 1
---

**A crença comum é que o EMR é a opção barata e o Glue, a cômoda.** Por hora de máquina isso é
verdade, e por uma boa margem. Por mês de uma carga real, só é verdade quando as máquinas estão
ocupadas, e um cluster barato por hora e ocioso em vinte e duas delas é a forma mais cara desta
lição de rodar um job de duas horas.

Comece pelos preços. A linha do EMR é só a taxa. A máquina é do EC2, que esta tabela não lê. O preço da própria máquina vem da tabela da lição 4 de
`cloud`, que imprimiu a `m7i.xlarge` a
**0.32130** USD por hora sob demanda em São Paulo, e a **0.20160** reservada por um ano sem
pagamento adiantado.

```
ana@laptop:~/aws$ python3 prices.py emr glue
AWS public price list, sa-east-1, USD, excluding tax

EMR, USD
  EMR fee on an m7i.xlarge, per hour                    0.05040  hour
  Serverless, per vCPU-hour                             0.09048  hour
  Serverless, per GB-hour of memory                     0.00988  hour

Glue, USD
  ETL job, per DPU-hour                                 0.69000  DPU-hour
  ETL job, Flex, per DPU-hour                           0.45000  DPU-hour
  crawler, per DPU-hour                                 0.69000  DPU-hour
  Data Catalog, per 100,000 objects beyond free         1.00000  month
  Data Catalog, per million requests beyond free        1.00000  million
```

**Uma DPU do Glue tem 4 vCPU e 16 GB de memória, e uma `m7i.xlarge` também**, o que torna a
comparação justa: uma unidade do mesmo tamanho, por uma hora, em cada produto.

| uma unidade de 4 vCPU e 16 GB, por uma hora | conta | USD |
|---|---|---|
| Glue | a DPU-hora | 0.69000 |
| Glue Flex | a DPU-hora Flex | 0.45000 |
| EMR Serverless | 4 × 0.09048 + 16 × 0.00988 = 0.36192 + 0.15808 | 0.52000 |
| EMR on EC2, sob demanda | 0.32130 + 0.05040 | 0.37170 |
| EMR on EC2, reservada | 0.20160 + 0.05040 | 0.25200 |

**O EMR on EC2 sai a 0.37170 contra 0.69000 do Glue, pouco mais da metade**, e a taxa do EMR é a
mesma seja qual for a forma de pagar a máquina, e é por isso que uma máquina reservada a leva a
0.25200. O Spot a leva mais para baixo, num valor que o mercado define no dia.

## O job de uma noite, de cinco jeitos

O job noturno da Quitanda usa dez unidades por duas horas, trinta noites por mês. O programa abaixo
põe preço nele em cada produto, e em mais um caso: o mesmo cluster EMR deixado ligado o mês inteiro.
Salve-o como `emr_vs_glue.py`:

```schooling-example
{"language": "python", "file": "emr_vs_glue.py", "parts": [{"code": "# USD per hour, sa-east-1. Glue and EMR from `python3 prices.py glue emr`;\n# the machine from the sheet of `cloud` lesson 4, m7i.xlarge on demand.\nGLUE_DPU = 0.69000\nGLUE_FLEX_DPU = 0.45000\nEMR_FEE = 0.05040\nM7I_XLARGE = 0.32130\nSERVERLESS_VCPU = 0.09048\nSERVERLESS_GB = 0.00988\nHOURS_PER_MONTH = 730\n\n", "note": "Seis preços copiados das duas tabelas, com a origem de cada um escrita acima deles, e as 730 horas de um mês médio."}, {"code": "per_unit = {                       # one unit: 4 vCPU and 16 GB, for an hour\n    'Glue': GLUE_DPU,\n    'Glue Flex': GLUE_FLEX_DPU,\n    'EMR Serverless': 4 * SERVERLESS_VCPU + 16 * SERVERLESS_GB,\n    'EMR on EC2': M7I_XLARGE + EMR_FEE,\n}\n\n", "note": "**O preço de uma unidade em cada produto.** O Serverless cobra processador e memória à parte, então a unidade dele são quatro de um e dezesseis do outro; o EMR on EC2 é a máquina mais a taxa."}, {"code": "WORKERS, HOURS, NIGHTS = 10, 2, 30\n\nfor name, usd in per_unit.items():\n    units = WORKERS + (1 if name == 'EMR on EC2' else 0)    # plus the primary node\n    month = units * HOURS * NIGHTS * usd\n    print(f'{name:<16}{usd:.5f} a unit-hour  {month:8.2f} a month')\n\n", "note": "Dez unidades por duas horas, trinta noites. O cluster também precisa do nó primário, que coordena e não faz trabalho nenhum, então o EMR on EC2 paga onze máquinas onde os outros pagam dez unidades."}, {"code": "left_on = (WORKERS + 1) * HOURS_PER_MONTH * per_unit['EMR on EC2']\nprint(f'{\"EMR left on\":<16}{per_unit[\"EMR on EC2\"]:.5f} a unit-hour  {left_on:8.2f} a month')\n", "note": "As mesmas onze máquinas criadas uma vez e nunca encerradas: todas as horas do mês, rodando job ou não."}]}
```
```
ana@laptop:~/aws$ python3 emr_vs_glue.py
Glue            0.69000 a unit-hour    414.00 a month
Glue Flex       0.45000 a unit-hour    270.00 a month
EMR Serverless  0.52000 a unit-hour    312.00 a month
EMR on EC2      0.37170 a unit-hour    245.32 a month
EMR left on     0.37170 a unit-hour   2984.75 a month
```

**O cluster EMR transitório é a linha mais barata, a 245.32, e o mesmo cluster deixado ligado é a
mais cara, doze vezes mais, a 2984.75.** Nada nas máquinas mudou entre essas duas linhas; só as
horas. Os 414.00 do Glue são 1,7 vez o cluster transitório, e esse é o preço de ninguém precisar
escolher tipo de instância, escrever uma definição de cluster ou encerrar nada. O Glue Flex, a
270.00, fica cerca de um décimo acima do EMR, para um job que pode esperar capacidade ociosa. O EMR
Serverless fica entre os dois Glues, a 312.00. Um custo que o programa deixa de fora cai só no
cluster EMR: a AWS cobra os minutos que as máquinas levam para ligar e instalar antes de o step
começar, e o moto, pronto na linha em que foi criado, não dá número nenhum para pôr ali.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Um gráfico de USD por mês contra horas de trabalho por noite, para um job de dez unidades em trinta noites. Três linhas sobem a partir de zero: Glue até cerca de 4968 em 24 horas, EMR Serverless até cerca de 3744, e EMR transitório até cerca de 2944. Uma linha tracejada plana, EMR sempre ligado, fica em 2984,75 quaisquer que sejam as horas. O Glue cruza a linha plana em 14,4 horas. Uma marca pontilhada em 2 horas mostra o job da Quitanda.\" data-fig=\"l24-month\"><defs><marker id=\"ah-l24-month\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"80\" y1=\"280\" x2=\"600\" y2=\"280\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"80\" y1=\"280\" x2=\"80\" y2=\"30\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"80.0\" y1=\"280\" x2=\"80.0\" y2=\"284\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"80.0\" y=\"295\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><line x1=\"166.66666666666669\" y1=\"280\" x2=\"166.66666666666669\" y2=\"284\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"166.66666666666669\" y=\"295\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><line x1=\"253.33333333333334\" y1=\"280\" x2=\"253.33333333333334\" y2=\"284\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"253.33333333333334\" y=\"295\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">8</text><line x1=\"340.0\" y1=\"280\" x2=\"340.0\" y2=\"284\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"340.0\" y=\"295\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">12</text><line x1=\"426.6666666666667\" y1=\"280\" x2=\"426.6666666666667\" y2=\"284\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"426.6666666666667\" y=\"295\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">16</text><line x1=\"513.3333333333333\" y1=\"280\" x2=\"513.3333333333333\" y2=\"284\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"513.3333333333333\" y=\"295\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20</text><line x1=\"600.0\" y1=\"280\" x2=\"600.0\" y2=\"284\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"600.0\" y=\"295\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">24</text><line x1=\"76\" y1=\"280.0\" x2=\"80\" y2=\"280.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"72\" y=\"280.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><line x1=\"76\" y1=\"230.0\" x2=\"80\" y2=\"230.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"72\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1000</text><line x1=\"76\" y1=\"180.0\" x2=\"80\" y2=\"180.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"72\" y=\"180.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2000</text><line x1=\"76\" y1=\"130.0\" x2=\"80\" y2=\"130.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"72\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3000</text><line x1=\"76\" y1=\"80.0\" x2=\"80\" y2=\"80.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"72\" y=\"80.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4000</text><line x1=\"76\" y1=\"30.0\" x2=\"80\" y2=\"30.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"72\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5000</text><text x=\"340.0\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">horas de trabalho por noite, dez unidades</text><text x=\"80\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">USD por mês</text><polyline points=\"80.0,280.0 600.0,31.6\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></polyline><polyline points=\"80.0,280.0 600.0,92.8\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"2\"></polyline><polyline points=\"80.0,280.0 600.0,132.8\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></polyline><polyline points=\"80.0,130.8 600.0,130.8\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"2\" stroke-dasharray=\"6 4\"></polyline><text x=\"608.0\" y=\"31.60000000000005\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">Glue</text><text x=\"608.0\" y=\"92.80000000000001\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor-dim)\">EMR Serverless</text><text x=\"608.0\" y=\"144.8068\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">EMR transitório</text><text x=\"608.0\" y=\"120.76245000000003\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">EMR sempre ligado</text><circle cx=\"392.4\" cy=\"130.8\" r=\"4\" fill=\"var(--phosphor)\"></circle><line x1=\"392.4135507246377\" y1=\"130.76245000000003\" x2=\"392.4135507246377\" y2=\"280\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\" stroke-dasharray=\"2 3\"></line><text x=\"392.4135507246377\" y=\"116.76245000000003\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">14,4 h</text><line x1=\"123.33333333333334\" y1=\"280\" x2=\"123.33333333333334\" y2=\"200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\" stroke-dasharray=\"2 3\"></line><text x=\"127.33333333333334\" y=\"195.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o job da Quitanda: 2 h</text></svg>", "caption": "Um cluster sempre ligado custa o mesmo trabalhando duas horas por noite ou vinte; o Glue só o alcança em 14,4.", "same": ["EMR Serverless", "Glue"]}
```

**O cluster sempre ligado custa o mesmo em qualquer número de horas de trabalho, e o Glue sobe a cada
hora.** As duas linhas se cruzam onde o custo mensal do Glue chega a 2984.75: dez DPUs × 30
noites × 0.69 dá 207.00 por mês para cada hora de trabalho noturno, e 2984.75 ÷ 207.00 dá 14,4.
**Um job que roda mais de umas catorze horas por dia sai mais barato num cluster que nunca para do
que no Glue**, e abaixo disso um cluster sempre ligado está pagando as horas em que ninguém o usa.

## Quando o EMR vence

**Quando o trabalho é constante e grande.** Muitas horas por dia em muitas máquinas é onde 0.37170
contra 0.69000 vira milhares de dólares por mês, e uma máquina reservada ou o Spot aumentam a
diferença.

**Quando o job precisa da máquina.** Uma biblioteca nativa, uma configuração específica do Spark, um
JAR no classpath, uma ferramenta da família Hadoop que o Glue não roda: no EMR isso vai numa
bootstrap action, um script que toda máquina roda ao ligar, e no Glue muitas vezes não tem onde ir.

**Quando pessoas trabalham nele.** Notebooks e consultas interativas precisam de algo ligado quando
a pessoa chega, e um cluster compartilhado o dia todo paga as horas ociosas uma vez, para todo mundo.

**Quando o Spot serve ao job.** Um job em lote que tolera perder nós de tarefa roda a maior parte do
trabalho na capacidade mais barata que a AWS vende, que o Glue não oferece; a opção Flex dele é o
mais perto disso.

## Quando o Glue vence

**Quando o trabalho é curto, pequeno ou irregular**, de modo que um cluster passaria mais tempo
ligando e esperando do que trabalhando.

**Quando ninguém quer ser dono de um cluster.** O Glue não tem tipo de máquina, papel para configurar,
encerramento para esquecer nem release para atualizar, e o job da lição 17 rodou sem mais nada em
volta.

**Quando o job é ETL comum sobre o Data Catalog**, que o Glue lê e escreve de forma nativa, com
bookmarks que lembram o que já foi processado.

**O julgamento é sobre horas e pessoas, não sobre Spark.** Os dois rodam o mesmo motor. Para o único
job noturno da Quitanda, o cluster transitório economiza 414.00 − 245.32 = 168.68 por mês em relação
ao Glue, e essa economia se paga numa definição de cluster que alguém escreve, atualiza e é chamado
para consertar às três da manhã. Com um job, o Glue costuma valer a pena; com quarenta, ou com um job
que roda o dia todo, o programa acima imprime um número que ninguém consegue ignorar.
