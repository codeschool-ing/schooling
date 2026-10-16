---
title: Pool por transação ou por sessão, e o que quebra no meio
version: 1
---

A linha `pool_mode = transaction` decidiu quando o PgBouncer pega de volta de um cliente uma conexão
com o servidor. Ela tem três valores possíveis, e a diferença entre os dois primeiros é toda a
questão de uma aplicação conseguir ou não usar um pool sem mudar nada:

- **`session`**: o cliente fica com uma conexão do servidor da hora em que conecta até desconectar.
  Nada muda do ponto de vista dele, e nada é economizado: duzentos clientes ainda precisam de duzentas
  conexões no servidor. Só ajuda com o custo de conectar, quando os clientes conectam e desconectam
  com frequência.
- **`transaction`**: o cliente segura uma conexão do servidor durante uma transação e a devolve no
  `COMMIT` ou no `ROLLBACK`; um comando fora de transação é uma transação sozinho. Duzentos clientes
  dividem oito conexões, que é o resultado da seção 04.
- **`statement`**: a conexão é devolvida depois de cada comando, então transações com vários comandos
  são recusadas. Pouco usado.

O modo transação é o que faz um pool valer a pena, e o preço dele é este: **a próxima transação de
um cliente pode rodar numa conexão diferente do servidor**, e tudo o que o cliente preparou na
conexão, e não dentro de uma transação, fica para trás na antiga.

## Uma configuração que vai para outra pessoa

Abra duas sessões `psql` pelo PgBouncer, `psql -h 127.0.0.1 -p 6432 market` em dois terminais. Na
**Sessão A**, defina um timeout de comando de um segundo, como uma aplicação faria ao iniciar, e
pergunte qual processo do servidor respondeu:

```
market=# SET statement_timeout = '1s';
SET
Time: 0.954 ms

market=# SELECT pg_backend_pid();
 pg_backend_pid 
----------------
           8617
(1 row)

Time: 0.878 ms
```

Agora na **Sessão B**, abra uma transação e faça a mesma pergunta:

```
market=# BEGIN;
BEGIN
Time: 0.685 ms

market=*# SELECT pg_backend_pid();
 pg_backend_pid 
----------------
           8617
(1 row)

Time: 0.941 ms
```

**8617**: a Sessão B recebeu a conexão que a Sessão A usou um instante antes, porque ela estava livre
e o PgBouncer reaproveita primeiro a que voltou mais recentemente. Deixe a transação de B aberta e
volte à A:

```
market=# SHOW statement_timeout;
 statement_timeout 
-------------------
 0
(1 row)

Time: 0.881 ms

market=# SELECT pg_backend_pid();
 pg_backend_pid 
----------------
           8753
(1 row)

Time: 1.122 ms
```

O `statement_timeout` da Sessão A é **`0`**, como se nunca tivesse sido definido, e o processo dela é
outro, 8753, porque a conexão antiga está dentro da transação de B. Agora faça commit em B e olhe a
configuração ali:

```
market=*# COMMIT;
COMMIT
Time: 0.797 ms

market=# SHOW statement_timeout;
 statement_timeout 
-------------------
 1s
(1 row)

Time: 0.738 ms

market=# SELECT pg_backend_pid();
 pg_backend_pid 
----------------
           8617
(1 row)

Time: 0.715 ms
```

A Sessão B nunca definiu nada, e o timeout dela é **`1s`**. A transação seguinte rodou de novo na
8617, a conexão que ainda carrega o `SET` da Sessão A. Então a configuração foi perdida pelo cliente
que a fez e **entregue a um cliente que não a pediu** — o que, no caso do `statement_timeout`, é o
relatório de um estranho cancelado depois de um segundo, sem mudança nenhuma no código dele.

A regra que sai daí é simples de dizer: **no modo transação, não configure nada na sessão.**
Configurações pertencem ao papel ou ao banco (`ALTER ROLE … SET`, como a aula 15 fez com os
timeouts), ou ficam dentro da transação com `SET LOCAL`, que termina com ela.

## A mesma armadilha, mais três vezes

Tudo o que vive na sessão, e não na transação, tem o mesmo problema:

- **Advisory locks de sessão.** O `pg_advisory_lock` (aula 12) fica com a conexão do servidor até
  ser liberado ou a conexão fechar. Pego através de um pool por transação, ele fica numa conexão que o
  cliente já não segura, e o `pg_advisory_unlock` do cliente pode rodar em outra e não liberar nada. O
  `pg_advisory_xact_lock`, que termina com a transação, é o que funciona.
- **`LISTEN`.** Uma conexão que escuta recebe notificações quando elas chegam, entre transações. No
  modo transação o cliente não está preso a conexão nenhuma entre transações, então quem escuta deve
  usar uma conexão direta ou um pool em modo sessão.
- **Tabelas temporárias e cursores `WITH HOLD`**, que sobrevivem à transação que os criou, pelo mesmo
  motivo.

## Prepared statements

Os drivers preparam comandos para economizar a análise: mandam a consulta uma vez com um nome e
depois só o nome e os parâmetros. O nome vive na **conexão do servidor**, então num pool por
transação a próxima execução pode cair numa conexão que nunca o viu. O `pgbench -M prepared` se
comporta como um driver desses:

```
ana@vm:~/workload$ pgbench -h 127.0.0.1 -p 6432 -n -M prepared -c 4 -T 5 -f customer-orders.sql market 2>&1 | grep -E "error|processed" | head -3
pgbench: error: ERROR:  prepared statement "P_0" already exists
pgbench: error: ERROR:  prepared statement "P_0" already exists
pgbench: error: client 0 script 0 aborted in command 1 query 0: ERROR:  prepared statement "P_0" does not exist
```

`prepared statement "P_0" already exists` numa conexão, `does not exist` em outras: clientes
preparando em conexões onde outro já tinha preparado o mesmo nome, e executando em conexões onde
ninguém tinha. O PgBouncer 1.21 trouxe uma correção, e o 1.22, a versão que o Ubuntu instala, a tem:
com **`max_prepared_statements`** acima de zero, o PgBouncer acompanha o que cada cliente preparou e
prepara de novo, com um nome próprio, na conexão que o cliente receber. Acrescente uma linha abaixo de
`max_client_conn` no arquivo e recarregue:

```ini
max_prepared_statements = 100
```

```
ana@vm:~$ sudo systemctl reload pgbouncer
ana@vm:~/workload$ pgbench -h 127.0.0.1 -p 6432 -n -M prepared -c 4 -T 5 -f customer-orders.sql market 2>&1 | grep -E "error|processed|^tps"
number of transactions actually processed: 86764
tps = 17414.583459 (without initial connection time)
```

**17415 transações por segundo** e nenhum erro. Restam dois limites. Ele cobre comandos preparados
pelo protocolo, que é o que os drivers fazem, e não o comando SQL `PREPARE` digitado como texto. E o
`100` é um teto de quantos ele acompanha, então um cliente que prepara mais comandos distintos que
isso vê os mais antigos serem preparados de novo pelo caminho.
