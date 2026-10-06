---
title: Armazenamento e processamento, separados
version: 1
---

No projeto shared-nothing da seção 06, cada nó é dono da sua parte dos dados nos seus próprios discos.
Isso tem uma consequência que a indústria levou uma década para contornar. **Para acrescentar poder de
processamento é preciso acrescentar armazenamento, e mover dados para ele.** Dobrar os nós significa
reescrever a distribuição de toda tabela em duas vezes mais máquinas, o que pode levar horas, e encolher
à noite significa fazer tudo de novo.

O projeto que o substituiu na nuvem guarda os dados num lugar e o processamento em outro:

- **Os dados moram no armazenamento de objetos**, o que a lição 5 de `cloud` descreveu: arquivos em
  buckets, baratos, e legíveis por qualquer número de máquinas ao mesmo tempo.
- **O processamento é um conjunto de máquinas sem dados próprios.** Elas leem os arquivos de que uma
  consulta precisa, guardam em cache o que leem com frequência, e podem ser ligadas, desligadas,
  aumentadas ou multiplicadas sem mover um byte dos dados guardados.

O que torna isso prático é o que a seção 10 acabou de fazer: uma tabela guardada como arquivos colunares,
particionada para uma consulta ler só os arquivos de que precisa, com estatísticas suficientes em cada
arquivo (a lição 8 as mostra) para pular quase todo o resto. Os dados foram gravados uma vez, em
`sales_by_month/`, e qualquer número de processos DuckDB, ou qualquer outro motor que leia Parquet,
poderia consultá-los ao mesmo tempo.

O que isso compra para um warehouse:

- **Elasticidade.** Um cluster maior para o fechamento do mês, um pequeno no resto do mês, e nenhum de
  noite.
- **Isolamento.** Os relatórios pesados do time financeiro rodam no seu próprio processamento, lendo os
  mesmos dados, e não atrasam o painel que todos os outros usam. É a escala "muitas consultas, muitas
  máquinas" da seção 04, e é onde a escala horizontal funciona melhor.
- **Pagar pelo que roda.** O armazenamento é cobrado por gigabyte-mês; o processamento por segundo ou pelo
  volume de dados lidos.

A lição 9 são três produtos construídos exatamente sobre essa separação, BigQuery, Snowflake e Redshift,
e como cada um cobra por ela. A lição 10 é a mesma ideia com os arquivos abertos para qualquer motor ler.
