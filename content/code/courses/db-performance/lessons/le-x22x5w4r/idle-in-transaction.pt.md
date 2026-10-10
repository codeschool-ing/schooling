---
title: Idle in transaction, e os timeouts que o encerram
version: 1
---

A Sessão A era uma pessoa que abriu uma transação e foi embora. Em produção o mesmo estado quase
sempre é produzido por **código**, e ele tem nome próprio na `pg_stat_activity`: `idle in
transaction`. A conexão está aberta, uma transação começou, o último comando terminou, e o servidor
espera o próximo, que a aplicação não tem pressa nenhuma de mandar.

## Como as aplicações chegam lá

Três formas cobrem quase tudo o que você vai encontrar:

- **Trabalho que não é de banco no meio de uma transação.** `BEGIN`, atualiza o pedido, chama o
  provedor de pagamento e espera dois segundos por ele, grava o resultado, `COMMIT`. Cada compra
  segura a transação aberta durante uma chamada HTTP ao servidor de outra empresa — e, enquanto ela
  está aberta, também a trava da linha do pedido, que é o assunto das aulas 12 e 13.
- **Uma transação que nunca foi fechada.** Um caminho de erro que retorna sem `ROLLBACK`, um
  framework que abre uma transação por requisição e uma requisição que nunca termina, um pool que
  devolve uma conexão com uma transação ainda aberta dentro.
- **Uma pessoa.** Um `psql` ou um cliente gráfico deixado com `BEGIN` digitado na hora do almoço, ou
  um cliente configurado para desligar o autocommit, de modo que o primeiro `SELECT` da manhã abre uma
  transação que dura até alguém desconectar.

A primeira é a que vale eliminar no projeto: **faça o trabalho lento de fora antes da transação ou
depois dela**, e deixe na transação só os comandos que precisam dar certo ou errado juntos. As
outras duas não se eliminam no projeto, só se limitam, e o PostgreSQL tem uma configuração para cada
uma.

## `idle_in_transaction_session_timeout`

Esta configuração encerra uma sessão que ficou ociosa dentro de uma transação por mais tempo do que
ela permite. Vem desligada, que é o valor `0`. Ajuste para cinco segundos numa sessão, abra uma
transação, leia alguma coisa e deixe o terminal em paz por seis segundos antes de digitar de novo:

```
market=# SHOW idle_in_transaction_session_timeout;
 idle_in_transaction_session_timeout 
-------------------------------------
 0
(1 row)

Time: 0.370 ms

market=# SET idle_in_transaction_session_timeout = '5s';
SET
Time: 0.213 ms

market=# BEGIN;
BEGIN
Time: 0.295 ms

market=*# SELECT count(*) FROM sellers;
 count 
-------
  1000
(1 row)

Time: 2.085 ms

market=*# SELECT count(*) FROM sellers;
FATAL:  terminating connection due to idle-in-transaction timeout
server closed the connection unexpectedly
	This probably means the server terminated abnormally
	before or while processing the request.
The connection to the server was lost. Attempting reset: Succeeded.
Time: 4.521 ms
```

O servidor esperou cinco segundos e então **encerrou a sessão inteira**, não só a transação:
`FATAL`, e a conexão acabou. O `psql` percebeu quando tentou mandar o próximo comando, e se
reconectou sozinho, o que o driver de uma aplicação pode fazer ou não. A transação foi desfeita, as
travas liberadas, e o horizonte que ela segurava avançou.

Essa severidade é o objetivo e também o preço. Uma sessão encerrada com `FATAL` custa à aplicação um
erro e uma reconexão, então o valor é escolhido contra o maior intervalo ocioso que uma transação
**correta** da aplicação chega a ter, com folga: longo o bastante para que só uma transação esquecida
o alcance, curto o bastante para que uma esquecida seja encerrada antes de causar muito estrago.
Minutos, e não segundos, é a faixa habitual, e o número certo é uma medida da sua aplicação, não um
padrão.

## `statement_timeout`, para a outra metade

Uma transação ocupada, e não ociosa, não é coberta por essa configuração. Um relatório de vinte
minutos segura um snapshot tanto quanto uma sessão ociosa, e o estado dele na `pg_stat_activity` é
`active`. O `statement_timeout` cancela qualquer comando isolado que rode mais do que ele permite:

```
market=# SET statement_timeout = '100ms';
SET
Time: 0.384 ms

market=# SELECT count(*) FROM order_lines WHERE quantity = 3;
ERROR:  canceling statement due to statement timeout
Time: 118.517 ms
```

Este é um `ERROR`, não um `FATAL`. O comando é cancelado, a sessão continua, e dentro de uma
transação a transação fica em estado de falha até o cliente fazer rollback. A contagem sobre
`order_lines` leva um par de centenas de milissegundos com o cache quente, então um limite de 100 a
cancelou aos **118,5 milissegundos**.

Nenhuma das duas cobre o caso da outra, e é por isso que existem duas. O PostgreSQL 17 traz uma
terceira, `transaction_timeout`, que limita a transação inteira, faça ela o que fizer; o servidor
deste curso é a versão 16, que não a tem, e por isso ela não foi rodada aqui.

## Onde configurá-las

`SET` muda uma configuração numa sessão, o que é certo para um experimento e errado para uma defesa,
porque as sessões que precisam dela são justamente aquelas para as quais ninguém está olhando.
Configure-as para **o banco**, ou para **o papel com que a aplicação se conecta**, de modo que toda
sessão nova já comece com elas:

```
market=# ALTER DATABASE market SET idle_in_transaction_session_timeout = '1min';
ALTER DATABASE
Time: 3.226 ms
market=# \q
ana@vm:~$ psql market
market=# SHOW idle_in_transaction_session_timeout;
 idle_in_transaction_session_timeout 
-------------------------------------
 1min
(1 row)

Time: 0.463 ms
```

O `ALTER DATABASE` não muda nada nas sessões já conectadas; a nova, depois de `\q` e `psql market`,
começa com o minuto. `ALTER ROLE app SET …` faz o mesmo para um papel. Esse é o lugar melhor quando a
aplicação, as migrações e as pessoas que leem dados se conectam com papéis diferentes e precisam de
limites diferentes: uma migração que reconstrói um índice roda, legitimamente, por mais tempo do
que qualquer requisição deveria.

Configurar para o servidor inteiro no `postgresql.conf` também funciona, e costuma ser amplo demais:
o mesmo limite passa a valer para uma migração, uma rotina de manutenção e a consulta longa e
legítima de um analista. Desfaça esta antes de seguir, para que ela não encerre as transações que a
próxima seção abre de propósito:

```
market=# ALTER DATABASE market RESET idle_in_transaction_session_timeout;
ALTER DATABASE
Time: 5.641 ms
```
