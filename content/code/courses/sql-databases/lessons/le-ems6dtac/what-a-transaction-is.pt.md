---
title: O que é uma transação, e aquela em que você já está
version: 2
---

```sql
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;
```

Duas instruções, uma unidade. Ou as duas tiveram efeito ou nenhuma teve, e nenhuma outra conexão
chega a ver um momento em que o dinheiro saiu de uma conta e não chegou na outra.

Sem o `BEGIN` e o `COMMIT`, a máquina perder energia entre as duas linhas destrói cem unidades de
dinheiro. Não perde de vista — **destrói**, de um jeito que nenhum código em volta das instruções
conserta, porque a primeira já é durável e nada registra que uma segunda era devida.

Essa é a metade fácil desta aula e a parte que todo mundo sabe. O resto trata do que acontece
quando outra pessoa está rodando as duas instruções dela ao mesmo tempo.

## `ROLLBACK`, que é a outra saída

```sql
BEGIN;
DELETE FROM order_lines WHERE order_id = 7;
-- that was the wrong order
ROLLBACK;
```

Não aconteceu nada. As linhas voltaram — ou melhor, elas nunca saíram, porque até uma transação
confirmar, as mudanças dela não são visíveis a ninguém e podem ser descartadas por inteiro.

É esta a rede de proteção a que a aula 7 ficou apontando. Um `DELETE` do qual você não tem certeza,
rodado dentro de uma transação, é uma instrução que você pode olhar antes de concordar com ela:

```sql
BEGIN;
DELETE FROM contacts WHERE id IN (…);
SELECT count(*) FROM contacts;     -- 4 812, and you expected 4 812
COMMIT;
```

Pegue o hábito enquanto o risco é baixo. Custa uma palavra.

## Você está sempre numa transação

Toda instrução roda dentro de uma. O que varia é quem a abriu:

```sql
UPDATE products SET price = price * 1.1;
```

Com **autocommit** ligado — que é o padrão no `psql`, no cliente `mysql` e na maioria dos drivers —
essa instrução é envolvida numa transação própria, aberta antes e confirmada depois. Então ela é
atômica sozinha: uma queda de energia no meio de um update de dez milhões de linhas deixa a tabela
exatamente como estava, e não pela metade.

O que vale dizer com todas as letras, porque as pessoas supõem o contrário: **uma instrução sozinha
já é atômica.** Você não precisa de transação para um `UPDATE` ser seguro. Você precisa de uma para
*duas* instruções serem seguras juntas.

Alguns drivers desligam o autocommit, e aí toda instrução que você roda abre uma transação que fica
aberta até você confirmar — inclusive um `SELECT`, que é como uma conexão parada acaba segurando
algo aberto por quatro horas. A seção `long-transactions` é sobre o que isso custa.

## O que uma transação não é

**Não é um bloqueio sobre tudo o que você tocou.** As outras conexões continuam trabalhando. O que
elas conseguem ver e pelo que são obrigadas a esperar é assunto das próximas quatro seções, e a
resposta não é "nada" nem "tudo".

**Não é um jeito de tornar seguro um trabalho longo envolvendo-o.** Uma transação em volta de uma
migração de um milhão de linhas dá tudo-ou-nada, e também segura todo bloqueio que tomou pelo tempo
inteiro, e torna as linhas que ela substituiu irrecuperáveis até terminar. O preenchimento em lotes
da aula 3 existe por causa disso: **a atomicidade tem um custo que cresce com o tempo que você a
segura.**

**E não substitui uma restrição.** Uma transação garante que as suas duas instruções acontecem
juntas. Ela não confere que o resultado faz sentido — para isso existem `NOT NULL`, `CHECK` e
chaves estrangeiras, e a próxima seção trata de por que as pessoas esperam outra coisa.

## Savepoints, para uma parte de uma

```sql
BEGIN;
INSERT INTO orders …;
SAVEPOINT before_lines;
INSERT INTO order_lines …;          -- this one fails
ROLLBACK TO before_lines;           -- undo just that, keep the order
INSERT INTO order_lines …;          -- try again differently
COMMIT;
```

Um savepoint é uma marca à qual você pode voltar sem abandonar a transação inteira. É como um
driver implementa uma transação aninhada — não existe tal coisa por baixo, e o que o seu framework
chama assim é quase sempre um savepoint.

Vale conhecer por uma razão específica. No PostgreSQL, **uma instrução que falha envenena a
transação**:

```
ERROR:  current transaction is aborted, commands ignored until end of transaction block
```

Toda instrução depois do erro é recusada até você desfazer. Um savepoint antes de uma instrução que
pode falhar é o jeito de seguir, e é por isso que um ORM que queira capturar um erro de integridade
e continuar põe um ali. O MySQL não se comporta assim — uma instrução que falha deixa a transação
usável — o que é uma diferença real entre os dois e uma contra a qual o código de aplicação costuma
ser escrito sem que ninguém perceba.
