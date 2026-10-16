---
title: Cancelar ou encerrar, e o que cada um faz com a vítima
version: 1
---

A árvore dá o nome da raiz. Duas funções agem sobre uma sessão pelo id de processo, e a diferença
entre elas é a diferença entre um conserto e uma surpresa:

| função | o que faz com a sessão |
|---|---|
| `pg_cancel_backend(pid)` | para o comando que ela está **rodando** agora; a conexão fica |
| `pg_terminate_backend(pid)` | encerra a **conexão**; qualquer transação aberta é desfeita |

O erro comum é ir na mais gentil primeiro, na raiz, e concluir que não funcionou. Ela fez exatamente
o que diz. **A raiz da maioria dos incidentes de trava não está rodando nada**, então não há o que
cancelar.

## Cancelando uma sessão ociosa

A raiz é a janela A, 5792, idle in transaction. Na janela D:

```
market=# SELECT pg_cancel_backend(5792);
 pg_cancel_backend 
-------------------
 t
(1 row)

Time: 0.543 ms

market=# \i ~/lock-tree.sql
    pid     |        state        | in_transaction |                  last_query                   
------------+---------------------+----------------+-----------------------------------------------
 5792       | idle in transaction | 00:00:35       | UPDATE orders SET status = 'shipped' WHERE id
    5794    | active              | 00:00:34       | UPDATE orders SET status = 'shipped' WHERE id
       5796 | active              | 00:00:29       | UPDATE orders SET status = 'cancelled' WHERE 
(3 rows)

Time: 2.566 ms
```

O `pg_cancel_backend` respondeu `t`, o que só quer dizer que o sinal foi enviado. A árvore não
mudou, 34 segundos viraram 35, e a janela A continua sendo a raiz. Um cancelamento interrompe um
comando em andamento, e a janela A não tinha nenhum; **as travas dela pertencem à transação, e um
cancelamento não termina transações.**

## Encerrando-a

```
market=# SELECT pg_terminate_backend(5792);
 pg_terminate_backend 
----------------------
 t
(1 row)

Time: 3.469 ms

market=# \i ~/lock-tree.sql
   pid   |        state        | in_transaction |                  last_query                   
---------+---------------------+----------------+-----------------------------------------------
 5794    | idle in transaction | 00:00:35       | UPDATE orders SET status = 'shipped' WHERE id
    5796 | active              | 00:00:31       | UPDATE orders SET status = 'cancelled' WHERE 
(2 rows)

Time: 2.067 ms
```

A janela A sumiu da árvore. A conexão dela foi fechada, a transação desfeita e **a trava de linha
no pedido 1 foi junto**. A janela B, que esperava essa trava, a recebeu na hora e terminou o update:

```
market=*# UPDATE orders SET status = 'shipped' WHERE id = 1;
UPDATE 1
Time: 34430.590 ms (00:34.431)
```

**34.431 milissegundos** para um update que leva dois. A janela B agora é a raiz, idle in
transaction, segurando os pedidos 1 e 2, com a janela C ainda esperando debaixo dela: encerrar a
raiz subiu a cadeia um nível, não a esvaziou. Se isso é o fim do incidente depende do que a
aplicação por trás da janela B fizer em seguida; se ela confirmar, a janela C passa.

O que o usuário da janela A viu? Nada, até digitar o próximo comando:

```
market=*# SELECT status FROM orders WHERE id = 1;
FATAL:  terminating connection due to administrator command
server closed the connection unexpectedly
	This probably means the server terminated abnormally
	before or while processing the request.
The connection to the server was lost. Attempting reset: Succeeded.
Time: 3.482 ms
```

O servidor fechou a conexão, e o psql só percebeu quando tentou usá-la. O psql se reconecta
sozinho, e é por isso que diz `Succeeded`, mas **a transação foi embora**: o update do pedido 1 foi
desfeito, e o `SELECT` que descobriu isso nunca rodou. Uma aplicação vê a mesma coisa como um erro
no próximo comando, e se ela se recupera depende de ter sido escrita para tentar de novo, que é o
assunto da aula 14.

## Cancelando um comando que espera

Um cancelamento é a ferramenta certa para uma sessão que **está** rodando algo: um relatório que
está há uma hora rodando, ou um comando preso numa fila de travas que você prefere ver falhar a
esperar. A janela C é do segundo tipo:

```
market=# SELECT pg_cancel_backend(5796);
 pg_cancel_backend 
-------------------
 t
(1 row)

Time: 0.547 ms
```

```
market=# UPDATE orders SET status = 'cancelled' WHERE id = 2;
ERROR:  canceling statement due to user request
CONTEXT:  while updating tuple (0,2) in relation "orders"
Time: 34135.050 ms (00:34.135)
```

O update da janela C falhou com `canceling statement due to user request`, depois de 34.135 ms de
espera, e o `CONTEXT` dá a linha pela qual ela esperava. A janela C não estava numa transação
própria, então o comando que falhou não deixou nada para trás. **Dentro de uma transação teria sido
diferente**: o comando falha, a transação fica marcada como falha, o prompt vira `market=!#` como na
aula 12, e **toda trava que a transação já segurava continua segura** até o cliente mandar
`ROLLBACK`. Cancelar um comando de uma transação longa não solta o que a transação tinha pegado.

Termine o experimento na janela B com `ROLLBACK;`, para que os pedidos 1 e 2 fiquem como o
`market.sql` os fez.

## Qual, quando

- **A raiz está `idle in transaction`:** cancelar não faz nada. Encerre-a, depois de descobrir pelo
  `last_query` e pelos logs da aplicação o que era, porque o trabalho dela é desfeito.
- **A raiz está `active`, um comando rodando há muito tempo:** cancele primeiro. O comando falha e,
  se era uma transação de um comando só, as travas vão embora. Se estava dentro de uma transação
  mais longa, as travas ficam até a aplicação desfazer, e talvez você precise encerrar mesmo assim.
- **Nunca encerre um processo do servidor com `kill -9`** pelo sistema operacional. O PostgreSQL
  trata um backend que morreu assim como possível dano à memória compartilhada e reinicia todas as
  conexões do servidor por segurança. As duas funções acima são o jeito de encerrar uma sessão.

As duas funções exigem superusuário ou participação em `pg_signal_backend`, e nenhuma delas manda
sinal à sessão de um superusuário a menos que você seja um. Num serviço gerenciado, esse papel
costuma ser o que a sua conta de administrador tem no lugar de superusuário.

**Encerrar a raiz termina o incidente; não o explica.** Alguma coisa na aplicação abriu uma
transação e parou de falar. A aula 15 trata de achar essas sessões antes de elas bloquearem alguém,
e do `idle_in_transaction_session_timeout`, que as encerra automaticamente.
