---
title: A mesma categoria em dois sistemas
version: 1
---

**Quando dois sistemas registram a mesma coisa, cada um com o seu vocabulário, uma tabela de
mapeamento é também o jeito de juntá-los.** As formas de pagamento são o exemplo: o site e o
aplicativo escrevem códigos em inglês, o caixa das lojas escreve palavras em português, e ninguém
escolheu nenhum dos dois para combinar com o outro.

```
ana@lab:~/clean$ psql -c 'SELECT payment, count(*) FROM raw.orders GROUP BY 1 ORDER BY 2 DESC'
 payment | count 
---------+-------
 card    | 15767
 pix     | 11365
 boleto  |  1419
(3 rows)

ana@lab:~/clean$ psql -c 'SELECT pagamento, count(*) FROM raw.store_sales GROUP BY 1 ORDER BY 2 DESC'
 pagamento | count 
-----------+-------
 Cartão    | 10654
 Pix       |  5871
 Dinheiro  |  2367
 PIX       |  2319
 pix       |  1203
 cartao    |  1180
(6 rows)
```

Três formas online; seis grafias de três formas nas lojas. Dinheiro só existe nas lojas e boleto só
online. **Somar as duas colunas como estão produziria nove formas de pagamento para quatro.**

A tabela para isso tem uma coluna a mais que o mapa de categorias, porque a mesma palavra bruta pode
querer dizer coisas diferentes em sistemas diferentes — `pix` por acaso concorda aqui, mas nada
garante que o `card` do próximo sistema queira dizer o mesmo que o do site:

```
source,raw,method
online,card,card
online,pix,pix
online,boleto,boleto
store,Cartão,card
store,cartao,card
store,Pix,pix
store,PIX,pix
store,pix,pix
store,Dinheiro,cash
```

**A chave é o par `(source, raw)`**, nunca o valor bruto sozinho. Aplicada a todo pedido online e a
toda venda das lojas, dá um vocabulário só para os dois canais:

```
ana@lab:~/clean$ psql -c "SELECT m.method, sum(CASE WHEN s.source = 'store' THEN 1 ELSE 0 END) AS store, sum(CASE WHEN s.source = 'online' THEN 1 ELSE 0 END) AS online FROM (SELECT 'store' AS source, pagamento AS raw FROM raw.store_sales UNION ALL SELECT 'online', payment FROM (SELECT DISTINCT * FROM raw.orders) o) s LEFT JOIN payment_map m USING (source, raw) GROUP BY 1 ORDER BY 1"
 method | store | online 
--------+-------+--------
 boleto |     0 |   1419
 card   | 11834 |  15754
 cash   |  2367 |      0
 pix    |  9393 |  11353
(4 rows)
```

Agora os dois canais se comparam: o Pix tem 9.393 vendas nas lojas contra 11.353 online, o dinheiro
só existe no balcão, e o negócio pode perguntar se quem paga boleto pagaria com Pix numa loja. Nenhuma
dessas perguntas se faria a nove rótulos.
