---
title: pg_blocking_pids, e a sessão na raiz
version: 1
---

O `pg_blocking_pids(pid)` recebe o id de processo de uma sessão e devolve os ids das sessões pelas
quais ela está esperando, como um array. Ele aplica as regras do próprio servidor: a matriz de
conflitos da aula 12 para travas de tabela, as esperas por transação da seção anterior para linhas,
e a fila da seção 04 da aula 12, em que uma sessão espera por alguém que também só está esperando.
**Ele responde a pergunta que o `pg_locks` obriga você a deduzir, e responde do jeito que o servidor
decidiu.** Um array vazio quer dizer que a sessão não espera ninguém.

## Quem está esperando, e por quem

As sessões que estão esperando uma trava agora são aquelas cujo `wait_event_type` no
`pg_stat_activity` é `Lock`. Na janela D:

```
market=# SELECT pid, pg_blocking_pids(pid) FROM pg_stat_activity WHERE wait_event_type = 'Lock';
 pid  | pg_blocking_pids 
------+------------------
 5794 | {5792}
 5796 | {5794}
(2 rows)

Time: 2.722 ms
```

A janela B (5794) espera a janela A (5792), e a janela C (5796) espera a janela B. Duas linhas, e o
formato inteiro do problema já está ali.

## A view para guardar

Essa resposta dá os nomes de quem espera. Para agir, você precisa da mesma lista com o que cada
sessão está fazendo e há quanto tempo, **incluindo as sessões que não estão esperando**, porque a
que está no fundo do problema costuma ser uma delas. Este arquivo lê tudo do `pg_stat_activity`, a
view com uma linha por conexão, e acrescenta o `pg_blocking_pids` a cada linha:

```sh
cat > ~/blocked.sql <<'SQL'
-- blocked.sql: every session on this database, oldest transaction first,
-- with the sessions it is waiting for and what it is doing.
SELECT pid,
       pg_blocking_pids(pid) AS blocked_by,
       state,
       wait_event_type || ':' || wait_event AS waiting_on,
       date_trunc('second', now() - xact_start) AS in_transaction,
       left(query, 45) AS last_query
FROM pg_stat_activity
WHERE datname = current_database() AND pid <> pg_backend_pid()
ORDER BY xact_start;
SQL
```

Grave-o e rode-o na janela D com `\i`, que lê um arquivo para dentro da sessão como se você o
tivesse digitado:

```
market=# \i ~/blocked.sql
 pid  | blocked_by |        state        |     waiting_on     | in_transaction |                  last_query                   
------+------------+---------------------+--------------------+----------------+-----------------------------------------------
 5792 | {}         | idle in transaction | Client:ClientRead  | 00:00:33       | UPDATE orders SET status = 'shipped' WHERE id
 5794 | {5792}     | active              | Lock:transactionid | 00:00:31       | UPDATE orders SET status = 'shipped' WHERE id
 5796 | {5794}     | active              | Lock:transactionid | 00:00:26       | UPDATE orders SET status = 'cancelled' WHERE 
(3 rows)

Time: 2.821 ms
```

Cinco colunas contam a história, uma sessão por linha.

**`blocked_by`** é a função acima. Leia como setas: 5794 aponta para 5792, 5796 aponta para 5794.

**`state`** é o que a conexão está fazendo. `active` quer dizer que um comando está rodando, e aqui
as duas sessões ativas estão rodando um comando que só está esperando. **`idle in transaction`**
quer dizer que a conexão tem uma transação aberta e não está rodando nada: o servidor está
esperando o cliente mandar o próximo comando. A janela A é isso: a sessão que não está fazendo nada,
com todo o resto preso atrás dela.

**`waiting_on`** junta `wait_event_type` e `wait_event`. `Lock:transactionid` é o `ShareLock on
transaction` da seção anterior, visto daqui. `Client:ClientRead` é um backend esperando o cliente
dizer alguma coisa, o que, para uma sessão idle in transaction, é a explicação inteira: **o
servidor não está lento, a aplicação parou de falar.**

**`in_transaction`** é há quanto tempo a transação da sessão começou, a partir de `xact_start`. A
transação aberta mais antiga é a primeira linha, porque o arquivo ordena por ela, e num servidor de
verdade é a primeira linha a olhar, por um motivo a que a aula 15 dedica uma aula inteira.

**`last_query`** é o comando mais recente que a sessão mandou, cortado aqui em 45 caracteres. Para
uma sessão ativa, é o comando rodando agora. Para uma ociosa, é o **último** comando que ela rodou,
e essa é a melhor pista que você tem sobre que parte da aplicação deixou a transação aberta: o
`UPDATE` do pedido 1, mandado há 33 segundos e nunca seguido de um `COMMIT`.

## O que ler primeiro

Num servidor de verdade, esta view tem dezenas ou centenas de linhas. Três hábitos a tornam rápida:

- **Olhe o `blocked_by` antes de qualquer coisa.** A maioria das linhas é `{}`; as que não são são
  o problema, e os pids dentro das chaves são onde olhar em seguida.
- **Siga um pid que aparece no `blocked_by` de alguém até a linha dele.** Se o `blocked_by` dele
  for `{}`, você achou uma sessão que bloqueia e não espera, e ela é candidata a raiz.
- **Desconfie da sessão que não está fazendo nada.** Uma consulta `active` longa é visível para
  todos; uma sessão `idle in transaction` há 33 segundos, ou há três horas, parece inofensiva em
  todo painel que só mostra consultas em execução.

Duas sessões esperando dá para seguir a olho. A próxima seção escreve a consulta que segue uma
cadeia mais longa por você.
