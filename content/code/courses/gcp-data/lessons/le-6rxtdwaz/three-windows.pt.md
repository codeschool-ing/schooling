---
title: Janelas fixas, deslizantes e de sessão
version: 1
---

**Uma janela é uma regra que dá a cada elemento um ou mais intervalos de horário de evento, e um
agrupamento é calculado uma vez por chave por intervalo.** O Beam traz três regras prontas, e elas
respondem três perguntas diferentes sobre os mesmos pedidos:

| janela | a regra | a pergunta que responde |
|---|---|---|
| **fixa** | intervalos de um comprimento, encostados, alinhados ao relógio | quanto em cada cinco minutos |
| **deslizante** | intervalos de um comprimento, começando de tempos em tempos, então se sobrepõem | quanto nos últimos dez minutos, perguntado a cada cinco |
| **sessões** | um intervalo por chave que cresce enquanto chegam elementos e fecha depois de um intervalo sem nenhum | quanto um cliente pediu numa visita |

As duas primeiras são conhecidas de antemão: a janela das 19:00 às 19:05 existe antes de qualquer
pedido. **Uma sessão não é**: ela é feita a partir dos dados, por chave, juntando as pequenas
janelas em volta de cada elemento sempre que elas se tocam. Isso faz das sessões o único tipo cujas
fronteiras mudam quando chega um dado atrasado: um pedido atrasado que cai entre duas sessões de um
cliente junta as duas numa só.

## Um programa, três janelas

As três rodam pelo horário em que cada pedido foi feito, e agrupam em vez de combinar, para que a
saída possa contar os pedidos além de somá-los. Salve como `~/gcp/windows.py`:

`windows.py`:

```python
"""windows.py: the same orders cut three ways, all by the time each was placed.

    python3 windows.py fixed        five-minute windows, per neighbourhood
    python3 windows.py sliding      ten-minute windows every five, per neighbourhood
    python3 windows.py sessions     a customer's orders with gaps under five minutes
"""
import sys

import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions
from apache_beam.transforms.window import FixedWindows, Sessions, SlidingWindows

from evening import ORDERS, clock, stamped

KIND = sys.argv[1]
WINDOW = {'fixed': FixedWindows(5 * 60),
          'sliding': SlidingWindows(10 * 60, 5 * 60),
          'sessions': Sessions(5 * 60)}[KIND]
KEY = 'customer' if KIND == 'sessions' else 'neighbourhood'


class Show(beam.DoFn):
    def process(self, group, window=beam.DoFn.WindowParam):
        key, cents = group
        print(f'{clock(window.start)}-{clock(window.end)}  {key:<10} '
              f'{len(cents)} order{"s" * (len(cents) != 1)}  {sum(cents) / 100:>7.2f}')


options = PipelineOptions([], runner='BundleBasedDirectRunner')
with beam.Pipeline(options=options) as p:
    (p
     | beam.Create(ORDERS)
     | beam.Map(stamped, KEY, 'placed')
     | beam.WindowInto(WINDOW)
     | beam.GroupByKey()
     | beam.ParDo(Show()))
```

```
ana@laptop:~/gcp$ python3 windows.py fixed | sort
19:00:00-19:05:00  Moema      3 orders    86.80
19:00:00-19:05:00  Pinheiros  2 orders   151.50
19:05:00-19:10:00  Moema      1 order    15.00
19:05:00-19:10:00  Pinheiros  2 orders    80.00
19:10:00-19:15:00  Moema      1 order    22.00
19:10:00-19:15:00  Pinheiros  1 order    56.00
```

**Janelas fixas dão a cada pedido exatamente uma casa.** Dez pedidos, seis grupos, e as contagens
somam dez. São os totais pelo horário do pedido da seção anterior, agora com uma contagem ao lado.

```
ana@laptop:~/gcp$ python3 windows.py sliding | sort
18:55:00-19:05:00  Moema      3 orders    86.80
18:55:00-19:05:00  Pinheiros  2 orders   151.50
19:00:00-19:10:00  Moema      4 orders   101.80
19:00:00-19:10:00  Pinheiros  4 orders   231.50
19:05:00-19:15:00  Moema      2 orders    37.00
19:05:00-19:15:00  Pinheiros  3 orders   136.00
19:10:00-19:20:00  Moema      1 order    22.00
19:10:00-19:20:00  Pinheiros  1 order    56.00
```

**Janelas deslizantes dão a cada pedido duas casas**, porque uma janela de dez minutos que começa a
cada cinco cobre metade da seguinte. A janela das 19:00 às 19:10 tem quatro pedidos de Moema e a das
19:05 às 19:15 tem dois, e um deles, o `o-505` das 19:06:00, está nas duas. As somas estão certas
para a pergunta que respondem, "os últimos dez minutos, a cada marca de cinco minutos", e somá-las
entre janelas conta cada pedido duas vezes. As janelas também começam antes do primeiro pedido e
terminam depois do último: **18:55 às 19:05 existe porque 19:01:10 cai dentro dela**, e é por isso
que uma janela deslizante sempre volta no tempo o seu comprimento menos o seu período.

```
ana@laptop:~/gcp$ python3 windows.py sessions | sort
19:01:10-19:08:30  c-17       2 orders    55.80
19:02:05-19:07:05  c-02       1 order   128.00
19:04:20-19:09:20  c-05       1 order    23.50
19:04:50-19:09:50  c-44       1 order    31.00
19:06:00-19:14:10  c-31       2 orders    23.00
19:07:45-19:12:45  c-02       1 order    72.00
19:11:15-19:16:15  c-05       1 order    56.00
19:13:40-19:18:40  c-17       1 order    22.00
```

**As sessões aqui são por cliente, com intervalo de cinco minutos.** O `c-17` pediu às 19:01:10 e
às 19:03:30, a menos de cinco minutos, então os dois viraram uma sessão das 19:01:10 às 19:08:30: o
horário do último pedido mais o intervalo. O terceiro pedido, às 19:13:40, veio depois de mais de
cinco minutos de silêncio e abriu uma sessão própria. O `c-02` pediu às 19:02:05 e às 19:07:45, a 5
minutos e 40 segundos, e ficou com duas sessões; um intervalo de seis minutos teria feito uma só.
**O intervalo é a definição inteira**, e escolhê-lo é escolher o que é uma visita. Para a Quitanda,
um cliente que pede de novo em menos de cinco minutos em geral esqueceu alguma coisa, e contar os
dois como uma cesta é o que o depósito quer.

## Escolhendo uma

| se a pergunta é | a janela |
|---|---|
| um relatório por hora, por dia, a cada cinco minutos | fixa |
| um número móvel, atualizado com frequência: pedidos na última hora, a cada minuto | deslizante |
| o comportamento de um usuário ou de um aparelho, sem relógio natural | sessões |
| o fluxo inteiro, com resultados quando se quiser | a janela global com um gatilho, a quinta seção |

**Uma janela deslizante custa a sua sobreposição.** Cada elemento é posto em comprimento ÷ período
janelas: duas aqui, sessenta para "a última hora, a cada minuto". Cada cópia é estado que o runner
guarda até a janela fechar, e no Dataflow esse estado é parte do que o Streaming Engine cobra.
