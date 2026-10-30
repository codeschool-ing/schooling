---
title: O que um job do Dataflow custa, e o fluxo que nunca para
version: 1
---

**Uma conta do Dataflow são as máquinas, por segundo, mais o que o serviço faz por elas.** Os
workers são cobrados por vCPU-hora e por GiB-hora de memória, enquanto existirem, em incrementos de
um segundo; os discos deles são cobrados por GiB-hora; e o shuffle, ou no streaming o Streaming
Engine, tem uma linha própria. Não há cobrança por pipeline nem por elemento. **Então um job em lote
custa os minutos em que roda, e um job de streaming custa cada hora do mês**, chegue um pedido ou
não.

## Os preços, São Paulo

De `cloud.google.com/dataflow/pricing`, região `southamerica-east1`, em dólares americanos, lidos em
2026-10-30:

| | lote | FlexRS | streaming |
|---|---:|---:|---:|
| por vCPU-hora | 0,084 | 0,0534 | 0,1035 |
| por GiB-hora de memória | 0,0053355 | 0,0033889 | 0,0053355 |
| por GiB de shuffle | 0,01747 | 0,01747 | — |
| Streaming Engine, por GiB processado (cobrança legada) | — | — | 0,02858 |
| Streaming Engine, por Compute Unit (cobrança por recurso) | — | — | 0,134 |

**Um desconto em dois degraus está embutido na linha de shuffle do lote.** A página cobra o shuffle
depois de um ajuste de volume: os primeiros 250 GiB de um job a um quarto do tamanho, os 4.870 GiB
seguintes pela metade, e o resto inteiro. Um disco persistente padrão custa 0,000081 dólar por
GiB-hora na mesma página, e o Dataflow Prime troca as linhas de vCPU, memória e shuffle por uma só,
a **Data Compute Unit**, a 0,09 dólar no lote e 0,134 no streaming. A página define uma DCU como
comparável ao que um job usa rodando uma hora num worker de 1 vCPU e 4 GB; não dá para definir
quantas um job usa, só ler a contagem depois.

**O FlexRS é o preço do lote para quem aceita esperar.** O job pode começar em qualquer momento
dentro de seis horas, numa mistura de máquinas comuns e preemptivas, por um desconto que a página
descreve como de uns 40%. Os workers dele vêm por padrão com 2 vCPU e 7,5 GB, no mínimo dois.

## Cinco formas de rodar o mesmo pipeline

A conta, com os preços como constantes e as suposições à vista. Salve como
`~/gcp/dataflow_bill.py`:

`dataflow_bill.py`:

```python
"""dataflow_bill.py: five ways to run Quitanda's pipeline, priced.

Prices: cloud.google.com/dataflow/pricing, southamerica-east1, USD, read 2026-10-30.
The sizes and the hours are this lesson's assumptions, not measurements.
"""
BATCH = {'vcpu': 0.084, 'gib': 0.0053355}           # per vCPU-hour, per GiB-hour
FLEXRS = {'vcpu': 0.0534, 'gib': 0.0033889}
STREAMING = {'vcpu': 0.1035, 'gib': 0.0053355}
SHUFFLE_GIB = 0.01747                # batch: per GiB of shuffle, after the adjustment
STREAMING_ENGINE_GIB = 0.02858       # streaming: per GiB processed, legacy billing
DCU_BATCH = 0.09                     # Dataflow Prime, per batch DCU
DISK_GIB_HOUR = 0.000081             # Standard Persistent Disk
NIGHT, MONTH = 12 / 60, 730          # hours


def billable_shuffle(gib):
    """The page's adjustment: 75% off the first 250 GiB, 50% off the next 4,870."""
    return min(gib, 250) * 0.25 + min(max(gib - 250, 0), 4870) * 0.5 + max(gib - 5120, 0)


def workers(price, n, vcpu, gib, disk_gib, hours):
    return n * hours * (vcpu * price['vcpu'] + gib * price['gib'] + disk_gib * DISK_GIB_HOUR)


nights = [
    ('batch, 4 workers of 1 vCPU, 10 GiB shuffled',
     workers(BATCH, 4, 1, 3.75, 25, NIGHT) + billable_shuffle(10) * SHUFFLE_GIB),
    ('FlexRS, 2 workers of 2 vCPU, 10 GiB shuffled',
     workers(FLEXRS, 2, 2, 7.5, 25, NIGHT) + billable_shuffle(10) * SHUFFLE_GIB),
    ('Prime, if the night counts 0.8 DCUs',
     0.8 * DCU_BATCH + 4 * NIGHT * 25 * DISK_GIB_HOUR),
]
streams = [
    ('streaming, the default worker, 400 GB of disk',
     workers(STREAMING, 1, 4, 15, 400, MONTH)),
    ('streaming, 2 vCPU, Streaming Engine, 20 GiB',
     workers(STREAMING, 1, 2, 7.5, 30, MONTH) + 20 * STREAMING_ENGINE_GIB),
]
for name, night in nights:
    print(f'{name:<48}{night:>8.4f} a night {night * 30:>8.2f} a month')
for name, month in streams:
    print(f'{name:<48}{"":>17}{month:>8.2f} a month')
```

```
ana@laptop:~/gcp$ python3 dataflow_bill.py
batch, 4 workers of 1 vCPU, 10 GiB shuffled       0.1285 a night     3.86 a month
FlexRS, 2 workers of 2 vCPU, 10 GiB shuffled      0.0974 a night     2.92 a month
Prime, if the night counts 0.8 DCUs               0.0736 a night     2.21 a month
streaming, the default worker, 400 GB of disk                      384.30 a month
streaming, 2 vCPU, Streaming Engine, 20 GiB                        182.67 a month
```

**O job da noite custa poucos dólares por mês em qualquer forma.** Quatro workers de lote padrão por
doze minutos, com 10 GiB pelo shuffle, dão 0,1285 dólar por noite: 0,8 vCPU-hora, 3 GiB-horas de
memória, 20 GiB-horas de disco, e 2,5 GiB cobráveis de shuffle dos 10, que é o ajuste trabalhando.
O FlexRS leva a 0,0974 por poder começar mais tarde, e o Prime ficaria em 0,0736 se a noite contasse
0,8 DCU, um número que ninguém sabe antes da execução: **essa linha é uma estimativa pela própria
comparação da página, não um preço**.

**O fluxo custa de cinquenta a cem vezes a noite.** Um worker de streaming com os padrões roda 730
horas por mês: 4 vCPU a 0,1035, 15 GiB a 0,0053355 e 400 GB de disco, 384,30 dólares antes de um
único evento ser contado. Com o Streaming Engine, o disco cai para 30 GB e um worker de 2 vCPU e
7,5 GB basta, 182,67 dólares com 20 GiB de dados processados. Os 20 GiB são suposição desta aula. Na cobrança legada, o Streaming Engine conta os bytes que entram no pipeline, os que passam entre
estágios e os guardados para as janelas, então até os poucos megabytes de eventos por dia da
Quitanda são contados mais de uma vez, e quantas vezes depende do pipeline. **Na cobrança por
recurso a linha é em Compute Units**, a 0,134 dólar cada, e a quantidade delas é medida pelo
Dataflow, não dá para prever pela página, então o programa não a precifica.

## O que a comparação decide

**Um job de streaming só se paga se alguém age dentro do minuto.** Para os totais por bairro da
Quitanda, lidos por uma analista de manhã, o lote da noite sobre a exportação responde a mesma
pergunta por uns 4 dólares por mês contra 183. Um fluxo vale os 183 dólares quando os totais
alimentam algo que não pode esperar a manhã, como uma tela no depósito que manda entregadores para o
bairro onde os pedidos estão se acumulando. O pipeline não precisa ser escrito duas vezes para
manter essa escolha aberta, que era o ponto da quarta seção.

Três coisas mudam os números, e cada uma é uma opção do pipeline, não código:

- **`--max_num_workers`**: o escalonamento automático acrescenta workers quando o acúmulo cresce, e
  a conta cresce junto. Um teto transforma um pico inesperado em atraso em vez de fatura.
- **`--machine_type`**, junto com `--enable_streaming_engine`: o worker de streaming padrão é
  dimensionado para um job que guarda o estado no próprio disco.
- **`--flexrs_goal=COST_OPTIMIZED`** num job em lote que pode começar dentro de seis horas.

A aula 23 compara a mesma conta com um cluster do Dataproc rodando Spark, onde as máquinas são suas
para dimensionar e para esquecer ligadas.
