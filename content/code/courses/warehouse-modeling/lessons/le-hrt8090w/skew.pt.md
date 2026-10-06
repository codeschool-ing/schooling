---
title: Desequilíbrio, quando uma máquina fica com metade do trabalho
version: 1
---

Suponha que o cluster tivesse sete nós e cada loja ganhasse o seu. Cada nó teria uma loja, o que parece
equilibrado. Não é, porque as lojas não são:

```
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT s.shop_name, count(*) AS rows, round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS pct FROM fact_sales f JOIN dim_shop s USING (shop_key) GROUP BY ALL ORDER BY rows DESC LIMIT 2"
┌───────────┬────────┬────────┐
│ shop_name │  rows  │  pct   │
│  varchar  │ int64  │ double │
├───────────┼────────┼────────┤
│ Online    │ 378374 │   42.6 │
│ Paulista  │ 147474 │   16.6 │
└───────────┴────────┴────────┘
```

**O site tem 42,6% de todos os itens de venda.** O nó dele faria 42,6% do trabalho de cada consulta,
enquanto o nó da Moinhos faria uns poucos por cento. Com sete nós, uma consulta que poderia terminar num
sétimo do tempo leva quase metade dele, porque o nó do site termina por último e todos esperam.

Isso é **desequilíbrio** (skew): trabalho espalhado de forma desigual entre os nós, de modo que
acrescentar nós para de ajudar. Ele vem de dois lugares, e só o primeiro é visível com antecedência:

- **Chaves desequilibradas.** Uma chave de distribuição com poucos valores, ou com valores de pesos muito
  diferentes. Lojas, países, uma coluna de cliente em que um atacadista tem um terço dos pedidos, ou uma
  coluna em que a maioria das linhas está vazia e todo valor vazio vai para o mesmo nó.
- **Consultas desequilibradas.** Uma chave que espalha as linhas por igual ainda pode espalhar o
  *trabalho* de forma desigual, se toda consulta filtra os mesmos poucos valores. Espalhados por data, os
  dados ficam equilibrados; mas se todos perguntam sobre a última semana, os nós com a última semana fazem
  todo o trabalho.

Como detectar: produtos MPP informam linhas por nó de uma tabela e tempo por nó de uma consulta, e a view
`SVV_TABLE_INFO` do Redshift tem uma coluna `skew_rows` exatamente para isso. **A razão entre o nó mais
cheio e a média é o número a observar.** Uma razão perto de 1 é saudável. O arranjo por número de pedido
da seção anterior tem razão 1,002; o arranjo por loja, 643.004 contra uma média de 221.869, tem 2,9.
