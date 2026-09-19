---
title: Índices de cobertura, em que a tabela nunca é tocada
version: 1
---

A primeira seção deixou um fio solto. Usar um índice são dois passos: achar a entrada, e depois
seguir o ponteiro dela para buscar a linha. Esse segundo passo é uma leitura aleatória, e numa
consulta que devolve muitas linhas é a maior parte do custo.

Um **índice de cobertura** é um que contém toda coluna de que a consulta precisa, então o segundo
passo nunca acontece.

```sql
CREATE INDEX ON orders (customer_id, placed_at);

SELECT customer_id, placed_at FROM orders WHERE customer_id = 2;
```

As duas colunas pedidas estão no índice. O banco percorre a sequência de entradas do cliente 2 e as
devolve — a tabela `orders` não é lida. O PostgreSQL chama isso de **index-only scan**, e aparece
com esse nome no plano.

Acrescente uma coluna e acabou:

```sql
SELECT customer_id, placed_at, total FROM orders WHERE customer_id = 2;
```

`total` não está no índice, então toda entrada agora precisa da linha dela buscada. Mesmo índice,
mesmo `WHERE`, várias vezes o trabalho — e a única diferença é uma coluna na lista do `SELECT`, que
não é onde ninguém procura por uma mudança de desempenho.

O que é a lição prática, e é o argumento da aula 4 chegando com um número junto: **`SELECT *` não
pode ser coberto por nada.** Pedir colunas de que você não precisa não é só banda; pode ser a
diferença entre ler um índice e ler uma tabela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 226\" role=\"img\" aria-label=\"Dois painéis com o mesmo índice em customer_id e placed_at. À esquerda, a consulta pede essas duas colunas: o bloco do índice está aceso, a tabela orders ao lado está apagada e não visitada, e uma nota diz que o segundo passo nunca acontece — um index-only scan. À direita, a consulta pede todas as colunas: uma seta vai do índice até a tabela, que está acesa, com uma nota de que isso é uma leitura aleatória por linha e que em muitas linhas é quase todo o custo.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">O mesmo índice e as mesmas linhas. O que muda é se a consulta pede uma coluna que o índice não guarda.</text><rect x=\"14\" y=\"42\" width=\"330\" height=\"150\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"179\" y=\"60\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--phosphor)\">toda coluna pedida está no índice</text><text x=\"30\" y=\"82\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">SELECT customer_id, placed_at</text><rect x=\"30\" y=\"98\" width=\"140\" height=\"54\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">índice</text><text x=\"100\" y=\"132\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">customer_id,</text><text x=\"100\" y=\"144\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">placed_at</text><rect x=\"204\" y=\"98\" width=\"124\" height=\"54\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"266\" y=\"125\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">a tabela orders</text><text x=\"179\" y=\"170\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--phosphor)\">o segundo passo nunca acontece — um index-only scan</text><rect x=\"376\" y=\"42\" width=\"330\" height=\"150\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"541\" y=\"60\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--amber)\">uma coluna não está</text><text x=\"392\" y=\"82\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">SELECT *</text><rect x=\"392\" y=\"98\" width=\"140\" height=\"54\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"462\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">índice</text><text x=\"462\" y=\"132\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">customer_id,</text><text x=\"462\" y=\"144\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">placed_at</text><rect x=\"566\" y=\"98\" width=\"124\" height=\"54\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"628\" y=\"125\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">a tabela orders</text><path d=\"M536 125 L562 125\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></path><path d=\"M562 125 L555 121 L555 129 Z\" fill=\"var(--amber)\"></path><text x=\"541\" y=\"170\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--amber)\">uma leitura aleatória por linha, e em muitas linhas é quase todo o custo</text><text x=\"14\" y=\"212\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Um índice de cobertura não é um tipo de índice: é uma relação entre índice e consulta, e uma coluna a mais no SELECT pode encerrá-la.</text></svg>", "caption": "A seta tracejada da primeira figura desta aula é a que isto remove. Que é também por que SELECT * desfaz isso em silêncio."}
```

## `INCLUDE`, para colunas que você só quer devolver

Há uma tensão. Para cobrir a consulta acima você teria que indexar `total` também:

```sql
CREATE INDEX ON orders (customer_id, placed_at, total);
```

Mas `total` não é algo por que você busque ou ordene. Pô-lo na chave deixa o índice maior, faz toda
comparação comparar três valores, e implica uma ordenação que ninguém quer.

O PostgreSQL 11 em diante, e o SQL Server antes dele, separam os dois trabalhos:

```sql
CREATE INDEX ON orders (customer_id, placed_at) INCLUDE (total);
```

`total` é guardado no índice e **não** faz parte da chave ordenada. O índice continua se comportando
como um índice de duas colunas para todo propósito da seção anterior — prefixo à esquerda,
ordenação, tudo — e a consulta fica coberta.

Use `INCLUDE` para colunas que aparecem no `SELECT` e nunca no `WHERE` nem no `ORDER BY`. Use a
chave para tudo o que você busca. Acertar essa divisão é a maior parte do que faz um índice de
cobertura valer o tamanho dele.

MySQL e MariaDB não têm `INCLUDE`; ali a coluna vai na chave ou não vai. O SQLite também não tem, e
vale o mesmo.

## O MySQL cobre uma coisa de graça

O InnoDB guarda a própria tabela em ordem de chave primária — um **índice agrupado** — e toda entrada
de índice secundário guarda a chave primária em vez de um ponteiro físico.

Duas consequências que surpreendem quem vem do PostgreSQL:

**Todo índice secundário cobre a chave primária.** Um índice em `(customer_id)` consegue responder a
`SELECT id, customer_id …` sem tocar a tabela, porque o `id` já está na entrada.

**E buscar uma linha são duas descidas de índice**, não um seguir de ponteiro: ache a entrada, leia a
chave primária dela, e desça o índice agrupado até a linha. O que torna uma chave primária larga
cara duas vezes — ela é copiada em todo índice secundário, e é percorrida em toda busca. É o
argumento mais forte para uma chave primária compacta especificamente no MySQL.

## O asterisco do PostgreSQL, que importa

Um index-only scan no PostgreSQL não é bem só o índice. A entrada de índice não registra se a linha
para a qual ela aponta é visível à sua transação — as versões de linha da aula 8 estão na tabela, e
não no índice. Então o banco consulta o **mapa de visibilidade**, uma estrutura pequena marcando
quais páginas contêm só linhas visíveis a todo mundo.

Se a página está marcada como toda visível, a entrada é usada como está. Se não está, a linha
precisa ser buscada afinal, e o index-only scan caladamente vira um comum.

O mapa de visibilidade é mantido pelo `VACUUM`. Então:

> **Um index-only scan numa tabela muito escrita deixa de ser só-índice até o `VACUUM` alcançar.**

É um efeito real e é um dos jeitos pelos quais a transação longa da aula 8 prejudica o desempenho em
vez de só o disco: ela segura o `VACUUM`, o mapa fica velho, e consultas que estavam rápidas voltam
a buscar linhas. Nada na consulta mudou.

## Quando recorrer a um

Um índice de cobertura vale construir quando uma consulta é **quente, estreita e seletiva**: roda
muito, precisa de poucas colunas, e devolve uma fatia pequena da tabela. Uma consulta de relatório
sobre a maior parte da tabela não quer um — ela quer a tabela.

E seja honesto quanto ao tamanho. Acrescentar duas colunas de `INCLUDE` a um índice numa tabela de
cem milhões de linhas pode somar gigabytes, todos disputando o mesmo cache. A resposta certa é quase
sempre medir a consulta primeiro, que é a aula 10, e acrescentar as colunas que você consegue provar
que são necessárias em vez das que a lista do `SELECT` por acaso tem hoje.
