---
title: O servidor anota o placar
version: 1
---

Quando alguém diz "o banco está lento", o instinto é abrir o `psql`, rodar a consulta suspeita e
cronometrá-la. Isso responde a uma pergunta sobre uma consulta, e a pergunta nunca foi essa. A
pergunta é **para onde vai o tempo do servidor**, e para isso é preciso um registro de tudo o que
ele rodou, que ninguém olhando um terminal tem.

O PostgreSQL consegue manter esse registro. A extensão `pg_stat_statements` observa cada comando
que o servidor executa e o soma a um placar corrente: quantas vezes rodou, quanto tempo levou no
total, o mais rápido e o mais lento, quantas linhas devolveu, quantas páginas leu. A aula 10 do
`sql-databases` a ligou por um momento; este curso a deixa ligada de vez, porque quase toda aula
daqui em diante começa perguntando algo a ela.

## Ligando

A extensão vem com o PostgreSQL, mas tem de ser **carregada quando o servidor inicia**, porque se
pendura no código que executa cada consulta. Essa é a configuração `shared_preload_libraries`, e
uma configuração lida na partida só muda com um reinício:

```
market=# ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';
ALTER SYSTEM
Time: 6.728 ms
ana@vm:~$ sudo systemctl restart postgresql
market=# CREATE EXTENSION pg_stat_statements;
CREATE EXTENSION
Time: 18.724 ms
```

Três passos, e a ordem importa. O `ALTER SYSTEM` grava a configuração num arquivo que o servidor lê
na partida, o `postgresql.auto.conf`, e ainda não muda nada. O reinício carrega a biblioteca. O
`CREATE EXTENSION` então cria, dentro do `market`, a view que você consulta.

O `ALTER SYSTEM` exige um superusuário, que é o que a aula 1 fez do seu papel. Num serviço
gerenciado você não consegue rodá-lo; o provedor tem um botão próprio, e a maioria liga esta
extensão por padrão, porque ninguém opera bem um banco sem ela.

## O que uma linha quer dizer

A view tem uma linha por **comando distinto**, e "distinto" é decidido depois que as constantes
saem. `WHERE customer_id = 17` e `WHERE customer_id = 90210` são o mesmo comando para a extensão,
guardado uma vez como `WHERE customer_id = $1`, com um número chamado `queryid` que identifica esse
formato. É isso que torna o registro útil: uma tela que roda a mesma consulta um milhão de vezes
com um milhão de clientes diferentes é uma linha com uma contagem grande, e não um milhão de linhas
com contagem um.

As colunas que este curso mais lê:

| coluna | o que diz |
|---|---|
| `calls` | quantas vezes o comando rodou |
| `total_exec_time` | a soma de todas as execuções, em milissegundos |
| `mean_exec_time`, `min_exec_time`, `max_exec_time`, `stddev_exec_time` | a média, os extremos e o quanto as execuções se espalharam |
| `rows` | as linhas devolvidas ou afetadas, somadas em todas as chamadas |
| `shared_blks_hit`, `shared_blks_read` | páginas encontradas na memória do PostgreSQL, e páginas que ele teve de pedir ao sistema operacional |
| `query` | o comando, com as constantes trocadas por `$1`, `$2`… |

Os tempos são **do próprio servidor**: de quando ele começou a executar a quando terminou, sem a
viagem pela conexão que o `\timing` da aula 1 inclui. E são contados **desde o último reset**, seja
uma chamada a `pg_stat_statements_reset()`, seja, como faz o caminho de volta às linhas conhecidas
desta aula, um banco novo. Todo placar tem um começo, e um número nele não significa nada enquanto
você não souber quando foi.

O registro está vazio por enquanto, fora os comandos que você acabou de digitar. A próxima seção dá
ao servidor algo para contar.
