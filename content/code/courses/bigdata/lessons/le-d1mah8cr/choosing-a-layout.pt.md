---
title: Escolhendo como gravar
version: 1
---

**Toda decisão desta aula é tomada quando os dados são gravados, e paga toda vez que são lidos.** Uma
tabela gravada uma vez e lida todo dia durante um ano é lida trezentas vezes, então uma gravação que
custa o dobro e torna cada leitura mais rápida é uma pechincha. As medições da aula, como regras:

- **Um formato colunar para tudo que analistas leem.** CSV é para chegar, não para ficar: janeiro
  levou 6,8 segundos para ser lido como CSV com gzip e menos de 3 como qualquer arquivo Parquet.
- **Um codec mais forte que o padrão** para dados lidos mais vezes do que gravados: o zstd cortou os
  33,0 MiB do Snappy para 19,6, e não leu mais devagar.
- **Timestamps como inteiros de 64 bits** no Parquet, com `spark.sql.parquet.outputTimestampType` em
  `TIMESTAMP_MICROS`, a menos que um leitor antigo precise de `INT96`.
- **Páginas da versão 2** onde todo leitor da tabela as suporta, o que o Spark, o Arrow, o DuckDB e o
  Trino atuais fazem: as codificações delta cortaram o arquivo pela metade de novo.
- **Ordenar pela coluna que a maioria das consultas filtra**, dentro das partições, e aceitar o que
  isso custa às outras colunas.
- **Arquivos de centenas de megabytes**, não um por hora de dados, e row groups do tamanho padrão. A
  escrita particionada da aula 8 e os arquivos pequenos da aula 3 são a mesma regra vista do outro
  lado.

Nada disso é de graça para mudar depois. **A organização de uma tabela muda reescrevendo-a**, o que
para uma tabela grande é um job por si só; os formatos de tabela da aula 11 tornam essa reescrita
segura de rodar enquanto outros leem, e a aula 14 põe um preço nela.
