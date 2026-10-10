---
title: Lendo o tópico de vendas
version: 1
---

Antes de contar qualquer coisa, veja o que o Spark recebe quando lê um tópico do Kafka. **Não são
as suas vendas: são os registros do Kafka, com a venda dentro de uma coluna, em bytes crus**, e o
primeiro trabalho de toda consulta de streaming sobre o Kafka é tirá-las de lá.

Comece com um tópico limpo e duzentas vendas. Se o tópico `sales` das lições anteriores ainda
existir, `./cluster.sh stop`, `./cluster.sh new 1` e `./cluster.sh start` dão antes um cluster
vazio, para que os seus números batam com os daqui:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 3
```

`--rate 0` manda as vendas o mais rápido que o Kafka aceita, porque desta vez ninguém está olhando
elas chegarem. O relógio do caixa continua avançando de um a vinte segundos entre vendas, então as
duzentas cobrem pouco mais de meia hora de loja, das 09:00 às 09:36:41:

```
ubuntu@stream:~/work$ python tills.py --count 200 --rate 0
```

## A menor consulta

Salve isto como `~/work/spark_raw.py`:

```schooling-example
{
  "language": "python",
  "file": "spark_raw.py",
  "parts": [
    {
      "code": "\"\"\"spark_raw.py: the sales topic as Spark sees it, before any parsing.\"\"\"\nimport sys\n\nfrom pyspark.sql import SparkSession\n",
      "note": "Para que serve, numa linha."
    },
    {
      "code": "spark = (SparkSession.builder.appName(\"spark-raw\").master(\"local[2]\")\n         .config(\"spark.jars.packages\", \"org.apache.spark:spark-sql-kafka-0-10_2.13:4.1.3\")\n         .config(\"spark.sql.session.timeZone\", \"America/Sao_Paulo\")\n         .config(\"spark.ui.showConsoleProgress\", \"false\")\n         .getOrCreate())\nspark.sparkContext.setLogLevel(\"ERROR\")\n",
      "note": "**Um programa Spark começa pedindo uma sessão**, e esta é um Spark inteiro dentro do seu processo Python: `local[2]` quer dizer duas threads de trabalho nesta máquina e nenhum cluster. A primeira linha `config` é o conector do Kafka da seção anterior. O fuso horário é definido para o Spark imprimir as horas como os relógios das lojas marcam, qualquer que seja o fuso da sua máquina."
    },
    {
      "code": "raw = (spark.readStream.format(\"kafka\")\n       .option(\"kafka.bootstrap.servers\", \"localhost:9092\")\n       .option(\"subscribe\", \"sales\")\n       .option(\"startingOffsets\", \"earliest\")\n       .load())\nraw.printSchema()\nsys.stdout.flush()\n",
      "note": "`readStream` no lugar de `read` é toda a diferença entre um stream e uma tabela aqui. **`startingOffsets` diz por onde começar na primeira vez que esta consulta roda**, e `earliest` quer dizer a venda mais antiga que o tópico ainda guarda. O esquema é impresso e descarregado na hora, para chegar à tela antes de qualquer coisa que o próprio Spark imprima."
    },
    {
      "code": "query = (raw.withColumn(\"value\", raw.value.cast(\"string\"))\n         .select(\"key\", \"value\", \"partition\", \"offset\", \"timestamp\")\n         .writeStream.format(\"console\").trigger(availableNow=True).start())\nquery.awaitTermination()",
      "note": "O valor é convertido de bytes para texto, cinco colunas ficam, e o resultado vai para o console. `availableNow` faz a consulta ler o que está no tópico agora e então parar, o que a seção 07 explica."
    }
  ]
}
```

O Spark escreve muita coisa sobre si mesmo na saída de erro: as bibliotecas que carrega, os avisos
das bibliotecas Java por baixo dele e, na primeira execução, o relatório inteiro do download do
conector. **Mande tudo isso para um arquivo com `2>spark.log`**, para que o que chega à sua tela
seja o que a consulta imprimiu, e leia o arquivo quando algo der errado:

```
ubuntu@stream:~/work$ python spark_raw.py 2>spark.log
```

Levou uns quinze segundos aqui, a maior parte para subir o Java, e a primeira execução demora mais
pelo tempo do download.

## O que saiu

Primeiro veio o esquema, depois um batch. **O esquema tem as mesmas sete colunas para qualquer
tópico do Kafka**, seja o que for que ele guarde:

| coluna | o que guarda |
|---|---|
| `key`, `value` | a chave e o valor do registro, em bytes; o Spark não sabe que são texto |
| `topic`, `partition`, `offset` | onde o registro está, que é também o que o Spark lembra como sua posição |
| `timestamp`, `timestampType` | o timestamp do registro no Kafka, e se quem o definiu foi o produtor ou o broker |

A coluna `key` mostra o problema que a conversão resolve para o valor: `[6E 61 74 61 6C]` é `natal`
em bytes. A coluna `timestamp` é a outra armadilha, e é o assunto da lição 9: é o momento em que o
`tills.py` entregou o registro ao Kafka, hoje, enquanto o momento da venda é o `at`, dentro do
JSON, em 2 de março de 2026. **Uma janela sobre `timestamp` contaria as vendas pela hora em que
foram enviadas.** A próxima seção tira o `at` de dentro do valor e conta por ele.

Só vinte linhas foram impressas, todas da partição 1, porque o console mostra vinte por padrão. A
partição 1 guarda a maior parte das vendas: as chaves de quatro das cinco lojas caem nela e só
`caruaru` cai na partição 0, o que a lição 3 explica. Isso vai importar na próxima seção.

O download do conector foi parar no seu diretório pessoal:

```
ubuntu@stream:~/work$ ls ~/.ivy2.5.2/jars
```

Onze arquivos: o conector, o cliente Java do próprio Kafka, que ele usa para falar com o broker, e
as bibliotecas de que os dois precisam. Nada ali é um grupo de consumidores, e a seção 06 diz por
que o Spark não precisa de um.
