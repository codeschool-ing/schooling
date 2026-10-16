---
title: Spark Connect
version: 1
---

**Todo programa deste curso foi um driver**: o `spark-submit` iniciava um processo Java ao lado do
Python, e os DataFrames do programa viviam nele. O *Spark Connect* divide isso em dois. Um servidor
roda o driver, perto do cluster; um cliente fino, em qualquer lugar, manda planos a ele por gRPC e
recebe linhas de volta. O cliente não precisa de Java, nem dos jars do Spark, nem de rota até os
executores.

O servidor vem com o Spark. Inicie-o no cluster standalone:

```sh
start-connect-server.sh
```

O cliente é um pacote Python à parte, o `pyspark-client`, que traz pandas, PyArrow e gRPC e nada da
JVM. Num ambiente só dele:

```sh
python3 -m venv ~/connect-env
~/connect-env/bin/pip install pyspark-client==4.1.3
```

Salve como `~/big/connect_client.py`:

```schooling-example
{
  "language": "python",
  "file": "connect_client.py",
  "parts": [
    {
      "code": "\"\"\"A Spark client with no Spark in it: the DataFrame API over a network connection.\"\"\"\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\n"
    },
    {
      "code": "spark = SparkSession.builder.remote(\"sc://localhost:15002\").getOrCreate()\nprint(\"server runs Spark\", spark.version)\n\n",
      "note": "**`remote` em vez de um master**: a sessão é uma conexão com um servidor Spark Connect, que roda o driver. Este processo não inicia Java nenhum e não segura recursos do cluster."
    },
    {
      "code": "clicks = spark.read.parquet(\"data/silver/clicks\")\nfor row in clicks.groupBy(\"kind\").count().orderBy(\"kind\").collect():\n    print(row.kind, row[\"count\"])\n\n",
      "note": "**O mesmo código de DataFrame da aula 5.** O cliente manda o plano, sem resolver, ao servidor; o servidor o analisa, roda no seu cluster e devolve as linhas em lotes Arrow. O caminho é do servidor, relativo ao diretório em que ele foi iniciado."
    },
    {
      "code": "try:\n    clicks.select(\"no_such_column\").collect()\nexcept Exception as e:\n    print(type(e).__name__ + \":\", str(e).splitlines()[0][:100])\n",
      "note": "**Um erro volta como exceção no cliente**, levantada pela análise do servidor, antes de qualquer coisa rodar."
    }
  ]
}
```

Rode com o Python do ambiente, não com o `spark-submit`, e com o log de erros do próprio cliente
mandado embora, já que o programa falha de propósito no fim:

```
ana@lab:~/big$ ~/connect-env/bin/python connect_client.py 2>/dev/null
server runs Spark 4.1.3
cart 1920654
purchase 959814
search 1920318
view 19199214
AnalysisException: [UNRESOLVED_COLUMN.WITH_SUGGESTION] A column, variable, or function parameter with name `no_such_col
```

**As mesmas contagens da aula 4, de um processo que nunca iniciou Java.** O plano viajou até o
servidor, que o rodou no cluster como o de qualquer outra aplicação, e as quatro linhas voltaram. O
erro proposital voltou como a mesma `AnalysisException` que uma sessão local levanta, do analisador do
servidor, antes de qualquer coisa rodar.

**É para isso que serviços gerenciados e notebooks migraram**, e isso muda três coisas. Uma queda do
cliente, ou um laptop que fecha, não mata mais um driver que segura os executores do cluster. O
cliente e o servidor podem ser atualizados separadamente, dentro de uma faixa de versões. E vários
usuários podem dividir um servidor, com as sessões separadas, do jeito que dividiriam um banco de
dados. O que não muda é nada de como o job roda: o plano, o shuffle e a memória são do servidor,
exatamente como antes.

Pare o servidor ao terminar:

```sh
stop-connect-server.sh
```
