---
title: Fatos que apontam para a versão certa
version: 1
---

Uma dimensão de tipo 2 é inútil se os fatos não apontarem para a versão certa dela, e esse é o
trabalho da **chave substituta**: `customer_key`, gerada pelo warehouse, uma por versão. O
`customer_id` diz *qual cliente*; o `customer_key` diz *qual cliente, morando onde, no momento da
venda*.

A carga de fatos a encontra com um join que é tanto sobre tempo quanto sobre identidade — a versão
cujo `valid_from` está no momento do pedido ou antes, e cujo `valid_to` está depois dele ou aberto:

```sql
  LEFT JOIN marts.dim_customer d
         ON d.customer_id = o.customer_id
        AND o.ordered_at >= d.valid_from
        AND (o.ordered_at < d.valid_to OR d.valid_to IS NULL)
```

O cliente 3145 comprou um livro em 11 de março, antes da mudança:

```
ana@vm:~/etl$ psql -d wh -c "SELECT f.order_date, f.order_id, d.city FROM marts.fact_sales f JOIN marts.dim_customer d USING (customer_key) WHERE d.customer_id = 3145 ORDER BY f.order_date"
 order_date | order_id |   city    
------------+----------+-----------
 2026-03-11 |   119940 | São Paulo
(1 row)
```

A venda é em São Paulo, e vai continuar em São Paulo no ano que vem, faça o cliente o que fizer.
**Esse é todo o ponto do tipo 2, e só funciona porque a chave foi procurada na noite em que o fato foi
carregado**, enquanto a versão que valia então era a atual. Recarregar o dia 11 de março hoje acharia
a mesma versão, pelo mesmo `valid_from` e `valid_to` — e é por isso que o join é pelo tempo e não pelo
`is_current`.

## Os fatos sem cliente

```
ana@vm:~/etl$ psql -d wh -c "SELECT count(*) FROM marts.dim_customer WHERE customer_id = 1880"
 count 
-------
     0
(1 row)

ana@vm:~/etl$ psql -d wh -c "SELECT customer_key = -1 AS unknown, count(*) FROM marts.fact_sales GROUP BY 1"
 unknown | count 
---------+-------
 f       |  4537
 t       |  1890
(2 rows)
```

Quase um terço das linhas de pedido tem `customer_key = -1`: nenhum cliente que o warehouse saiba
nomear. Dois tipos de venda vão parar lá, por motivos diferentes:

- vendas anônimas — um cliente no caixa que não deu nome. A loja tem `NULL`, e o warehouse não
  tem para quem apontar;
- vendas de clientes que pediram para ser apagados. A loja pôs o `customer_id` dos pedidos deles
  em `NULL`, e a carga da dimensão apagou todas as versões deles: o cliente 1880 não tem mais linha
  nenhuma.

**`-1` é um valor, não um `NULL`, de propósito.** Um relatório que junta fatos com clientes por um
inner join descarta em silêncio todo fato cuja chave é `NULL`, e quase um terço das linhas vai junto. Com `-1` e
uma linha na dimensão que case com ele — "cliente desconhecido" — o join guarda as vendas e as rotula
com honestidade. `warehouse-modeling` chama essa linha de membro desconhecido; é na carga que ela
mostra o seu valor.

O apagamento é a mesma decisão que a lição 2 tomou para os e-mails, uma camada acima: a loja esqueceu
o cliente, então o warehouse precisa esquecer também. **Histórico numa dimensão de tipo 2 não é motivo
para guardar uma pessoa que a lei manda apagar.** As vendas dela ficam, ligadas a ninguém.
