---
title: Deixando o driver sem memória
version: 1
---

**Executores despejam em disco; o driver não.** Tudo o que um programa traz de volta ao driver, com
`collect`, `toPandas` ou um `show` de muitas linhas, precisa caber na memória do driver de uma vez, e
não há disco para recorrer. O jeito mais comum de matar um programa Spark é pedir o resultado inteiro
numa variável. Salve como `~/big/collect_all.py`:

```schooling-example
{
  "language": "python",
  "file": "collect_all.py",
  "parts": [
    {
      "code": "\"\"\"Bring every event to the driver.\"\"\"\nfrom pyspark.sql import SparkSession\n\nspark = SparkSession.builder.appName(\"collect all\").getOrCreate()\n"
    },
    {
      "code": "rows = spark.read.parquet(\"data/silver/clicks\").collect()\nprint(len(rows), \"rows\")\n",
      "note": "**O `collect` manda cada linha do resultado ao driver**, que precisa segurar todas de uma vez."
    }
  ]
}
```

O Spark tem uma proteção para isso, o `spark.driver.maxResultSize`, o máximo que os resultados das
tarefas podem somar, 1 GB por padrão. Rode com a proteção baixada para 100 MB, para que dispare
rápido e de forma limpa, e com o `grep` guardando a primeira linha de erro de um longo stack trace:

```
ana@lab:~/big$ spark-submit --conf spark.driver.maxResultSize=100m collect_all.py 2>&1 | grep -m 1 ERROR
01:13:24 ERROR TaskSetManager: Total size of serialized results of 3 tasks (128.2 MiB) is bigger than spark.driver.maxResultSize (100.0 MiB)
```

**Os resultados de três tarefas já tinham chegado a 128,2 MiB quando o job foi parado**, de 15, então
todos somariam uns 640 MiB de linhas serializadas, mais em objetos Python depois de desempacotados,
para um driver cuja parte do Spark é 434 MiB. A proteção transformou uma queda numa mensagem de erro.
Sem ela, ou com ela acima do que o driver aguenta, o driver fica sem memória e a aplicação inteira
morre, que é a única falha irrecuperável da aula 2.

**A correção não é mais memória para o driver.** É não trazer os dados ao driver: escrevê-los com
`write.parquet`, o que cada executor faz para as próprias partições, ou agregar no cluster e recolher
o resultado pequeno. O `show(20)`, o `take(20)` e o `limit(20).collect()` trazem só o que mostram. Um
resultado grande demais para o driver é um resultado que deveria ir para um arquivo.
