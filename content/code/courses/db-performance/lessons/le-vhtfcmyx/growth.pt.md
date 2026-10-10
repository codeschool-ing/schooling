---
title: Crescimento, medido a partir do que já está lá
version: 1
---

A primeira pergunta do planejamento de capacidade parece pedir uma bola de cristal — de que tamanho
este banco vai estar no ano que vem? — e quase nunca pede. **O banco já contém a própria história.**
Toda linha com uma data é um registro de quando chegou, e contá-las por mês é a taxa de crescimento,
medida em vez de adivinhada.

`orders` tem `placed_at`. Conte o último ano por mês:

```
market=# SELECT date_trunc('month', placed_at)::date AS month, count(*) AS orders FROM orders WHERE placed_at >= '2025-01-01' GROUP BY 1 ORDER BY 1;
   month    | orders 
------------+--------
 2025-01-01 |  77177
 2025-02-01 |  73093
 2025-03-01 |  82945
 2025-04-01 |  84240
 2025-05-01 |  89903
 2025-06-01 |  89500
 2025-07-01 |  95909
 2025-08-01 |  99337
 2025-09-01 |  99072
 2025-10-01 | 105273
 2025-11-01 | 105503
 2025-12-01 | 107780
(12 rows)

Time: 511.996 ms
```

De 77177 pedidos em janeiro para 107780 em dezembro: a loja está crescendo, e não por um percentual
fixo — os meses sobem mais ou menos os mesmos **dois a três mil pedidos** cada, com a queda de
fevereiro porque fevereiro é curto. Isso é uma tendência linear, e tendência linear é o tipo fácil:
o próximo dezembro fica uns 30 mil pedidos por mês acima. Uma loja crescendo por percentual,
dobrando todo ano, faria uma curva para cima na mesma tabela, e a previsão abaixo teria de ser
feita com essa curva em vez de uma reta.

Dois avisos sobre ler uma tabela assim. **Um mês não é uma unidade de trabalho**: um fim de semana
de Black Friday pode carregar os pedidos de um mês em três dias, e um banco que aguenta o mês médio
ainda pode cair no pico. E **a história só cobre o que a aplicação registra**: uma funcionalidade
nova que grava uma tabela que não existia não tem história para medir, e o crescimento dela tem de
ser estimado a partir da funcionalidade.

## De linhas para bytes

Linhas não enchem disco. Bytes enchem, e a conversão também é uma medida:

```
market=# SELECT relname, reltuples::bigint AS rows, pg_size_pretty(pg_total_relation_size(oid)) AS with_indexes, round(pg_total_relation_size(oid) / reltuples) AS bytes_per_row FROM pg_class WHERE relname IN ('orders', 'order_lines', 'events') ORDER BY relname;
   relname   |  rows   | with_indexes | bytes_per_row 
-------------+---------+--------------+---------------
 events      | 4999827 | 618 MB       |           130
 order_lines | 4999992 | 432 MB       |            91
 orders      | 2000000 | 247 MB       |           130
(3 rows)

Time: 3.596 ms
```

**130 bytes por pedido** e 91 por linha de pedido, contando os índices de cada tabela junto. Esse é
o número pelo qual multiplicar: ele inclui a própria linha, a contabilidade que o PostgreSQL guarda
em cada linha, o espaço livre dentro das páginas e cada índice — por isso é mais do que as cinco
colunas de um pedido sugeririam. Medido na tabela como ela está, já inclui os índices que a
aplicação criou, e muda quando alguém acrescenta outro.

Então os pedidos da loja crescem uns 108 mil por mês, e as linhas de pedido duas vezes e meia isso:

| tabela | linhas por mês | bytes por linha | por mês |
|---|---|---|---|
| `orders` | 108 000 | 130 | 14 MB |
| `order_lines` | 270 000 | 91 | 25 MB |
| `events` | 1 670 000 | 130 | 217 MB |

Os eventos são a surpresa, e o motivo de fazer a conta em vez de supor. São um log de cliques: cinco
milhões em noventa dias, um milhão e dois terços por mês, e **eles crescem o banco mais que todo o
resto junto**. Uma previsão feita só com os pedidos erraria por um fator de seis.

## Quanto falta para o disco encher

```
ana@vm:~$ df -h /var/lib/postgresql
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda        252G   17G   23G  43% /
```

Este é o computador da gravação, não uma máquina virtual como a sua, e o disco dele é compartilhado
com tudo o mais que roda nele, então os números são só um exemplo: 23 GB disponíveis. A uns 256 MB
por mês, o banco enche isso em **uns noventa meses** — sete anos e meio, se nada mais mudar. O disco
de 30 GB da sua máquina virtual, com o Ubuntu, o banco e a cópia dele, vai mostrar outro `Avail`, e
a mesma conta funciona nele.

"Se nada mais mudar" faz muito trabalho nessa frase, e as próximas três seções tratam do que ele
esconde. O log de escrita antecipada (WAL), arquivos temporários de uma ordenação grande, uma cópia
feita por uma aula como o `market_base` e um backup gravado no mesmo disco ocupam espaço que cresce
com o banco sem serem linhas dele. Uma previsão feita com linhas é um limite inferior; o alerta da
última seção desta aula é o que a mantém honesta.
