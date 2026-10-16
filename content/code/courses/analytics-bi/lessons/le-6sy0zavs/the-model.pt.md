---
title: O modelo: a estrela da aula 3, desenhada no Power BI
version: 1
---

Com os cinco arquivos carregados, a **exibição de modelo** do Power BI os mostra como cinco caixas, e
o modelo é o que você desenha entre elas. Cada linha é um **relacionamento**: uma coluna de uma
tabela que corresponde a uma coluna de outra, para que um filtro numa chegue à outra.

Os relacionamentos são exatamente os joins da estrela da aula 3:

| de (lado muitos) | para (lado um) | por |
|---|---|---|
| `orders` | `customers` | `customer_id` |
| `orders` | `calendar` | `order_date` = `day` |
| `order_lines` | `orders` | `order_id` |
| `order_lines` | `products` | `product_id` |

O Power BI muitas vezes propõe relacionamentos sozinho, casando nomes de colunas. Confira cada um que
ele propuser contra esta tabela, e apague os que ele inventou: um relacionamento adivinhado por um
nome é um join que ninguém decidiu.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"pbi-model\" aria-label=\"O modelo como o Power BI o desenha: cinco tabelas ligadas por quatro relacionamentos. Customers e calendar se ligam a orders; orders se liga a order lines; products se liga a order lines. Todo relacionamento é muitos para um, com o lado um na dimensão ou em orders. Uma seta em cada linha mostra a direção única do filtro, do lado um para o lado muitos: de customers e calendar para orders, de orders para order lines, de products para order lines. Nenhuma seta volta de order lines para orders.\"><defs><marker id=\"pbi-model-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"140\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">customers</text><rect x=\"20\" y=\"200\" width=\"140\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">calendar</text><rect x=\"290\" y=\"120\" width=\"140\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">orders</text><rect x=\"560\" y=\"40\" width=\"140\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"630\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">order_lines</text><rect x=\"560\" y=\"210\" width=\"140\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"630\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">products</text><line x1=\"160\" y1=\"70\" x2=\"288\" y2=\"132\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#pbi-model-ah)\"></line><text x=\"168\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">1</text><text x=\"276\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">*</text><line x1=\"160\" y1=\"214\" x2=\"288\" y2=\"154\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#pbi-model-ah)\"></line><text x=\"168\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">1</text><text x=\"276\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">*</text><line x1=\"430\" y1=\"132\" x2=\"558\" y2=\"70\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#pbi-model-ah)\"></line><text x=\"438\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">1</text><text x=\"546\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">*</text><line x1=\"630\" y1=\"210\" x2=\"630\" y2=\"86\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#pbi-model-ah)\"></line><text x=\"642\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">1</text><text x=\"642\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">*</text><text x=\"360\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\" font-style=\"italic\">um filtro anda para onde as setas apontam, e não além</text></svg>", "caption": "Muitos para um, direção única: um filtro em products chega a order lines e para ali."}
```

Cada relacionamento tem duas propriedades que importam:

- **Cardinalidade.** Todo relacionamento aqui é **muitos para um**: muitos pedidos por cliente, um
  cliente por pedido. É a regra da estrela — uma dimensão tem uma linha por chave — escrita como
  configuração. O Power BI mostra o lado "um" com um `1` e o lado muitos com um asterisco.
- **Direção do filtro cruzado.** Para que lado um filtro anda pela linha. O padrão aqui é **única**:
  do lado um para o lado muitos, de `customers` para `orders`. Um filtro de região filtra os pedidos;
  um filtro nos pedidos não filtra os clientes. Uma seção mais adiante nesta aula mostra o que esse
  padrão protege, e o que ele custa.

## A calendar é uma tabela de datas

As funções de tempo do Power BI, usadas mais adiante nesta aula, precisam de uma tabela com uma linha
por dia e sem buracos, **marcada** como tabela de datas do modelo (*Marcar como tabela de datas*,
escolhendo `day`). A `calendar` da camada foi feita exatamente para isso: o `generate_series` dá
todo dia de janeiro de 2025 a junho de 2026, sem buraco nem mesmo em 14 de agosto de 2025, o dia sem
pedidos. Isso importa mais do que parece: uma calendar feita das datas que aparecem em `orders`
ficaria sem esse dia, e um total acumulado passaria por cima dele em silêncio.
