---
title: Clustering, e os blocos que um filtro pula
version: 1
---

**O clustering ordena as linhas de cada partição por até quatro colunas, para que um filtro nelas possa
pular blocos de armazenamento.** É a segunda das duas decisões, e a que funciona onde uma partição não
consegue: numa coluna com valores demais para particionar, ou como segundo filtro dentro da partição
que o primeiro escolheu. Os painéis da Quitanda perguntam sobre uma loja num dia. O dia é a partição; a
loja é o cluster.

**O que torna um pulo possível é a mesma coisa que a aula 13 mediu num arquivo Parquet**: para cada bloco
de armazenamento, o menor e o maior valor de uma coluna nele. Se as linhas estão ordenadas por
`store_id`, cada bloco guarda uma faixa estreita de lojas, e um filtro `store_id = 7` lê só os blocos
cuja faixa contém o 7. Se não estão ordenadas, todo bloco guarda toda loja, e o filtro lê todos.

## Os grupos de linhas, nos dois layouts

**Um arquivo Parquet guarda essa faixa para cada grupo de linhas**, e a função `parquet_metadata` do
DuckDB a lê do rodapé do arquivo sem ler uma linha. `orders_by_store` está ordenada por loja dentro de
cada dia, em grupos de 2.048 linhas. Para o último dia dos dados:

```
ana@laptop:~/gcp$ python3 ask.py "SELECT row_group_id, stats_min_value AS min_store, stats_max_value AS max_store FROM parquet_metadata('warehouse/orders_by_store/dt=2026-09-29/*.parquet') WHERE path_in_schema = 'store_id' ORDER BY row_group_id"
┌──────────────┬───────────┬───────────┐
│ row_group_id │ min_store │ max_store │
│    int64     │  varchar  │  varchar  │
├──────────────┼───────────┼───────────┤
│            0 │ 1         │ 3         │
│            1 │ 3         │ 5         │
│            2 │ 5         │ 7         │
│            3 │ 7         │ 9         │
│            4 │ 9         │ 11        │
│            5 │ 11        │ 13        │
│            6 │ 13        │ 15        │
│            7 │ 15        │ 16        │
│            8 │ 1         │ 1         │
└──────────────┴───────────┴───────────┘
```

**Cada grupo guarda duas ou três lojas**, de 1 a 3, de 3 a 5 e assim por diante até 16. O nono grupo, de
1 a 1, são alguns pedidos da loja 1 escritos por uma segunda thread do DuckDB depois das outras, que é
como um escritor paralelo se comporta, e não atrapalha os pulos. A mesma pergunta, feita aos dois
layouts daquele dia:

```
ana@laptop:~/gcp$ python3 ask.py "SELECT CASE WHEN file_name LIKE '%by_store%' THEN 'by store' ELSE 'by time' END AS layout, count(*) AS row_groups, count(*) FILTER (WHERE stats_min_value::INT <= 7 AND stats_max_value::INT >= 7) AS may_hold_store_7 FROM parquet_metadata(['warehouse/orders_by_time/dt=2026-09-29/data_0.parquet', 'warehouse/orders_by_store/dt=2026-09-29/data_0.parquet']) WHERE path_in_schema = 'store_id' GROUP BY layout ORDER BY layout"
┌──────────┬────────────┬──────────────────┐
│  layout  │ row_groups │ may_hold_store_7 │
│ varchar  │   int64    │      int64       │
├──────────┼────────────┼──────────────────┤
│ by store │          9 │                2 │
│ by time  │          9 │                9 │
└──────────┴────────────┴──────────────────┘
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Um dia de pedidos, 2026-09-29, como nove grupos de linhas em dois layouts. Na ordem de chegada, todo grupo guarda as lojas 1 a 16, e os nove podem conter a loja 7, então um filtro na loja 7 lê os nove. Ordenados por loja, os grupos guardam as lojas 1 a 3, 3 a 5, 5 a 7, 7 a 9, 9 a 11, 11 a 13, 13 a 15, 15 a 16 e 1 a 1; só dois, 5 a 7 e 7 a 9, podem conter a loja 7, e o filtro lê esses dois.\" data-fig=\"l15-groups\"><text x=\"20\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">store_id = 7, em 2026-09-29</text><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">na ordem de chegada: 9 de 9 lidos</text><rect x=\"20\" y=\"52\" width=\"68\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"54\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1–16</text><rect x=\"96\" y=\"52\" width=\"68\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1–16</text><rect x=\"172\" y=\"52\" width=\"68\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"206\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1–16</text><rect x=\"248\" y=\"52\" width=\"68\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"282\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1–16</text><rect x=\"324\" y=\"52\" width=\"68\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"358\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1–16</text><rect x=\"400\" y=\"52\" width=\"68\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"434\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1–16</text><rect x=\"476\" y=\"52\" width=\"68\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"510\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1–16</text><rect x=\"552\" y=\"52\" width=\"68\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"586\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1–16</text><rect x=\"628\" y=\"52\" width=\"68\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"662\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2–16</text><text x=\"20\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">ordenados por loja: 2 de 9 lidos</text><rect x=\"20\" y=\"132\" width=\"68\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"54\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1–3</text><rect x=\"96\" y=\"132\" width=\"68\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"130\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3–5</text><rect x=\"172\" y=\"132\" width=\"68\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"206\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5–7</text><rect x=\"248\" y=\"132\" width=\"68\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"282\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">7–9</text><rect x=\"324\" y=\"132\" width=\"68\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"358\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">9–11</text><rect x=\"400\" y=\"132\" width=\"68\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"434\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">11–13</text><rect x=\"476\" y=\"132\" width=\"68\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"510\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">13–15</text><rect x=\"552\" y=\"132\" width=\"68\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"586\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">15–16</text><rect x=\"628\" y=\"132\" width=\"68\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"662\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1–1</text></svg>", "caption": "A faixa de lojas de cada grupo de linhas, pelas estatísticas dos próprios arquivos: ordenados, um filtro numa loja lê dois grupos de nove; na ordem de chegada, lê todos."}
```

**Ordenados por loja, dois dos nove grupos podiam conter a loja 7; na ordem de chegada, todos os nove
podiam.** Um filtro `store_id = 7` lê dois nonos das linhas do dia num layout e o dia inteiro no outro,
pelas mesmas linhas e os mesmos tamanhos de arquivo. Isso é clustering, medido nos grupos de linhas do
Parquet. Os blocos do BigQuery são dele e não são grupos de linhas do Parquet, então dois nonos é uma
ilustração do efeito e não o número do BigQuery para esta tabela.

## Clustering no BigQuery

**Uma tabela cita até quatro colunas de clustering, e a ordem delas importa.** `CLUSTER BY store_id` no
DDL da primeira seção é uma; `CLUSTER BY store_id, payment` ordenaria por loja primeiro e por pagamento
dentro de cada loja. Como numa chave de ordenação composta, um filtro na primeira coluna pula mais, um
filtro na segunda só pula dentro de cada valor da primeira, e um filtro só na segunda pula pouco. As
colunas têm de ser de primeiro nível e dos tipos que a documentação do Google lista, que incluem
`STRING`, `INT64`, `DATE`, `TIMESTAMP` e `BOOL`.

**O BigQuery mantém a tabela ordenada sozinho, sem custo.** Conforme linhas novas chegam, uma carga
noturna acrescenta blocos ordenados entre si mas não com os antigos, e a documentação descreve a
reclusterização automática, feita em segundo plano sem usar os slots nem os bytes do projeto. Ninguém a
agenda e ninguém paga por ela, o que é uma diferença em relação a warehouses em que reordenar uma
tabela é um job que alguém lembra de rodar.

**O clustering não aparece no dry run.** A página de preços diz que uma consulta "that includes a filter
on the clustered columns" poda blocos "and can reduce the number of scanned bytes", e a documentação do
Google sobre tabelas clusterizadas acrescenta o porém: os bytes que o dry run estima são um limite
superior, calculado antes de qualquer bloco ser pulado, e a conta depois costuma ser menor. Um filtro de
partição é conhecido antes de a consulta rodar; um pulo de cluster só é conhecido enquanto ela roda.
Então **o particionamento é a economia que dá para prometer e o clustering é a economia que aparece na
conta.**

## Por quais colunas clusterizar

**Pelas colunas pelas quais as consultas filtram, na ordem de quantas vezes filtram**, depois que a
coluna de particionamento ficou com a primeira. Na Quitanda isso é `store_id`, e depois talvez
`payment`. Uma coluna com poucos valores, como `payment` com três, se ordena em sequências longas e pula
bem; uma com um valor por linha, como `order_id`, se ordena em sequências curtas que um filtro de um
pedido pula quase por inteiro e das quais um filtro em qualquer outra coisa não ganha nada. Clusterizar
por uma coluna pela qual ninguém filtra não custa nada na conta, e também não compra nada.
