---
title: Deadlocks são normais, e a culpa é sua
version: 1
---

Duas transferências no mesmo instante, em direções opostas:

```
T1  (100 da Ana para o Bruno)         T2  (50 do Bruno para a Ana)
BEGIN                                 BEGIN
UPDATE accounts … WHERE id = 1        UPDATE accounts … WHERE id = 2
  → segura o bloqueio da linha 1        → segura o bloqueio da linha 2
UPDATE accounts … WHERE id = 2        UPDATE accounts … WHERE id = 1
  → espera pela T2                      → espera pela T1
```

Cada uma segura o que a outra precisa. Nenhuma consegue seguir e nenhuma vai desistir. Isso é um
deadlock, e nenhuma quantidade de espera resolve.

## O que o banco faz a respeito

Ele percebe, e mata uma delas:

```
ERROR:  deadlock detected
DETAIL: Process 8231 waits for ShareLock on transaction 993; blocked by process 8244.
        Process 8244 waits for ShareLock on transaction 991; blocked by process 8231.
HINT:   See server log for query details.
```

O PostgreSQL procura um ciclo no grafo de espera depois de uma transação ter esperado um segundo —
`deadlock_timeout`, e um segundo é bastante porque a conferência não é de graça e a maioria das
esperas é contenção comum que se resolve sozinha. O MySQL detecta na hora e reporta o erro 1213.

A parte importante é o que isto **não** é. Não é corrupção, não é uma queda, e não é um bug do
banco. Uma transação é desfeita limpamente, a outra segue, e a aplicação da vítima é avisada. Um
deadlock é o banco percebendo um erro na sua ordem de bloqueio e resolvendo do único jeito que pode.

Por isso a primeira reação não é alarme. É: **isto é raro o bastante para repetir, ou frequente o
bastante para corrigir a ordem?** As duas respostas são legítimas e a segunda em geral está
disponível.

## A causa, quase sempre

**Duas transações tomam os mesmos bloqueios em ordens diferentes.** Na transferência acima, a T1 vai
de 1 para 2 e a T2 de 2 para 1. Faça as duas irem em ordem crescente de id e o ciclo não se forma:
quem pegar a linha 1 primeiro também pega a 2, e a outra simplesmente espera e depois segue.

```sql
UPDATE accounts SET balance = balance + delta
FROM  (VALUES (1, -100), (2, 100)) AS t(id, delta)
WHERE accounts.id = t.id
ORDER BY accounts.id;
```

Ou, se as atualizações são instruções separadas, ordene os ids na aplicação antes de emiti-las. São
duas linhas de código e removem uma classe inteira de incidente.

A mesma regra vale para um lote: `UPDATE … WHERE id IN (…)` toma os bloqueios de linha na ordem em
que o plano as produzir, então dois lotes sobre conjuntos que se sobrepõem podem dar deadlock.
Ordenar a entrada faz os dois entrarem na fila.

## Três outras origens que vale reconhecer

**Subida de bloqueio.** Duas transações tomam `FOR SHARE` numa linha, e depois as duas tentam
atualizá-la. Cada uma espera a outra liberar o bloqueio compartilhado. A correção é tomar
`FOR UPDATE` no começo, quando você já sabe que pretende escrever — **tome o bloqueio mais forte de
que vai precisar, assim que precisar dele.**

**Chaves estrangeiras.** Inserir uma linha filha toma um bloqueio no pai para conferir que a
referência ainda existe. Duas transações inserindo filhos de dois pais, em ordens opostas, dão
deadlock sem que nenhuma delas nomeie uma linha pai. Esta é genuinamente surpreendente na primeira
vez.

**Bloqueios de índice e de intervalo no MySQL.** Em `REPEATABLE READ`, o InnoDB bloqueia os
intervalos entre entradas de índice para impedir fantasmas, então dois inserts que não tocam linha
em comum ainda podem disputar o mesmo intervalo. Deadlocks que não fazem sentido em termos de linhas
costumam fazer sentido em termos do índice.

## Ler as evidências

Não adivinhe a ordem. Os dois bancos contam:

```sql
SHOW ENGINE INNODB STATUS;      -- MySQL: a seção LATEST DETECTED DEADLOCK, com as duas consultas
```

O PostgreSQL escreve as duas instruções no log do servidor quando detecta um, e `log_lock_waits =
on` acrescenta uma entrada para qualquer espera maior que o `deadlock_timeout`, que é como você acha
a contenção antes de ela virar um ciclo.

E mantenha a distinção entre os dois erros, porque eles têm correções diferentes:

| | quer dizer | correção |
|---|---|---|
| **deadlock detected** | um ciclo: ninguém consegue seguir | mude a ordem em que os bloqueios são tomados |
| **lock wait timeout** | contenção comum que demorou demais | encurte a transação que está segurando |

Um lock wait timeout é alguém segurando um bloqueio por muito tempo. Reordenar não vai ajudar; a
seção `long-transactions` vai.

## E repita mesmo assim

Você não consegue projetar deadlocks para fora por completo. Uma mudança de esquema, uma consulta
nova, uma tarefa em lote que alguém acrescentou — cada uma é uma chance de um novo par de ordens.
Ordem consistente os torna raros, e raro não é nunca.

Então o erro de deadlock entra, junto da falha de serialização da seção anterior, na lista de coisas
que a sua aplicação precisa saber rodar de novo. Isso é uma seção adiante, e é o mesmo laço para os
dois.
