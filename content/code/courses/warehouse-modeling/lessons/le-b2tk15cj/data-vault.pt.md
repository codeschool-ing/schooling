---
title: Um fragmento de Data Vault
version: 1
---

Um Data Vault tem três tipos de tabela, e os nomes dizem o que cada um guarda:

- **Hubs** guardam chaves de negócio e mais nada: uma linha por número de cliente, por ISBN, por número de
  pedido, com o momento em que foi carregada pela primeira vez e o sistema de onde veio.
- **Links** guardam relações entre hubs: este pedido pertence a este cliente. Um link é muitos para muitos
  por construção, então uma relação que muda depois não exige redesenho.
- **Satélites** guardam atributos descritivos, presos a um hub ou a um link, com uma linha para cada
  mudança, carimbada com quando foi carregada e de onde.

Aqui estão um hub de clientes e um satélite do nível, construídos a partir dos dados da rede:

```sql
-- A fragment of a Data Vault for customers: a hub of business keys, and a
-- satellite of their tier, one row per change, both stamped with the load.
CREATE TABLE hub_customer AS
SELECT md5(CAST(customer_id AS VARCHAR)) AS customer_hk, customer_id,
       TIMESTAMPTZ '2025-12-31 23:00:00-03' AS load_ts, 'shop.customers' AS record_source
FROM staging.customers;

CREATE TABLE sat_customer_tier AS
SELECT md5(CAST(customer_id AS VARCHAR)) AS customer_hk, valid_from AS load_ts, tier,
       'shop.customer_changes' AS record_source
FROM dim_customer WHERE customer_key > 0;

-- The current tier of every customer, as a reader of the vault has to ask it.
SELECT tier, count(*) AS customers
FROM (SELECT h.customer_id, s.tier
      FROM hub_customer h
      JOIN sat_customer_tier s USING (customer_hk)
      QUALIFY row_number() OVER (PARTITION BY h.customer_hk ORDER BY s.load_ts DESC) = 1)
GROUP BY tier ORDER BY customers DESC;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < vault.sql
┌─────────┬───────────┐
│  tier   │ customers │
│ varchar │   int64   │
├─────────┼───────────┤
│ reader  │     33831 │
│ regular │      4652 │
│ patron  │      1517 │
└─────────┴───────────┘
```

A resposta está certa: os mesmos 33.831 readers, 4.652 regulars e 1.517 patrons das linhas atuais da
`dim_customer`. Mas veja o que foi preciso: uma junção do hub ao satélite e uma função de janela para
escolher a linha mais recente de cada cliente. **Essa é toda pergunta feita a um vault**, e por isso
ninguém tira relatórios direto de um. Um vault é a camada a partir da qual as estrelas são construídas.

O que o vault compra em troca:

- **Toda mudança na origem vira um insert.** Um atributo novo é um satélite novo. Uma origem nova é um
  satélite novo num hub existente. Nada do que existe é alterado, o que torna as cargas simples e
  paralelas.
- **Auditabilidade.** Toda linha diz que carga a trouxe e de que sistema, e nada é sobrescrito. "Em que o
  warehouse acreditava em 3 de março, e por quê?" tem resposta.
- **Chaves hash.** O `md5` da chave de negócio dá a mesma chave em toda carga e em todo sistema sem uma
  consulta, então hubs, links e satélites podem ser carregados em qualquer ordem, em paralelo.

São vantagens reais para uma organização com muitas origens que mudam o tempo todo. Para uma origem e um
time pequeno, são três tabelas onde a `dim_customer` era uma, e uma segunda camada a construir antes de
qualquer relatório existir.
