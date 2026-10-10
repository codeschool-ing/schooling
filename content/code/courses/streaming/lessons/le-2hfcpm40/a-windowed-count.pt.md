---
title: Uma contagem por janela, em três modos de saída
version: 1
---

A contagem que as lições 10 e 11 montaram à mão, vendas por janela de cinco minutos de tempo do
evento com um watermark, são poucas linhas de Spark. **O que pede reflexão não é a consulta, é o
modo de saída**: depois de cada batch, quais linhas da tabela de resultado partem para o sink. São
três, e as mesmas duzentas vendas saem de cada um de um jeito.

O resto da lição roda um único programa com argumentos diferentes em vez de editá-lo. Salve-o como
`~/work/spark_sales.py`:

```schooling-example
{
  "language": "python",
  "file": "spark_sales.py",
  "parts": [
    {
      "code": "\"\"\"spark_sales.py: Ponto Final's sales per five-minute window, counted by Spark.\n\n    python spark_sales.py [--mode M] [--trigger T] [--sink S] [--checkpoint DIR]\n\n--mode is update, append or complete. --trigger is available-now, a number\nof seconds, or continuous. --sink is console, kafka or files.\n\"\"\"\nimport argparse\nimport os\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nargs = argparse.ArgumentParser()\nargs.add_argument(\"--mode\", default=\"update\")\nargs.add_argument(\"--trigger\", default=\"available-now\")\nargs.add_argument(\"--sink\", default=\"console\")\nargs.add_argument(\"--checkpoint\", default=\"~/spark/ckpt/sales\")\nargs = args.parse_args()\n",
      "note": "O que ele conta, e os quatro argumentos que o resto da lição muda."
    },
    {
      "code": "spark = (SparkSession.builder.appName(\"spark-sales\").master(\"local[2]\")\n         .config(\"spark.jars.packages\", \"org.apache.spark:spark-sql-kafka-0-10_2.13:4.1.3\")\n         .config(\"spark.sql.session.timeZone\", \"America/Sao_Paulo\")\n         .config(\"spark.sql.shuffle.partitions\", \"2\")\n         .config(\"spark.ui.showConsoleProgress\", \"false\")\n         .getOrCreate())\nspark.sparkContext.setLogLevel(\"ERROR\")\n",
      "note": "A sessão da seção anterior, com uma linha a mais. **`spark.sql.shuffle.partitions` é em quantos pedaços um agrupamento é dividido**, e o padrão de 200 quer dizer 200 tarefas pequenas e 200 pedaços de estado por batch, o que numa máquina só é puro custo."
    },
    {
      "code": "SALE = \"sale STRING, shop STRING, book STRING, qty INT, cents BIGINT, at TIMESTAMP\"\nsales = (spark.readStream.format(\"kafka\")\n         .option(\"kafka.bootstrap.servers\", \"localhost:9092\")\n         .option(\"subscribe\", \"sales\")\n         .option(\"startingOffsets\", \"earliest\")\n         .option(\"maxOffsetsPerTrigger\", 50)\n         .load()\n         .select(F.from_json(F.col(\"value\").cast(\"string\"), SALE).alias(\"s\"))\n         .select(\"s.*\"))\n",
      "note": "O valor é interpretado como JSON com um esquema escrito em tipos SQL, e `at` vira um timestamp. **`maxOffsetsPerTrigger` limita cada batch a 50 registros**, para que as duzentas vendas que já estão no tópico cheguem em quatro batches e você veja a contagem andar, em vez de ver tudo de uma vez."
    },
    {
      "code": "per_window = (sales.withWatermark(\"at\", \"2 minutes\")\n              .groupBy(F.window(\"at\", \"5 minutes\"))\n              .agg(F.count(\"*\").alias(\"sales\"), F.sum(\"cents\").alias(\"cents\"))\n              .select(F.date_format(\"window.start\", \"HH:mm\").alias(\"start\"),\n                      F.date_format(\"window.end\", \"HH:mm\").alias(\"end\"), \"sales\", \"cents\"))\n",
      "note": "A consulta em si. **`withWatermark` diz que uma venda mais de dois minutos mais velha que a mais recente já vista pode ser ignorada**, e é isso que deixa o Spark fechar uma janela e esquecê-la. Depois, uma janela fixa de cinco minutos sobre `at`, uma contagem, uma soma, e o início e o fim da janela impressos como horas da loja."
    },
    {
      "code": "if args.sink == \"kafka\":\n    per_window = per_window.select(F.col(\"start\").alias(\"key\"),\n                                   F.to_json(F.struct(\"*\")).alias(\"value\"))\nout = (per_window.writeStream.outputMode(args.mode)\n       .option(\"checkpointLocation\", os.path.expanduser(args.checkpoint)))\nif args.sink == \"kafka\":\n    out = (out.format(\"kafka\").option(\"kafka.bootstrap.servers\", \"localhost:9092\")\n           .option(\"topic\", \"sales-per-window\"))\nelif args.sink == \"files\":\n    out = out.format(\"json\").option(\"path\", os.path.expanduser(\"~/spark/out\"))\nelse:\n    out = out.format(\"console\")\n",
      "note": "Para onde vão as linhas. Todo sink recebe o modo de saída e um diretório de checkpoint; a seção 06 abre o diretório, e a seção 08 trata dos sinks de Kafka e de arquivos, que precisam das linhas num formato próprio."
    },
    {
      "code": "if args.trigger == \"available-now\":\n    out = out.trigger(availableNow=True)\nelif args.trigger == \"continuous\":\n    out = out.trigger(continuous=\"1 second\")\nelse:\n    out = out.trigger(processingTime=f\"{args.trigger} seconds\")\nout.start().awaitTermination()",
      "note": "Quando os batches rodam, que é a seção 07. Nada aconteceu até o `start`, que dispara a consulta em segundo plano e retorna; `awaitTermination` mantém o programa vivo até a consulta terminar."
    }
  ]
}
```

Cada execução abaixo ganha um diretório de checkpoint próprio. Um checkpoint pertence a uma
consulta, e a seção 06 mostra o que acontece quando uma consulta encontra um antigo.

## Update: as linhas que mudaram

```
ubuntu@stream:~/work$ python spark_sales.py --mode update --checkpoint ~/spark/ckpt/update 2>spark.log
```

**O modo update imprime, depois de cada batch, só as janelas que aquele batch alterou**, com os
totais até ali. A janela de 09:05 mostra 18 vendas depois do batch 0 e 28 depois do batch 1: a
mesma janela duas vezes, e quem lê a jusante precisa substituir a primeira linha pela segunda, não
somar as duas.

O batch 0 traz uma surpresa: uma janela de 09:10 com uma venda, antes de a de 09:05 estar
terminada. O Spark pegou os seus 50 registros das duas partições com dados, em proporção ao que
cada uma tinha, e a partição 0 guarda só as vendas de Caruaru, que são mais esparsas. **Dez
registros da partição 0 chegam mais longe na manhã que quarenta da partição 1**, então um mesmo
batch viu uma venda das 09:10 junto com vendas das 09:08. O tempo do evento entre partições nunca
vem em ordem, e é a lição 9 chegando a um motor de verdade.

O batch 5 não leu nada e imprimiu uma tabela vazia. O Spark o rodou mesmo assim porque o watermark
tinha andado no fim do batch 4, e um batch sem dados é o jeito que ele tem de agir sobre isso.

## Complete: a tabela inteira, toda vez

```
ubuntu@stream:~/work$ python spark_sales.py --mode complete --checkpoint ~/spark/ckpt/complete 2>spark.log
```

**O modo complete imprime o resultado inteiro depois de cada batch**, sem ordem definida. É o mais
fácil de consumir, porque a última saída é sempre a resposta toda, e o mais caro: o Spark precisa
guardar toda janela para sempre, então o watermark não é usado para descartar nada. Num stream que
nunca acaba, esse estado nunca para de crescer, e por isso o modo complete só faz sentido para um
resultado que fica pequeno, como um total por loja.

## Append: só o que é final

```
ubuntu@stream:~/work$ python spark_sales.py --mode append --checkpoint ~/spark/ckpt/append 2>spark.log
```

**O modo append imprime uma janela uma única vez, quando o watermark diz que ela não pode mais
mudar**, e nunca mais. O batch 0 não imprimiu nada: o watermark começa em zero, então nenhuma janela
é final ainda. No fim do batch 0 a venda mais recente vista era das 09:10:12, então o watermark do
batch 1 virou 09:08:12, depois do fim da janela de 09:00, e o batch 1 a imprimiu, com a contagem
final de 30.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"O modo append sobre as duzentas vendas. Oito janelas de cinco minutos, de 09:00 a 09:40, ao longo de um eixo de tempo. Abaixo delas, o watermark que o Spark usou em cada batch: zero no batch 0, depois 09:08:12, 09:15:49, 09:24:24, 09:34:33 e 09:34:41. Cada janela é impressa no primeiro batch cujo watermark passou do fim dela: 09:00 no batch 1, 09:05 e 09:10 no batch 2, 09:15 no batch 3, 09:20 e 09:25 no batch 4. As janelas de 09:30 e 09:35 nunca são impressas, porque o watermark para em 09:34:41.\" data-fig=\"l12-append\"><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">janelas</text><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">watermark</text><rect x=\"111.0\" y=\"55\" width=\"68\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"145.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">09:00</text><text x=\"145.0\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">batch 1</text><rect x=\"181.0\" y=\"55\" width=\"68\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"215.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">09:05</text><text x=\"215.0\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">batch 2</text><rect x=\"251.0\" y=\"55\" width=\"68\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">09:10</text><text x=\"285.0\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">batch 2</text><rect x=\"321.0\" y=\"55\" width=\"68\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"355.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">09:15</text><text x=\"355.0\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">batch 3</text><rect x=\"391.0\" y=\"55\" width=\"68\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"425.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">09:20</text><text x=\"425.0\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">batch 4</text><rect x=\"461.0\" y=\"55\" width=\"68\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"495.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">09:25</text><text x=\"495.0\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">batch 4</text><rect x=\"531.0\" y=\"55\" width=\"68\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"565.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">09:30</text><rect x=\"601.0\" y=\"55\" width=\"68\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"635.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">09:35</text><text x=\"558.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">nunca impressas</text><text x=\"20\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">impressa no</text><line x1=\"110.0\" y1=\"140\" x2=\"670.0\" y2=\"140\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"224.79999999999998\" y1=\"128\" x2=\"224.79999999999998\" y2=\"152\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><text x=\"224.79999999999998\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">batch 1</text><text x=\"224.79999999999998\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">09:08:12</text><line x1=\"331.43333333333334\" y1=\"128\" x2=\"331.43333333333334\" y2=\"152\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><text x=\"331.43333333333334\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">batch 2</text><text x=\"331.43333333333334\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">09:15:49</text><line x1=\"451.59999999999997\" y1=\"128\" x2=\"451.59999999999997\" y2=\"152\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><text x=\"451.59999999999997\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">batch 3</text><text x=\"451.59999999999997\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">09:24:24</text><line x1=\"593.6999999999999\" y1=\"128\" x2=\"593.6999999999999\" y2=\"152\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><text x=\"593.6999999999999\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">batch 4</text><text x=\"593.6999999999999\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">09:34:33</text><line x1=\"595.5666666666666\" y1=\"128\" x2=\"595.5666666666666\" y2=\"152\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></line><text x=\"591.5666666666666\" y=\"200\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">batch 5</text><text x=\"591.5666666666666\" y=\"214\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">09:34:41</text><circle cx=\"623.5666666666666\" cy=\"140\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"629.5666666666666\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">última venda 09:36:41</text><line x1=\"623.5666666666666\" y1=\"146\" x2=\"623.5666666666666\" y2=\"222\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\" stroke-dasharray=\"2 2\"></line></svg>", "caption": "Uma janela sai no modo append quando o watermark passa do fim dela; as duas últimas esperam uma venda que nunca chega.", "same": ["watermark", "batch 1", "batch 2", "batch 3", "batch 4", "batch 5"]}
```

Conte as janelas: seis foram impressas, e os dados têm oito. **As janelas de 09:30 e 09:35 nunca
foram impressas**, e não se perderam. A última venda é das 09:36:41, então o watermark parou em
09:34:41, e a janela de 09:30 termina às 09:35. As duas continuam no estado do Spark, esperando uma
venda tardia o bastante para empurrar o watermark para além delas. Numa loja essa venda chega
segundos depois; num tópico que parou de receber vendas, ela nunca chega.

| modo | depois de cada batch | estado guardado | precisa de watermark |
|---|---|---|---|
| update | as janelas que mudaram, totais até ali | até o watermark passar | para esquecer janelas |
| complete | todas as janelas | tudo, para sempre | não |
| append | janelas finais, uma vez cada | até o watermark passar | sim |

Qual usar é decidido pelo sink e por quem o lê. Uma tabela que pode ser atualizada no lugar, ou um
tópico do Kafka compactado com a janela como chave, aceita o modo update. Um arquivo, ou qualquer
coisa à qual só se pode acrescentar, pede o modo append, ao preço do atraso do watermark. A seção
08 testa os dois.
