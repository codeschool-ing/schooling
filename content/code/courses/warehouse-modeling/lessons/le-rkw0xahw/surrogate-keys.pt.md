---
title: Chaves substitutas, do próprio warehouse
version: 1
---

Uma **chave substituta** (surrogate key) é um inteiro sem significado que o warehouse atribui a cada
linha de uma dimensão, e que as tabelas fato usam para apontar para ela. `book_key`, `shop_key` e
`customer_key` são chaves substitutas. A chave natural fica ao lado como atributo comum, para a linha
ainda poder ser encontrada por ela.

Três propriedades fazem valer a coluna a mais.

**Ela é do warehouse.** Nenhum sistema de origem consegue mudá-la, reaproveitá-la ou renumerá-la. Um
novo sistema de caixa, um ISBN corrigido ou um cadastro de cliente unificado mudam um atributo da linha
da dimensão e deixam em paz todo fato que aponta para ela.

**Pode haver mais de uma por coisa.** O cliente 2123 tem duas:

```
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT customer_key, customer_id, city, state, tier, valid_from, valid_to FROM dim_customer WHERE customer_id = 2123"
┌──────────────┬─────────────┬──────────┬─────────┬─────────┬──────────────────────────┬──────────────────────────┐
│ customer_key │ customer_id │   city   │  state  │  tier   │        valid_from        │         valid_to         │
│    int64     │    int64    │ varchar  │ varchar │ varchar │ timestamp with time zone │ timestamp with time zone │
├──────────────┼─────────────┼──────────┼─────────┼─────────┼──────────────────────────┼──────────────────────────┤
│         2621 │        2123 │ Contagem │ MG      │ reader  │ 2023-05-02 11:27:36-03   │ 2025-04-13 19:59:35-03   │
│         2622 │        2123 │ Londrina │ PR      │ reader  │ 2025-04-13 19:59:35-03   │ 9999-12-31 00:00:00-03   │
└──────────────┴─────────────┴──────────┴─────────┴─────────┴──────────────────────────┴──────────────────────────┘
```

Uma linha para os anos em Contagem, uma para o tempo desde a mudança, e cada venda aponta para a linha
que era verdade quando aconteceu. A chave natural não consegue isso, porque é um valor por cliente.
**É nessa propriedade que a lição 5 se apoia**, e o motivo de chaves substitutas não serem opcionais
num warehouse que guarda histórico.

**Ela é pequena.** A tabela fato carrega uma por linha por dimensão, 887.477 vezes. As mesmas
referências escritas como inteiro e como e-mail:

```sql
-- The same 887,477 references, kept as an integer key and as an e-mail address.
COPY (SELECT customer_key FROM fact_sales) TO 'by_key.parquet';
COPY (SELECT coalesce(c.email, '') AS customer_email
      FROM fact_sales f
      LEFT JOIN dim_customer d USING (customer_key)
      LEFT JOIN staging.customers c ON c.customer_id = d.customer_id) TO 'by_email.parquet';
```

```
ana@lab:~/wh$ duckdb wh.duckdb < key-size.sql
ana@lab:~/wh$ ls -l by_key.parquet by_email.parquet
-rw-r--r-- 1 ana ana 4129699 Oct  6 13:38 by_email.parquet
-rw-r--r-- 1 ana ana 2480761 Oct  6 13:38 by_key.parquet
```

**4.129.699 bytes contra 2.480.761: o e-mail custa 66% a mais** para uma coluna, comprimida, e toda
junção compara strings mais longas. Numa tabela fato com cinco chaves de dimensão, essa diferença é paga
cinco vezes.

Duas regras mantêm as chaves substitutas sem significado, que é a razão de existirem:

- **Ninguém lê nada no número.** O `book_key` 581 não é o 581º livro em nenhuma ordem que uma pessoa
  reconheceria. Uma chave que codifica algo, como a região de uma loja no primeiro dígito, fica errada
  no dia em que a loja muda de lugar.
- **A carga as atribui, e só a carga.** A lição 2 usou `row_number()` sobre uma ordem natural, o que
  basta para uma tabela construída do zero. Uma dimensão que cresce noite após noite usa uma sequence,
  para que linhas novas recebam números novos e as antigas mantenham os seus.

A data é a exceção deliberada, da lição 2: `20250418` significa algo, porque um dia não muda de
identidade.
