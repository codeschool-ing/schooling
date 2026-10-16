---
title: Travas consultivas, para o que não é linha
version: 1
---

Toda trava até aqui protegia algo que o banco conhece: uma tabela, uma linha. Às vezes o que
precisa de proteção é um trabalho. A recontagem noturna dos pedidos de cada vendedor tem de rodar
uma vez, mas é disparada por um agendador em cada um de três servidores de aplicação, porque ninguém
quer que o job dependa de uma máquina estar de pé. Nada nos dados diz "a recontagem está rodando",
e uma linha de `status` para dizer isso é a ferramenta errada: um worker que cai depois de
marcá-la a deixa marcada, e o job não roda mais até uma pessoa perceber.

**Uma trava consultiva (advisory lock) é uma trava sobre um número.** O banco não dá significado
nenhum a ela; o seu código decide que o número 42, ou o hash do texto `nightly-recount`, quer dizer
"a recontagem". O servidor só garante que duas sessões não seguram o mesmo número ao mesmo tempo, e
que as travas de uma sessão são liberadas quando a sessão termina, do jeito que terminar.

## Pegando uma, e não conseguindo

Na janela A:

```
market=# SELECT pg_try_advisory_lock(42);
 pg_try_advisory_lock 
----------------------
 t
(1 row)

Time: 1.248 ms
```

Na janela B, o mesmo número:

```
market=# SELECT pg_try_advisory_lock(42);
 pg_try_advisory_lock 
----------------------
 f
(1 row)

Time: 1.008 ms

market=# SELECT pg_advisory_lock(42);
```

O `pg_try_advisory_lock` responde na hora, `t` ou `f`, e nunca espera: a janela A pegou a trava 42
e a janela B ouviu não. O `pg_advisory_lock`, sem `try`, espera como qualquer outra trava, e a
janela B está esperando agora. Libere-a na janela A:

```
market=# SELECT pg_advisory_unlock(42);
 pg_advisory_unlock 
--------------------
 t
(1 row)

Time: 0.927 ms
```

```
market=# SELECT pg_advisory_lock(42);
 pg_advisory_lock 
------------------
 
(1 row)

Time: 6487.695 ms (00:06.488)
```

A janela B tinha esperado **6434 ms**, e a trava passou para ela no momento em que a janela A
soltou. Libere-a na janela B também com `SELECT pg_advisory_unlock(42);`.

Estas são travas **de sessão**: duram até serem liberadas ou até a sessão se desconectar, aconteça
o que acontecer com as transações no meio, e a mesma sessão pode pegar o mesmo número duas vezes e
então precisa liberá-lo duas vezes. A família `pg_advisory_xact_lock` é a versão **de transação**,
liberada no `COMMIT` ou no `ROLLBACK` e impossível de liberar à mão; ela é a escolha mais segura
quando o trabalho cabe numa transação, porque não há liberação para esquecer.

## Um job que só um worker roda

O agendador de cada servidor roda este arquivo com o `psql`. Ele pede a trava sem esperar, faz o
trabalho se conseguiu e avisa se não conseguiu, usando o `\if` do próprio psql:

```sh
cat > ~/nightly-job.sql <<'SQL'
-- nightly-job.sql: the nightly recount, started by every worker at 02:00
-- and done by exactly one of them. The others find the lock taken.
SELECT pg_try_advisory_lock(hashtext('nightly-recount')) AS got_it \gset
\if :got_it
  \echo 'this worker runs the nightly recount'
  -- the recount itself; pg_sleep stands in for it here
  SELECT pg_sleep(5) \g /dev/null
  \echo 'done'
\else
  \echo 'another worker holds the lock: nothing to do'
\endif
SQL
```

O `hashtext` transforma o nome do job no número, para que o código se leia como um nome e dois jobs
diferentes não colidam porque alguém reusou o 42. O `\gset` põe a resposta, `t` ou `f`, na variável
`got_it` do psql, e o `\if` decide por ela. Não há liberação no fim, de propósito: a trava vai
embora quando o psql se desconecta no fim do arquivo, e vai embora também se o psql for morto no
meio, que é exatamente o caso em que a linha de `status` falhava.

Comece dois workers com um segundo de diferença, como fariam dois agendadores com relógios
levemente diferentes:

```
ana@vm:~$ psql -qX market -f nightly-job.sql & sleep 1; psql -qX market -f nightly-job.sql; wait
this worker runs the nightly recount
another worker holds the lock: nothing to do
done
```

O primeiro worker pegou a trava e rodou; o segundo, um segundo depois, a encontrou segura e saiu na
hora; o primeiro terminou cinco segundos depois de começar. **Uma recontagem, de qualquer worker
que chegue primeiro, e nenhuma linha em lugar nenhum que uma queda possa deixar para trás.**

## Com o que tomar cuidado

**A trava pertence a uma conexão.** Atrás de um pooler de conexões em modo transação (aula 16), uma
trava consultiva de sessão é pega na conexão de servidor que o pooler entregou para aquela
transação. A transação seguinte pode receber outra, e a trava fica segura numa conexão que o seu
código não tem mais. Use as funções de transação nesse caso, ou uma conexão só do job.

**O espaço de números é compartilhado pelo banco inteiro.** Toda trava consultiva no `market` usa os
mesmos números, então duas equipes que escolhem 42 se bloqueiam. Faça hash de um nome, como o
arquivo faz, ou use a forma de dois argumentos, `pg_advisory_lock(class, id)`, com um número de
classe por tipo de trabalho.

**Elas aparecem no `pg_locks`** com `locktype` `advisory`, e é assim que a aula 13 acha a sessão que
segura uma quando um job parece travado.
