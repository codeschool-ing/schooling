---
title: Uma configuração que sobrevive ao seu cliente
version: 1
---

O modo transaction devolve a conexão com o servidor depois de cada transação, então a próxima
transação do mesmo cliente pode rodar numa conexão diferente, e a de outro cliente pode rodar nesta.
Tudo o que um cliente configura **para a sua sessão** fica com a conexão do servidor, não com o
cliente. O `shop` recebeu um pool de uma conexão só, o que torna o efeito certo em vez de provável.
Três clientes separados, um depois do outro:

```
ana@vm:~$ psql -h 127.0.0.1 -p 6433 -U shop_app shop -c "SET statement_timeout = '1ms'"
SET
ana@vm:~$ psql -h 127.0.0.1 -p 6433 -U shop_app shop -c "SHOW statement_timeout"
 statement_timeout 
-------------------
 1ms
(1 row)

ana@vm:~$ psql -h 127.0.0.1 -p 6433 -U shop_app shop -c "SELECT count(*) FROM orders"
ERROR:  canceling statement due to statement timeout
```

O primeiro cliente definiu um `statement_timeout` de um milissegundo para a sua sessão e saiu. O
segundo cliente, que não definiu nada, **encontrou a configuração**. O terceiro rodou uma contagem
comum e foi cancelado por um timeout que nunca pediu. Em produção, com um pool de vinte e mil
clientes, isso é um bug que aparece em uma requisição a cada algumas centenas, na conexão em que a
configuração tiver caído, e que nunca se reproduz na máquina de um desenvolvedor.

O que vaza no modo transaction é qualquer coisa que pertença à sessão e não à transação:

- `SET` sem `LOCAL`: timeouts, `search_path`, o fuso horário;
- prepared statements criados com `PREPARE` em SQL, e advisory locks de nível de sessão;
- tabelas temporárias, e `LISTEN`.

A cura para as configurações é o `SET LOCAL`, que dura até o fim da transação:

```
ana@vm:~$ psql -h 127.0.0.1 -p 6433 -U shop_app shop -c "SET statement_timeout = 0"
SET
ana@vm:~$ psql -h 127.0.0.1 -p 6433 -U shop_app shop -c "BEGIN" -c "SET LOCAL statement_timeout = '1ms'" -c "SHOW statement_timeout" -c "COMMIT"
BEGIN
SET
 statement_timeout 
-------------------
 1ms
(1 row)

COMMIT
ana@vm:~$ psql -h 127.0.0.1 -p 6433 -U shop_app shop -c "SHOW statement_timeout"
 statement_timeout 
-------------------
 0
(1 row)
```

Dentro da transação o timeout valeu; depois do `COMMIT`, o próximo cliente vê `0`, o padrão que o
primeiro comando deste bloco restaurou. Uma aplicação atrás de um pool em modo transaction define tudo
de que precisa com `SET LOCAL` dentro de cada transação, ou uma vez por usuário no banco com
`ALTER ROLE … SET`, que toda conexão nova herda.
