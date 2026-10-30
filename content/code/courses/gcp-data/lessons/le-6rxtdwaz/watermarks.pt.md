---
title: A marca d'água, e os pedidos que ela deixa para trás
version: 1
---

**Uma marca d'água é uma afirmação de uma fonte sobre o horário do evento: nada feito antes deste
momento ainda está a caminho.** Ela avança à medida que o fluxo avança, e é o que fecha uma janela.
Quando a marca d'água passa das 19:05, o runner conclui que a janela das 19:00 às 19:05 tem tudo o
que vai receber, calcula o agrupamento e o emite. Sem marca d'água uma janela de fluxo nunca
fecharia, pelo motivo que fez o `--window 0` da aula 21 se recusar a rodar: não haveria momento em
que esperar mais deixasse de valer a pena.

**A afirmação é um palpite, e essa é a parte que ninguém espera.** Uma fonte sabe o que recebeu, não
o que ainda está parado num celular dentro de um elevador. Toda fonte no Beam estima a marca d'água
de algum jeito, pelo timestamp mais antigo que ainda tem, pelo acúmulo, ou por uma folga fixa, e um
elemento cujo horário de evento já está atrás da marca d'água quando ele chega está **atrasado**. O
que acontece com dados atrasados é uma decisão sua no pipeline, e o padrão é o que surpreende.

## Um fluxo que você controla

O programa reproduz a noite pelo `arrivals` do `evening.py`. Os pedidos vêm na ordem em que
chegaram, o relógio de processamento é movido até cada chegada, e a marca d'água fica **um minuto
atrás da última chegada**: uma fonte que supõe que nada atrasa mais de um minuto. É a linha tracejada da
figura de duas seções atrás, e os três pedidos acima dela são os que esta marca d'água vai chamar de
atrasados. Salve como `~/gcp/late.py`:

```schooling-example
{"language": "python", "file": "late.py", "parts": [{"code": "\"\"\"late.py: the evening replayed as a stream, with a watermark and a trigger.\n\n    python3 late.py                       on time only; late orders are dropped\n    python3 late.py --lateness 300        late orders up to five minutes, each fires a pane\n    python3 late.py --lateness 300 --early --mode discarding\n\"\"\"\nimport argparse\n\nimport apache_beam as beam\nfrom apache_beam.options.pipeline_options import PipelineOptions, StandardOptions\nfrom apache_beam.transforms import trigger\nfrom apache_beam.transforms.window import FixedWindows\n\nfrom evening import arrivals, clock\n\n", "note": "**A docstring lista as três execuções que esta aula faz.** `trigger` é o módulo de gatilhos do Beam, e `arrivals` é o TestStream do `evening.py`."}, {"code": "ap = argparse.ArgumentParser()\nap.add_argument('--lateness', type=int, default=0)\nap.add_argument('--early', action='store_true')\nap.add_argument('--mode', choices=['accumulating', 'discarding'], default='accumulating')\nargs = ap.parse_args()\n\n", "note": "Três opções, cada uma um ajuste da janela: segundos de **atraso permitido**, se dispara **antes**, e o **modo de acumulação**. Sem nenhuma delas a janela se comporta como o padrão do Beam."}, {"code": "early = trigger.AfterProcessingTime(60) if args.early else None\nlate = trigger.AfterCount(1) if args.lateness else None\nmode = {'accumulating': trigger.AccumulationMode.ACCUMULATING,\n        'discarding': trigger.AccumulationMode.DISCARDING}[args.mode]\nTIMING = {0: 'EARLY', 1: 'ON_TIME', 2: 'LATE', 3: 'UNKNOWN'}\n\n\n", "note": "**O gatilho, montado a partir das opções.** `AfterWatermark` dispara quando a marca d'água passa o fim da janela; `early` acrescenta painéis antes disso, um minuto de tempo de processamento depois do primeiro elemento do painel, e `late` acrescenta um painel para cada elemento atrasado que ainda é aceito. `TIMING` dá nome aos códigos que o Beam dá a um painel."}, {"code": "class Show(beam.DoFn):\n    def process(self, total, window=beam.DoFn.WindowParam, pane=beam.DoFn.PaneInfoParam):\n        neighbourhood, cents = total\n        print(f'{clock(window.start)}-{clock(window.end)}  {neighbourhood:<10} {cents / 100:>7.2f}'\n              f'  {TIMING[pane.timing]:<8} pane {pane.index}')\n\n\n", "note": "`Show` imprime uma linha por painel: a janela, o bairro, a soma e **qual painel é**, o momento e o índice dele. Uma janela e chave que disparam três vezes imprimem três linhas."}, {"code": "options = PipelineOptions([], runner='BundleBasedDirectRunner')\noptions.view_as(StandardOptions).streaming = True\nwith beam.Pipeline(options=options) as p:\n    (p\n     | arrivals(lag=60)\n     | beam.WindowInto(FixedWindows(5 * 60),\n                       trigger=trigger.AfterWatermark(early=early, late=late),\n                       allowed_lateness=args.lateness,\n                       accumulation_mode=mode)\n     | beam.CombinePerKey(sum)\n     | beam.ParDo(Show()))\n", "note": "**Streaming, porque um TestStream é um fluxo** e o runner tem de tratá-lo como tal, com marca d'água e relógio. Depois o pipeline propriamente dito: a reprodução com atraso de um minuto, janelas fixas de cinco minutos com o gatilho e o atraso permitido, e uma soma por bairro."}]}
```

## O padrão: no horário, e mais nada

Sem opções, a janela tem o gatilho padrão e nenhum atraso permitido: dispara uma vez, quando a
marca d'água passa do fim dela, e o que chegar para ela depois é descartado.

```
ana@laptop:~/gcp$ python3 late.py
19:00:00-19:05:00  Moema        55.80  ON_TIME  pane 0
19:00:00-19:05:00  Pinheiros   128.00  ON_TIME  pane 0
19:05:00-19:10:00  Moema        15.00  ON_TIME  pane 0
19:05:00-19:10:00  Pinheiros    72.00  ON_TIME  pane 0
19:10:00-19:15:00  Moema        22.00  ON_TIME  pane 0
19:10:00-19:15:00  Pinheiros    56.00  ON_TIME  pane 0
```

**Seis painéis, todos `ON_TIME`, e três pedidos faltando.** Compare com o `by_time.py placed` da
seção sobre os dois relógios: a primeira janela de Moema diz 55,80 aqui e 86,80 lá, sem os 31,00 do
`o-507`. A primeira janela de Pinheiros diz 128,00 contra 151,50, sem o `o-504`, e a segunda diz
72,00 contra 80,00, sem o `o-510`. **Nada relatou a perda.** Nenhum erro, nenhum aviso, nenhuma
linha na saída, e o pipeline rodou até o fim com uma tabela de aparência correta. Um relatório
montado em cima dela mostraria a Quitanda com 62,50 reais a menos nesses quinze minutos, e ninguém
saberia quais pedidos.

Siga o `o-504` pela reprodução para ver por quê. Ele foi feito às 19:04:20 e chegou às 19:08:40. O
pedido antes dele, o `o-506`, chegou às 19:07:46 e moveu a marca d'água para 19:06:46, depois do fim
da janela das 19:00, às 19:05. **Então a janela das 19:00 já tinha disparado, com o que tinha, antes
de o `o-504` existir para o pipeline**, e sem atraso permitido o estado dela já tinha sumido. O
mesmo aconteceu com o `o-507`, cuja janela tinha fechado mais de seis minutos antes de ele chegar, e
com o `o-510`, feito às 19:09:10 e chegado às 19:14:00, depois de a marca d'água passar das 19:10.

```
ana@laptop:~/gcp$ python3 late.py
19:00:00-19:05:00  Moema        55.80  ON_TIME  pane 0
19:00:00-19:05:00  Pinheiros   128.00  ON_TIME  pane 0
19:05:00-19:10:00  Moema        15.00  ON_TIME  pane 0
19:05:00-19:10:00  Pinheiros    72.00  ON_TIME  pane 0
19:10:00-19:15:00  Moema        22.00  ON_TIME  pane 0
19:10:00-19:15:00  Pinheiros    56.00  ON_TIME  pane 0
```

**A mesma saída de novo, linha por linha.** É esse o ponto do TestStream: a ordem de chegada, o
relógio e a marca d'água estão todos no programa, então uma execução é um fato sobre o pipeline e
não sobre o laptop. Um pipeline lendo o Pub/Sub no DirectRunner não dá essa garantia, como a última
seção mostra.

## O que o atraso da marca d'água decide

O minuto de atraso é escolha desta reprodução, e é o botão entre duas falhas:

- **Uma marca d'água colada demais na última chegada** fecha as janelas depressa e chama mais dados
  de atrasados. Com atraso zero, a marca d'água fica na última chegada, e um pedido feito às
  19:04:59 que levou dois segundos no caminho está atrasado se outro pedido chegar às 19:05:00
  primeiro.
- **Uma marca d'água atrasada demais** mantém cada janela aberta por mais tempo, então os resultados
  saem mais tarde e o runner guarda mais estado. Com dez minutos de atraso, os dez pedidos desta
  noite estariam no horário, e a janela das 19:00 seria publicada por volta das 19:15.

Nenhum atraso faz o problema sumir, porque algum celular em algum lugar sempre vai ficar no elevador
por mais tempo do que qualquer atraso. A próxima seção é como um pipeline mantém a janela aberta
para os retardatários sem fazer todo mundo esperar por eles.
