---
title: O número do pedido, uma dimensão sem tabela
version: 1
---

`fact_sales` guarda `order_id`, e nenhuma tabela dimensão vem com ele.

```
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT count(*) AS lines, count(DISTINCT order_id) AS orders FROM fact_sales"
┌────────┬────────┐
│ lines  │ orders │
│ int64  │ int64  │
├────────┼────────┤
│ 887477 │ 572439 │
└────────┴────────┘
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT f.line_no, b.title, f.quantity, f.net_cents FROM fact_sales f JOIN dim_book b USING (book_key) WHERE f.order_id = 112406 ORDER BY f.line_no"
┌─────────┬──────────────────────┬──────────┬───────────┐
│ line_no │        title         │ quantity │ net_cents │
│  int64  │       varchar        │  int64   │   int64   │
├─────────┼──────────────────────┼──────────┼───────────┤
│       1 │ The Paper River VI   │        1 │      3290 │
│       2 │ The Bright River     │        1 │      2990 │
│       3 │ The Broken House III │        1 │      6890 │
└─────────┴──────────────────────┴──────────┴───────────┘
```

887.477 itens de 572.439 pedidos. Tudo o que há a dizer sobre um pedido já está dito pelas outras
chaves dos seus itens: a data, a loja, o cliente, a promoção. Uma `dim_order` seria uma tabela de
572.439 linhas sem nada além do número do pedido, ou seja, uma tabela que não descreve nada. Então o
número fica na linha fato e não aponta para lugar nenhum.

Kimball chama isso de **dimensão degenerada**: uma chave de dimensão sem dimensão por trás. Ela merece
a sua coluna por três motivos:

- **Ela agrupa os itens.** "Pedidos com mais de três livros" e "média de livros por pedido" são
  perguntas sobre o pedido, respondidas agrupando pelo número dele.
- **É o caminho de volta.** Quando um total parece errado, alguém precisa achar os cupons por trás
  dele, e o número do pedido é o que o caixa imprimiu neles.
- **É a chave para outras granularidades.** A seção 05 somou vendas e pagamentos por pedido. Sem o
  número do pedido nas duas, não haveria por onde somar.

O mesmo raciocínio vale para números de nota fiscal, de chamado e ids de transação: identificadores
do próprio evento, guardados na linha fato porque o evento não tem descrição além do que o fato já
carrega.
