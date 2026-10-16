---
title: Travas de linha, e a fila que não espera
version: 1
---

As travas de tabela decidem quem pode tocar numa tabela. Dentro de uma tabela, a espera do dia a
dia é por **linhas**: duas transações que querem mudar a mesma linha não podem ter as duas, e a
segunda espera. A aula 8 de `sql-databases` apresentou as cláusulas; esta seção roda cada uma no
`market` com duas janelas, para você ver quem espera, por quanto tempo e o que a que esperou lê
quando é liberada.

Uma trava de linha não fica guardada onde ficam as travas de tabela. O PostgreSQL a escreve **na
própria linha**, no cabeçalho dela, então uma transação pode travar um milhão de linhas sem usar um
milhão de entradas de memória. O preço é que o `pg_locks` não consegue listar linhas travadas; a
aula 13 mostra o que ele lista no lugar.

## Dois escritores, uma linha

Na janela A, comece uma transação e mude o pedido 1:

```
market=# BEGIN;
BEGIN
Time: 0.351 ms

market=*# UPDATE orders SET status = 'shipped' WHERE id = 1;
UPDATE 1
Time: 2.694 ms
```

Na janela B, mude outro pedido, leia o pedido 1 e então tente travá-lo:

```
market=# BEGIN;
BEGIN
Time: 0.363 ms

market=*# UPDATE orders SET status = 'shipped' WHERE id = 2;
UPDATE 1
Time: 2.744 ms

market=*# SELECT status FROM orders WHERE id = 1;
  status   
-----------
 delivered
(1 row)

Time: 0.889 ms

market=*# SELECT status FROM orders WHERE id = 1 FOR UPDATE NOWAIT;
ERROR:  could not obtain lock on row in relation "orders"
Time: 0.601 ms

market=!# ROLLBACK;
ROLLBACK
Time: 0.259 ms

market=# BEGIN;
BEGIN
Time: 0.195 ms

market=*# SELECT status FROM orders WHERE id = 1 FOR UPDATE;
```

Quatro coisas aconteceram na janela B, e cada uma é uma regra.

**Uma linha diferente não é conflito.** O pedido 2 foi atualizado em menos de 3 ms, ao lado do
update aberto da janela A. Travas de linha são por linha, então escritores em linhas diferentes da
mesma tabela nunca esperam uns pelos outros.

**Ler nunca é bloqueado por uma trava de linha.** O `SELECT` simples do pedido 1 respondeu na hora,
e respondeu `delivered`: a mudança da janela A não foi confirmada, então a janela B lê a versão de
antes dela.

**`NOWAIT` recusa em vez de esperar.** `FOR UPDATE` pede a mesma trava que um update pegaria, no
momento da leitura, e `NOWAIT` transforma "esperar" num erro imediato, `could not obtain lock on
row in relation "orders"`. O erro abortou a transação da janela B, e é por isso que o prompt virou
`market=!#` e precisou de um `ROLLBACK`. Use-o onde uma pessoa está esperando resposta e "alguém
está editando isto" é uma resposta melhor que um spinner.

**Sem `NOWAIT`, ele espera.** O último `SELECT … FOR UPDATE` não imprimiu nada. Agora confirme a
janela A:

```
market=*# COMMIT;
COMMIT
Time: 153.469 ms
```

```
market=*# SELECT status FROM orders WHERE id = 1 FOR UPDATE;
 status  
---------
 shipped
(1 row)

Time: 7084.975 ms (00:07.085)
```

A janela B ganhou a trava depois de **7085 ms** de espera, e leu `shipped`, não `delivered`. **Uma
leitura com trava devolve a linha como ela está quando a trava é concedida**, depois da mudança da
outra transação, e é isso que torna seguro um `SELECT … FOR UPDATE` seguido de um `UPDATE` contra a
atualização perdida que a aula 14 mede. Desfaça a janela B com `ROLLBACK;` antes de seguir.

## Dividindo uma trava

`FOR SHARE` é a trava mais fraca: muitas transações podem segurá-la na mesma linha ao mesmo tempo,
e ela impede que a linha seja mudada enquanto isso. Na janela A:

```
market=# BEGIN;
BEGIN
Time: 0.213 ms

market=*# SELECT status FROM orders WHERE id = 3 FOR SHARE;
  status   
-----------
 delivered
(1 row)

Time: 0.747 ms
```

Então a janela B pega a mesma trava na mesma linha, o que funciona, e tenta mudar a linha, o que
não funciona:

```
market=# BEGIN;
BEGIN
Time: 0.245 ms

market=*# SELECT status FROM orders WHERE id = 3 FOR SHARE;
  status   
-----------
 delivered
(1 row)

Time: 0.490 ms

market=*# UPDATE orders SET status = 'cancelled' WHERE id = 3;
```

A trava compartilhada da própria janela B não a deixa atualizar a linha enquanto a janela A também
segura uma. Desfaça a janela A:

```
market=*# ROLLBACK;
ROLLBACK
Time: 0.379 ms
```

```
market=*# UPDATE orders SET status = 'cancelled' WHERE id = 3;
UPDATE 1
Time: 5888.203 ms (00:05.888)
```

**5888 ms** de espera, e então o update. `FOR SHARE` serve para uma checagem como "este vendedor
precisa continuar existindo enquanto eu insiro o pedido dele": várias transações podem fazer essa
checagem ao mesmo tempo, e nenhuma delas pode apagar o vendedor debaixo das outras. Também é o jeito
mais fácil de escrever um deadlock: duas transações que seguram cada uma uma trava compartilhada
numa linha e depois tentam cada uma atualizá-la esperam uma pela outra, e esse é o assunto da seção
06 desta aula. Desfaça a janela B também.

## Uma fila de tarefas em `orders`

O depósito embala pedidos, e várias estações de embalagem pedem trabalho ao banco ao mesmo tempo.
Cada estação pega os três pedidos pendentes mais antigos e os marca como `packing`, num comando só.
Na janela A:

```
market=# BEGIN;
BEGIN
Time: 0.470 ms

market=*# UPDATE orders SET status = 'packing' WHERE id IN (SELECT id FROM orders WHERE status = 'pending' ORDER BY id LIMIT 3 FOR UPDATE) RETURNING id;
   id    
---------
 1992683
 1992684
 1992682
(3 rows)

UPDATE 3
Time: 506.600 ms
```

Na janela B, uma segunda estação faz a mesma pergunta no mesmo momento:

```
market=# BEGIN;
BEGIN
Time: 0.351 ms

market=*# UPDATE orders SET status = 'packing' WHERE id IN (SELECT id FROM orders WHERE status = 'pending' ORDER BY id LIMIT 3 FOR UPDATE) RETURNING id;
```

A janela B espera. Os três pedidos pendentes mais antigos estão travados pela janela A, e a segunda
estação não consegue passar por eles. Confirme a janela A, como uma estação faria depois de marcar
os três dela:

```
market=*# COMMIT;
COMMIT
Time: 5.076 ms
```

```
market=*# UPDATE orders SET status = 'packing' WHERE id IN (SELECT id FROM orders WHERE status = 'pending' ORDER BY id LIMIT 3 FOR UPDATE) RETURNING id;
   id    
---------
 1992686
 1992687
 1992685
(3 rows)

UPDATE 3
Time: 7495.285 ms (00:07.495)
```

A janela B esperou **7495 ms**, então releu as linhas pelas quais esperava, viu que não estavam
mais `pending` e pegou as três seguintes. A resposta está certa; as estações só se revezaram. Com
dez estações, isso é uma fila atendida por uma estação de cada vez, e quanto mais estações você
acrescenta, mais cada uma espera. Desfaça a janela B, para que os três pedidos dela voltem a ficar
pendentes.

**`SKIP LOCKED` é o conserto**, e é uma cláusula só. Rode o mesmo comando com ela, nas duas
janelas:

```
market=# BEGIN;
BEGIN
Time: 0.266 ms

market=*# UPDATE orders SET status = 'packing' WHERE id IN (SELECT id FROM orders WHERE status = 'pending' ORDER BY id LIMIT 3 FOR UPDATE SKIP LOCKED) RETURNING id;
   id    
---------
 1992686
 1992687
 1992685
(3 rows)

UPDATE 3
Time: 418.933 ms
```

```
market=# BEGIN;
BEGIN
Time: 0.221 ms

market=*# UPDATE orders SET status = 'packing' WHERE id IN (SELECT id FROM orders WHERE status = 'pending' ORDER BY id LIMIT 3 FOR UPDATE SKIP LOCKED) RETURNING id;
   id    
---------
 1992690
 1992689
 1992688
(3 rows)

UPDATE 3
Time: 427.529 ms
```

**A janela B não esperou mais.** Ela pulou as três linhas que a janela A tinha travado e pegou as
três seguintes em 428 ms, mais ou menos o que a janela A levou. Esse é o tempo de achar pedidos
pendentes entre dois milhões sem índice em `status`, e o índice parcial da aula 9 é o que se cria
aqui. Cada estação pega as próprias linhas, ninguém espera ninguém, e uma estação que cai antes de
confirmar simplesmente libera as linhas dela para a próxima pegar. Desfaça as duas janelas.

Dois avisos junto com ele. O `SKIP LOCKED` dá uma visão inconsistente de propósito: um relatório que
o usasse perderia em silêncio toda linha travada, então ele pertence a filas e a nenhum outro
lugar. E a trava dura até a transação da estação terminar, então **uma estação deve confirmar assim
que marcar as linhas dela** e fazer a embalagem fora da transação. Uma estação que mantém a
transação aberta enquanto trabalha segura as linhas dela, e as travas da tabela, pelo tempo que o
trabalho levar.
