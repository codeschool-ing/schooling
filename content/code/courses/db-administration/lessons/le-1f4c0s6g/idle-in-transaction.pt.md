---
title: Ocioso dentro de uma transação
version: 1
---

A conexão que mais faz estrago costuma ser a que não está fazendo nada. **Uma sessão que abriu uma
transação e parou de mandar comandos está `idle in transaction`**, e guarda tudo o que a transação
pegou: os locks de linha do que ela mudou, e o snapshot que diz ao vacuum quais versões antigas de
linha alguém ainda pode precisar. Uma aplicação que esqueceu um `COMMIT`, uma pessoa que digitou
`BEGIN` no psql e foi almoçar, e um programa esperando uma requisição web lenta entre dois comandos
têm todos essa cara.

Crie uma. Num terminal, como `app`, comece uma transação, mude uma linha e pare:

```sh
sudo -u app psql shop
```

```sql
BEGIN;
UPDATE customers SET name = 'Customer 1' WHERE id = 1;
```

## Encontrando

O `ps` já diz, porque o nome do backend carrega o estado dele:

```
ana@db:~$ ps -u postgres -o pid,cmd | grep "app shop"
    655 postgres: 16/main: app shop [local] idle in transaction
```

A `pg_stat_activity` diz há quanto tempo, que é o que decide se é um problema:

```
ana@db:~$ psql shop
shop=# SELECT pid, usename, state, now() - xact_start AS open_for, query
shop-#   FROM pg_stat_activity WHERE state = 'idle in transaction';
 pid | usename |        state        |    open_for     |                         query                          
-----+---------+---------------------+-----------------+--------------------------------------------------------
 655 | app     | idle in transaction | 00:00:01.111508 | UPDATE customers SET name = 'Customer 1' WHERE id = 1;
(1 row)

shop=# SELECT pg_cancel_backend(pid) FROM pg_stat_activity WHERE state = 'idle in transaction';
 pg_cancel_backend 
-------------------
 t
(1 row)

shop=# SELECT pid, state FROM pg_stat_activity WHERE usename = 'app';
 pid |        state        
-----+---------------------
 655 | idle in transaction
(1 row)

shop=# SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state = 'idle in transaction';
 pg_terminate_backend 
----------------------
 t
(1 row)

shop=# SELECT pid, state FROM pg_stat_activity WHERE usename = 'app';
 pid | state 
-----+-------
(0 rows)
```

O `xact_start` é quando a transação começou, então `open_for` é há quanto tempo ela segura o que
segura; na máquina de gravação ela estava aberta havia menos de dois segundos, e num servidor de
verdade as que valem a pena achar estão abertas há minutos ou horas. A `query` é o último comando,
que aqui nomeia a linha travada. Qualquer outra sessão que tente atualizar o cliente 1 agora espera
por esta, enquanto ela continuar aberta; as lições 12 e 13 do `db-performance` seguem uma fila
dessas até a ponta. A lição 14 mostra o que um snapshot antigo faz com o vacuum.

## Cancelar não basta

**O `pg_cancel_backend` cancela o comando que um backend está rodando, e este não está rodando
nenhum.** Ele respondeu `t`, querendo dizer que o sinal foi enviado, e a sessão ficou exatamente
como estava. Cancelar é a ferramenta certa para uma consulta que demora demais, e deixa a sessão e a
transação dela vivas.

**O `pg_terminate_backend` encerra a sessão**: o backend desfaz a transação, solta os locks e sai,
que é o `SIGTERM` que o shell mandou na seção de max-connections. O update é desfeito. Quem estava
esperando por aquela linha segue em frente. No primeiro terminal, a pessoa que saiu de perto descobre
no próximo comando:

```
ana@db:~$ sudo -u app psql shop
shop=> BEGIN;
BEGIN

shop=*> UPDATE customers SET name = 'Customer 1' WHERE id = 1;
UPDATE 1

shop=*> SELECT name FROM customers WHERE id = 1;
FATAL:  terminating connection due to administrator command
server closed the connection unexpectedly
	This probably means the server terminated abnormally
	before or while processing the request.
The connection to the server was lost. Attempting reset: Succeeded.
```

O `*` em `shop=*>` é o psql dizendo que há uma transação aberta, o que vale a pena notar nas suas
próprias sessões. O psql reconectou sozinho, numa sessão nova sem transação.

## Deixando o servidor fazer isso

Achar essas sessões à mão funciona uma vez. **O `idle_in_transaction_session_timeout` faz o servidor
encerrar qualquer sessão que fique ociosa numa transação por mais tempo que o limite.** Ajuste-o no
papel da aplicação em vez de no servidor inteiro, para que as suas próprias sessões e os trabalhos
longos de manutenção não sejam pegos por um limite escolhido para a aplicação:

```
ana@db:~$ psql shop -c "ALTER ROLE app SET idle_in_transaction_session_timeout = '10s'"
ALTER ROLE
ana@db:~$ sudo -u app psql shop
shop=> BEGIN;
BEGIN

shop=*> SELECT count(*) FROM orders WHERE customer_id = 42;
 count 
-------
    20
(1 row)

shop=*> SELECT 1;
FATAL:  terminating connection due to idle-in-transaction timeout
server closed the connection unexpectedly
	This probably means the server terminated abnormally
	before or while processing the request.
The connection to the server was lost. Attempting reset: Succeeded.
ana@db:~$ sudo grep "idle-in-transaction" /var/log/postgresql/postgresql-16-main.log
2026-10-10 16:57:08.033 -03 [691] app@shop FATAL:  terminating connection due to idle-in-transaction timeout
```

Doze segundos se passaram entre a contagem e o `SELECT 1`, e o servidor tinha encerrado a sessão aos
dez. **A configuração de um papel vale a partir da próxima conexão dele**, e é por isso que esta foi
uma sessão nova. A linha do log nomeia o papel e o banco, e uma sequência delas é a evidência a levar
para quem é dono da aplicação, porque a correção está no código dela: uma transação deve ficar
aberta só enquanto comandos estão sendo enviados.

Dez segundos é pouco, para a demonstração; um limite real é escolhido a partir de quanto tempo levam
as transações honestas da aplicação, muitas vezes um minuto ou alguns. O PostgreSQL 16 também tem o
`idle_session_timeout`, que encerra sessões ociosas fora de uma transação; raramente é o que você
quer na frente de uma aplicação que mantém um pool de conexões abertas de propósito.
