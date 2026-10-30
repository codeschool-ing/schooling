---
title: Quando o Dataproc vence o Dataflow, e quando não vence
version: 1
---

**A crença comum é que o Dataproc é a opção barata e o Dataflow, a cômoda.** Por hora de trabalho, a
primeira metade mal se sustenta: com os preços das páginas do Google para São Paulo, a mesma máquina
custa, nos dois, valores a menos de um quinto um do outro. O que decide a conta são as horas em que
ninguém trabalha, e o que decide a escolha, na maior parte, nem é a conta.

## Os preços, e de onde veio cada um

Todo número abaixo foi lido em 2026-10-30, em dólares americanos, para `southamerica-east1`.

| o quê | preço | página |
|---|---|---|
| `n2-standard-4`, 4 vCPU e 16 GiB, sob demanda | $0.30832 por hora | `cloud.google.com/products/compute/pricing/general-purpose` |
| taxa de gestão do Dataproc, clusters | $0.010 por vCPU-hora | `cloud.google.com/dataproc/pricing` |
| disco persistente padrão | $0.000082192 por GiB-hora | `cloud.google.com/compute/disks-image-pricing` |
| Dataproc Serverless, nível standard | $0.095246 por DCU-hora | `cloud.google.com/dataproc/pricing` |
| vCPU de worker em lote do Dataflow | $0.084 por hora | `cloud.google.com/dataflow/pricing` |
| memória de worker em lote do Dataflow | $0.0053355 por GiB-hora | `cloud.google.com/dataflow/pricing` |
| disco persistente padrão do Dataflow | $0.000081 por GiB-hora | `cloud.google.com/dataflow/pricing` |

**A taxa de gestão é a única linha que é do próprio Dataproc num cluster**, e a página de preços a
dá como uma taxa só, $0.010 por vCPU-hora, aplicada a toda vCPU do master e dos dois tipos de
worker. Todo o resto da conta de um cluster é do Compute Engine: as máquinas, pelo preço do tipo
delas, e os discos. A página do Compute Engine também vende a mesma `n2-standard-4` mais barata com
compromisso de um ou três anos, e como Spot a um preço que muda por dia, e é por isso que nenhuma
linha aqui é Spot.

Três coisas ficam fora de todas as linhas abaixo e merecem ser nomeadas. **O Dataflow Shuffle** cobra
$0.01747 por GiB de dados embaralhados num job em lote em São Paulo, e o Serverless cobra
armazenamento de shuffle por GiB-hora; os dois dependem dos dados, e este job embaralha uma linha por
cliente. **O armazenamento e as leituras** dos buckets são os mesmos, qualquer que seja o motor que os
lê. **Os descontos por compromisso e por uso contínuo** baixam as linhas do Compute Engine e ficaram
no preço sob demanda.

## O job de uma noite, de quatro jeitos

O job noturno da Quitanda, no tamanho que terá daqui a um ano: dez workers de 4 vCPU e 16 GiB por
duas horas, trinta noites por mês. O programa dá o preço de uma unidade desse tamanho em cada
produto, depois o do mês, e depois o do mesmo cluster deixado ligado. Salve-o como
`dataproc_vs_dataflow.py`:

```schooling-example
{"language": "python", "file": "dataproc_vs_dataflow.py", "parts": [{"code": "# USD, southamerica-east1, read on 2026-10-30, with the page each line came from.\nN2_STANDARD_4 = 0.30832    # an hour, on demand: cloud.google.com/products/compute/pricing/general-purpose\nFEE_PER_VCPU = 0.010       # an hour, Dataproc on Compute Engine: cloud.google.com/dataproc/pricing\nPD_STANDARD = 0.000082192  # a GiB-hour: cloud.google.com/compute/disks-image-pricing\nDCU = 0.095246             # an hour, Serverless, standard tier: cloud.google.com/dataproc/pricing\nDF_VCPU = 0.084            # an hour, Dataflow batch: cloud.google.com/dataflow/pricing\nDF_GIB = 0.0053355         # a GiB-hour of memory, Dataflow batch\nDF_PD = 0.000081           # a GiB-hour of standard disk, Dataflow\nHOURS_PER_MONTH = 730\n\n", "note": "Sete preços de quatro páginas, cada um com a sua página ao lado, e as 730 horas de um mês médio."}, {"code": "node = N2_STANDARD_4 + 4 * FEE_PER_VCPU + 100 * PD_STANDARD   # with a 100 GiB boot disk\nexecutor = (4 * 0.6 + 16 * 0.1) * DCU                         # 4 vCPU and 16 GiB are 4 DCUs\nworker = 4 * DF_VCPU + 16 * DF_GIB + 25 * DF_PD               # 25 GiB of disk, with Shuffle\nprint(f'one unit of 4 vCPU and 16 GiB for an hour: cluster {node:.5f}, '\n      f'Serverless {executor:.5f}, Dataflow {worker:.5f}')\n\n", "note": "**Uma unidade do mesmo tamanho em cada produto, por uma hora.** Um nó de cluster é a máquina, a taxa sobre as quatro vCPUs e o disco. Um executor do Serverless vira DCUs pelas taxas da página, 0,6 por vCPU e 0,1 por GiB. Um worker do Dataflow é cobrado por vCPU, memória e disco diretamente."}, {"code": "WORKERS, HOURS, NIGHTS = 10, 2, 30\nmonth = {\n    'Dataproc cluster': (WORKERS + 1) * node * HOURS * NIGHTS,          # plus the master\n    'Dataproc Serverless': (WORKERS + 1) * executor * HOURS * NIGHTS,   # plus the driver\n    'Dataflow': WORKERS * worker * HOURS * NIGHTS,\n    'cluster left on': (WORKERS + 1) * node * HOURS_PER_MONTH,\n}\nfor name, usd in month.items():\n    print(f'{name:<21}{usd:8.2f} a month')\n\n", "note": "Dez unidades por duas horas, trinta noites. Um cluster paga também o master, e um batch do Serverless paga o driver, os dois do tamanho de um worker; o Dataflow coordena o job ele mesmo e cobra só os workers. A última linha é o mesmo cluster criado uma vez e nunca apagado."}, {"code": "per_nightly_hour = WORKERS * worker * NIGHTS\nprint(f'left on, the cluster is cheaper than Dataflow above '\n      f'{month[\"cluster left on\"] / per_nightly_hour:.1f} hours of work a night')\n", "note": "Onde a linha reta de um cluster que nunca para encontra a linha crescente do Dataflow: o custo de um mês do cluster ocioso, dividido pelo que cada hora de trabalho noturno custa no Dataflow em trinta noites."}]}
```

```
ana@laptop:~/gcp$ python3 dataproc_vs_dataflow.py
one unit of 4 vCPU and 16 GiB for an hour: cluster 0.35654, Serverless 0.38098, Dataflow 0.42339
Dataproc cluster       235.32 a month
Dataproc Serverless    251.45 a month
Dataflow               254.04 a month
cluster left on       2863.01 a month
left on, the cluster is cheaper than Dataflow above 22.5 hours of work a night
```

**Por hora da mesma unidade, os três ficam próximos: 0.35654 por nó de cluster, 0.38098 por executor
do Serverless e 0.42339 por worker do Dataflow.** O cluster é o mais barato porque a máquina do
Compute Engine mais um centavo de taxa por vCPU sai menos que as taxas de vCPU e memória do Dataflow,
que incluem o serviço que gerencia os workers. No mês a diferença encolhe de novo, porque o cluster e
o batch pagam cada um uma máquina a mais que o Dataflow: o master e o driver. **235.32, 251.45 e
254.04 ficam a menos de 8% um do outro**, menos que a diferença que um job mal dimensionado faz.

**A quarta linha é a que importa.** As mesmas onze máquinas, criadas uma vez e nunca apagadas, custam
2863.01 por mês, doze vezes o cluster efêmero, pelo mesmo trabalho exato. Nada nas máquinas mudou
entre as duas linhas; só as horas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Um gráfico de USD por mês contra horas de trabalho por noite, para um job de dez workers em trinta noites. Três linhas sobem do zero quase juntas: o Dataflow até cerca de 3048 em 24 horas, o Dataproc Serverless até cerca de 3017 e um cluster Dataproc efêmero até cerca de 2824. Uma linha reta tracejada, o cluster sempre ligado, fica em 2863.01 quaisquer que sejam as horas. O Dataflow a cruza em 22,5 horas. Uma marca pontilhada em 2 horas mostra o job da Quitanda.\" data-fig=\"l23-month\"><line x1=\"80.0\" y1=\"280.0\" x2=\"560.0\" y2=\"280.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"80.0\" y1=\"280.0\" x2=\"80.0\" y2=\"30.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"80.0\" y1=\"280.0\" x2=\"80.0\" y2=\"284.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"80.0\" y=\"295.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><line x1=\"160.0\" y1=\"280.0\" x2=\"160.0\" y2=\"284.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"160.0\" y=\"295.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><line x1=\"240.0\" y1=\"280.0\" x2=\"240.0\" y2=\"284.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"240.0\" y=\"295.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">8</text><line x1=\"320.0\" y1=\"280.0\" x2=\"320.0\" y2=\"284.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"320.0\" y=\"295.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">12</text><line x1=\"400.0\" y1=\"280.0\" x2=\"400.0\" y2=\"284.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"400.0\" y=\"295.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">16</text><line x1=\"480.0\" y1=\"280.0\" x2=\"480.0\" y2=\"284.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"480.0\" y=\"295.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20</text><line x1=\"560.0\" y1=\"280.0\" x2=\"560.0\" y2=\"284.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"560.0\" y=\"295.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">24</text><line x1=\"76.0\" y1=\"280.0\" x2=\"80.0\" y2=\"280.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"72.0\" y=\"280.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><line x1=\"76.0\" y1=\"244.3\" x2=\"80.0\" y2=\"244.3\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"72.0\" y=\"244.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">500</text><line x1=\"76.0\" y1=\"208.6\" x2=\"80.0\" y2=\"208.6\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"72.0\" y=\"208.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1000</text><line x1=\"76.0\" y1=\"172.9\" x2=\"80.0\" y2=\"172.9\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"72.0\" y=\"172.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1500</text><line x1=\"76.0\" y1=\"137.1\" x2=\"80.0\" y2=\"137.1\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"72.0\" y=\"137.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2000</text><line x1=\"76.0\" y1=\"101.4\" x2=\"80.0\" y2=\"101.4\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"72.0\" y=\"101.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2500</text><line x1=\"76.0\" y1=\"65.7\" x2=\"80.0\" y2=\"65.7\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"72.0\" y=\"65.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3000</text><line x1=\"76.0\" y1=\"30.0\" x2=\"80.0\" y2=\"30.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"72.0\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3500</text><text x=\"320.0\" y=\"316.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">horas de trabalho por noite, dez workers</text><text x=\"80.0\" y=\"14.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">USD por mês</text><polyline points=\"80.0,280.0 560.0,62.3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></polyline><polyline points=\"80.0,280.0 560.0,64.5\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"2\"></polyline><polyline points=\"80.0,280.0 560.0,78.3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></polyline><polyline points=\"80.0,75.5 560.0,75.5\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"2\" stroke-dasharray=\"6 4\"></polyline><text x=\"568\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">Dataflow</text><text x=\"90\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">cluster sempre ligado</text><text x=\"568\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">Serverless</text><text x=\"568\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">cluster efêmero</text><circle cx=\"530.0\" cy=\"75.5\" r=\"4\" fill=\"var(--phosphor)\"></circle><line x1=\"530.0\" y1=\"75.5\" x2=\"530.0\" y2=\"280.0\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\" stroke-dasharray=\"2 3\"></line><text x=\"524.0\" y=\"61.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">22,5 h</text><line x1=\"120.0\" y1=\"280.0\" x2=\"120.0\" y2=\"215.7\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\" stroke-dasharray=\"2 3\"></line><text x=\"124.0\" y=\"210.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o job da Quitanda: 2 h</text></svg>", "caption": "Por hora de trabalho, os três ficam a um décimo um do outro; um cluster sempre ligado custa o mesmo trabalhando duas horas por noite ou vinte, e o Dataflow só o alcança em 22,5.", "same": ["Dataflow", "Serverless"]}
```

**A linha reta e as que sobem se encontram em 22,5 horas de trabalho por noite.** Dez workers do
Dataflow custam 4.23393 por hora, o que em trinta noites dá 127.02 por mês para cada hora noturna, e
2863.01 dividido por isso dá 22,5. Então um cluster que nunca para só é mais barato que o Dataflow
para um trabalho que o mantém ocupado quase o dia inteiro. Abaixo disso, um cluster ligado está
pagando horas que ninguém usa, e a proteção é o `--delete-max-idle` da seção anterior, não um tipo de
máquina mais barato.

## Quando o Dataproc vence

**Quando o código já é Spark ou Hadoop.** Um time com anos de jobs Spark, consultas Hive ou
MapReduce os leva para o Dataproc trocando caminhos `hdfs://` por `gs://`, e esse é o maior motivo
isolado para o Dataproc existir. Reescrever os mesmos jobs em Apache Beam para o Dataflow é um
projeto; mudá-los de lugar é uma tarde por job.

**Quando o job precisa da máquina.** Uma biblioteca nativa, uma configuração específica do Spark, um
JAR no classpath, um agente que tem de rodar ao lado do job: no Dataproc isso vai numa ação de
inicialização ou numa imagem própria, e no Dataflow tem de ir num contêiner de worker.

**Quando pessoas trabalham nele.** Notebooks, Spark SQL explorado à mão, um analista no Trino: isso
precisa de algo ligado quando a pessoa chega, e um cluster compartilhado o dia todo paga as horas
ociosas uma vez para todo mundo, com o `--delete-max-idle` para a noite.

**Quando o Spot cabe no job.** Um job em lote grande que aguenta perder workers secundários pode rodar
a maior parte do trabalho na capacidade mais barata que o Google vende, a um preço em que esta aula
não conseguiu pôr número. O equivalente mais próximo no Dataflow é o FlexRS, que a página do Dataflow
descreve como um desconto na vCPU e na memória em lote em troca de começar o job até seis horas
depois.

## Quando o Dataflow vence

**Quando o pipeline é novo**, e em especial quando é em lote e em fluxo ao mesmo tempo. A aula 21
escreveu um pipeline Beam para os dois, e a aula 22 deu a ele janelas e watermarks; o Spark tem o
próprio motor de streaming, e no Dataproc ele roda num cluster que alguém tem de manter ligado o dia
inteiro.

**Quando ninguém quer ser dono de um cluster.** O Dataflow não tem imagem para atualizar, número de
workers para escolher de antemão, ação de inicialização para estourar o tempo nem cluster para
esquecer. Ele escala os workers de cada job pelo que o job está fazendo e os para quando ele termina.

**Quando o trabalho é irregular.** Um job que roda em algumas noites e não em outras, ou roda por
minutos, é onde o Dataflow e o Serverless, que só cobram enquanto há trabalho, saem mais baratos, e
onde um cluster passa mais da vida ligando que trabalhando.

**O julgamento é sobre o código que você tem e as horas que usa, não sobre o motor.** Para o único
job noturno novo da Quitanda, o Dataflow custa 254.04 − 235.32 = 18.72 por mês a mais que um cluster
efêmero, e compra um pipeline que ninguém precisa dimensionar, atualizar ou apagar. No dia em que a
empresa herdar cem jobs Spark de uma aquisição, ou uma cientista de dados quiser um notebook sobre os
mesmos dados toda manhã, o Dataproc deixa de ser o motor mais barato e passa a ser o óbvio.
