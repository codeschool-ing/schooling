---
title: Serviços gerenciados
version: 1
---

**Um serviço gerenciado roda o cluster e deixa o job com você.** Toda nuvem grande vende Spark assim,
e elas diferem principalmente em quanto do cluster ainda deixam você ver:

| | o que você pede | o que o provedor roda | como é cobrado |
|---|---|---|---|
| **Amazon EMR**, **Google Dataproc**, **Azure HDInsight** | um cluster de um dado tamanho, com Spark e Hadoop instalados | as máquinas, a instalação, o YARN | por hora de máquina enquanto o cluster existe |
| os modos *serverless* deles, **AWS Glue** | um job, com um teto para os seus recursos | tudo, inclusive o tamanho do cluster | por unidade de trabalho realmente usada |
| **Databricks**, **Microsoft Fabric** | um workspace, notebooks, jobs e um catálogo | clusters iniciados e parados para você, um formato de tabela, governança | por unidade de processamento, por cima das máquinas da nuvem |

**Nenhum deles foi rodado para este curso**, porque cada um precisa de uma conta com um cartão por
trás e cobra desde o primeiro minuto. O que dá para dizer sem rodá-los é o que eles mudam e o que não
mudam.

**Eles mudam quem é acordado de madrugada.** Instalar o Spark, atualizar o Java, trocar um disco
morto, aplicar patches ao sistema operacional: o trabalho das aulas 1, 3 e 12 é do provedor. Um
cluster que existe só enquanto um job roda, iniciado em um minuto e desfeito quando o job termina, é o
jeito normal de rodar trabalho em lote na nuvem, e transforma a pergunta de dimensionamento da aula 2
numa pergunta sobre cada job em vez de sobre uma frota.

**Eles não mudam nada das aulas 5 a 11.** Um job lê Parquet de um object store, planeja pelo Catalyst,
embaralha, desbalanceia, despeja em disco e usa cache num cluster gerenciado exatamente como neste. Os
tamanhos padrão de executor, as partições de shuffle, os tamanhos de arquivo e a ordenação ainda são
escolhas suas, e uma escolha ruim é cobrada por hora em vez de custar uma noite lenta. A aula 14 põe
preços nas duas coisas.

**O aprisionamento que existe mora acima do Spark**: o catálogo do provedor, as extensões dele ao
formato de tabela, os seus notebooks, o seu agendador de jobs. Um job escrito com `spark.read.parquet` e
SQL comum muda de um para outro com a sua configuração; um job escrito com as APIs próprias de um
provedor muda com uma reescrita.
