---
title: A carga incremental
version: 1
---

**Uma extração incremental lê só as linhas que mudaram desde a última execução.** Ela precisa que a
origem diga quando cada linha mudou, e a loja diz: toda tabela tem `updated_at`, que os caixas e o
escritório preenchem sempre que escrevem uma linha. Uma venda o preenche quando o pedido é feito; um
estorno o preenche de novo quando o status muda.

Então a pergunta de cada noite vira: *quais linhas têm um `updated_at` mais recente que a última vez
que eu olhei?* Na primeira noite não houve última vez, e vem tudo:

```
ana@vm:~/etl$ python incremental.py customers
shop.customers: 5098 rows, the first run, watermark now 03-01 22:21:41
ana@vm:~/etl$ python incremental.py orders
shop.orders: 17195 rows, the first run, watermark now 03-01 23:50:30
ana@vm:~/etl$ python incremental.py orders 60
shop.orders+60m: 17195 rows, the first run, watermark now 03-01 23:50:30
```

(A terceira linha, com `60` no fim, é uma segunda cópia da mesma extração com uma configuração que
a seção depois da próxima explica. Por enquanto, passe por ela.)

Na noite seguinte o `shop` toca o dia 2 de março, e a extração lê o dia:

```
ana@vm:~/etl$ sudo shop day 2026-03-02
```

```
ana@vm:~/etl$ python incremental.py orders
shop.orders: 261 rows since 03-01 23:50:30, watermark now 03-02 23:59:47
ana@vm:~/etl$ python incremental.py orders 60
shop.orders+60m: 265 rows since 03-01 23:50:30, watermark now 03-02 23:59:47
```

**261 linhas em vez de 17.453.** As 261 são os pedidos novos do dia e os pedidos anteriores cujo
status mudou naquele dia — os dois tipos têm um `updated_at` novo, e a extração não precisa saber de
que tipo cada um é. O custo agora cresce com a mudança, não com a tabela: em cinco anos continua sendo
duzentas ou trezentas linhas por noite.

## O que ela pede da origem

O método inteiro se apoia numa coluna, e em três promessas sobre ela que a origem precisa cumprir:

- **toda escrita a preenche** — um `UPDATE` que esquece de tocar o `updated_at` é uma mudança que
  nenhum pipeline incremental vai ver;
- **ela nunca anda para trás** numa linha;
- **ela tem índice**, ou "as linhas que mudaram desde ontem" é uma varredura completa disfarçada. A
  loja tem `orders_updated_at` exatamente para isso.

A primeira promessa é a que quebra. Um desenvolvedor corrige à mão um erro de digitação na cidade de
um cliente, direto no banco, e não pensa no `updated_at`; o warehouse guarda o erro para sempre.
**Onde o dono da origem concorda, um gatilho que preenche o `updated_at` em toda escrita transforma
a promessa numa garantia**. A loja do laboratório não tem um, o que mantém os horários exatamente onde o arquivo do dia
os pôs.
