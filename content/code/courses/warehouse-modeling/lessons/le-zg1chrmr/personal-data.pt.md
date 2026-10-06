---
title: Quais colunas são dados pessoais
version: 1
---

A **Lei Geral de Proteção de Dados**, a LGPD, Lei 13.709 de 2018, define **dado pessoal** no artigo 5º como informação
relacionada a pessoa natural identificada ou identificável. *Identificável* é a palavra que importa: um número de
cliente é dado pessoal, porque a empresa consegue transformá-lo de volta numa pessoa, ainda que seja só um número.

O mesmo artigo nomeia uma categoria mais estreita, o **dado pessoal sensível**: origem racial ou étnica, convicção
religiosa, opinião política, filiação a sindicato, saúde, vida sexual, dado genético ou biométrico. O modelo da Ponto
Final não tem coluna desse tipo. O artigo 11 acrescenta um aviso que se aplica a ele mesmo assim: suas regras valem para
**qualquer tratamento que possa revelar** dados sensíveis. A lista dos livros que uma pessoa comprou pode dizer muito
sobre sua religião ou sua política, então a combinação da `fact_sales` com um cliente nomeado merece um cuidado de que
nenhuma das duas tabelas precisa sozinha.

O arquivo de classificação de Ana dá a cada coluna do modelo uma de três classes:

```
table_name,column_name,class
fact_sales,date_key,none
fact_sales,shop_key,none
fact_sales,book_key,none
fact_sales,customer_key,pseudonymous
fact_sales,promotion_key,none
```

- **personal**: identifica ou descreve uma pessoa, como um nome, um número de cliente, a cidade onde mora, ou o momento
  em que o nível de fidelidade de alguém mudou;
- **pseudonymous**: uma chave ou número que leva a uma pessoa só por meio de outra tabela, como a `customer_key` numa
  tabela fato ou um número de pedido. A LGPD continua tratando isso como dado pessoal; a classe registra que ele está a
  uma junção de distância;
- **none**: todo o resto.

```
ana@lab:~/wh$ duckdb -c "SELECT class, count(*) AS columns FROM read_csv('classification.csv') GROUP BY class ORDER BY columns DESC"
┌──────────────┬─────────┐
│    class     │ columns │
│   varchar    │  int64  │
├──────────────┼─────────┤
│ none         │      69 │
│ pseudonymous │      12 │
│ personal     │      11 │
└──────────────┴─────────┘
ana@lab:~/wh$ duckdb -c "SELECT table_name, string_agg(column_name, ', ') AS personal FROM read_csv('classification.csv') WHERE class = 'personal' GROUP BY table_name ORDER BY table_name"
┌──────────────┬────────────────────────────────────────────────────────────┐
│  table_name  │                          personal                          │
│   varchar    │                          varchar                           │
├──────────────┼────────────────────────────────────────────────────────────┤
│ dim_author   │ author_id, author_name, country                            │
│ dim_book     │ authors                                                    │
│ dim_customer │ customer_id, name, tier, city, state, valid_from, valid_to │
└──────────────┴────────────────────────────────────────────────────────────┘
```

**Onze colunas são pessoais e doze são pseudônimas**, de 92. Dois resultados merecem um segundo olhar. Autores são
pessoas: o nome e o país de um autor são dados pessoais, públicos ou não, e o mesmo vale para a coluna `authors` que a
`dim_book` traz ao lado de cada título. E a classificação é por coluna, mas o risco é por combinação, e é por isso que
a classe pseudônima existe: uma tabela fato sem nenhum nome ainda é, por uma junção, um registro do que uma pessoa
nomeada fez.

A classificação é o que torna respondíveis as perguntas da lei. O artigo 37 espera que a empresa mantenha registro das
operações de tratamento de dados pessoais. **Quais tabelas guardam dados pessoais, e em quais colunas** agora é uma
consulta, não uma investigação, e o teste da seção 5 recusa uma coluna nova até alguém decidir a que classe ela
pertence.
