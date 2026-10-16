---
title: Serializable, e a regra que duas transações quebraram juntas
version: 1
---

A loja tem uma regra: **um cliente pode ter no máximo um pedido pendente por vez.** Ela é checada na
aplicação, do jeito óbvio: conta os pedidos pendentes do cliente e insere o novo só se a contagem
for zero. Nada no esquema a impõe.

Cada transação que roda essa checagem está correta sozinha. A crença para largar é que um nível de
isolamento rígido o bastante torna uma checagem dessas segura. O `REPEATABLE READ` não torna, e vale
ver o motivo: **duas transações podem cada uma ler, cada uma decidir e cada uma escrever uma linha
diferente**, e nenhuma linha é escrita duas vezes. Isso é **write skew**, e é a anomalia que só o
`SERIALIZABLE` pega.

## Dois pedidos, os dois permitidos

O cliente 7 faz um pedido pelo celular e pelo notebook no mesmo momento. Cada requisição roda a
checagem na própria transação `REPEATABLE READ`. Na janela A:

```
market=# BEGIN ISOLATION LEVEL REPEATABLE READ;
BEGIN
Time: 0.344 ms

market=*# SELECT count(*) FROM orders WHERE customer_id = 7 AND status = 'pending';
 count 
-------
     0
(1 row)

Time: 1.618 ms
```

E na janela B:

```
market=# BEGIN ISOLATION LEVEL REPEATABLE READ;
BEGIN
Time: 0.263 ms

market=*# SELECT count(*) FROM orders WHERE customer_id = 7 AND status = 'pending';
 count 
-------
     0
(1 row)

Time: 1.643 ms
```

As duas veem zero pedidos pendentes, então as duas seguem: a janela A insere, a janela B insere, e
então as duas confirmam, a janela A primeiro:

```
market=*# INSERT INTO orders (customer_id, seller_id, placed_at, status, total_cents) VALUES (7, 2, now(), 'pending', 1000);
INSERT 0 1
Time: 2.084 ms

market=*# COMMIT;
COMMIT
Time: 1.087 ms
```

```
market=*# INSERT INTO orders (customer_id, seller_id, placed_at, status, total_cents) VALUES (7, 2, now(), 'pending', 1000);
INSERT 0 1
Time: 1.425 ms

market=*# COMMIT;
COMMIT
Time: 0.713 ms
```

E a regra:

```
market=# SELECT count(*) FROM orders WHERE customer_id = 7 AND status = 'pending';
 count 
-------
     2
(1 row)

Time: 0.579 ms
```

**Dois pedidos pendentes, e nenhuma transação fez nada de errado.** Cada uma leu um snapshot em que a
contagem era zero. Cada uma inseriu uma linha nova, então ninguém sobrescreveu nada, e o `REPEATABLE
READ` não tinha o que recusar. A ordem em que as duas rodaram não fez diferença: nenhuma ordem delas,
uma depois da outra, teria produzido dois pedidos pendentes, e essa é a definição do problema. O
resultado não poderia ter vindo de rodá-las uma por vez.

Remova os dois pedidos antes de tentar de novo; na janela A, `DELETE FROM orders WHERE customer_id
= 7 AND status = 'pending';` apagou os dois.

## As mesmas duas, serializáveis

O `SERIALIZABLE` promete exatamente o que o último parágrafo disse que faltava: **o resultado de
transações rodadas juntas é um que rodá-las uma depois da outra, em alguma ordem, poderia ter
produzido.** Se não consegue cumprir essa promessa, ele faz uma delas falhar.

Rode a mesma coisa com `BEGIN ISOLATION LEVEL SERIALIZABLE`. Na janela B, primeiro peça ao psql que
mostre o erro completo, com `\set VERBOSITY verbose`, para que o código apareça:

```
market=# BEGIN ISOLATION LEVEL SERIALIZABLE;
BEGIN
Time: 0.300 ms

market=*# SELECT count(*) FROM orders WHERE customer_id = 7 AND status = 'pending';
 count 
-------
     0
(1 row)

Time: 0.904 ms
```

```
market=# \set VERBOSITY verbose
market=# BEGIN ISOLATION LEVEL SERIALIZABLE;
BEGIN
Time: 0.421 ms

market=*# SELECT count(*) FROM orders WHERE customer_id = 7 AND status = 'pending';
 count 
-------
     0
(1 row)

Time: 0.572 ms
```

De novo a janela A insere, a janela B insere, e as duas confirmam, a janela A primeiro:

```
market=*# INSERT INTO orders (customer_id, seller_id, placed_at, status, total_cents) VALUES (7, 2, now(), 'pending', 1000);
INSERT 0 1
Time: 1.885 ms

market=*# COMMIT;
COMMIT
Time: 0.954 ms
```

```
market=*# INSERT INTO orders (customer_id, seller_id, placed_at, status, total_cents) VALUES (7, 2, now(), 'pending', 1000);
INSERT 0 1
Time: 1.924 ms

market=*# COMMIT;
ERROR:  40001: could not serialize access due to read/write dependencies among transactions
DETAIL:  Reason code: Canceled on identification as a pivot, during commit attempt.
HINT:  The transaction might succeed if retried.
LOCATION:  PreCommit_CheckForSerializationFailure, predicate.c:4662
Time: 0.460 ms
```

```
market=# SELECT count(*) FROM orders WHERE customer_id = 7 AND status = 'pending';
 count 
-------
     1
(1 row)

Time: 0.500 ms
```

**Um pedido pendente: a regra se manteve.** O `COMMIT` da janela B falhou com o SQLSTATE
**`40001`**, `could not serialize access due to read/write dependencies among transactions`, e o
insert dela foi desfeito com o resto da transação. O `HINT` diz o que importa: **a transação pode dar
certo se for tentada de novo.** Rodada de novo, a contagem da janela B veria o pedido da janela A,
acharia um e recusaria o segundo pedido, como a aplicação pretendia.

## Como o servidor soube

Nenhuma linha foi escrita duas vezes, então travas de linha não podem tê-lo pegado. O
`SERIALIZABLE` no PostgreSQL também registra **o que cada transação leu**, como travas de predicado
que não bloqueiam ninguém: a contagem da janela A leu as entradas de índice do cliente 7, e a da
janela B também. Cada uma então inseriu nessa mesma parte. O servidor viu que A tinha lido algo que B
mudou e B tinha lido algo que A mudou, o que é um ciclo que nenhuma ordem serial explica, e recusou a
transação cujo commit fecharia o ciclo. O "pivot" da linha `DETAIL` é essa transação.

## Quanto cada nível custa

| nível | o que impede | como falha |
|---|---|---|
| `READ COMMITTED` | ler dados não confirmados | não falha: atualizações perdidas e write skew passam em silêncio |
| `REPEATABLE READ` | mudanças aparecendo no meio da transação, atualizações perdidas | 40001 quando uma linha que ela escreveria mudou depois do snapshot |
| `SERIALIZABLE` | toda anomalia, write skew incluído | 40001 sempre que acha um ciclo de leituras e escritas |

O preço dos níveis mais fortes é pago em dois lugares. **Falhas**: cada 40001 é uma transação feita
duas vezes, e a seção 05 desta aula mede quantas. **Contabilidade**: o `SERIALIZABLE` guarda travas
de predicado para toda transação, o que custa memória e algum processamento, e quando o servidor não
consegue acompanhar leituras com precisão ele as alarga, de poucas linhas para uma página e para a
tabela inteira, e recusa mais transações que o estritamente necessário. Essas recusas são falsos
positivos, e são seguras: uma nova tentativa as resolve.

Dois hábitos mantêm esse custo baixo. Use `SERIALIZABLE` nas transações cuja correção depende do que
elas leem, não por padrão em tudo. E mantenha essas transações curtas, porque uma longa junta
dependências do jeito que uma transação longa da aula 12 juntava travas. Para a regra desta seção há
também um conserto mais simples, que não precisa de nível especial: **um índice único parcial**, em
`customer_id` onde `status = 'pending'`, do tipo da aula 9, transforma a regra numa que o esquema
impõe, e o segundo insert falha com violação de unicidade seja qual for o nível de isolamento.
