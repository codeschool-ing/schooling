---
title: O log, para a execução lenta isolada
version: 1
---

O `pg_stat_statements` soma execuções, e somar é o que o faz bom em achar para onde vai o tempo. É
também o que o deixa cego para um evento isolado. Um comando com média de 9 milissegundos pode ter
tido uma execução que levou dois segundos às 03:12 da madrugada, e o placar guarda isso só como mais
uma contribuição para `max_exec_time`, sem hora, sem parâmetros e sem sessão.

Para isso, o **log** do servidor é a outra metade. A configuração `log_min_duration_statement` faz
o servidor escrever uma linha para cada comando que demora mais que um limite, com o momento em que
terminou, o processo que o rodou, o papel e o banco, e o comando **com os valores de verdade**. Não
precisa de reinício — um reload basta, porque a configuração pode mudar com o servidor rodando:

```
market=# ALTER SYSTEM SET log_min_duration_statement = '50ms';
ALTER SYSTEM
Time: 2.682 ms

market=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)

Time: 0.699 ms
ana@vm:~/workload$ pgbench -n -c 4 -T 10 -f seller-dashboard.sql -f pending-count.sql market > /dev/null
```

Depois, alguns segundos de dois dos scripts da carga, e o fim do arquivo de log:

```
ana@vm:~$ sudo tail -n 4 /var/log/postgresql/postgresql-16-main.log
	WHERE seller_id = 21 AND placed_at >= '2025-12-01'
	GROUP BY 1 ORDER BY 1;
2026-10-10 04:25:37.386 -03 [11018] ana@market LOG:  duration: 100.997 ms  statement: SELECT count(*) FROM orders WHERE status = 'pending';
2026-10-10 04:25:37.403 -03 [11017] ana@market LOG:  duration: 124.966 ms  statement: SELECT count(*) FROM orders WHERE status = 'pending';
```

O arquivo está cortado onde o `tail` cortou. As duas primeiras linhas são o fim de uma entrada
mais longa: uma execução do painel do vendedor que passou de 50 milissegundos, escrita como a
aplicação a enviou, em várias linhas, **com o vendedor para quem era** — `seller_id = 21` —, onde o
`pg_stat_statements` só diria `$2`. As duas últimas são a contagem da tela de operações, com 101 e
125 milissegundos, de dois processos diferentes, os números entre colchetes, com dezessete
milissegundos de distância. Esse é o formato que o placar não consegue mostrar: **duas pessoas
atualizaram a mesma tela no mesmo momento, e cada uma pagou o preço inteiro**.

## Escolhendo o limite

O limite é uma troca entre o que você pega e o que custa. Cada linha é uma escrita num arquivo no
mesmo disco do banco, e um limite zero registra todo comando, o que, num servidor fazendo mil por
segundo, são mil linhas por segundo e uma lentidão mensurável por si só. Duas escolhas são comuns
na prática:

- **algumas centenas de milissegundos a um segundo** num servidor de produção movimentado, para
  pegar os pontos fora da curva e nada mais;
- **zero, por uma janela curta**, quando você precisa ver tudo o que uma aplicação faz — por um
  minuto, e depois de volta.

A aula 19 do `db-administration` trata de logging como um todo, o que registrar e a que custo. Para
este curso, o log é uma ferramenta que você liga, lê e desliga de novo:

```sql
ALTER SYSTEM RESET log_min_duration_statement;
SELECT pg_reload_conf();
```

## Qual usar

Elas respondem a perguntas diferentes, e o erro é usar uma para a pergunta da outra:

| pergunta | ferramenta |
|---|---|
| para onde vai o tempo do servidor, ao longo de um dia? | `pg_stat_statements` |
| o que aconteceu às 03:12 da madrugada? | o log |
| que valores deixaram este comando lento? | o log |
| meu conserto deixou este comando mais barato? | `pg_stat_statements`, zerado antes e lido depois |

O log responde com **evidência sobre uma execução**: uma hora, um processo, os valores exatos. O
placar responde com **aritmética sobre todas elas**. Uma terceira ferramenta fica entre as duas: a
extensão `auto_explain` escreve o **plano** de um comando lento no mesmo log, para que a evidência
inclua o que o servidor decidiu fazer. Um plano é o que a aula 3 ensina a ler, e é nesse momento
que ela passa a ser útil.
