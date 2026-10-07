---
title: Derivar: a coluna que ninguém guardou
version: 1
---

Boa parte de uma transformação é acrescentar colunas que a origem nunca teve, porque a origem nunca
precisou delas: quanto uma linha valeu, se um pedido conta como venda, em que dia aconteceu. Os dois
arquivos de staging de pedidos e de linhas são quase só isso:

```
-- One row per order, as the shop has it, with the shop's own date worked out once.
DROP TABLE IF EXISTS staging.orders CASCADE;
CREATE TABLE staging.orders AS
SELECT order_id,
       shop_id,
       customer_id,
       ordered_at,
       (ordered_at AT TIME ZONE 'America/Sao_Paulo')::date AS order_date,
       status,
       status = 'completed' AS is_sale
  FROM raw.orders;
```

```
-- One row per order line, with what the line was worth.
DROP TABLE IF EXISTS staging.order_lines CASCADE;
CREATE TABLE staging.order_lines AS
SELECT order_id,
       line_no,
       book_id,
       quantity,
       unit_price_cents,
       quantity * unit_price_cents AS line_cents
  FROM raw.order_lines;
```

Cada coluna derivada é uma decisão escrita uma vez. O `is_sale` diz que um pedido estornado não é uma
venda, e todo relatório que o lê herda a decisão em vez de repetir `status = 'completed'` — ou, pior,
repeti-la um pouco diferente. O `line_cents` diz que receita é quantidade vezes o preço pago, não o
preço de tabela.

## A derivação fácil de errar

O `order_date` parece a coluna mais inocente do warehouse. **Um horário não tem data; um horário num
fuso tem.** O `ordered_at` é um momento, guardado em UTC dentro do PostgreSQL, e a data em que ele cai
depende de onde você está quando pergunta. Aqui estão dois dias de pedidos, datados em São Paulo e
depois datados do jeito que um servidor ajustado para UTC os dataria:

```
ana@vm:~/etl$ psql -d wh -c "SELECT (ordered_at AT TIME ZONE 'America/Sao_Paulo')::date AS sao_paulo_day, count(*) FROM raw.orders WHERE ordered_at >= '2026-03-06' AND ordered_at < '2026-03-08' GROUP BY 1 ORDER BY 1"
 sao_paulo_day | count 
---------------+-------
 2026-03-06    |   279
 2026-03-07    |   344
(2 rows)

ana@vm:~/etl$ PGTZ=UTC psql -d wh -c "SELECT ordered_at::date AS utc_day, count(*) FROM raw.orders WHERE ordered_at >= '2026-03-06 00:00-03' AND ordered_at < '2026-03-08 00:00-03' GROUP BY 1 ORDER BY 1"
  utc_day   | count 
------------+-------
 2026-03-06 |   252
 2026-03-07 |   337
 2026-03-08 |    34
(3 rows)
```

Os mesmos 623 pedidos. Em São Paulo eles pertencem aos dias 6 e 7. Em UTC, todo pedido feito depois
das 21:00 no horário local passou para o dia seguinte — 27 da sexta para o sábado, 34 do sábado para
um domingo que, em São Paulo, ainda não tinha começado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l06-zones\" aria-label=\"Dois relógios sobre a mesma noite. No relógio de São Paulo, a sexta-feira vai até a meia-noite. No relógio UTC, o dia muda às 21:00 de São Paulo, então todo pedido entre 21:00 e meia-noite fica com data de sábado.\"><text x=\"108.0\" y=\"72.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">São Paulo</text><rect x=\"120.0\" y=\"60.0\" width=\"420.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"540.0\" y=\"60.0\" width=\"140.0\" height=\"24.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sexta, 6 de março</text><text x=\"610.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sábado, 7 de março</text><text x=\"108.0\" y=\"142.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">UTC</text><rect x=\"120.0\" y=\"130.0\" width=\"315.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"435.0\" y=\"130.0\" width=\"245.0\" height=\"24.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"277.5\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sexta, 6 de março</text><text x=\"557.5\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sábado, 7 de março</text><path d=\"M435.0 40.0 L435.0 56.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M435.0 88.0 L435.0 126.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M435.0 158.0 L435.0 180.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M540.0 40.0 L540.0 56.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M540.0 88.0 L540.0 126.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M540.0 158.0 L540.0 180.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"487.5\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">pedidos feitos entre 21:00 e 24:00</text><text x=\"487.5\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">com data de sábado em UTC</text><text x=\"120.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">12:00</text><text x=\"260.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16:00</text><text x=\"400.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20:00</text><text x=\"540.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">00:00</text><text x=\"680.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">04:00</text></svg>", "caption": "O mesmo momento cai em duas datas. De quem é o dia precisa ser escrito na derivação, uma vez.", "same": ["São Paulo", "UTC"]}
```

**Nada naquela segunda consulta está errado como SQL.** O `::date` é válido; o fuso do servidor é uma
configuração que alguém escolheu. As duas respostas discordam porque ninguém escreveu de quem é o
dia, e o primeiro relatório que perceber vai ser um gerente perguntando por que as vendas de sábado
estão menores no warehouse que nos caixas.

Então o `order_date` é derivado no staging, uma vez, com o fuso escrito por extenso, e nada mais
adiante pode derivar uma data do `ordered_at` de novo. O dia da Ponto Final é o de São Paulo. Um
negócio que vende em vários fusos precisa decidir de quem é o dia do relatório, e escrever isso.
