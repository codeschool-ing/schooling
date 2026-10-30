---
title: "Lakehouse ou warehouse: quem escreve, e em que linguagem"
version: 1
---

**Um lakehouse e um warehouse do Fabric guardam as tabelas do mesmo jeito, como tabelas Delta no
OneLake, e diferem em quem pode escrevê-las.** É toda a escolha, e ela costuma ser feita pelas
pessoas e não pelos dados: um time que escreve Python e Spark fica com um lakehouse, e um time que
escreve T-SQL fica com um warehouse. Esta seção é ensinada a partir da documentação da Microsoft e
não foi executada.

## Lado a lado

| | lakehouse | warehouse |
|---|---|---|
| escrito por | Spark: notebooks e definições de job Spark; também pipelines e dataflows | T-SQL: `INSERT`, `UPDATE`, `DELETE`, `MERGE`, `CREATE TABLE AS SELECT`, `COPY INTO`; também pipelines |
| lido com T-SQL | sim, pelo **endpoint de análise SQL**, que é só de leitura | sim |
| transações | uma tabela por escrita, a do próprio Delta | várias tabelas numa transação |
| arquivos que não são tabelas | sim, a área `Files` | não |
| schema | definido por quem escreve a tabela | declarado com `CREATE TABLE` |
| guardado como | tabelas Delta no OneLake | tabelas Delta no OneLake |

**O endpoint de análise SQL é criado com todo lakehouse, e não escreve.** Ele deixa um analista
rodar `SELECT` sobre as tabelas do lakehouse em T-SQL, definir views e conceder acesso, mas um
`INSERT` numa tabela do lakehouse por ele é recusado, porque a tabela pertence ao Spark. O warehouse
é o item em que o T-SQL é dono das tabelas, e por isso aquele em que o `UPDATE` funciona.

**As transações entre tabelas são o motivo de existir um warehouse ao lado do lakehouse.** Carregar
a noite da Quitanda é gravar os pedidos, os itens deles e o resumo do dia. Num lakehouse cada escrita
Delta faz commit sozinha, então um leitor entre a segunda e a terceira vê pedidos cujo resumo ainda
não está lá. Num warehouse as três podem ser um `BEGIN TRANSACTION` e um `COMMIT`, e o leitor vê a
noite inteira ou nada dela, que é a garantia que `sql-databases` ensinou num servidor só, agora sobre
arquivos num lago.

## Lendo de um no outro

**Como os dois são Delta no OneLake, nenhum precisa exportar para o outro.** Dentro de um workspace,
uma consulta no warehouse pode chamar uma tabela do lakehouse pelo nome de três partes, item, schema
e tabela, e juntá-la às suas:

```sql
SELECT o.neighbourhood, sum(o.total_cents) / 100 AS reais, max(t.target_reais) AS target
FROM sales.dbo.orders AS o
JOIN finance.dbo.targets AS t ON t.neighbourhood = o.neighbourhood
GROUP BY o.neighbourhood;
```

Aqui `sales` é o lakehouse em que a sexta seção grava e `finance` é um warehouse ao lado dele. Esta
consulta não foi executada: ela aparece pela forma do nome, e pelo que falta nela, que é qualquer
cópia de `orders` para dentro do warehouse. O Spark lê as tabelas do warehouse do mesmo jeito, como
pastas Delta, sem conector.

## Onde isso fica perto da lição 16

**Um warehouse do Fabric é um pool SQL dedicado sem os botões.** Não há DWU para escolher, pool para
pausar nem coluna de distribuição: as sessenta distribuições da lição 16 e a escolha entre hash,
round-robin e replicada são feitas pelo motor. O que você ganha é que toda consulta é paga em CUs da
capacidade, suavizada como todo o resto, em vez de um pool que custa o mesmo ocioso e ocupado. O que
você perde é o controle sobre como as linhas se espalham, que no Synapse é como um time experiente
deixa barato um join grande. Um time que passou anos afinando distribuições tem motivo para ficar; um
time que começa agora costuma ter menos.
