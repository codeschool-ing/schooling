---
title: let, join e parse
version: 1
---

**`let` dá nome a algo para o resto da consulta, e `join` junta duas tabelas por uma coluna que elas têm em comum.** As
rotas da loja pertencem a equipes, e esse mapa não está nos logs. Uma tabela pequena escrita na própria consulta com
`datatable` o fornece:

```kql
// owners.kql: which team answers for each route's failures this week
let owners = datatable(Name: string, Team: string) [
    "GET /products", "catalogue",
    "GET /cart", "basket",
    "POST /cart", "basket",
    "POST /checkout", "payments"
];
AppRequests
| where not(Success)
| summarize failed = count() by Name
| join kind=leftouter owners on Name
| project Team, Name, failed
| order by failed desc
```

```

```

`kind=leftouter` mantém toda rota do lado esquerdo mesmo que o direito não tenha dono para ela, e é o tipo a usar quando
o lado direito é uma tabela de consulta: uma rota que alguém esqueceu de acrescentar apareceria com equipe vazia, em vez
de sumir da resposta. O tipo de join padrão no KQL não é o inner join que a maioria espera; ele remove chaves duplicadas
do lado esquerdo antes. **Diga o tipo sempre.**

Na semana inteira, catalogue tem mais falhas, 135, e payments 130. Esse é o número que um relatório semanal mostraria, e
ele diz que catalogue teve a semana pior. A seção anterior diz o contrário: quase todas as falhas de payments caíram numa
janela de 42 minutos, enquanto as de catalogue se espalharam ralas por sete dias. **Um total responde "quantas", nunca
"quão grave".**

## parse

O `parse` corta uma string em colunas por um padrão, e é assim que um campo escrito como texto vira algo por que agrupar.
Os nomes das rotas trazem um método e um caminho:

```
ana@laptop:~/azure/kusto$ python3 kql.py 'AppRequests | parse Name with Method " " Path | summarize requests = count() by Method'
Method  requests
GET     187271
POST    62446
```

O padrão se lê como a string aparece: o que vem antes de um espaço vai para `Method`, o resto para `Path`. Três
requisições em quatro foram leituras. Em logs reais, o `parse` é o que transforma uma mensagem como
`order 1042 failed after 3 retries` num número de pedido e numa contagem, e o `parse_json()` faz o mesmo com um campo que
guarda JSON.
