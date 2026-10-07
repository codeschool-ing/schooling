---
title: Qual consulta é a lenta
version: 1
---

A aula anterior terminou numa regra: acrescente um índice porque você olhou. Esta aula é o olhar,
e ela começa um passo antes de onde a maioria começa — antes de conseguir ler um plano, você
precisa saber **de qual** consulta ler o plano.

O jeito errado de descobrir é esperar a reclamação. A reclamação nomeia uma tela, a tela roda seis
consultas, e a lenta não é a que a pessoa chutou. O jeito certo é perguntar ao banco, que estava
contando.

## O banco guarda o placar

A extensão `pg_stat_statements` do PostgreSQL registra toda instrução distinta que o servidor
rodou, com quantas vezes e por quanto tempo. Ela precisa ser carregada na inicialização —
`shared_preload_libraries` na configuração — e daí em diante é uma tabela que você consulta como
qualquer outra.

Ligá-la são três comandos, e o do meio reinicia o servidor, porque uma biblioteca carregada na
inicialização só é lida na inicialização:

```
ana@vm:~$ psql shop -c "ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements'"
ALTER SYSTEM
ana@vm:~$ sudo pg_ctlcluster 16 main restart
ana@vm:~$ psql shop -c "CREATE EXTENSION pg_stat_statements"
CREATE EXTENSION
```

Depois a loja precisa de algum tráfego para ter placar. Este arquivo é uma manhã de consultas de
uma aplicação comprimida em poucos segundos — o `\gexec` roda cada linha que um `SELECT` devolve
como uma instrução própria, então cada linha abaixo manda a mesma consulta muitas vezes com
valores diferentes:

```sql
-- traffic.sql: a morning of the shop's queries, a few seconds long.
SELECT pg_stat_statements_reset();

SELECT 'SELECT c.city, count(*) FROM customers c JOIN orders o ON o.customer_id = c.id GROUP BY c.city'
FROM generate_series(1, 3) \gexec

SELECT format('SELECT count(*) FROM orders WHERE status = %L', (ARRAY['paid', 'shipped', 'cancelled'])[1 + n % 3])
FROM generate_series(1, 30) AS n \gexec

SELECT $$SELECT * FROM orders WHERE date(placed_at) = DATE '2025-03-01'$$ \gexec

SELECT format('SELECT id, name FROM customers WHERE email = %L', 'user' || n * 211 || '@example.com')
FROM generate_series(1, 400) AS n \gexec

SELECT format('SELECT id, total FROM orders WHERE customer_id = %s', n * 613)
FROM generate_series(1, 150) AS n \gexec
```

```
ana@vm:~$ psql shop -f traffic.sql >/dev/null
```

Aqui está o que o servidor guardou:

```
shop=# SELECT calls, round(total_exec_time::numeric) AS total_ms, round(mean_exec_time::numeric, 1) AS mean_ms, left(query, 55) AS query FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 5;
 calls | total_ms | mean_ms |                          query                          
-------+----------+---------+---------------------------------------------------------
   150 |     3532 |    23.5 | SELECT id, total FROM orders WHERE customer_id = $1
     3 |      404 |   134.7 | SELECT c.city, count(*) FROM customers c JOIN orders o 
    30 |      297 |     9.9 | SELECT count(*) FROM orders WHERE status = $1
     1 |       47 |    47.1 | SELECT * FROM orders WHERE date(placed_at) = DATE $1
   400 |        5 |     0.0 | SELECT id, name FROM customers WHERE email = $1
(5 rows)
```

Três coisas para ler nessa tabela, e são as três coisas para as quais a ferramenta existe.

**Os literais sumiram.** `WHERE email = $1`, não `WHERE email = 'user211@example.com'`. Quatrocentas
buscas por quatrocentos endereços diferentes são uma linha, porque são uma consulta — que é o que
você quer quando a pergunta é "o que esta aplicação está fazendo", e é por isso que a ferramenta
vale mais que o log logo abaixo.

**Ordene pelo total, não pela média.** A consulta do topo leva 23 milissegundos, que ninguém
chamaria de lento, e rodou cento e cinquenta vezes: três segundos e meio do servidor, mais que todo
o resto da lista somado. O relatório por cidade logo abaixo é quase seis vezes mais lento por
chamada e custa cerca de um nono disso, porque rodou três vezes. Uma consulta de um milissegundo que roda um milhão de vezes por
dia são mil segundos de banco, e ela nunca aparece na reclamação de ninguém.

**A média é a outra lista**, e é nela que mora a experiência de um usuário:

```
shop=# SELECT calls, round(mean_exec_time::numeric, 1) AS mean_ms, left(query, 55) AS query FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 3;
 calls | mean_ms |                          query                          
-------+---------+---------------------------------------------------------
     3 |   134.7 | SELECT c.city, count(*) FROM customers c JOIN orders o 
     1 |    47.1 | SELECT * FROM orders WHERE date(placed_at) = DATE $1
   150 |    23.5 | SELECT id, total FROM orders WHERE customer_id = $1
(3 rows)
```

O relatório por cidade vem primeiro, com 135 milissegundos por chamada, e a consulta com
`date(placed_at)` rodou uma vez e levou 47. Alguém esperou por cada uma. A aula 9 disse por que a
segunda é lenta, e a seção sobre estimativas desta aula mostra o que o plano diz a respeito. A busca
por `customer_id`, topo da outra lista, é a terceira aqui — e a próxima etapa começa por ela.

Duas listas, duas perguntas: **o que está custando mais ao servidor**, e **o que está custando
mais a uma pessoa**. Trabalhe a primeira quando a máquina está ocupada e a segunda quando alguém
está insatisfeito, e confira as duas, porque elas discordam mais vezes do que concordam.

## O log, para as que só às vezes são lentas

O `pg_stat_statements` faz média. Uma consulta que é rápida mil vezes e leva dez segundos uma vez é
uma consulta rápida naquela tabela. A outra ferramenta pega a vez. O `log_min_duration_statement`
escreve no log do servidor toda instrução mais lenta que um limiar, e um superusuário pode mudá-lo
sem reiniciar:

```
shop=# ALTER SYSTEM SET log_min_duration_statement = '100ms';
ALTER SYSTEM

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)
```

Cem milissegundos, para que o relatório por cidade deste servidor passe dele. Rode o relatório duas
vezes e leia o fim do log — o arquivo que o `pg_lsclusters` mostrou na aula 1:

```
ana@vm:~$ psql shop -c "SELECT c.city, count(*) FROM customers c JOIN orders o ON o.customer_id = c.id GROUP BY c.city;" >/dev/null
ana@vm:~$ psql shop -c "SELECT c.city, count(*) FROM customers c JOIN orders o ON o.customer_id = c.id GROUP BY c.city;" >/dev/null
ana@vm:~$ sudo tail -n 2 /var/log/postgresql/postgresql-16-main.log
2026-10-07 07:57:31.963 UTC [11417] ana@shop LOG:  duration: 149.903 ms  statement: SELECT c.city, count(*) FROM customers c JOIN orders o ON o.customer_id = c.id GROUP BY c.city;
2026-10-07 07:57:32.191 UTC [11426] ana@shop LOG:  duration: 180.310 ms  statement: SELECT c.city, count(*) FROM customers c JOIN orders o ON o.customer_id = c.id GROUP BY c.city;
```

Cada linha tem a hora, o processo, quem pediu e em que banco — `ana@shop` —, depois a duração e o
**texto completo, literais incluídos**. Os literais são a graça aqui. Quando uma consulta é lenta só para um cliente, o log tem o cliente,
e o plano que você vai tirar em seguida tem que ser rodado com aquele valor e não com um
marcador. Um plano para `$1` é um plano para ninguém em particular, e a seção sobre estimativas
diz por que isso pode ser outro plano.

Onde pôr o limiar é uma decisão, e um limiar baixo num servidor movimentado escreve um log mais
rápido do que alguém lê. Algumas centenas de milissegundos é onde a maioria começa, e ele desce
conforme as óbvias vão sendo resolvidas. Na sua própria máquina, volte atrás depois de olhar:

```
shop=# ALTER SYSTEM RESET log_min_duration_statement;
ALTER SYSTEM

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)
```

O MySQL tem as mesmas duas ferramentas com outros nomes: o slow query log, com `long_query_time`,
e as tabelas do `performance_schema`, que `sys.statement_analysis` resume no mesmo formato da
tabela acima. A aula 12 tem as diferenças.

## O que você tem agora

Uma consulta, com o valor para o qual ela foi lenta, e um número de quão lenta. Essa é a entrada
de todo o resto desta aula, e vale insistir: **um plano sem uma medição para comparar é um plano
que você não consegue dizer se melhorou.**
