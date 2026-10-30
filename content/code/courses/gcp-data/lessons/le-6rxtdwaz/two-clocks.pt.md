---
title: Horário do evento e horário de processamento
version: 1
---

**Todo evento num fluxo tem dois horários, e uma janela precisa escolher um.** O **horário do
evento** é quando a coisa aconteceu: o momento em que o cliente apertou o botão. O **horário de
processamento** é quando o pipeline a viu, o que é depois, por poucos milissegundos quando a rede
se comporta e por minutos quando um celular está num elevador. A execução em fluxo da aula 21 cortou
janelas pelo horário de processamento, o horário de publicação que o Pub/Sub carimba numa mensagem,
e disse isso. Esta aula corta pelo horário do evento, que é o que uma pergunta como "quanto Moema
pediu entre 19:00 e 19:05" quer dizer.

A imagem errada é que os dois diferem por um atraso pequeno e constante, de modo que cortar pela
chegada erra por um ou dois segundos e nada pior. **O atraso não é constante.** A maioria dos
eventos chega na hora e alguns chegam minutos atrasados, e os atrasados não são uma amostra ao
acaso: vêm de celulares em redes ruins, ou seja, de lugares e momentos específicos.

## Uma noite, dez pedidos

Para ver a diferença, os dados precisam ser pequenos o bastante para conferir à mão, e a ordem de
chegada precisa estar sob o seu controle e não sob o da rede. Este módulo guarda dez pedidos de 15
de outubro com os dois horários anotados, e os programas desta aula o importam. Sete chegaram em até
dois segundos; três não. Salve como `~/gcp/evening.py`:

`evening.py`:

```python
"""evening.py: ten orders of one evening at Quitanda, as the riders' phones sent them.

Imported by the other programs of this lesson. Each order carries the time it
was placed, which is its event time, and the time it reached Pub/Sub, which is
when a pipeline could first see it.
"""
from datetime import datetime, timedelta, timezone

from apache_beam.testing.test_stream import TestStream
from apache_beam.transforms.window import TimestampedValue

SP = timezone(timedelta(hours=-3))

ORDERS = [
    # order    customer  neighbourhood  cents   placed      arrived
    ('o-501', 'c-17', 'Moema',      4590, '19:01:10', '19:01:12'),
    ('o-502', 'c-02', 'Pinheiros', 12800, '19:02:05', '19:02:06'),
    ('o-503', 'c-17', 'Moema',       990, '19:03:30', '19:03:31'),
    ('o-504', 'c-05', 'Pinheiros',  2350, '19:04:20', '19:08:40'),
    ('o-505', 'c-31', 'Moema',      1500, '19:06:00', '19:06:02'),
    ('o-506', 'c-02', 'Pinheiros',  7200, '19:07:45', '19:07:46'),
    ('o-507', 'c-44', 'Moema',      3100, '19:04:50', '19:12:30'),
    ('o-508', 'c-05', 'Pinheiros',  5600, '19:11:15', '19:11:16'),
    ('o-509', 'c-17', 'Moema',      2200, '19:13:40', '19:13:41'),
    ('o-510', 'c-31', 'Pinheiros',   800, '19:09:10', '19:14:00'),
]


def at(hhmmss):
    """Seconds since the epoch for a time on 15 October 2026, São Paulo."""
    h, m, s = map(int, hhmmss.split(':'))
    return datetime(2026, 10, 15, h, m, s, tzinfo=SP).timestamp()


def clock(timestamp):
    return datetime.fromtimestamp(float(timestamp), SP).strftime('%H:%M:%S')


def stamped(order, key, time):
    """One order as (key, cents), stamped with its 'placed' or 'arrived' time."""
    column = {'placed': 4, 'arrived': 5}[time]
    index = {'neighbourhood': 2, 'customer': 1}[key]
    return TimestampedValue((order[index], order[3]), at(order[column]))


def arrivals(lag=60):
    """The orders as a TestStream, replayed in the order they arrived.

    Before each order the processing-time clock moves to its arrival, and after
    it the watermark moves to `lag` seconds behind that arrival: the source's
    claim that nothing placed earlier is still on its way.
    """
    stream = TestStream().advance_watermark_to(at('19:00:00'))
    now = at('19:00:00')
    for o in sorted(ORDERS, key=lambda o: o[5]):
        stream = stream.advance_processing_time(at(o[5]) - now)
        now = at(o[5])
        stream = stream.add_elements([TimestampedValue((o[2], o[3]), at(o[4]))])
        stream = stream.advance_watermark_to(now - lag)
    return stream.advance_processing_time(60).advance_watermark_to_infinity()
```

**`stamped` e `arrivals` são as duas formas como a aula entrega esses pedidos ao Beam.** `stamped`
transforma um pedido num elemento cujo timestamp é um dos dois horários, para um pipeline em lote
que lê todos de uma vez. `arrivals` monta um **TestStream**, a ferramenta do Beam para testar
pipelines de streaming: uma fonte que emite os elementos na ordem que você der, move o relógio de
processamento quando você mandar e move a marca d'água (watermark) quando você mandar. A quarta
seção explica a marca d'água; por enquanto ela é a linha `advance_watermark_to(now - lag)`. Nada num
TestStream depende da velocidade do laptop, então toda execução dá a mesma saída, coisa que um fluxo
vindo do Pub/Sub nunca promete.

## Os mesmos pedidos, em janelas de cada relógio

Um pipeline em lote que carimba cada pedido com um dos dois horários, corta a noite em janelas de
cinco minutos e soma os pedidos de cada bairro em cada uma. Salve como `~/gcp/by_time.py`:

`by_time.py`:

```python
"""by_time.py: the evening's orders in five-minute windows, by one of two clocks.

    python3 by_time.py placed       windows of event time
    python3 by_time.py arrived      windows of processing time
"""
import sys

import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions
from apache_beam.transforms.window import FixedWindows

from evening import ORDERS, clock, stamped


class Show(beam.DoFn):
    def process(self, total, window=beam.DoFn.WindowParam):
        neighbourhood, cents = total
        print(f'{clock(window.start)}-{clock(window.end)}  {neighbourhood:<10} {cents / 100:>7.2f}')


options = PipelineOptions([], runner='BundleBasedDirectRunner')
with beam.Pipeline(options=options) as p:
    (p
     | beam.Create(ORDERS)
     | beam.Map(stamped, 'neighbourhood', sys.argv[1])
     | beam.WindowInto(FixedWindows(5 * 60))
     | beam.CombinePerKey(sum)
     | beam.ParDo(Show()))
```

`beam.Map(stamped, 'neighbourhood', sys.argv[1])` passa os dois argumentos a mais para `stamped` a
cada pedido. A janela é escolhida pelo timestamp do elemento, então a única diferença entre as duas
execuções é qual horário é esse:

```
ana@laptop:~/gcp$ python3 by_time.py placed | sort
19:00:00-19:05:00  Moema        86.80
19:00:00-19:05:00  Pinheiros   151.50
19:05:00-19:10:00  Moema        15.00
19:05:00-19:10:00  Pinheiros    80.00
19:10:00-19:15:00  Moema        22.00
19:10:00-19:15:00  Pinheiros    56.00
ana@laptop:~/gcp$ python3 by_time.py arrived | sort
19:00:00-19:05:00  Moema        55.80
19:00:00-19:05:00  Pinheiros   128.00
19:05:00-19:10:00  Moema        15.00
19:05:00-19:10:00  Pinheiros    95.50
19:10:00-19:15:00  Moema        53.00
19:10:00-19:15:00  Pinheiros    64.00
```

**Os totais da noite são os mesmos; as janelas em que caem, não.** Pelo horário em que cada pedido
foi feito, Pinheiros pediu 151,50 reais entre 19:00 e 19:05; pelo horário em que cada um chegou,
128,00. Os 23,50 do `o-504`, feito às 19:04:20 e chegado às 19:08:40, foram para a janela seguinte,
onde Pinheiros mostra 95,50 em vez de 80,00. O `o-507` e o `o-510` mudaram do mesmo jeito, e a
última janela de Moema tem 53,00 pela chegada contra 22,00 pelo pedido. **As duas execuções somaram
cada pedido uma vez**; o que mudou é a pergunta que cada uma respondeu. A primeira responde "quanto
foi pedido nesses cinco minutos", que é a pergunta. A segunda responde "quanto chegou até nós nesses
cinco minutos", que é um fato sobre a rede.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"Um gráfico dos dez pedidos da noite, o horário em que cada um foi feito na horizontal e o horário em que chegou na vertical, das 19:00 às 19:15 nos dois eixos. Sete pedidos ficam na diagonal: chegaram até dois segundos depois de feitos. Três ficam bem acima dela: o-504, feito às 19:04:20 e chegado às 19:08:40; o-507, feito às 19:04:50 e chegado às 19:12:30; o-510, feito às 19:09:10 e chegado às 19:14:00. Uma linha tracejada um minuto acima da diagonal é a marca d'água; os três atrasados ficam acima dela, o que quer dizer que a marca d'água já tinha passado o horário em que foram feitos quando eles chegaram. Linhas verticais marcam as janelas de cinco minutos nas 19:05 e 19:10.\" data-fig=\"gcp22-clocks\"><line x1=\"90.0\" y1=\"40\" x2=\"90.0\" y2=\"300\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></line><text x=\"90.0\" y=\"314\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">19:00</text><text x=\"82\" y=\"300.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">19:00</text><line x1=\"270.0\" y1=\"40\" x2=\"270.0\" y2=\"300\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></line><text x=\"270.0\" y=\"314\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">19:05</text><text x=\"82\" y=\"213.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">19:05</text><line x1=\"450.0\" y1=\"40\" x2=\"450.0\" y2=\"300\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></line><text x=\"450.0\" y=\"314\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">19:10</text><text x=\"82\" y=\"126.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">19:10</text><line x1=\"630.0\" y1=\"40\" x2=\"630.0\" y2=\"300\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></line><text x=\"630.0\" y=\"314\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">19:15</text><text x=\"82\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">19:15</text><line x1=\"90\" y1=\"300\" x2=\"630\" y2=\"300\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"90\" y1=\"300\" x2=\"90\" y2=\"40\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"360\" y=\"330\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">feito: horário do evento</text><text x=\"30\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">chegou: horário de processamento</text><line x1=\"90.0\" y1=\"282.7\" x2=\"594.0\" y2=\"40.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" stroke-dasharray=\"5 3\"></line><text x=\"625\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">marca d'água, um minuto atrás da última chegada</text><circle cx=\"132.0\" cy=\"279.2\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"165.0\" cy=\"263.6\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"216.0\" cy=\"239.0\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"246.0\" cy=\"149.8\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"254.0\" y=\"149.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">o-504</text><circle cx=\"306.0\" cy=\"195.4\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"369.0\" cy=\"165.4\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"264.0\" cy=\"83.3\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"272.0\" y=\"83.3\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">o-507</text><circle cx=\"495.0\" cy=\"104.7\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"582.0\" cy=\"62.8\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"420.0\" cy=\"57.3\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"428.0\" y=\"57.3\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">o-510</text><text x=\"102\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">atrasados: feitos antes do ponto que a marca d'água já tinha passado</text></svg>", "caption": "Os mesmos dez pedidos em dois relógios. Uma janela é uma faixa entre duas linhas verticais; um ponto acima da marca d'água tracejada chegou ao pipeline depois de o pipeline ter deixado de esperar por ele."}
```

**Um lote sobre um arquivo não tem dificuldade aqui**, porque tem todos os pedidos antes de começar:
pode esperar o `o-507` porque o `o-507` já está no arquivo. Um fluxo não sabe se um pedido feito às
19:04 ainda está a caminho, e em algum momento tem de publicar a janela das 19:00 assim mesmo. O
ponto em que ele decide é a marca d'água, duas seções adiante.
