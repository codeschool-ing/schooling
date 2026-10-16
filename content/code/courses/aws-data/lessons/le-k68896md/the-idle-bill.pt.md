---
title: Quanto custa um ambiente enquanto espera
version: 1
---

**Um ambiente do MWAA é cobrado por toda hora em que existe, e não há como pausá-lo.** Ele não tem
estado parado: o scheduler, o servidor web, o banco de metadados e os workers base rodam o tempo
todo, porque o scheduler precisa estar acordado para perceber que chegaram as três da manhã. O único
jeito de parar de pagar é apagar o ambiente, o que apaga o banco dele e, com o banco, a história de
toda execução. Então a pergunta honesta sobre o MWAA não é quanto um pipeline custa quando roda, e
sim quanto o ambiente custa quando nada roda.

```
ana@laptop:~/aws$ python3 prices.py mwaa
AWS public price list, sa-east-1, USD, excluding tax

MWAA, USD per hour
  small environment                                     0.84249  hour
  small extra worker                                    0.09456  hour
  medium environment                                    1.27233  hour
  medium extra worker                                   0.18913  hour
  large environment                                     1.70217  hour
  large extra worker                                    0.37826  hour
```

**Uma classe de ambiente é um tamanho para o ambiente inteiro**, `mw1.small`, `mw1.medium` e
`mw1.large` nestas três linhas: uma classe maior tem scheduler e servidor web maiores e workers
maiores, e dá conta de mais DAGs e mais tarefas ao mesmo tempo. A linha "extra worker" é quanto custa
por hora cada worker além do base enquanto o autoscaling o mantém, e é assim que um ambiente cresce
nas horas em que está ocupado.

## Um ambiente pequeno, um mês, fazendo quase nada

O pipeline da Quitanda são os dois jobs do Glue da DAG: umas duas horas de trabalho por noite. Ponha
preço num ambiente pequeno por um mês de 730 horas:

| | conta | USD |
|---|---|---|
| ambiente pequeno, o mês | 0.84249 × 730 | 615.02 |
| o mesmo, o ano | 0.84249 × 8760 | 7380.21 |
| três workers pequenos extras, duas horas por noite, 30 noites | 3 × 2 × 30 × 0.09456 | 17.02 |
| ambiente médio, o mês | 1.27233 × 730 | 928.80 |
| ambiente grande, o mês | 1.70217 × 730 | 1242.58 |

**615.02 por mês compram 60 horas de orquestração e 670 horas de espera.** Dividido pelas horas em que
o pipeline trabalha, o ambiente custa 615.02 ÷ 60 = 10.25 USD por hora de trabalho, antes de uma única
DPU do Glue, que é cobrada à parte. Os três workers extras, a parte que acompanha o trabalho, somam
17.02 a isso; os 615.02 são o preço de estar acordado. O MWAA também cobra o armazenamento do banco
de metadados, por gigabyte-mês, e a tabela não imprime essa linha.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Uma linha do tempo de um dia, de 00:00 a 24:00. A barra do que é cobrado cobre as 24 horas: 0,84249 vezes 24 dá 20,22 USD por dia. A barra do trabalho cobre só de 03:00 a 05:00, as duas horas dos dois jobs do Glue.\" data-fig=\"l25-day\"><defs><marker id=\"ah-l25-day\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"150.0\" y1=\"150\" x2=\"150.0\" y2=\"155\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"150.0\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">00:00</text><line x1=\"217.5\" y1=\"150\" x2=\"217.5\" y2=\"155\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"217.5\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">03:00</text><line x1=\"285.0\" y1=\"150\" x2=\"285.0\" y2=\"155\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"285.0\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">06:00</text><line x1=\"352.5\" y1=\"150\" x2=\"352.5\" y2=\"155\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"352.5\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:00</text><line x1=\"420.0\" y1=\"150\" x2=\"420.0\" y2=\"155\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"420.0\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">12:00</text><line x1=\"487.5\" y1=\"150\" x2=\"487.5\" y2=\"155\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"487.5\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">15:00</text><line x1=\"555.0\" y1=\"150\" x2=\"555.0\" y2=\"155\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"555.0\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">18:00</text><line x1=\"622.5\" y1=\"150\" x2=\"622.5\" y2=\"155\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"622.5\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">21:00</text><line x1=\"690.0\" y1=\"150\" x2=\"690.0\" y2=\"155\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"690.0\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">24:00</text><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">cobrado</text><rect x=\"150\" y=\"55\" width=\"540\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">24 horas: 0,84249 x 24 = 20,22 por dia</text><text x=\"20\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">trabalhando</text><rect x=\"217.5\" y=\"100\" width=\"45.0\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270.5\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2 horas: os dois jobs do Glue</text><line x1=\"150\" y1=\"150\" x2=\"690\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"420.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">uma noite de um ambiente pequeno</text></svg>", "caption": "Um ambiente pequeno é cobrado o dia todo por duas horas de trabalho; as outras vinte e duas são o preço de estar acordado às três."}
```

**O formato é o oposto do dos serviços das últimas lições.** Glue, EMR Serverless e Athena cobram
pelo trabalho e nada pela espera; um ambiente do MWAA cobra pela espera e quase nada a mais pelo
trabalho. Isso o torna barato por pipeline quando há muitos pipelines, e caro por pipeline quando há
poucos. Quarenta DAGs dividindo um ambiente pequeno custam 615.02 ÷ 40 = 15.38 por mês cada, e
ninguém chamaria isso de caro por um agendador com novas tentativas, backfills e um servidor web.
Uma DAG sozinha paga os 615.02 inteiros.

## Quando a espera vale a pena

**O MWAA justifica o preço quando o próprio Airflow é o ponto.** Muitas DAGs, escritas por várias
equipes, com dependências entre elas; backfills, em que rodar de novo o intervalo da terça passada é
um clique; sensores que esperam um arquivo ou uma partição aparecer; operadores para dezenas de
serviços além dos da AWS; e uma equipe que já conhece o Airflow, ou um pipeline que um dia precisa
ir para outra nuvem, onde o Airflow também roda. Para isso, 615.02 por mês é um preço razoável para
não operar você mesmo um agendador, um banco e uma frota de workers.

**Ele não justifica o preço para um punhado de pipelines simples**, cada um uma cadeia curta de
chamadas à AWS rodada num horário. Esse caso tem uma resposta mais barata, feita de dois serviços
que não custam nada enquanto esperam, e as duas próximas seções a montam.
