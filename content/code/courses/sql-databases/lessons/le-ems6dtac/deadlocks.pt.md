---
title: Deadlocks são normais, e a culpa é sua
version: 2
---

Duas transferências no mesmo instante, em direções opostas:

```localised
T1  (100 da Ana para o Bruno)         T2  (50 do Bruno para a Ana)
BEGIN                                 BEGIN
UPDATE accounts … WHERE id = 1        UPDATE accounts … WHERE id = 2
  → segura o bloqueio da linha 1        → segura o bloqueio da linha 2
UPDATE accounts … WHERE id = 2        UPDATE accounts … WHERE id = 1
  → espera pela T2                      → espera pela T1
```

Cada uma segura o que a outra precisa. Nenhuma consegue seguir e nenhuma vai desistir. Isso é um
deadlock, e nenhuma quantidade de espera resolve.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Dois painéis. À esquerda, intitulado ordens opostas, um ciclo: a transação T1 toma a linha 1 e depois a 2, e a T2 toma a linha 2 e depois a 1. Setas cheias mostram cada uma segurando uma linha; duas setas tracejadas se cruzam entre elas, cada transação esperando a linha que a outra segura, fechando um laço. À direita, intitulado ordem crescente, uma fila: as duas tomam a linha 1 primeiro, então T1 segura as duas e T2 apenas espera, e laço nenhum se forma.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">As mesmas duas transferências, tomando os mesmos dois locks, em duas ordens diferentes.</text><rect x=\"14\" y=\"40\" width=\"330\" height=\"168\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"179\" y=\"58\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--amber)\">ordens opostas — um ciclo</text><rect x=\"36\" y=\"74\" width=\"108\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"90\" y=\"87\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">T1  1 e depois 2</text><rect x=\"216\" y=\"74\" width=\"108\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"270\" y=\"87\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">T2  2 e depois 1</text><rect x=\"36\" y=\"150\" width=\"108\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"90\" y=\"163\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">row 1</text><rect x=\"216\" y=\"150\" width=\"108\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"270\" y=\"163\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">row 2</text><path d=\"M90 100 L90 148\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></path><path d=\"M90 148 L86.0 140.0 L94.0 140.0 Z\" fill=\"var(--phosphor)\"></path><path d=\"M270 100 L270 148\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></path><path d=\"M270 148 L266.0 140.0 L274.0 140.0 Z\" fill=\"var(--phosphor)\"></path><path d=\"M144 92 L216 160\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.3\" stroke-dasharray=\"5 4\"></path><path d=\"M216 160 L207.4 157.4 L212.9 151.6 Z\" fill=\"var(--amber)\"></path><path d=\"M216 92 L144 160\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.3\" stroke-dasharray=\"5 4\"></path><path d=\"M144 160 L147.1 151.6 L152.6 157.4 Z\" fill=\"var(--amber)\"></path><text x=\"179\" y=\"192\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--amber)\">cada uma espera o que a outra segura</text><text x=\"26\" y=\"222\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cheia: segura o lock  ·  tracejada: espera por ele</text><rect x=\"376\" y=\"40\" width=\"330\" height=\"168\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"541\" y=\"58\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--phosphor)\">ordem crescente — uma fila</text><rect x=\"398\" y=\"74\" width=\"108\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"452\" y=\"87\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">T1  1 e depois 2</text><rect x=\"578\" y=\"74\" width=\"108\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"632\" y=\"87\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">T2  2 e depois 1</text><rect x=\"398\" y=\"150\" width=\"108\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"452\" y=\"163\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">row 1</text><rect x=\"578\" y=\"150\" width=\"108\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"632\" y=\"163\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">row 2</text><path d=\"M452 100 L452 148\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></path><path d=\"M452 148 L448.0 140.0 L456.0 140.0 Z\" fill=\"var(--phosphor)\"></path><path d=\"M506 100 L626 148\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></path><path d=\"M626 148 L617.1 148.7 L620.1 141.3 Z\" fill=\"var(--phosphor)\"></path><path d=\"M632 100 L632 148\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.3\" stroke-dasharray=\"5 4\"></path><path d=\"M632 148 L628.0 140.0 L636.0 140.0 Z\" fill=\"var(--wire)\"></path><text x=\"541\" y=\"192\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--phosphor)\">a segunda apenas espera, e então segue</text><text x=\"388\" y=\"222\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cheia: segura o lock  ·  tracejada: espera por ele</text><text x=\"14\" y=\"248\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Esperar não resolve um ciclo, então o banco mata uma das duas. Ordenar os ids remove o ciclo e custa duas linhas.</text></svg>", "caption": "Um deadlock é um laço na espera, e o conserto é tornar o laço impossível em vez de esperar melhor."}
```

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
SHOW ENGINE INNODB STATUS;      -- MySQL: the LATEST DETECTED DEADLOCK section, with both queries
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
