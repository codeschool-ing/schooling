---
title: Explorando em SQL
version: 1
---

A maior parte das perguntas desta aula pode ser feita direto ao banco, e para um primeiro olhar
sobre uma tabela grande muitas vezes ele é o lugar mais rápido: os dados não precisam sair do
servidor.

```
ana@lab:~/clean$ python -c "from explore import delivered as d; print(d.groupby('channel')['total'].agg(['size', 'median', 'mean']).round(2).to_string())"
          size  median   mean
channel                      
app      11851    57.5  89.75
site     14659    57.6  97.55
ana@lab:~/clean$ psql -c "SELECT channel, count(*), percentile_cont(0.5) WITHIN GROUP (ORDER BY total::numeric) AS median, round(avg(total::numeric), 2) AS mean FROM (SELECT DISTINCT * FROM raw.orders) o WHERE status = 'delivered' GROUP BY channel"
 channel | count | median | mean  
---------+-------+--------+-------
 app     | 11851 |   57.5 | 89.89
 site    | 14659 |  57.65 | 97.96
(2 rows)

ana@lab:~/clean$ psql -c "SELECT corr(n.items, o.total::numeric) AS pearson FROM (SELECT DISTINCT * FROM raw.orders) o JOIN (SELECT order_id, count(*) AS items FROM raw.order_items GROUP BY order_id) n USING (order_id) WHERE o.status = 'delivered'"
       pearson       
---------------------
 0.22300728275886306
(1 row)
```

A linha do pandas vem primeiro, dos pedidos limpos, para haver com o que comparar. A consulta em
SQL dá a mesma forma por canal, uma linha para cada; `percentile_cont(0.5) WITHIN GROUP (ORDER BY
...)` é a mediana. Nas duas, as medianas dos dois canais são quase iguais enquanto as médias
diferem em uns R$ 8, que é a cauda longa de novo, sobretudo os dezesseis pedidos corporativos,
todos feitos pelo site.

Mas as duas ferramentas não concordam exatamente: R$ 89,89 contra R$ 89,75 na média do aplicativo,
R$ 57,65 contra R$ 57,60 na mediana do site. Vale entender essa diferença em vez de ignorá-la. Estas consultas leem `raw.orders`, então os sete
totais digitados errado da aula 9 continuam dez vezes maiores e os totais negativos continuam
negativos. **A mediana quase não percebe; a média percebe.** Um primeiro olhar em SQL sobre tabelas brutas
serve para formas e ordens de grandeza, e todo número que vai para um relatório vem dos dados
limpos.

A segunda consulta é a correlação de Pearson, embutida no PostgreSQL como `corr`, entre o número de
itens e o total: 0,223, contra 0,224 do pandas nos totais limpos. O PostgreSQL não tem correlação
de postos embutida. Os postos podem ser calculados com `rank() OVER (ORDER BY ...)` e passados ao
`corr`, que é exatamente o que o pandas fez uma seção atrás.
