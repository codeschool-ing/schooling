---
title: Achando a chave quente
version: 1
---

**Uma tarefa lenta diz que uma partição é grande; não diz qual chave a fez assim.** A chave se acha
contando linhas por chave e ordenando, o que é barato perto do job que sofre com ela. Com a tabela
de visitantes da seção anterior, a contagem já está feita. Salve como `~/big/hot_key.py`:

```schooling-example
{
  "language": "python",
  "file": "hot_key.py",
  "parts": [
    {
      "code": "\"\"\"The visitors with the most events.\"\"\"\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"hot key\").getOrCreate()\n"
    },
    {
      "code": "visitors = spark.read.parquet(\"data/silver/visitors\")\nvisitors.orderBy(F.desc(\"events\")).show(5)\n",
      "note": "**Achar uma chave quente é um agrupamento e uma ordenação**: contar por chave, a maior primeiro. Com a tabela de visitantes já contada, é uma ordenação."
    },
    {
      "code": "print(\"median events per visitor:\", visitors.approxQuantile(\"events\", [0.5], 0.01)[0])\n",
      "note": "O visitante mediano, para comparar: a mediana aproximada de `events`, calculada no cluster."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit hot_key.py
WARNING: Using incubator modules: jdk.incubator.vector
+----------+----------+------+
|visitor_id| first_day|events|
+----------+----------+------+
|  v0000000|2025-01-01|960905|
|  v1885325|2025-02-06|    69|
|  v1639364|2025-01-06|    66|
|  v1057185|2025-01-09|    64|
|  v1586330|2025-01-25|    64|
+----------+----------+------+
only showing top 5 rows
median events per visitor: 12.0
```

**O `v0000000` tem 960.905 eventos; o visitante seguinte tem 69, e o visitante mediano 12.** A
segunda coluna da tabela é a que interessa: o desbalanceamento raramente é uma ladeira suave.
Quase sempre é um valor, ou um punhado, muito acima de tudo, e o resto da distribuição é comum.

Os suspeitos de sempre são os mesmos nos dados de qualquer empresa:

- **Um valor de preenchimento.** Um `NULL`, um texto vazio, `0`, `unknown` ou `-1` usado onde faltava
  o valor real. Toda linha sem nada a dizer cai numa chave.
- **Uma máquina.** Um robô de busca, uma checagem de monitoramento, um teste de carga, uma
  integração que chama o mesmo endereço a cada segundo. É o nosso caso: o `v0000000` é um robô que
  nunca se identifica.
- **Um cliente gigante.** Uma loja num marketplace, uma cidade num país, um produto no dia do
  lançamento. Os dados estão certos e a distribuição é o negócio.

Os dois primeiros muitas vezes se resolvem perguntando se as linhas deveriam estar no job. Juntar
os eventos do robô aos atributos de visitante não responde pergunta nenhuma que alguém fez; um
filtro antes do join faz o desbalanceamento sumir junto com as linhas. O terceiro não se filtra, e
o resto desta aula é sobre ele.

**O `approxQuantile` é aproximado de propósito.** Uma mediana exata precisa de todos os valores
ordenados num lugar só. Com um erro relativo de 0,01, o Spark calcula um resumo por partição e os
junta, e a resposta fica a menos de um por cento da posição verdadeira: bom o bastante para "como é
um visitante comum", e sem nunca trazer os dados ao driver.
