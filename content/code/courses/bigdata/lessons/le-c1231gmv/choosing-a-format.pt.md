---
title: Escolhendo um formato
version: 1
---

**Os três formatos resolvem o mesmo problema, e desde 2023 vêm convergindo.** Cada um acrescentou o
que os outros tinham: o Delta tem deletion vectors e pode gravar os metadados do Iceberg ao lado dos
seus, o Iceberg tem deletes e merges por linha, e o Apache XTable traduz os metadados de uma tabela
entre os três. As diferenças que sobram são de ênfase.

| | Delta Lake | Apache Iceberg | Apache Hudi |
|---|---|---|---|
| começou na | Databricks, 2019 | Netflix, 2018 | Uber, 2017 |
| metadados | um log de commits JSON, com checkpoints em Parquet | arquivos de metadados, manifest lists e manifests | uma timeline de commits, e uma tabela de metadados |
| mais forte em | Spark, e a plataforma da Databricks | muitos motores, por catálogos | upserts frequentes e leituras incrementais |
| um commit é | criar o próximo arquivo do log | trocar o ponteiro do catálogo | concluir um instante na timeline |

**Escolha pelo que lê a tabela, não pela tabela.** Um lake lido só pelo Spark é bem servido por
qualquer um deles, e o Delta é o que menos pede configuração. Um lake lido por Spark, Trino, Flink e
um warehouse na nuvem é para o que servem os catálogos do Iceberg, e é o que mais motores suportam
hoje. Uma tabela que recebe um fluxo de correções a cada poucos minutos é o caso do Hudi. Uma equipe
raramente escolhe do zero: a plataforma em que ela roda em geral já escolheu.

**O que os três tornam possível é o que esta aula mediu**: um job repetido que não dobra os dados, um
delete que não significa reescrever arquivos à mão, uma tabela que pode ser lida como era, e uma
compactação que não quebra os leitores que já estão rodando. Eles não deixam os arquivos menores nem
uma consulta mais rápida por si sós; as escolhas da aula 10 são feitas por baixo, e continuam
importando.
