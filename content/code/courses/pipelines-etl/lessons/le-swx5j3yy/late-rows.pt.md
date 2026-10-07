---
title: A linha que chega no passado
version: 1
---

A marca d'água tem uma armadilha, e é ela que faz as pessoas desconfiarem de cargas incrementais.

O `updated_at` é preenchido quando uma linha é *escrita*. A linha fica visível quando a sua transação
é *confirmada*. São dois momentos diferentes, e uma transação longa pode pôr minutos entre eles.
**Uma linha escrita antes da marca d'água e confirmada depois que a extração rodou cai numa janela
que o pipeline nunca mais vai pedir.**

O laboratório encena uma. Na loja da Paulista em 2 de março, uma maquininha de cartão trava às 23:40
com a transação aberta; o pedido é confirmado depois de a extração daquela noite ter lido até
23:59:47. O que o caixa deixa na loja é um pedido cujos horários dizem 23:40:

```
ana@vm:~/etl$ psql -c "SELECT order_id, ordered_at, updated_at FROM orders WHERE order_id = 900001"
 order_id |       ordered_at       |       updated_at       
----------+------------------------+------------------------
   900001 | 2026-03-02 23:40:00-03 | 2026-03-02 23:40:00-03
(1 row)

ana@vm:~/etl$ sudo bash ~/lab/lab.sh day 2026-03-03
ana@vm:~/etl$ python incremental.py orders
shop.orders: 301 rows since 03-02 23:59:47, watermark now 03-03 23:51:38
ana@vm:~/etl$ python incremental.py orders 60
shop.orders+60m: 306 rows since 03-02 23:59:47, watermark now 03-03 23:51:38
ana@vm:~/etl$ psql -d wh -c "SELECT 'no lookback' AS run, count(*) FROM raw.orders_changes WHERE order_id = 900001 UNION ALL SELECT '60 minutes', count(*) FROM raw.orders_changes_60m WHERE order_id = 900001"
     run     | count 
-------------+-------
 no lookback |     0
 60 minutes  |     1
(2 rows)
```

A extração simples da noite de 3 de março pede tudo depois de 23:59:47 do dia 2, e o pedido 900001
não está acima disso. A contagem no fim diz o resto: **o warehouse nunca vai ter este pedido**, e
nada avisou coisa nenhuma.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l04-late\" aria-label=\"O pedido 900001 numa linha do tempo. O updated_at dele é 23:40 de 2 de março, mas a transação é confirmada depois de a extração da noite ter lido até 23:59:47. A noite seguinte lê só o que está acima de 23:59:47, então o pedido cai num vão que nenhuma noite lê. Um retrocesso de sessenta minutos começa a próxima janela em 22:59:47 e o cobre.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M30.0 120.0 L690.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M420.0 40.0 L420.0 200.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"420.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">marca d'água 23:59:47</text><circle cx=\"280.0\" cy=\"120.0\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"270.0\" y=\"102.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">escrito: updated_at 23:40</text><path d=\"M286.0 112 C 360.0 50, 480.0 50, 526.0 111\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#st-ah-paper-dim)\"></path><circle cx=\"530.0\" cy=\"120.0\" r=\"6\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\"></circle><text x=\"530.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">confirmado, depois da extração</text><rect x=\"420.0\" y=\"156.0\" width=\"220.0\" height=\"20.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"530.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a noite 3 lê a partir daqui</text><rect x=\"260.0\" y=\"194.0\" width=\"380.0\" height=\"20.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"450.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">com retrocesso de 60 minutos</text><text x=\"280.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">lido por nenhuma noite</text></svg>", "caption": "Uma linha fica visível quando é confirmada, mas carrega o horário em que foi escrita. Reler o fim da última janela é o que a pega."}
```

## Ler de novo um pouco do passado

A segunda extração, a que tem `60` na linha de comando, não confia na borda da própria janela. Ela
pede tudo acima de *a marca d'água menos sessenta minutos*, então cada noite relê a última hora da
noite anterior. Em 3 de março essa hora continha o pedido do caixa lento, e a cópia com retrocesso o
tem.

O preço são linhas lidas duas vezes:

```
ana@vm:~/etl$ psql -d wh -c "SELECT count(*) AS rows, count(DISTINCT (order_id, updated_at)) AS versions FROM raw.orders_changes_60m"
 rows  | versions 
-------+----------
 17766 |    17758
(1 row)
```

Oito linhas foram carregadas duas vezes ao longo das três noites — a última hora de cada noite, lida
de novo na seguinte. **Um retrocesso aceita duplicatas em troca de completude, e as duplicatas são a
metade fácil**: uma versão de uma linha é identificada pela chave e pelo `updated_at`, e a próxima seção
transforma muitas versões numa só. Uma linha perdida não tem esse remédio.

Quanto retroceder é um juízo sobre a origem: o tempo mais longo que uma transação pode ficar aberta
lá, com folga. Se os caixas da loja desistem de um pagamento depois de alguns minutos, uma hora é
generosa. Uma origem que roda jobs em lote de uma hora precisa de mais. Alguns bancos oferecem uma
resposta exata — o PostgreSQL sabe informar a transação mais antiga ainda em andamento — e a lição 5
evita a pergunta inteira lendo as mudanças na ordem de confirmação, a partir do próprio log do banco.
