---
title: HBase
version: 1
---

**O HBase responde à pergunta em que todo o resto deste curso é ruim: uma linha, agora.** O Spark e o
Hive leem arquivos inteiros para responder perguntas sobre muitas linhas. Buscar os últimos eventos de
um visitante, para um site enquanto o visitante espera, pede milissegundos e poucas linhas. O HBase é
o desenho do Bigtable do Google sobre o Hadoop: uma tabela de linhas ordenadas por uma *chave de
linha*, dividida em faixas chamadas *regiões*, cada uma servida por um *region server*, com tudo
guardado em arquivos do HDFS que são gravados uma vez e nunca alterados, a regra da aula 3.

**Ele contorna essa regra nunca editando um arquivo.** Uma gravação vai para um log e para a memória;
quando a memória enche, ela é gravada como um arquivo ordenado novo; e os arquivos são juntados em
segundo plano, uma *compactação*, que é o `OPTIMIZE` do Delta da aula 11 rodando sem parar. Uma
leitura confere a memória e os arquivos que podem ter a chave, usando o mesmo tipo de bloom filter da
aula 10.

O HBase é um download separado da Apache Software Foundation. No modo standalone o master, um region
server e o ZooKeeper de que ele precisa dividem um processo Java, e aqui ele guarda os seus arquivos no
HDFS da aula 3:

```sh
cd ~
curl -O https://downloads.apache.org/hbase/2.6.7/hbase-2.6.7-hadoop3-bin.tar.gz
curl -O https://downloads.apache.org/hbase/2.6.7/hbase-2.6.7-hadoop3-bin.tar.gz.sha512
sha512sum hbase-2.6.7-hadoop3-bin.tar.gz | cut -d' ' -f1
cut -d: -f2 hbase-2.6.7-hadoop3-bin.tar.gz.sha512 | tr -d ' \n' | tr A-F a-f; echo
tar -xzf hbase-2.6.7-hadoop3-bin.tar.gz
ln -s hbase-2.6.7-hadoop3 hbase
cat > ~/hbase/conf/hbase-site.xml <<'END'
<configuration>
  <property><name>hbase.rootdir</name><value>hdfs://localhost:9000/hbase</value></property>
  <property><name>hbase.zookeeper.property.dataDir</name><value>${user.home}/hbase-zk</value></property>
</configuration>
END
echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> ~/hbase/conf/hbase-env.sh
echo 'export HBASE_DISABLE_HADOOP_CLASSPATH_LOOKUP=true' >> ~/hbase/conf/hbase-env.sh
echo 'export PATH=~/hbase/bin:$PATH' >> ~/.sparkrc
. ~/.sparkrc
start-hbase.sh
cd ~/big
```

O arquivo de checksum é escrito num formato diferente do do Spark, então as duas linhas de checksum
imprimem o valor calculado e o publicado um embaixo do outro, para comparar. Eles têm de ser iguais:

```
ana@lab:~$ sha512sum hbase-2.6.7-hadoop3-bin.tar.gz | cut -d' ' -f1
2e0835a3ed8e5a9114f5d878deafb2f7a6b1c8386ba422d1a307fcc5551d452dc7da468729a43acf75dcfe0b20424cb48f72ed424dfd15f81b1b3624454ed82d
ana@lab:~$ cut -d: -f2 hbase-2.6.7-hadoop3-bin.tar.gz.sha512 | tr -d ' \n' | tr A-F a-f; echo
2e0835a3ed8e5a9114f5d878deafb2f7a6b1c8386ba422d1a307fcc5551d452dc7da468729a43acf75dcfe0b20424cb48f72ed424dfd15f81b1b3624454ed82d
ana@lab:~$ sha512sum hbase-2.6.7-hadoop3-bin.tar.gz | cut -d' ' -f1
2e0835a3ed8e5a9114f5d878deafb2f7a6b1c8386ba422d1a307fcc5551d452dc7da468729a43acf75dcfe0b20424cb48f72ed424dfd15f81b1b3624454ed82d
ana@lab:~$ cut -d: -f2 hbase-2.6.7-hadoop3-bin.tar.gz.sha512 | tr -d ' \n' | tr A-F a-f; echo
2e0835a3ed8e5a9114f5d878deafb2f7a6b1c8386ba422d1a307fcc5551d452dc7da468729a43acf75dcfe0b20424cb48f72ed424dfd15f81b1b3624454ed82d
```

A linha do `HBASE_DISABLE_HADOOP_CLASSPATH_LOOKUP` mantém o HBase na sua própria cópia das bibliotecas
do Hadoop em vez de misturar a instalada na aula 3.

**A chave de linha é o desenho.** Este programa grava os eventos de janeiro como linhas separadas por
tabulação com uma chave feita do visitante, do horário e do evento. Salve como `~/big/to_hbase.py`:

```schooling-example
{
  "language": "python",
  "file": "to_hbase.py",
  "parts": [
    {
      "code": "\"\"\"January's events as tab-separated lines, keyed for HBase: visitor, then time.\"\"\"\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"to hbase\").getOrCreate()\njanuary = spark.read.parquet(\"data/silver/clicks\").where(F.col(\"day\") < \"2025-02-01\")\n"
    },
    {
      "code": "key = F.concat_ws(\"|\", \"visitor_id\", F.date_format(\"ts\", \"yyyyMMddHHmmss\"),\n                  F.lpad(F.col(\"event_id\").cast(\"string\"), 8, \"0\"))\n(january.select(key.alias(\"row\"), \"kind\", F.coalesce(F.col(\"book_id\").cast(\"string\"), F.lit(\"\")),\n                \"device\")\n .write.mode(\"overwrite\").option(\"sep\", \"\\t\").csv(\"hdfs://localhost:9000/hbase-in/january\"))\n",
      "note": "**A chave de linha é todo o desenho de uma tabela HBase.** As linhas ficam ordenadas por ela, e as únicas perguntas rápidas são sobre uma chave ou um intervalo de chaves. Começar pelo visitante junta os eventos de cada visitante, o tempo depois dele os põe em ordem, e o id do evento no fim separa dois eventos no mesmo segundo."
    }
  ]
}
```

Depois crie uma tabela com uma família de colunas, `e`, e carregue as linhas com o job de importação
do próprio HBase:

```
ana@lab:~/big$ spark-submit to_hbase.py 2>/dev/null
ana@lab:~/big$ echo "create 'events', 'e'" | hbase shell -n 2>/dev/null; echo
hbase:001:0> create 'events', 'e'
Created table events
Took 1.3279 seconds
=> Hbase::Table - events
hbase:002:0> 

ana@lab:~/big$ time hbase org.apache.hadoop.hbase.mapreduce.ImportTsv -Dimporttsv.columns=HBASE_ROW_KEY,e:kind,e:book,e:device events hdfs://localhost:9000/hbase-in/january 2> import.log

real	1m6.624s
user	0m35.508s
sys	0m2.622s
ana@lab:~/big$ grep -E 'Map input records|Bad Lines' import.log | tail -2
		Map input records=2038357
		Bad Lines=0
```

E faça duas perguntas, escritas num arquivo para o shell do HBase rodar:

```sh
cat > look.rb <<'END'
scan 'events', {ROWPREFIXFILTER => 'v0936542|', LIMIT => 3}
count 'events', INTERVAL => 1000000
exit
END
```

```
ana@lab:~/big$ hbase shell -n look.rb 2>/dev/null
hbase:001:0> scan 'events', {ROWPREFIXFILTER => 'v0936542|', LIMIT => 3}
ROW  COLUMN+CELL
 v0936542|20250118142457|01157304 column=e:book, timestamp=2026-10-16T05:16:44.224, value=21
 v0936542|20250118142457|01157304 column=e:device, timestamp=2026-10-16T05:16:44.224, value=mobile
 v0936542|20250118142457|01157304 column=e:kind, timestamp=2026-10-16T05:16:44.224, value=view
 v0936542|20250118142458|01157305 column=e:book, timestamp=2026-10-16T05:16:44.224, value=285
 v0936542|20250118142458|01157305 column=e:device, timestamp=2026-10-16T05:16:44.224, value=mobile
 v0936542|20250118142458|01157305 column=e:kind, timestamp=2026-10-16T05:16:44.224, value=view
 v0936542|20250118142500|01157306 column=e:book, timestamp=2026-10-16T05:16:44.224, value=2182
 v0936542|20250118142500|01157306 column=e:device, timestamp=2026-10-16T05:16:44.224, value=desktop
 v0936542|20250118142500|01157306 column=e:kind, timestamp=2026-10-16T05:16:44.224, value=view
3 row(s)
Took 0.7674 seconds
hbase:002:0> count 'events', INTERVAL => 1000000
Current count: 1000000, row: v0936542|20250128030555|01783832
Current count: 2000000, row: v1961327|20250130171110|01953935
2038357 row(s)
Took 14.6208 seconds
=> 2038357
hbase:003:0> exit
```

**Os três primeiros eventos de um visitante voltaram em ordem de tempo em menos de um segundo**, porque são vizinhos
na tabela ordenada: a varredura foi direto à primeira chave que começa com `v0936542|` e parou na
terceira. Cada evento são três células, uma por coluna, cada uma com o momento em que foi gravada.
**Contar a tabela levou segundos**, porque uma contagem é uma varredura de todas as linhas, a pergunta
em que o HBase é pior e para a qual o Spark é feito. Essa assimetria é a escolha inteira: HBase para
servir chaves conhecidas a uma aplicação, um lake colunar para perguntas sobre tudo.

Uma chave de linha que começasse pelo tempo poria todo evento novo no fim da tabela, numa região de um
servidor, o *hotspot* que é o desbalanceamento da aula 8 num banco de dados. Chaves que começam por
algo espalhado, como um id de visitante ou um hash, são a regra.
