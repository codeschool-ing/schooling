---
title: A fila de travas, e o ALTER que parou toda leitura
version: 1
---

Esta é a queda de que esta seção trata. Alguém acrescenta uma coluna a uma tabela, um comando que
levaria dois milissegundos, e pelos quinze segundos seguintes **toda consulta naquela tabela
espera**, inclusive leituras simples que não conflitam com nada que alguém esteja segurando. A
intuição que falha é a de que um comando só espera por travas que conflitam com a dele. Ele também
espera por **todo comando que pediu antes dele** e ainda está esperando.

## Três janelas

Abra um terceiro terminal com `psql market`, a janela C. Na janela A, comece algo que leia `orders`
por um tempo; aqui o `pg_sleep(15)` faz o papel de um relatório lento:

```
market=# SELECT pg_sleep(15), status FROM orders WHERE id = 1;
```

Cerca de um segundo depois, na janela B, acrescente uma coluna. Acrescentar uma coluna que aceita
nulo e não tem default muda só o catálogo e leva milissegundos. Mas o `ALTER TABLE` precisa de
`ACCESS EXCLUSIVE`, a linha 8 da matriz da seção 02 desta aula, e isso conflita com o `ACCESS
SHARE` da janela A:

```
market=# ALTER TABLE orders ADD COLUMN gift_note text;
```

Um segundo depois disso, na janela C, leia um pedido, a consulta mais barata que existe:

```
market=# SELECT status FROM orders WHERE id = 2;
```

As três estão esperando. A janela A está trabalhando; as janelas B e C estão sem prompt. Espere a
janela A terminar:

```
market=# SELECT pg_sleep(15), status FROM orders WHERE id = 1;
 pg_sleep | status  
----------+---------
          | shipped
(1 row)

Time: 15018.259 ms (00:15.018)
```

```
market=# ALTER TABLE orders ADD COLUMN gift_note text;
ALTER TABLE
Time: 13507.137 ms (00:13.507)
```

```
market=# SELECT status FROM orders WHERE id = 2;
  status   
-----------
 delivered
(1 row)

Time: 12001.566 ms (00:12.002)
```

**A janela C esperou 12,0 segundos para ler uma linha.** O `ACCESS SHARE` dela não conflita com o
`ACCESS SHARE` da janela A; nada que a janela A segurava estava no caminho. O que estava no caminho
era a janela B.

## Por que C esperou

Cada tabela tem uma fila de pedidos de trava que não puderam ser concedidos na hora. **Um pedido
novo só é concedido se não conflitar com ninguém que segura a trava nem com ninguém que já está
esperando na fila.** A segunda condição é o que impede uma trava forte de esperar para sempre: se
leitores pudessem furar a fila, uma tabela movimentada sempre teria algum leitor segurando `ACCESS
SHARE`, e um `ALTER TABLE` nunca entraria. Então o servidor faz todo mundo entrar na fila atrás do
`ALTER` que espera, e o `ALTER` que espera está esperando o relatório lento:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 232\" role=\"img\" aria-label=\"Uma linha do tempo de três janelas ao longo de uns quinze segundos. A janela A roda um SELECT por 15,0 segundos, segurando ACCESS SHARE em orders. A janela B pede ACCESS EXCLUSIVE para acrescentar uma coluna cerca de um segundo e meio depois e espera 13,5 segundos. A janela C pede ACCESS SHARE para ler um pedido aos três segundos e espera 12,0 segundos, atrás de B, embora a trava dela não conflite com a de A. Quando A termina, B roda e C roda logo em seguida.\"><text x=\"14\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">janela A</text><text x=\"14\" y=\"70\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">SELECT pg_sleep(15)…</text><rect x=\"150\" y=\"40\" width=\"510.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"158\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">segura ACCESS SHARE</text><text x=\"14\" y=\"104\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">janela B</text><text x=\"14\" y=\"122\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">ALTER TABLE … ADD COLUMN</text><rect x=\"201.0\" y=\"92\" width=\"459.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"209.0\" y=\"104\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">espera 13,5 s por ACCESS EXCLUSIVE</text><rect x=\"660.0\" y=\"92\" width=\"8\" height=\"24\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"14\" y=\"156\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">janela C</text><text x=\"14\" y=\"174\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">SELECT status … id = 2</text><rect x=\"252.0\" y=\"144\" width=\"408.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"260.0\" y=\"156\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">espera 12,0 s atrás de B</text><rect x=\"660.0\" y=\"144\" width=\"8\" height=\"24\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><path d=\"M150 196 L694 196\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M150 196 L150 201\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><text x=\"150\" y=\"212\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">0 s</text><path d=\"M320 196 L320 201\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><text x=\"320\" y=\"212\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">5 s</text><path d=\"M490 196 L490 201\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><text x=\"490\" y=\"212\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">10 s</text><path d=\"M660 196 L660 201\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><text x=\"660\" y=\"212\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">15 s</text><path d=\"M660 34 L660 196\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1\"></path><text x=\"656\" y=\"24\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--amber)\">A termina: B, depois C</text></svg>", "caption": "A fila de travas. C não conflita com A, mas chegou depois de B, e B está esperando A."}
```

O `ALTER` em si, quando concedido, levou uns dois milissegundos, e tudo o que estava atrás dele
entrou de uma vez. Numa tabela de verdade, a fila atrás da janela B não é um `SELECT`; é todo pedido
que a aplicação manda durante esses quinze segundos, cada um segurando uma conexão enquanto espera.
A aula 16 mostra o que acontece quando as conexões acabam primeiro.

Tire a coluna na janela B com `ALTER TABLE orders DROP COLUMN gift_note;` antes de seguir.

## A defesa: `lock_timeout`

O problema é a espera, não o `ALTER`. Então limite quanto tempo uma trava forte pode esperar: o
**`lock_timeout`** faz um comando desistir se a trava não tiver sido concedida dentro desse tempo,
o que também o tira da fila e deixa passar todo mundo atrás dele. Comece o relatório lento de novo
na janela A e então, na janela B:

```
market=# ALTER TABLE orders DROP COLUMN gift_note;
ALTER TABLE
Time: 2.701 ms

market=# SET lock_timeout = '2s';
SET
Time: 0.437 ms

market=# ALTER TABLE orders ADD COLUMN gift_note text;
ERROR:  canceling statement due to lock timeout
Time: 2000.845 ms (00:02.001)
```

E a janela C, que pediu a leitura meio segundo depois de o `ALTER` da janela B começar a esperar:

```
market=# SELECT status FROM orders WHERE id = 2;
  status   
-----------
 delivered
(1 row)

Time: 1088.808 ms (00:01.089)
```

**O `ALTER` desistiu depois de exatamente dois segundos, e a janela C esperou 1089 ms em vez de
12.002.** A mudança de esquema não aconteceu, e esse é o resultado honesto: ela pode ser tentada de
novo um minuto depois, quando o relatório terminar, e até lá a aplicação só notou um soluço de dois
segundos.

Na prática, isso vira três hábitos para todo comando que pega `ACCESS EXCLUSIVE` numa tabela
movimentada — `ALTER TABLE`, `DROP INDEX` sem `CONCURRENTLY`, `TRUNCATE`:

- **Defina `lock_timeout` na mesma sessão antes**, poucos segundos no máximo.
- **Tente de novo num laço** até entrar, em vez de aumentar o tempo limite; a aula 22 de
  `db-administration` constrói esse laço para uma migração ao vivo.
- **Procure transações longas antes de começar**, porque é atrás delas que o `ALTER` ficaria na
  fila; a aula 13 trata de achá-las enquanto estão acontecendo.

O `statement_timeout` não é substituto. Ele limita quanto tempo um comando roda no total, espera
incluída, então também cortaria o relatório lento; o `lock_timeout` só limita a espera por uma
trava, e mira exatamente o comando que, de outro modo, seguraria a fila.
