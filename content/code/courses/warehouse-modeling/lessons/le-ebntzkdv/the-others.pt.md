---
title: Os outros
version: 1
---

Três produtos não são o mercado inteiro, e vários outros merecem ser reconhecidos pelo nome, cada um porque
responde de outro jeito a uma pergunta deste curso.

- O **Databricks SQL** roda SQL warehouses sobre tabelas guardadas num formato aberto, o Delta Lake, no seu
  próprio armazenamento de objetos. É a ponte entre esta lição e a lição 10, que desmonta o formato aberto.
- O **Azure Synapse Analytics** e o **Microsoft Fabric** são da Microsoft: os pools dedicados do Synapse são um
  warehouse MPP shared-nothing com escolhas de distribuição muito parecidas com as do Redshift, e o Fabric põe
  warehouse e lake atrás de um produto só, com armazenamento em formato aberto.
- O **ClickHouse** é um banco colunar de código aberto feito para agregar muito rápido sobre tabelas muito
  grandes, em geral de eventos e logs. Pode ser rodado nas suas próprias máquinas ou alugado.
- O **DuckDB**, o motor deste curso, roda dentro de um processo numa máquina e lê Parquet de qualquer lugar. O
  **MotherDuck** é um serviço gerenciado construído em torno dele. Para os muitos warehouses que cabem na
  memória de uma máquina, a regra prática da lição 7, ele é uma alternativa honesta a alugar um cluster.
- O próprio **PostgreSQL**, com extensões que acrescentam armazenamento colunar ou distribuem tabelas entre
  nós, é usado como warehouse por times que querem uma tecnologia de banco em vez de duas.

Nenhum desses foi avaliado neste curso além do DuckDB, que rodou toda consulta dele. Eles aparecem pelo nome para
que quem encontrar um numa descrição de vaga consiga situá-lo: **um motor colunar, um lugar onde os dados
moram, e um jeito de pagar pelo processamento**, que é o que todos eles são.
