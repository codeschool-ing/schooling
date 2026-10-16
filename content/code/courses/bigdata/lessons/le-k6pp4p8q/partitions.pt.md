---
title: Quantas partições, e quem decide
version: 1
---

**Uma partição é uma fatia de um conjunto de dados que uma tarefa trata.** Quantas existem decide
quanto paralelismo um estágio tem, de que tamanho é cada tarefa e quantos arquivos uma escrita
produz. O Spark decide esse número em três lugares diferentes, por três regras diferentes.

**Ao ler arquivos**, o Spark os empacota em partições de cerca de 128 MB,
`spark.sql.files.maxPartitionBytes`, dividindo arquivos grandes e agrupando os pequenos. Cada arquivo
também conta como 4 MB a mais que o seu tamanho, `spark.sql.files.openCostInBytes`, porque abrir um
arquivo custa algo seja o que for que ele guarde. Os cliques da camada silver são 365 arquivos de
cerca de 1,1 MB cada:

| | |
|---|---|
| cada arquivo, como o Spark conta | 1,1 MB + 4 MB = 5,1 MB |
| 365 arquivos | cerca de 1.850 MB |
| em partições de 128 MB | cerca de 15 |

**15 partições**, o número que o `jobs_stages.py` imprimiu. O `textFile` da aula 5 sobre o CSV em gzip
fez 365, uma por arquivo, porque um arquivo gzip não pode ser dividido e o Spark não agrupa arquivos
inteiros numa leitura de RDD.

**Depois de um shuffle**, o número é o `spark.sql.shuffle.partitions`, 200 por padrão, sejam quais
forem os dados. É o 200 da aula 6, que a execução adaptativa depois junta. A seção 07 mostra a
execução sem ela.

**Quando você pede**, com `repartition(n)`, que embaralha em exatamente `n` partições, ou
`coalesce(n)`, que junta partições existentes sem shuffle. A aula 8 usa os dois.

A regra de bolso é **de duas a quatro vezes mais partições que núcleos**, cada uma entre uns 100 MB e
1 GB. Menos que isso e alguns núcleos ficam parados na última onda, como a aula 2 mediu; muito mais e
o custo fixo por tarefa começa a aparecer, junto com os arquivos pequenos quando o resultado é
escrito.
