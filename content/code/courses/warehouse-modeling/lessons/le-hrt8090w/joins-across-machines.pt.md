---
title: Junções quando as linhas moram longe
version: 1
---

Uma junção de duas linhas só acontece num nó que tenha as duas. Num sistema MPP cada tabela é espalhada
pela sua própria chave, então os dois lados de uma junção costumam estar em nós diferentes, e um deles
precisa se mover. Há três jeitos de fazer isso, e o planejador escolhe um por junção.

**Co-localizado: nada se move.** Se as duas tabelas são espalhadas pela chave da junção, as linhas
correspondentes já estão no mesmo nó. Vendas e pagamentos, ambos espalhados por `order_id`, podem ser
ligados por `order_id` sem tráfego de rede nenhum.

**Broadcast: o lado pequeno é copiado para todos.** Uma dimensão de alguns milhares de linhas é mandada
inteira a cada nó, e cada nó liga a sua parte da tabela fato à sua própria cópia.

**Shuffle: os dois lados são reespalhados pela chave da junção.** Cada linha recebe um novo hash pela
chave da junção e é mandada ao nó a que essa chave pertence. Caro, porque a maioria das linhas se move.

Aqui está a aritmética para ligar vendas, espalhadas por pedido, a livros, espalhados por livro, em quatro
nós:

```sql
-- Sales are spread by order. To join them with books spread by book, how
-- many rows would have to move? And to copy the whole book table to every
-- machine instead?
SELECT count(*) FILTER (WHERE hash(order_id) % 4 <> hash(book_key) % 4) AS sales_rows_moved,
       count(*)                                                          AS sales_rows,
       (SELECT count(*) * 3 FROM dim_book)                               AS book_rows_copied
FROM fact_sales;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < movement.sql
┌──────────────────┬────────────┬──────────────────┐
│ sales_rows_moved │ sales_rows │ book_rows_copied │
│      int64       │   int64    │      int64       │
├──────────────────┼────────────┼──────────────────┤
│           666023 │     887477 │             9000 │
└──────────────────┴────────────┴──────────────────┘
```

**Reespalhar as vendas por livro moveria 666.023 de 887.477 linhas, três quartos da tabela.** É o que a
distribuição aleatória em quatro nós prevê: uma linha fica onde está uma vez em quatro. **Fazer broadcast
da tabela de livros move 9.000 linhas**: 3.000 livros, copiados para os três nós que ainda não os têm.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Três jeitos de um sistema MPP ligar vendas a livros em quatro nós, com as linhas que cada um move neste laboratório. Co-localizado: as duas tabelas espalhadas pela chave da junção, nada se move. Broadcast: a tabela de livros, de 3.000 linhas, copiada para os outros três nós, 9.000 linhas movidas. Shuffle: as vendas reespalhadas por livro, 666.023 de 887.477 linhas movidas.\"><rect x=\"20\" y=\"30\" width=\"215\" height=\"180\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"127\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">co-localizado</text><text x=\"127\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">as duas espalhadas pela chave</text><rect x=\"40\" y=\"105\" width=\"36\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"86\" y=\"105\" width=\"36\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"132\" y=\"105\" width=\"36\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"178\" y=\"105\" width=\"36\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"127\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">0 linhas se movem</text><rect x=\"255\" y=\"30\" width=\"215\" height=\"180\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"362\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">broadcast</text><text x=\"362\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a tabela pequena copiada a todos</text><rect x=\"275\" y=\"105\" width=\"36\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"321\" y=\"105\" width=\"36\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"367\" y=\"105\" width=\"36\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"413\" y=\"105\" width=\"36\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><line x1=\"293\" y1=\"130\" x2=\"339\" y2=\"130\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></line><line x1=\"293\" y1=\"130\" x2=\"385\" y2=\"130\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></line><line x1=\"293\" y1=\"130\" x2=\"431\" y2=\"130\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></line><text x=\"362\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">9.000 linhas se movem</text><rect x=\"490\" y=\"30\" width=\"215\" height=\"180\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"597\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">shuffle</text><text x=\"597\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a tabela grande reespalhada</text><rect x=\"510\" y=\"105\" width=\"36\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"556\" y=\"105\" width=\"36\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"602\" y=\"105\" width=\"36\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"648\" y=\"105\" width=\"36\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><line x1=\"528\" y1=\"120\" x2=\"574\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"1\"></line><line x1=\"574\" y1=\"120\" x2=\"620\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"1\"></line><line x1=\"620\" y1=\"120\" x2=\"666\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"1\"></line><line x1=\"666\" y1=\"120\" x2=\"528\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"1\"></line><text x=\"597\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">666.023 linhas se movem</text></svg>", "caption": "Co-localizado, broadcast e shuffle, com as linhas que cada um moveria entre quatro nós aqui.", "same": ["broadcast", "shuffle"]}
```

Essa diferença é o motivo de o esquema estrela combinar tão bem com MPP:

- **A tabela fato é espalhada por uma chave com muitos valores**, para partes iguais.
- **As dimensões são pequenas e vão por broadcast**, ou simplesmente ficam como cópia inteira em cada nó
  desde o começo. O Redshift chama isso de `DISTSTYLE ALL`.
- **Junções entre duas tabelas grandes são o caso caro**, e o lugar onde gastar a chave de distribuição:
  espalhe as duas pela chave que as liga, e elas ficam co-localizadas.
