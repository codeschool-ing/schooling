---
title: Tipo 2, uma linha nova para cada versão
version: 1
---

**O tipo 2 acrescenta uma linha nova quando um atributo acompanhado muda**, e deixa a linha antiga
como estava. Cada linha é uma versão do cliente, e carrega o período em que foi verdade. O cliente
número um, na `dim_customer` do warehouse:

```
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT customer_key, tier, city, valid_from, valid_to, is_current FROM dim_customer WHERE customer_id = 1 ORDER BY valid_from"
┌──────────────┬─────────┬─────────┬──────────────────────────┬──────────────────────────┬────────────┐
│ customer_key │  tier   │  city   │        valid_from        │         valid_to         │ is_current │
│    int64     │ varchar │ varchar │ timestamp with time zone │ timestamp with time zone │  boolean   │
├──────────────┼─────────┼─────────┼──────────────────────────┼──────────────────────────┼────────────┤
│            1 │ reader  │ Recife  │ 2022-11-19 20:06:40-03   │ 2024-01-08 17:21:54-03   │ false      │
│            2 │ regular │ Recife  │ 2024-01-08 17:21:54-03   │ 2025-01-30 14:20:27-03   │ false      │
│            3 │ patron  │ Recife  │ 2025-01-30 14:20:27-03   │ 9999-12-31 00:00:00-03   │ true       │
└──────────────┴─────────┴─────────┴──────────────────────────┴──────────────────────────┴────────────┘
```

Três linhas, três chaves substitutas. Cada linha tem:

- **`valid_from` e `valid_to`**, o período em que esta versão foi verdade. O fim de uma é exatamente o
  começo da próxima, então todo instante pertence a uma versão e nenhum a duas.
- **`is_current`**, verdadeiro só na última versão, então "clientes como estão agora" é um filtro e não
  um cálculo.
- **uma chave substituta própria.** É o que a lição 4 prometeu: um cliente, várias chaves, e cada venda
  aponta para a chave da versão que era verdade quando aconteceu.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Uma linha do tempo do cliente 1 de novembro de 2022 até hoje, dividida em três versões na dim_customer. Chave 1, reader, de 19 de novembro de 2022 a 8 de janeiro de 2024. Chave 2, regular, de 8 de janeiro de 2024 a 30 de janeiro de 2025. Chave 3, patron, desde 30 de janeiro de 2025, a atual. Uma venda em 15 de março de 2024 cai na segunda versão e aponta para a chave 2; uma venda em junho de 2025 cai na terceira e aponta para a chave 3.\"><defs><marker id=\"ah-type-2-timeline\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30.0\" y=\"60\" width=\"236.21052631578948\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"148.10526315789474\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">chave 1 · reader</text><rect x=\"266.2105263157895\" y=\"60\" width=\"229.26315789473682\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"380.8421052631579\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">chave 2 · regular</text><rect x=\"495.4736842105263\" y=\"60\" width=\"194.5263157894737\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"592.7368421052631\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">chave 3 · patron</text><text x=\"30\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">cliente 1 na dim_customer</text><line x1=\"30.0\" y1=\"102\" x2=\"30.0\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"30.0\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nov 2022</text><line x1=\"266.2105263157895\" y1=\"102\" x2=\"266.2105263157895\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"266.2105263157895\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">8 jan 2024</text><line x1=\"495.4736842105263\" y1=\"102\" x2=\"495.4736842105263\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"495.4736842105263\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">30 jan 2025</text><line x1=\"316.57894736842104\" y1=\"185\" x2=\"316.57894736842104\" y2=\"106\" stroke=\"var(--paper)\" stroke-width=\"1.5\" marker-end=\"url(#ah-type-2-timeline)\"></line><text x=\"316.57894736842104\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">venda, 15/03/2024 → chave 2</text><line x1=\"573.6315789473684\" y1=\"185\" x2=\"573.6315789473684\" y2=\"106\" stroke=\"var(--paper)\" stroke-width=\"1.5\" marker-end=\"url(#ah-type-2-timeline)\"></line><text x=\"573.6315789473684\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">venda, jun/2025 → chave 3</text></svg>", "caption": "Tipo 2: uma linha por versão, e cada venda aponta para a versão vigente na sua data."}
```

Uma venda deste cliente em 15 de março de 2024 apontaria para a chave 2, o *regular*; uma em junho de
2025, para a chave 3, o *patron*. As linhas fato nunca mudam, e o passado mantém a descrição que tinha.

Quantas versões isso dá?

```
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT versions, count(*) AS customers FROM (SELECT customer_id, count(*) AS versions FROM dim_customer WHERE customer_key > 0 GROUP BY customer_id) GROUP BY versions ORDER BY versions"
┌──────────┬───────────┐
│ versions │ customers │
│  int64   │   int64   │
├──────────┼───────────┤
│        1 │     32542 │
│        2 │      5686 │
│        3 │      1694 │
│        4 │        78 │
└──────────┴───────────┘
```

32.542 clientes nunca mudaram nada que se acompanha, e têm uma linha. 5.686 têm duas, 1.694 três, 78
quatro. **A dimensão cresceu de 40.000 linhas para 49.309** (com o membro desconhecido), cerca de um
quarto maior, para guardar dois anos de histórico. É uma proporção típica, e é o principal custo do tipo
2: linhas, e uma junção um pouco mais cuidadosa. A próxima seção é a junção.
