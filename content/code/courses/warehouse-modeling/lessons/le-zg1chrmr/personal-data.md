---
title: Which columns are personal data
version: 2
---

Brazil's Lei Geral de Proteção de Dados, the LGPD, Law 13,709 of 2018, defines **personal data** in article 5 as
information relating to an identified or identifiable natural person. *Identifiable* is the word that matters: a
customer number is personal data, because the company can turn it back into a person, even though it is only a
number.

The same article names a narrower category, **sensitive personal data**: racial or ethnic origin, religious
conviction, political opinion, union membership, health, sex life, genetic or biometric data. Ponto Final's model has
no column of that kind. Article 11 adds a warning that applies to it anyway: its rules cover **any processing that can
reveal** sensitive data. A list of the books one person bought can say a good deal about their religion or their
politics, so the combination of `fact_sales` and a named customer deserves care that neither table needs alone.

Ana's classification file, `classification.csv`, gives every column of the model one of three classes:

- **personal**: identifies or describes a person, such as a name, a customer number, a city of residence, or the
  moment somebody's loyalty tier changed;
- **pseudonymous**: a key or number that leads to a person only through another table, such as `customer_key` in a fact
  table or an order number. The LGPD still treats this as personal data; the class records that it is one join away;
- **none**: everything else.

The whole file, to save in `~/wh`:

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

**Eleven columns are personal and twelve are pseudonymous**, out of 92. Two results deserve a second look. Authors are
people: an author's name and country are personal data, public or not, and so is the `authors` column that
`dim_book` carries beside each title. And the classification is per column but the risk is per combination, which is
why the pseudonymous class exists at all: a fact table with no names in it is still, through one join, a record of what
a named person did.

The classification is what makes the law's questions answerable. Article 37 expects a company to keep a record of its
processing of personal data. **Which tables hold personal data, and in which columns** is now a query rather than an
investigation, and the test of section 5 refuses a new column until somebody has decided which class it belongs to.
