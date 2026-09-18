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

Aqui está ela na loja da aula 1, depois de uma manhã de tráfego:

```
shop=# SELECT calls, round(total_exec_time::numeric) AS total_ms, round(mean_exec_time::numeric, 1) AS mean_ms, left(query, 55) AS query FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 5;
 calls | total_ms | mean_ms |                          query                          
-------+----------+---------+---------------------------------------------------------
     3 |     1096 |   365.3 | SELECT c.city, count(*) FROM customers c JOIN orders o 
    30 |      890 |    29.7 | SELECT count(*) FROM orders WHERE status = $1
     1 |      115 |   114.7 | SELECT * FROM orders WHERE date(placed_at) = DATE $1
   400 |       24 |     0.1 | SELECT id, name FROM customers WHERE email = $1
   150 |       18 |     0.1 | SELECT id, total FROM orders WHERE customer_id = $1
(5 rows)
```

Três coisas para ler nessa tabela, e são as três coisas para as quais a ferramenta existe.

**Os literais sumiram.** `WHERE email = $1`, não `WHERE email = 'ana@example.com'`. Quatrocentas
buscas por quatrocentos endereços diferentes são uma linha, porque são uma consulta — que é o que
você quer quando a pergunta é "o que esta aplicação está fazendo", e é por isso que a ferramenta
vale mais que o log logo abaixo.

**Ordene pelo total, não pela média.** O relatório do topo roda três vezes e custa um segundo no
total. A contagem por status é doze vezes mais rápida por chamada e ainda assim é a segunda da
lista, porque rodou trinta vezes. Uma consulta de um milissegundo que roda um milhão de vezes por
dia são mil segundos de banco, e ela nunca aparece na reclamação de ninguém.

**A média é a outra lista**, e é nela que mora a experiência de um usuário:

```
shop=# SELECT calls, round(mean_exec_time::numeric, 1) AS mean_ms, left(query, 55) AS query FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 3;
 calls | mean_ms |                          query                          
-------+---------+---------------------------------------------------------
     3 |   365.3 | SELECT c.city, count(*) FROM customers c JOIN orders o 
     1 |   114.7 | SELECT * FROM orders WHERE date(placed_at) = DATE $1
    30 |    29.7 | SELECT count(*) FROM orders WHERE status = $1
(3 rows)
```

A consulta com `date(placed_at)` rodou uma vez e levou um décimo de segundo. Alguém esperou por
isso. A aula 9 disse por que ela é lenta, e a seção sobre estimativas desta aula mostra o que o
plano diz a respeito.

Duas listas, duas perguntas: **o que está custando mais ao servidor**, e **o que está custando
mais a uma pessoa**. Trabalhe a primeira quando a máquina está ocupada e a segunda quando alguém
está insatisfeito, e confira as duas, porque elas discordam mais vezes do que concordam.

## O log, para as que só às vezes são lentas

O `pg_stat_statements` faz média. Uma consulta que é rápida mil vezes e leva dez segundos uma vez é
uma consulta rápida naquela tabela. A outra ferramenta pega a vez:

```
log_min_duration_statement = 250ms
```

Toda instrução mais lenta que o limiar é escrita no log com a duração e o texto completo, literais
incluídos:

```
2026-09-17 23:02:51.164 UTC [4335] postgres@shop LOG:  duration: 369.678 ms  statement: SELECT c.city, count(*) FROM customers c JOIN orders o ON o.customer_id = c.id GROUP BY c.city;
2026-09-17 23:02:51.594 UTC [4337] postgres@shop LOG:  duration: 398.804 ms  statement: SELECT c.city, count(*) FROM customers c JOIN orders o ON o.customer_id = c.id GROUP BY c.city;
```

Os literais são a graça aqui. Quando uma consulta é lenta só para um cliente, o log tem o cliente,
e o plano que você vai tirar em seguida tem que ser rodado com aquele valor e não com um
marcador. Um plano para `$1` é um plano para ninguém em particular, e a seção sobre estimativas
diz por que isso pode ser outro plano.

Onde pôr o limiar é uma decisão, e um limiar baixo num servidor movimentado escreve um log mais
rápido do que alguém lê. Algumas centenas de milissegundos é onde a maioria começa, e ele desce
conforme as óbvias vão sendo resolvidas.

O MySQL tem as mesmas duas ferramentas com outros nomes: o slow query log, com `long_query_time`,
e as tabelas do `performance_schema`, que `sys.statement_analysis` resume no mesmo formato da
tabela acima. A aula 12 tem as diferenças.

## O que você tem agora

Uma consulta, com o valor para o qual ela foi lenta, e um número de quão lenta. Essa é a entrada
de todo o resto desta aula, e vale insistir: **um plano sem uma medição para comparar é um plano
que você não consegue dizer se melhorou.**
