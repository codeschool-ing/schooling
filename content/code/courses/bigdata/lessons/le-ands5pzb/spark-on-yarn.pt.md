---
title: Spark no YARN
version: 1
---

**O Spark roda no YARN sem cluster Spark nenhum**: os executores são contêineres YARN, pedidos pelo
driver como os de qualquer outra aplicação. Um job só precisa de `--master yarn` e de saber onde está a
configuração do cluster, em `HADOOP_CONF_DIR`. A contagem da aula 4, em Spark, lendo o mesmo arquivo do
HDFS. Salve como `~/big/kinds_yarn.py`:

```schooling-example
{
  "language": "python",
  "file": "kinds_yarn.py",
  "parts": [
    {
      "code": "\"\"\"Lesson 4's count of events by kind, as a Spark job submitted to YARN.\"\"\"\nfrom pyspark.sql import SparkSession\n\nspark = SparkSession.builder.appName(\"kinds on yarn\").getOrCreate()\n"
    },
    {
      "code": "SCHEMA = \"event_id LONG, ts TIMESTAMP, visitor_id STRING, kind STRING, book_id INT, device STRING\"\nclicks = spark.read.schema(SCHEMA).csv(\"hdfs:///raw/clicks-2025.csv\")\n",
      "note": "**O mesmo arquivo que o job de streaming leu**, do HDFS: o CSV único do ano da aula 3, sem linha de cabeçalho. A configuração do cluster diz onde está o HDFS, então o `hdfs:///` não precisa de host."
    },
    {
      "code": "for row in clicks.groupBy(\"kind\").count().orderBy(\"kind\").collect():\n    print(row.kind, row[\"count\"])\n",
      "note": "**No modo cluster este `print` não chega ao seu terminal**: o driver roda num contêiner do cluster, e o que ele imprime vai para o log desse contêiner."
    }
  ]
}
```

Submetido à fila dos analistas no *modo cluster*:

```
ana@lab:~/big$ time HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop spark-submit --master yarn --deploy-mode cluster --queue analysts --driver-memory 512m --executor-memory 512m --num-executors 1 --conf spark.driver.memoryOverhead=256m --conf spark.executor.memoryOverhead=256m kinds_yarn.py
WARNING: Using incubator modules: jdk.incubator.vector
05:07:54 WARN Client: Neither spark.yarn.jars nor spark.yarn.archive is set, falling back to uploading libraries under SPARK_HOME.

real	1m34.003s
user	0m14.427s
sys	0m3.351s
ana@lab:~/big$ yarn application -list -appStates FINISHED 2>/dev/null
Total number of applications (application-types: [], states: [FINISHED] and tags: []):2
                Application-Id	    Application-Name	    Application-Type	      User	     Queue	             State	       Final-State	       Progress	                       Tracking-URL
application_1792137929690_0002	       kinds_yarn.py	               SPARK	       ana	root.analysts	          FINISHED	         SUCCEEDED	           100%	                                N/A
application_1792137929690_0001	streamjob9869232074237175939.jar	           MAPREDUCE	       ana	root.nightly	          FINISHED	         SUCCEEDED	           100%	http://lab:19888/jobhistory/job/job_1792137929690_0001
ana@lab:~/big$ yarn logs -applicationId application_1792137929690_0002 -log_files stdout 2>/dev/null | grep -v '^$'
Container: container_1792137929690_0002_01_000001 on lab_38703
LogAggregationType: AGGREGATED
==============================================================
LogType:stdout
LogLastModifiedTime:Fri Oct 16 05:09:23 -0300 2026
LogLength:58
LogContents:
cart 1920654
purchase 959814
search 1920318
view 19199214
End of LogType:stdout
***********************************************************************
Container: container_1792137929690_0002_01_000002 on lab_38703
LogAggregationType: AGGREGATED
==============================================================
LogType:stdout
LogLastModifiedTime:Fri Oct 16 05:09:23 -0300 2026
LogLength:0
LogContents:
End of LogType:stdout
***********************************************************************
```

**No modo cluster o driver roda no cluster, dentro do contêiner do ApplicationMaster**, e a máquina que
submeteu o job pode se desconectar assim que ele é aceito. É assim que um job agendado deve rodar: um
laptop que fecha a tampa não mata a carga noturna. É também por isso que as contagens não apareceram:
o `print` escreveu na saída padrão do driver, que é um arquivo no log do contêiner, e o `yarn logs` o
busca no HDFS quando a aplicação termina. No *modo client*, o padrão, o driver roda onde o
`spark-submit` foi digitado e imprime ali, o que serve a um notebook e a nada que tenha de sobreviver a
um terminal. **O cluster standalone da aula 1 não consegue rodar um driver Python no modo cluster**; o
YARN e o Kubernetes conseguem.

Os parâmetros de memória estão lá por causa da fila. Os 30% dos analistas são cerca de 1,8 GB, e um
contêiner é a memória pedida mais um overhead para tudo o que fica fora do heap Java, de pelo menos
384 MB por padrão. Um driver e um executor de 512 MB cada, com 256 MB de overhead, cabem em dois
contêineres de 768 MB; com os padrões não teriam cabido, e a aplicação teria esperado por um espaço que
nunca viria.

**O aviso sobre `spark.yarn.jars` é o Spark mandando os seus próprios jars, cerca de 460 MB, para o
HDFS a cada aplicação**, para que os contêineres possam iniciar o Spark. Empacotá-los uma vez num
arquivo no HDFS e citá-lo em `spark.yarn.archive` economiza isso a cada submissão, e é a primeira coisa
que se faz num cluster em que o Spark roda no YARN.
