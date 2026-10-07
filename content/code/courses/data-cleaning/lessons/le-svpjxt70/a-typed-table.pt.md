---
title: Uma tabela que recusa dado ruim
version: 1
---

Tudo até aqui converte uma coluna uma vez. Mas os dados continuam chegando, e a exportação do mês
que vem terá as suas próprias grafias. **A última defesa é uma tabela que não consegue guardar um
tipo errado**, então as regras da conversão também são escritas onde ninguém pode pulá-las:

```sql
CREATE SCHEMA clean;
CREATE TABLE clean.customers (
  customer_id text PRIMARY KEY CHECK (customer_id ~ '^C[0-9]{5}$'),
  birth_year  int  CHECK (birth_year BETWEEN 1920 AND 2010),
  opt_in      boolean
);
INSERT INTO clean.customers
SELECT DISTINCT customer_id,
       CASE WHEN birth_year = '1900' THEN NULL
            WHEN length(birth_year) = 2 AND birth_year > '25' THEN ('19' || birth_year)::int
            WHEN length(birth_year) = 2 THEN ('20' || birth_year)::int
            ELSE birth_year::int END,
       CASE WHEN lower(trim(marketing_opt_in)) IN ('true', '1', 's', 'sim') THEN true
            WHEN lower(trim(marketing_opt_in)) IN ('false', '0', 'n', 'não', 'nao') THEN false
            END
FROM raw.customers;
```

Cada coluna leva o seu tipo e uma verificação. O código do cliente precisa ter a forma `C` mais
cinco dígitos. O ano de nascimento precisa ser um inteiro entre 1920 e 2010. O consentimento é um
booleano, e `NULL` é permitido porque "não se sabe" é uma resposta real. O insert repete em SQL as
decisões desta aula: marcadores viram `NULL`, anos de dois dígitos ganham o século pela mesma
regra, e o consentimento mapeia duas listas escritas. Uma grafia que não está em nenhuma das listas
cai pelo `CASE` até `NULL`, e é por isso que a versão em pandas, que recusa grafias desconhecidas,
roda antes.

```
ana@lab:~/clean$ psql -f clean_customers.sql
CREATE SCHEMA
CREATE TABLE
INSERT 0 2376
ana@lab:~/clean$ psql -c 'SELECT count(*), min(birth_year), max(birth_year), count(*) FILTER (WHERE opt_in) AS yes FROM clean.customers'
 count | min  | max  | yes  
-------+------+------+------
  2376 | 1952 | 2006 | 1288
(1 row)

ana@lab:~/clean$ psql -c "INSERT INTO clean.customers VALUES ('C99999', 1890, true)"
ERROR:  new row for relation "customers" violates check constraint "customers_birth_year_check"
DETAIL:  Failing row contains (C99999, 1890, t).
```

2.376 clientes, um por código, nascidos entre 1952 e 2006, com 1.288 que disseram sim: os mesmos
números que o pandas deu. **Duas implementações que concordam verificam uma à outra**, e se um dia
discordarem, uma delas tem uma regra que a outra não tem.

O último comando é a razão de ser da tabela. Alguém, no mês que vem, tenta inserir um cliente
nascido em 1890, e o banco recusa com o nome da regra quebrada. **Uma restrição de verificação
transforma uma decisão de limpeza numa propriedade dos dados**: ela não depende mais de todo mundo
rodar o script certo, porque a linha errada nunca entra.

A faixa em si é uma decisão, como a regra do século. 1920 diz que ninguém com mais de 105 anos
compra comida; 2010 diz que ninguém com menos de quinze anos tem conta. As duas estão
escritas onde um revisor pode vê-las e discutir, o que é melhor que uma faixa que mora só na cabeça
de alguém.
