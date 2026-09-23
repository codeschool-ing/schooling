---
title: Percorrer uma árvore com WITH RECURSIVE
version: 2
---

A aula 1 lhe deu uma tabela que aponta para si mesma:

```sql
CREATE TABLE categories (
    id        integer PRIMARY KEY,
    name      text NOT NULL,
    parent_id integer REFERENCES categories (id)
);
```

Cozinha contém Panelas contém Frigideiras contém Frigideira antiaderente. Uma junção lhe dá um
nível. Duas junções dão dois níveis, e você não sabe quão fundo a árvore vai — então *"tudo abaixo
de Cozinha"* não tem resposta no SQL que você tem até aqui.

```sql
WITH RECURSIVE tree AS (
    SELECT id, name, parent_id, 1 AS depth
    FROM   categories
    WHERE  id = 3                                     -- the anchor: where to start

    UNION ALL

    SELECT c.id, c.name, c.parent_id, t.depth + 1
    FROM   categories c
    JOIN   tree t ON c.parent_id = t.id               -- the step: one level further
)
SELECT * FROM tree ORDER BY depth, name;
```

Toda consulta recursiva tem essas duas metades e o `UNION ALL` entre elas.

## O que ela faz de fato

A palavra "recursiva" engana — nada chama a si mesmo. Ela itera:

```localised
rodada 0   a âncora roda                        → Cozinha                         (depth 1)
rodada 1   o passo roda contra a rodada 0       → Panelas, Louça                  (depth 2)
rodada 2   o passo roda contra a rodada 1       → Frigideiras, Facas, Pratos      (depth 3)
rodada 3   o passo roda contra a rodada 2       → Frigideira antiaderente         (depth 4)
rodada 4   o passo roda contra a rodada 3       → nada, então para
```

Cada rodada junta contra **só o que a rodada anterior produziu**, e não contra tudo o que foi achado
até ali. É por isso que termina: no instante em que uma rodada não acrescenta linha, a consulta
acabou, e o resultado é a saída de todas as rodadas empilhada.

Releia essa lista se a sintaxe pareceu mágica. É um laço com a condição escrita como junção.

## Para cima é a mesma consulta virada

```sql
WITH RECURSIVE ancestors AS (
    SELECT id, name, parent_id FROM categories WHERE id = 41
    UNION ALL
    SELECT c.id, c.name, c.parent_id
    FROM   categories c JOIN ancestors a ON a.parent_id = c.id
)
SELECT * FROM ancestors;
```

A condição da junção trocou de lado: `a.parent_id = c.id` em vez de `c.parent_id = t.id`. Isso lhe
dá um caminho de migalhas — esta categoria e toda categoria acima dela — e são as mesmas quatro
linhas.

## Nível, caminho, e acertar a ordem

`ORDER BY depth` dá nível por nível, que raramente é o que uma pessoa quer ler. Um menu quer cada
ramo inteiro, e isso precisa de um caminho:

```sql
WITH RECURSIVE tree AS (
    SELECT id, name, parent_id, ARRAY[name] AS path
    FROM   categories WHERE parent_id IS NULL
    UNION ALL
    SELECT c.id, c.name, c.parent_id, t.path || c.name
    FROM   categories c JOIN tree t ON c.parent_id = t.id
)
SELECT repeat('  ', array_length(path, 1) - 1) || name AS label
FROM   tree
ORDER BY path;
```

Ordenar pelo caminho acumulado põe cada filho logo abaixo do pai, indentado. MySQL e SQLite não têm
tipo array, então ali o caminho é uma string: `t.path || '/' || c.name`, que ordena igual desde que
nenhum nome contenha o separador.

## Um ciclo é um laço infinito

Se alguém fizer a categoria 3 ser pai da categoria 1, que é pai da 3, a consulta acima nunca para.
Nada no modelo de dados impede — uma chave estrangeira para a própria tabela convive perfeitamente
com um ciclo, e as restrições da aula 3 não conseguem expressar "sem ciclos".

Três defesas, na ordem em que você deve gostar delas:

**Carregue o caminho e recuse revisitar.**

```sql
WHERE NOT (c.id = ANY(t.path_ids))
```

Explícito, portável, e custa mais uma coluna.

**`UNION` em vez de `UNION ALL`**, que remove duplicatas a cada rodada e portanto termina. Funciona,
esconde o problema, e remover duplicatas a cada rodada é caro numa árvore grande.

**A cláusula `CYCLE` do PostgreSQL 14**, que é a mais arrumada onde você a tem:

```sql
) CYCLE id SET is_cycle USING path
SELECT * FROM tree WHERE NOT is_cycle;
```

E uma quarta coisa, que não é defesa mas é bom senso: ponha um limite de profundidade —
`WHERE t.depth < 20` — para uma consulta desgovernada falhar num segundo em vez de encher um disco.
Uma árvore de categorias com vinte níveis é um bug de qualquer jeito.

## Gerar linhas do nada

O outro uso do dia a dia, e não é árvore nenhuma:

```sql
WITH RECURSIVE days AS (
    SELECT DATE '2026-01-01' AS day
    UNION ALL
    SELECT day + 1 FROM days WHERE day < DATE '2026-01-31'
)
SELECT d.day, coalesce(sum(o.total), 0) AS revenue
FROM   days d
LEFT JOIN orders o ON o.ordered_on = d.day
GROUP BY d.day
ORDER BY d.day;
```

É assim que um relatório ganha **uma linha para um dia em que nada foi vendido**. A aula 6 disse que
um grupo sem linhas não existe; aqui você fabrica as linhas primeiro e junta os dados sobre elas
pela esquerda, então um domingo parado mostra um zero em vez de sumir do gráfico. O PostgreSQL tem
`generate_series` para isso e é mais curto; a forma recursiva é a que funciona em todo lugar.

O suporte é amplo o bastante para se confiar: PostgreSQL, SQLite, MySQL 8 e MariaDB 10.2. PostgreSQL
e SQLite exigem a palavra `RECURSIVE`; o MySQL exige também, e nenhum deles se incomoda com ela
estar ali quando a consulta acaba não precisando.
