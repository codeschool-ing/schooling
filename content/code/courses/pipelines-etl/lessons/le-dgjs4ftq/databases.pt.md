---
title: Um banco, e o momento em que você o lê
version: 1
---

Um banco de dados é a origem mais amigável: ele responde a qualquer pergunta que o SQL saiba fazer.
**A armadilha é que ele continua mudando enquanto você o lê**, e um pipeline que lê duas tabelas com
dois comandos pode pegar dois momentos diferentes.

A primeira tentativa da Ana lê os pedidos, depois as linhas. Entre as duas, a extração fica lenta por
quatro segundos — uma rede ocupada, uma tabela grande — e o laboratório toca o dia seguinte de vendas
na loja enquanto ela espera:

```
"""Read orders, then their lines, as two separate statements."""
import time

import psycopg

with psycopg.connect("dbname=shop", autocommit=True) as shop:
    orders = shop.execute("SELECT count(*) FROM orders").fetchone()[0]
    time.sleep(4)                      # a slow extraction, or a busy network
    lines = shop.execute("SELECT count(DISTINCT order_id) FROM order_lines").fetchone()[0]
print(f"orders read: {orders}, orders the lines belong to: {lines}")
```

```
ana@vm:~/etl$ python torn.py
orders read: 17453, orders the lines belong to: 17749
```

As linhas pertencem a 296 pedidos que a contagem de pedidos nunca viu. Carregadas juntas, essas
linhas apontariam para pedidos que não estão no warehouse, e todo join de linhas com pedidos as
descartaria em silêncio. **Nada falhou. Cada número está certo para o momento em que foi lido.**
Juntos, estão errados.

## Um momento, de propósito

O PostgreSQL sabe segurar um momento parado. Uma transação em `REPEATABLE READ` tira um snapshot na
primeira consulta, e cada comando dentro dela vê o banco como ele era então, não importa o que seja
confirmado no meio-tempo:

```
"""The same two reads, inside one transaction that sees one moment."""
import time

import psycopg

with psycopg.connect("dbname=shop") as shop:
    shop.execute("SET TRANSACTION ISOLATION LEVEL REPEATABLE READ, READ ONLY")
    orders = shop.execute("SELECT count(*) FROM orders").fetchone()[0]
    time.sleep(4)
    lines = shop.execute("SELECT count(DISTINCT order_id) FROM order_lines").fetchone()[0]
print(f"orders read: {orders}, orders the lines belong to: {lines}")
```

```
ana@vm:~/etl$ python snapshot.py
orders read: 17749, orders the lines belong to: 17749
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l03-torn\" aria-label=\"Uma linha do tempo de quatro segundos. No início, a extração conta os pedidos e obtém 17.453. Um segundo depois, um dia de vendas confirma 296 pedidos novos e as suas linhas. Aos quatro segundos a extração lê as linhas, e elas pertencem a 17.749 pedidos. Embaixo, as mesmas leituras dentro de uma transação REPEATABLE READ veem as duas o momento da primeira consulta.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"st-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><path d=\"M140.0 250.0 L625.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M140.0 246.0 L140.0 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"140.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M257.5 246.0 L257.5 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"257.5\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><path d=\"M375.0 246.0 L375.0 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"375.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><path d=\"M492.5 246.0 L492.5 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"492.5\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><path d=\"M610.0 246.0 L610.0 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"610.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><text x=\"632.0\" y=\"250.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">segundos</text><path d=\"M257.5 30.0 L257.5 232.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M328.0 30.0 L328.0 232.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"292.8\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">um dia de vendas é confirmado</text><text x=\"20.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">dois comandos</text><path d=\"M140.0 80.0 L610.0 80.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"140.0\" cy=\"80.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"140.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">contar pedidos</text><text x=\"140.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">17.453</text><circle cx=\"610.0\" cy=\"80.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"610.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ler linhas</text><text x=\"610.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">17.749</text><text x=\"20.0\" y=\"145.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">uma transação REPEATABLE READ</text><path d=\"M140.0 175.0 L610.0 175.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"140.0\" cy=\"175.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"140.0\" y=\"193.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">contar pedidos</text><text x=\"140.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">17.749</text><circle cx=\"610.0\" cy=\"175.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"610.0\" y=\"193.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ler linhas</text><text x=\"610.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">17.749</text><path d=\"M602.0 171 C 492.5 135, 257.5 135, 148.0 169\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#st-ah-phosphor)\"></path></svg>", "caption": "Cada leitura está certa para o seu próprio momento. O snapshot faz as duas descreverem o mesmo."}
```

Outro dia de vendas caiu durante esses quatro segundos também, e a transação não o viu. As duas
contagens concordam porque descrevem um momento só. **Leia tudo o que uma carga precisa dentro de um
snapshot**, e diga que momento foi — a lição 4 o registra.

O `READ ONLY` está ali como promessa: a extração não consegue escrever na origem nem por engano, e o
PostgreSQL pode pular parte da contabilidade de que uma transação de escrita precisa.

## O que um snapshot longo custa

Um snapshot não é de graça. Enquanto ele está aberto, o PostgreSQL guarda toda versão antiga de toda
linha de que o snapshot ainda possa precisar, então uma transação aberta por horas faz tabelas e
índices crescerem na origem. **Extraia num snapshot, e mantenha-o curto**: minutos, não a noite.
Quando uma leitura completa de uma tabela grande não pode ser curta, ela pertence a uma réplica, que é
o assunto da próxima seção.
