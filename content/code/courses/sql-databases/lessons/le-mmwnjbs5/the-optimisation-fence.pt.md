---
title: Um CTE é calculado uma vez, e ele é mais lento?
version: 1
---

Alguém vai lhe dizer que `WITH` é lento. Outra pessoa vai lhe dizer que não custa nada. As duas
estão citando um banco real de um ano real, e as duas estão repetindo isso muito depois de ter
deixado de ser verdade. Esta seção é o que acontece de fato, porque a resposta muda o que você
escreve.

## Duas coisas que um banco pode fazer com um passo nomeado

**Embutir.** A definição é substituída dentro da consulta de fora e o planejador trata o conjunto
como uma consulta só — então um filtro de fora pode ser empurrado para dentro, um índice pode ser
usado, e só as linhas que importam chegam a ser produzidas.

**Materializar.** A definição é executada sozinha, as linhas são guardadas num resultado temporário,
e a consulta de fora lê dali. Nada de fora pode influenciar o que ela produziu.

Para uma tabela derivada, os bancos sempre embutiram quando deu. Para um CTE, a história é mais
bagunçada.

## O que o PostgreSQL fazia, e quando mudou

**Antes da versão 12, todo CTE era materializado.** Sempre, sem jeito de pedir outra coisa. Era
conhecido como cerca de otimização, e a consequência é fácil de demonstrar:

```sql
WITH everything AS (SELECT * FROM orders)
SELECT * FROM everything WHERE id = 7;
```

No PostgreSQL 11 isso lê a tabela `orders` inteira, monta tudo na memória, e depois acha uma linha.
A mesma consulta escrita com tabela derivada usa o índice e toca uma linha. Uma tabela de um milhão
de linhas faz disso a diferença entre um segundo e um milissegundo.

As pessoas também usavam a cerca de propósito — como a única dica disponível. Um planejador tomando
uma decisão ruim podia ser isolado empurrando parte da consulta para um CTE, e era uma técnica
legítima, ainda que desconfortável.

**A partir da versão 12 um CTE é embutido** quando é referenciado exatamente uma vez, não é
recursivo, e não faz nada que modifique dados. Caso contrário é materializado. E você pode dizer o
que quer:

```sql
WITH everything AS NOT MATERIALIZED (SELECT * FROM orders)  -- embuta
WITH everything AS MATERIALIZED     (SELECT * FROM orders)  -- calcule uma vez, cerque
```

Duas conclusões decorrem, e elas importam mais que a história:

- **Conselho sobre CTEs escrito antes de 2019 é sobre outro banco.** Inclusive conselho que você
  acha no topo de uma busca hoje, porque nada na internet é revisado.
- **Uma atualização mudou os planos de consultas que ninguém tocou.** Em geral para melhor. Nem
  sempre: uma consulta que se apoiava na cerca para evitar um plano ruim perdeu a cerca.

O MySQL 8 faz o mesmo tipo de coisa pelas heurísticas dele, fundindo uma tabela derivada ou CTE na
consulta de fora quando dá e materializando quando não dá, com `NO_MERGE` como a dica para impedir.
O SQLite achata subconsultas sob uma lista documentada de condições, e um CTE referenciado mais de
uma vez é materializado.

## Então ele é calculado uma vez?

Só quando é materializado. Tome um CTE referenciado duas vezes:

```sql
WITH monthly AS (SELECT date_trunc('month', placed_at) AS month, sum(total) AS revenue
                 FROM orders GROUP BY 1)
SELECT this.month, this.revenue, prev.revenue
FROM   monthly this LEFT JOIN monthly prev ON prev.month = this.month - INTERVAL '1 month';
```

Aqui o PostgreSQL materializa, porque embutir significaria calcular a agregação duas vezes. Então a
parte cara roda uma vez, que é exatamente o que você queria — e vale saber que isso é consequência
da regra e não uma promessa que o `WITH` faz.

A afirmação a aposentar é a outra: **nomear um passo não o memoriza.** Um CTE não é uma variável
guardando um valor. É uma consulta, e se ela roda uma vez ou é dobrada dentro da consulta de fora é
decisão do planejador.

## O que fazer na prática

**Escreva `WITH` quando ler melhor, que é a maior parte do tempo.** Em qualquer banco que você
encontre hoje, a versão legível tem a mesma velocidade ou perto o bastante para a diferença não ser
o motivo da escolha.

**Quando você precisar de materialização, escreva `MATERIALIZED`.** Não conte com o padrão de uma
versão, e não use um CTE como cerca em silêncio — alguém vai reescrever como junção, o plano vai
mudar, e a razão de estar escrito assim não está em lugar nenhum do arquivo. Um comentário dizendo
por quê faz parte da correção.

**E meça em vez de discutir.** Toda afirmação desta seção é conferível em cerca de um minuto com o
`EXPLAIN`, que é a aula 10. Até você ter rodado nos seus dados, na sua versão, a velocidade de uma
consulta é opinião — inclusive a velocidade da consulta que você acabou de melhorar.
