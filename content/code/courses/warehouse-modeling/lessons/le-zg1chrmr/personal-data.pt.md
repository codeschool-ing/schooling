---
title: Quais colunas são dados pessoais
version: 2
---

A Lei Geral de Proteção de Dados, a LGPD, Lei 13.709 de 2018, define **dado pessoal** no artigo 5º como informação
relacionada a pessoa natural identificada ou identificável. *Identificável* é a palavra que importa: um número de
cliente é dado pessoal, porque a empresa consegue transformá-lo de volta numa pessoa, ainda que seja só um número.

O mesmo artigo nomeia uma categoria mais estreita, o **dado pessoal sensível**: origem racial ou étnica, convicção
religiosa, opinião política, filiação a sindicato, saúde, vida sexual, dado genético ou biométrico. O modelo da Ponto
Final não tem coluna desse tipo. O artigo 11 acrescenta um aviso que se aplica a ele mesmo assim: suas regras valem para
**qualquer tratamento que possa revelar** dados sensíveis. A lista dos livros que uma pessoa comprou pode dizer muito
sobre sua religião ou sua política, então a combinação da `fact_sales` com um cliente nomeado merece um cuidado de que
nenhuma das duas tabelas precisa sozinha.

O arquivo de classificação de Ana, `classification.csv`, dá a cada coluna do modelo uma de três classes:

- **personal**: identifica ou descreve uma pessoa, como um nome, um número de cliente, a cidade onde mora, ou o momento
  em que o nível de fidelidade de alguém mudou;
- **pseudonymous**: uma chave ou número que leva a uma pessoa só por meio de outra tabela, como a `customer_key` numa
  tabela fato ou um número de pedido. A LGPD continua tratando isso como dado pessoal; a classe registra que ele está a
  uma junção de distância;
- **none**: todo o resto.

O arquivo inteiro, para salvar em `~/wh`:

```
table_name,column_name,class
fact_sales,date_key,none
fact_sales,shop_key,none
fact_sales,book_key,none
fact_sales,customer_key,pseudonymous
fact_sales,promotion_key,none
fact_sales,order_id,pseudonymous
fact_sales,line_no,none
fact_sales,quantity,none
fact_sales,gross_cents,none
fact_sales,discount_cents,none
fact_sales,net_cents,none
fact_payments,date_key,none
fact_payments,shop_key,none
fact_payments,customer_key,pseudonymous
fact_payments,order_id,pseudonymous
fact_payments,payment_id,pseudonymous
fact_payments,method,none
fact_payments,installments,none
fact_payments,amount_cents,none
fact_inventory,date_key,none
fact_inventory,shop_key,none
fact_inventory,book_key,none
fact_inventory,on_hand,none
fact_fulfilment,order_id,pseudonymous
fact_fulfilment,customer_key,pseudonymous
fact_fulfilment,ordered_date_key,none
fact_fulfilment,paid_date_key,none
fact_fulfilment,shipped_date_key,none
fact_fulfilment,delivered_date_key,none
fact_fulfilment,status,none
fact_fulfilment,days_to_ship,none
fact_fulfilment,days_to_deliver,none
fact_event_attendance,date_key,none
fact_event_attendance,shop_key,none
fact_event_attendance,author_key,pseudonymous
fact_event_attendance,customer_key,pseudonymous
dim_date,date_key,none
dim_date,date,none
dim_date,year,none
dim_date,quarter,none
dim_date,month,none
dim_date,month_name,none
dim_date,day_of_month,none
dim_date,day_of_week,none
dim_date,day_name,none
dim_date,is_weekend,none
dim_date,is_holiday,none
dim_date,holiday,none
dim_shop,shop_key,none
dim_shop,shop_id,none
dim_shop,shop_name,none
dim_shop,city,none
dim_shop,state,none
dim_shop,region,none
dim_shop,channel,none
dim_shop,opened_on,none
dim_book,book_key,none
dim_book,book_id,none
dim_book,isbn,none
dim_book,title,none
dim_book,authors,personal
dim_book,format,none
dim_book,category,none
dim_book,subcategory,none
dim_book,department,none
dim_book,publisher,none
dim_book,published_on,none
dim_customer,customer_key,pseudonymous
dim_customer,customer_id,personal
dim_customer,name,personal
dim_customer,tier,personal
dim_customer,city,personal
dim_customer,state,personal
dim_customer,valid_from,personal
dim_customer,valid_to,personal
dim_customer,is_current,none
dim_promotion,promotion_key,none
dim_promotion,promotion_id,none
dim_promotion,code,none
dim_promotion,promotion_name,none
dim_promotion,percent_off,none
dim_promotion,starts_on,none
dim_promotion,ends_on,none
dim_promotion,applies_to,none
dim_author,author_key,pseudonymous
dim_author,author_id,personal
dim_author,author_name,personal
dim_author,country,personal
bridge_book_author,book_key,none
bridge_book_author,author_key,pseudonymous
bridge_book_author,position,none
bridge_book_author,weight,none
```

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
