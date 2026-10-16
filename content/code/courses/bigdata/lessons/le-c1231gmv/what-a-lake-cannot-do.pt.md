---
title: O que um diretório de arquivos não consegue fazer
version: 1
---

**Até aqui um lake foi um diretório de arquivos Parquet, e um diretório não é uma tabela.** Ele não
tem registro do que foi gravado quando, não tem como mudar uma linha sem reescrever arquivos à mão, e
nada impede dois programas de gravarem ao mesmo tempo. A aula 3 nomeou essas lacunas e a aula 5
avisou que um append noturno rodado duas vezes dobra um dia. Salve como `~/big/plain_append.py`:

```schooling-example
{
  "language": "python",
  "file": "plain_append.py",
  "parts": [
    {
      "code": "\"\"\"January's purchases appended to a plain Parquet directory, by a job that ran twice.\"\"\"\nimport os\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"plain append\").getOrCreate()\nPATH = \"data/plain/purchases\"\njanuary = (spark.read.parquet(\"data/silver/clicks\")\n           .where((F.col(\"kind\") == \"purchase\") & (F.col(\"day\") < \"2025-02-01\")))\n\n"
    },
    {
      "code": "for run in (1, 2):\n    january.write.mode(\"append\").parquet(PATH)\n    files = sorted(f for f in os.listdir(PATH) if f.endswith(\".parquet\"))\n    print(f\"after run {run}: {spark.read.parquet(PATH).count()} purchases in {len(files)} files\")\n",
      "note": "**O mesmo append noturno, rodado duas vezes**, como acontece quando um agendador repete um job que na verdade tinha terminado."
    },
    {
      "code": "print(\"\\n\".join(files))\n",
      "note": "**O que o diretório sabe sobre isso**: nomes de arquivo, cuja parte do meio é a mesma nos arquivos de uma gravação, e nada que diga qual gravação veio primeiro ou que a segunda repete a primeira."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit plain_append.py
WARNING: Using incubator modules: jdk.incubator.vector
after run 1: 80988 purchases in 3 files
after run 2: 161976 purchases in 6 files
part-00000-afd13b26-e03f-473c-84d9-0f1d6f8e47cf-c000.snappy.parquet
part-00000-b90a94fc-2c0e-4510-970b-915b3ed49f87-c000.snappy.parquet
part-00001-afd13b26-e03f-473c-84d9-0f1d6f8e47cf-c000.snappy.parquet
part-00001-b90a94fc-2c0e-4510-970b-915b3ed49f87-c000.snappy.parquet
part-00002-afd13b26-e03f-473c-84d9-0f1d6f8e47cf-c000.snappy.parquet
part-00002-b90a94fc-2c0e-4510-970b-915b3ed49f87-c000.snappy.parquet
```

**O dobro das compras, e nada no diretório diz isso.** A segunda execução gravou mais três arquivos ao
lado dos três primeiros. Quem lê o diretório pega todos os arquivos dele, então todo relatório de
janeiro agora conta cada compra duas vezes, e o único caminho de volta é saber quais arquivos apagar.

O mesmo diretório tem as outras lacunas também:

- **Sem transações.** Um job que falha no meio de uma gravação deixa os arquivos que terminou, e um
  leitor que lista o diretório durante uma gravação vê alguns dos arquivos novos e outros não.
- **Sem mudanças em linhas.** Apagar os eventos de um visitante, um pedido que as leis de privacidade
  tornam rotineiro, significa achar cada arquivo que os guarda e reescrever um a um, à mão, enquanto
  ninguém lê.
- **Sem histórico.** Depois que um arquivo é sobrescrito, o que a tabela dizia ontem se foi.
- **Sem esquema próprio.** Cada arquivo traz o seu esquema; nada impede os arquivos de amanhã de
  terem outro.

**Um formato de tabela aberto resolve as quatro do mesmo jeito: um log de commits ao lado dos
arquivos de dados.** Uma tabela é o conjunto de arquivos que o log diz que ela tem, no commit mais
recente, e uma gravação não fica visível até o seu commit ficar. Delta Lake, Apache Iceberg e Apache
Hudi são três desenhos dessa ideia, todos abertos, todos construídos sobre arquivos Parquet, e todos
legíveis pelo Spark.
