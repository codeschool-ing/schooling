---
title: Pequenas flags, e onde pô-las
version: 1
---

Alguns atributos de um fato não pertencem a dimensão nenhuma. Um pagamento tem um meio e um número de
parcelas. Nenhum dos dois é uma coisa com descrição própria: `pix` não tem nada mais a dizer sobre si
além de `pix`. Há três lugares para pô-los, e cada um tem um custo:

- **Colunas na tabela fato.** Simples, e com 586.405 pagamentos repete uma string curta meio milhão de
  vezes. A lição 8 mostra que um banco colunar torna isso barato. O custo está em outro lugar: a tabela
  fato vira uma mistura de medidas e descrições, e uma ferramenta de relatório oferece `method` como
  algo para somar.
- **Uma pequena dimensão por flag.** Limpo, e multiplica as chaves na tabela fato: uma por flag, cada
  uma apontando para uma tabela de duas a seis linhas.
- **Uma dimensão com toda combinação que ocorre.** Kimball a chama de **dimensão junk** (lixo), não
  como julgamento, mas porque ela junta as sobras.

Quantas combinações ocorrem de fato?

```
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT count(*) AS payments, count(DISTINCT method) AS methods, count(DISTINCT installments) AS installment_counts, count(DISTINCT (method, installments)) AS combinations FROM fact_payments"
┌──────────┬─────────┬────────────────────┬──────────────┐
│ payments │ methods │ installment_counts │ combinations │
│  int64   │  int64  │       int64        │    int64     │
├──────────┼─────────┼────────────────────┼──────────────┤
│   586405 │       4 │                  6 │            9 │
└──────────┴─────────┴────────────────────┴──────────────┘
```

Quatro meios e seis quantidades de parcelas poderiam dar vinte e quatro combinações; ocorrem nove,
porque só o cartão é parcelado. Nove linhas são uma dimensão:

```sql
-- A junk dimension: every combination of the payment's small flags that
-- actually occurs, once, with a key.
CREATE TABLE dim_payment_profile AS
SELECT row_number() OVER (ORDER BY method, installments) AS payment_profile_key,
       method, installments,
       CASE WHEN installments = 1 THEN 'paid at once' ELSE 'in instalments' END AS terms
FROM (SELECT DISTINCT method, installments FROM fact_payments);

SELECT * FROM dim_payment_profile;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < junk.sql
┌─────────────────────┬───────────┬──────────────┬────────────────┐
│ payment_profile_key │  method   │ installments │     terms      │
│        int64        │  varchar  │    int64     │    varchar     │
├─────────────────────┼───────────┼──────────────┼────────────────┤
│                   1 │ card      │            1 │ paid at once   │
│                   2 │ card      │            2 │ in instalments │
│                   3 │ card      │            3 │ in instalments │
│                   4 │ card      │            4 │ in instalments │
│                   5 │ card      │            5 │ in instalments │
│                   6 │ card      │            6 │ in instalments │
│                   7 │ cash      │            1 │ paid at once   │
│                   8 │ gift_card │            1 │ paid at once   │
│                   9 │ pix       │            1 │ paid at once   │
└─────────────────────┴───────────┴──────────────┴────────────────┘
```

**A tabela fato ganha uma chave em vez de duas colunas**, e a dimensão é onde rótulos derivados como
`terms` podem morar: escritos uma vez, a partir das flags, como `region` foi escrita uma vez a partir
do estado na lição 2.

A regra do que vai numa delas: **flags e códigos de baixa cardinalidade que descrevem o evento, que
servem para filtrar ou agrupar, e que não têm atributos próprios.** Um campo com descrição própria, como
a promoção com seu nome e suas datas, é uma dimensão de verdade. Um campo com um valor diferente em
quase toda linha, como o número do pedido, nem é dimensão, e a lição 4 trata dele.
