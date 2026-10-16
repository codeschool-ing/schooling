---
title: Anexar e desanexar, e por que remover um mês vence apagá-lo
version: 1
---

Uma partição é uma tabela, e ela pode deixar de ser ou passar a ser uma das do pai sem que suas
linhas se movam. `ATTACH PARTITION` pega uma tabela que já existe e a torna partição; `DETACH
PARTITION` torna uma partição de novo uma tabela independente. Esses dois, mais o `DROP TABLE`, são
tudo o que faz uma tabela particionada envelhecer, e são onde o trabalho da seção 02 é feito.

## Acrescentando o próximo mês, preparado de antemão

`PARTITION OF`, como na seção 03, cria a tabela nova e a anexa num comando só. O outro jeito é
construir a tabela sozinha, carregá-la e indexá-la enquanto ninguém a vê, e anexá-la quando estiver
pronta:

```
market=# CREATE TABLE events_2026_02 (LIKE events_by_month INCLUDING DEFAULTS);
CREATE TABLE
Time: 5.217 ms

market=# ALTER TABLE events_2026_02 ADD CHECK (at >= '2026-02-01' AND at < '2026-03-01');
ALTER TABLE
Time: 2.380 ms

market=# ALTER TABLE events_by_month ATTACH PARTITION events_2026_02 FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
ALTER TABLE
Time: 6.529 ms
```

`LIKE events_by_month INCLUDING DEFAULTS` copia as colunas. A restrição `CHECK` é o passo que torna o
anexo barato, e é fácil de esquecer: para anexar uma tabela, o servidor precisa ter certeza de que
toda linha dela pertence ao intervalo, e sem uma restrição que prove isso ele **lê a tabela inteira**
para conferir, segurando uma trava (lock) enquanto isso. Com uma restrição que bate com o limite, ele
lê a restrição. Aqui a tabela estava vazia, então dos dois jeitos levaria milissegundos; num mês
carregado de antemão, a diferença é uma leitura de todas as linhas, com o pai esperando.

## Removendo um mês

A seção 02 apagou outubro de `events` e mediu: **1611210 linhas em três segundos, 251 MB de WAL**,
e um `ROLLBACK` para desfazer. Eis o mesmo mês saindo de `events_by_month`, com o WAL medido do
mesmo jeito:

```
market=# SELECT pg_current_wal_lsn() AS before \gset
Time: 0.863 ms

market=# ALTER TABLE events_by_month DETACH PARTITION events_2025_10;
ALTER TABLE
Time: 2.703 ms

market=# DROP TABLE events_2025_10;
DROP TABLE
Time: 220.588 ms

market=# SELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), :'before')) AS wal_written;
 wal_written 
-------------
 55 kB
(1 row)

Time: 0.582 ms
```

O detach levou **2,7 milissegundos** e o drop **221**, que é o sistema operacional removendo os
arquivos. O WAL gravado pelos dois juntos foi de **55 kB**, contra 251 MB, porque o servidor
registrou que uma tabela foi embora, e não cada uma das suas 1,6 milhão de linhas. Não há linhas
mortas para o `VACUUM` achar, nem entradas de índice apontando para elas, nem espaço sobrando dentro
de um arquivo à espera de reaproveitamento: o espaço volta para o disco no momento em que o drop faz
commit.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Duas maneiras de remover outubro. Em cima, events como uma tabela só: um DELETE marca 1611210 linhas como mortas dentro do mesmo arquivo, grava 251 MB de WAL e leva uns três segundos, e o arquivo continua do mesmo tamanho. Embaixo, events_by_month em quatro partições mensais: outubro é desanexado do pai e removido como um arquivo inteiro, gravando 55 kB de WAL, enquanto novembro, dezembro e janeiro continuam anexados.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma tabela só: DELETE</text><rect x=\"14\" y=\"30\" width=\"560\" height=\"56\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"16\" y=\"32\" width=\"180\" height=\"52\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"106\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">outubro, marcado morto</text><text x=\"106\" y=\"70\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">1611210 rows</text><text x=\"385\" y=\"58\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">novembro e dezembro, no mesmo arquivo</text><text x=\"590\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">251 MB WAL</text><text x=\"590\" y=\"66\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">2969 ms</text><text x=\"14\" y=\"124\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">particionada por mês: DETACH, depois DROP</text><rect x=\"170\" y=\"140\" width=\"404\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"372\" y=\"155\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">events_by_month</text><rect x=\"14\" y=\"214\" width=\"140\" height=\"40\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"84\" y=\"234\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--amber)\">events_2025_10</text><rect x=\"204\" y=\"214\" width=\"118\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"263\" y=\"234\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">events_2025_11</text><path d=\"M263 170 L263 214\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><rect x=\"328\" y=\"214\" width=\"118\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"387\" y=\"234\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">events_2025_12</text><path d=\"M387 170 L387 214\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><rect x=\"452\" y=\"214\" width=\"118\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"511\" y=\"234\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">events_2026_01</text><path d=\"M511 170 L511 214\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M84 214 L84 190 L170 160\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><text x=\"14\" y=\"274\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">desanexada, depois removida inteira</text><text x=\"590\" y=\"224\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">55 kB WAL</text><text x=\"590\" y=\"242\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">2.7 + 221 ms</text></svg>", "caption": "Removendo outubro dos dois jeitos, com os números das duas transcrições."}
```

O detach e o drop são dois comandos de propósito. Entre eles, `events_2025_10` é uma tabela comum
que nenhuma consulta no pai enxerga, e esse é o momento de copiá-la para um lugar mais barato,
guardá-la para uma auditoria ou conferir o que há nela. Remover dados antigos deixa de ser uma
decisão que não dá para desfazer no meio de uma tarde movimentada.

## Desanexando sem bloquear, e a partição padrão

Um `DETACH PARTITION` comum pega uma trava forte no pai, então toda consulta em `events_by_month`
espera por ele, pouco, mas toda vez. `DETACH PARTITION … CONCURRENTLY` faz o mesmo trabalho em dois
passos que deixam as consultas seguirem, ao preço de não poder rodar dentro de um bloco de
transação:

```
market=# ALTER TABLE events_by_month DETACH PARTITION events_2026_02 CONCURRENTLY;
ALTER TABLE
Time: 4.019 ms
```

Funcionou para fevereiro. Agora dê à tabela uma **partição padrão** (default), uma partição sem
intervalo que recebe toda linha que nenhuma outra aceita, e tente o mesmo com janeiro:

```
market=# CREATE TABLE events_default PARTITION OF events_by_month DEFAULT;
CREATE TABLE
Time: 7.076 ms

market=# ALTER TABLE events_by_month DETACH PARTITION events_2026_01 CONCURRENTLY;
ERROR:  cannot detach partitions concurrently when a default partition exists
Time: 1.309 ms

market=# INSERT INTO events_by_month VALUES (0, '2026-03-01', NULL, 'view', '{}');
INSERT 0 1
Time: 2.131 ms

market=# SELECT tableoid::regclass, id, at FROM events_by_month WHERE id = 0;
    tableoid    | id |           at           
----------------+----+------------------------
 events_default |  0 | 2026-03-01 00:00:00-03
(1 row)

Time: 1.542 ms
```

A partição padrão pegou a linha de março que a seção 03 recusou. Ela também tornou impossível o
detach concorrente, com um erro que diz isso. Uma partição padrão muda o jeito como outras partições
podem ser acrescentadas e removidas. Toda mudança nos intervalos tem de conferir que a padrão já não
guarda linhas que agora pertenceriam a outro lugar: a mesma leitura completa que a restrição `CHECK`
evitou acima, desta vez da padrão.

Então uma partição padrão é uma troca, e o conselho habitual é preferir **criar partições com
antecedência** e manter uma padrão só onde a alternativa é pior: numa lista, onde um valor
desconhecido deve ser guardado e percebido em vez de recusado, e com um alerta para a padrão guardar
qualquer linha. Uma padrão que se enche em silêncio com um mês que ninguém criou é o problema de
março, adiado e mais difícil de desfazer.
