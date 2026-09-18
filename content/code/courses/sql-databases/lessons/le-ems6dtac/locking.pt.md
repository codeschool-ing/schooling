---
title: Bloqueios, quando você quer ser explícito
version: 1
---

Comece pelo fato que explica por que bancos parecem tão rápidos:

> **Quem lê não bloqueia quem escreve, e quem escreve não bloqueia quem lê.**

PostgreSQL, MySQL com InnoDB e Oracle guardam versões antigas de uma linha em vez de sobrescrever no
lugar, então um `SELECT` lê a versão que estava confirmada quando o instantâneo dele foi tirado
enquanto um `UPDATE` escreve uma nova ao lado. Ninguém espera. É isso que o controle de concorrência
multiversão compra, e é por isso que o bloqueio em que você precisa pensar é quase sempre escritor
contra escritor.

**Escrever numa linha a bloqueia até a transação terminar.** Duas transações atualizando a mesma
linha: a segunda espera no `UPDATE` até a primeira confirmar ou desfazer. Isso é automático, é o que
torna `UPDATE products SET stock = stock - 1` seguro contra a atualização perdida, e é a maior parte
do bloqueio que acontece num sistema em funcionamento.

## Bloquear uma linha que você só leu

A atualização perdida volta quando a decisão acontece na sua aplicação, porque um `SELECT` simples
não bloqueia nada:

```sql
BEGIN;
SELECT stock FROM products WHERE id = 7 FOR UPDATE;   -- 10, e agora está bloqueada
-- a aplicação decide
UPDATE products SET stock = 9 WHERE id = 7;
COMMIT;
```

`FOR UPDATE` toma o mesmo bloqueio que o `UPDATE` teria tomado, no momento em que você lê. Uma
segunda transação rodando o mesmo código espera no próprio `SELECT`, e lê 9 em vez de 10 quando
passa.

As variantes, em ordem decrescente de força:

| cláusula | impede |
|---|---|
| `FOR UPDATE` | outros escritores e outros bloqueadores da mesma linha |
| `FOR NO KEY UPDATE` | o mesmo, mas permite um `FOR KEY SHARE` — o que um `UPDATE` comum toma |
| `FOR SHARE` | escritores, permitindo que outros leitores tomem o mesmo bloqueio |
| `FOR KEY SHARE` | mudanças só na chave — o que uma conferência de chave estrangeira toma |

`FOR SHARE` é o que se busca quando se quer dizer *"ninguém pode mudar isto enquanto eu decido"* e
vários podem estar decidindo ao mesmo tempo. Cuidado: duas transações com bloqueio compartilhado que
depois querem os dois subir de nível são um deadlock, e é o jeito mais comum de escrever um de
propósito.

## `NOWAIT` e `SKIP LOCKED`

Esperar é o padrão. Existem outras duas respostas:

```sql
SELECT … FOR UPDATE NOWAIT;       -- erro na hora se estiver bloqueada
SELECT … FOR UPDATE SKIP LOCKED;  -- deixa de fora, em silêncio, as linhas bloqueadas
```

`NOWAIT` é para trabalho interativo: uma pessoa que clica em editar deve ouvir *"outra pessoa está
com isto aberto"* em vez de olhar uma ampulheta por noventa segundos.

`SKIP LOCKED` é como se escreve uma fila de trabalho, e vale ter na mão:

```sql
BEGIN;
SELECT id, payload FROM jobs
WHERE  status = 'pending'
ORDER BY created_at
LIMIT  1
FOR UPDATE SKIP LOCKED;

UPDATE jobs SET status = 'running' WHERE id = $1;
COMMIT;
```

Dez trabalhadores rodam isso ao mesmo tempo. Cada um pega a primeira tarefa pendente que ninguém
bloqueou, então eles nunca colidem e nunca ficam na fila um do outro. Sem `SKIP LOCKED` os dez
esperam pela mesma linha e a fila processa uma tarefa por vez; com ele a tabela é uma fila de
trabalho e não precisa de intermediário. PostgreSQL, MySQL 8 e Oracle têm.

## A alternativa otimista

Bloquear é pessimista: você supõe um conflito e o impede. A outra abordagem supõe que não haverá um
e o detecta se houver, com uma coluna de versão:

```sql
SELECT id, name, version FROM documents WHERE id = 7;   -- versão 4, sem bloqueio

UPDATE documents SET name = $1, version = 5
WHERE  id = 7 AND version = 4;
```

Se outra pessoa salvou nesse meio-tempo, a linha está na versão 5, o `WHERE` não casa nada, e **zero
linhas são atualizadas**. Sem erro — você tem que olhar a contagem de linhas afetadas e tratar zero
como conflito, que é a parte que as pessoas esquecem.

É isso que a maioria dos ORMs chama de bloqueio otimista, e é o formato certo quando o intervalo
entre ler e escrever inclui uma pessoa: você não pode segurar um bloqueio de banco enquanto alguém
preenche um formulário por vinte minutos. A aula 11 volta a isso.

## Bloqueios sobre coisas que não são linhas

```sql
SELECT pg_advisory_xact_lock(4815);
```

Um bloqueio consultivo é um número que o banco deixa uma transação segurar por vez. Ele não protege
nada sozinho — quer dizer o que o código combinar que ele queira dizer — e é a ferramenta para
*"só um importador pode rodar por vez"*, onde não há linha a bloquear porque o que se protege é um
processo.

Use uma constante definida num lugar só, e prefira a forma `xact`, que é liberada no fim da
transação. A versão de sessão precisa ser liberada à mão, e uma conexão devolvida a um pool ainda
segurando uma leva o bloqueio junto.

## Dois hábitos

**Segure bloqueios pelo menor tempo possível.** Tome-os o mais tarde que puder e confirme logo. Cada
uma das patologias das duas próximas seções piora quanto mais tempo eles são segurados.

**Tome-os numa ordem consistente.** Duas transações que bloqueiam a linha 1 e depois a 2 vão fazer
fila. Duas que as bloqueiam em ordens opostas vão dar deadlock, que é a próxima seção — e ordenar de
forma consistente é a correção que não custa nada.
