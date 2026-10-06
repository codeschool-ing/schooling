---
title: A mesma estrela, de três jeitos
version: 1
---

Ponha os três lado a lado e o padrão fica claro: **o modelo lógico é o mesmo, e cada produto faz uma pergunta
física diferente sobre ele.**

| | BigQuery | Snowflake | Redshift |
|---|---|---|---|
| onde os dados moram | armazenamento do Google, formato próprio | armazenamento de objetos da nuvem, formato próprio | armazenamento gerenciado com cache local (RA3), ou serverless |
| processamento | slots, atribuídos pelo serviço | virtual warehouses que você cria e dimensiona | nós que você escolhe, ou RPUs no serverless |
| como se paga o processamento | bytes lidos por consulta, ou slots reservados | créditos por segundo de warehouse ligado | horas de nó, ou horas de RPU |
| o que você declara | `PARTITION BY`, `CLUSTER BY` | `CLUSTER BY` em tabelas grandes | `DISTSTYLE`, `DISTKEY`, `SORTKEY` |
| o que ele faz por você | todo o resto | micro-partições e as estatísticas delas | escolhas `AUTO`, se você deixar |
| tipos inteiros | `INT64` | `NUMBER(38,0)` | `INTEGER`, `BIGINT` |

As declarações miram as duas coisas que as lições 7 e 8 mediram. **Manter juntas as linhas que uma consulta
quer**, para blocos e partições poderem ser pulados: as partições e o clustering do BigQuery, as chaves de
clustering do Snowflake, as sort keys do Redshift. E, onde o produto ainda expõe isso, **manter os dois lados
de uma junção na mesma máquina**: as chaves de distribuição do Redshift.

O que não aparece na tabela é igualmente importante. **Fatos e dimensões, a granularidade, chaves
substitutas, histórico tipo 2, dimensões conformadas e tabelas ponte são iguais nos três**, e no DuckDB, e no
PostgreSQL se fosse o caso. Um warehouse bem projetado consegue mudar de um produto para outro com o DDL
reescrito e o modelo intocado; um projetado em torno dos botões de um produto só não consegue.

Para quem está na trilha `software-architecture`, esta tabela é a que se leva para a reunião: a escolha entre
os três é sobretudo sobre a conta e o modelo de operação, e muito pouco sobre o projeto das tabelas.
