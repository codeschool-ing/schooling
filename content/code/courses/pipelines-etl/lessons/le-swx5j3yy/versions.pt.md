---
title: Muitas versões, uma linha
version: 1
---

Uma extração incremental não entrega uma tabela. **Ela entrega um fluxo de versões**: toda vez que
uma linha muda, chega uma cópia nova dela com um `updated_at` novo. A tabela crua da Ana guarda todas,
acrescentadas, nunca atualizadas:

```
ana@vm:~/etl$ psql -d wh -c "SELECT order_id, status, updated_at, extracted_at FROM raw.orders_changes WHERE order_id IN (SELECT order_id FROM raw.orders_changes GROUP BY order_id HAVING count(*) > 1) ORDER BY order_id, updated_at LIMIT 4"
 order_id |  status   |       updated_at       |         extracted_at          
----------+-----------+------------------------+-------------------------------
   113697 | completed | 2026-02-17 19:27:23-03 | 2026-10-07 05:25:18.487912-03
   113697 | refunded  | 2026-03-03 17:17:14-03 | 2026-10-07 05:25:21.119214-03
   114178 | completed | 2026-02-19 15:57:06-03 | 2026-10-07 05:25:18.487912-03
   114178 | refunded  | 2026-03-03 10:34:33-03 | 2026-10-07 05:25:21.119214-03
(4 rows)
```

O pedido 113697 foi feito em 17 de fevereiro e estornado em 3 de março. A extração da primeira noite
o carregou como concluído; a da terceira noite o carregou de novo como estornado. **As duas linhas
são verdadeiras**: cada uma é o que a loja dizia no momento em que foi lida, e a coluna
`extracted_at` registra esse momento — no relógio da própria máquina, que está em outubro, enquanto
os dados da loja vivem em março.

Guardar cada versão é a camada crua fazendo o seu trabalho da lição 2: o histórico do que foi visto
está lá para uma auditoria, uma depuração ou a correção de um bug. Mas a maioria de quem lê quer uma
linha por pedido, a mais recente, e isso é uma consulta:

```
-- The latest version of each order the extraction has seen.
CREATE OR REPLACE VIEW raw.orders_latest AS
SELECT DISTINCT ON (order_id) *
  FROM raw.orders_changes
 ORDER BY order_id, updated_at DESC, extracted_at DESC;
```

O `DISTINCT ON (order_id)` guarda a primeira linha de cada pedido na ordem que o `ORDER BY` dá —
o `updated_at` mais novo primeiro e, se o retrocesso entregou a mesma versão duas vezes, a extraída
por último. Comparando com a loja:

```
ana@vm:~/etl$ psql -q -d wh -f latest.sql
ana@vm:~/etl$ psql -d wh -c "SELECT (SELECT count(*) FROM raw.orders_changes) AS versions, (SELECT count(*) FROM raw.orders_latest) AS orders"
 versions | orders 
----------+--------
    17757 |  17749
(1 row)

ana@vm:~/etl$ psql -c "SELECT count(*) AS orders FROM orders WHERE updated_at <= '2026-03-03 23:59:59-03'"
 orders 
--------
  17750
(1 row)
```

Dezessete mil setecentas e cinquenta e sete versões viram 17.749 pedidos. A loja tem 17.750 pedidos
atualizados até o fim de 3 de março. **O que falta é o 900001**, o pedido do caixa lento: esta view
é montada sobre a extração sem retrocesso, e essa extração nunca o viu. Uma contagem comparada com
a origem é a verificação mais barata que existe, e ela acabou de achar o bug que a seção anterior
descreveu.

## Uma view, não uma tabela

`raw.orders_latest` é uma view, então é recalculada toda vez que é lida e nunca fica desatualizada em
relação às versões por baixo dela. Quando isso ficar lento, o estado mais recente passa a ser
guardado numa tabela que cada carga atualiza por chave — um *upsert*, que é o assunto da lição 7,
junto com a dimensão que muda devagar, que guarda as versões de propósito.
