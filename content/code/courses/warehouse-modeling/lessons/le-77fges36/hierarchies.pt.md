---
title: Hierarquias, regulares e irregulares
version: 1
---

Um departamento contém subcategorias, que contêm categorias, que contêm livros. Uma **hierarquia** é
um conjunto de atributos em que cada nível se agrega no de cima, e os relatórios a usam para começar
num total e descer no detalhe.

Quando todo galho tem a mesma profundidade, a hierarquia é **regular**, e a estrela a guarda como uma
coluna por nível. A árvore da rede não é regular. Percorra-a do topo:

```sql
-- Walk the category tree from each top-level node down, and print the path.
WITH RECURSIVE tree AS (
    SELECT category_id, name, name AS path, 1 AS depth
    FROM staging.categories WHERE parent_id IS NULL
    UNION ALL
    SELECT c.category_id, c.name, t.path || ' > ' || c.name, t.depth + 1
    FROM staging.categories c JOIN tree t ON c.parent_id = t.category_id
)
SELECT depth, count(*) AS nodes, min(path) AS example
FROM tree GROUP BY depth ORDER BY depth;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < tree.sql
┌───────┬───────┬─────────────────────────────┐
│ depth │ nodes │           example           │
│ int32 │ int64 │           varchar           │
├───────┼───────┼─────────────────────────────┤
│     1 │     4 │ Children                    │
│     2 │    15 │ Children > Early readers    │
│     3 │    22 │ Fiction > Crime > Detective │
└───────┴───────┴─────────────────────────────┘
```

Quatro departamentos, quinze nós no segundo nível e vinte e dois no terceiro. Alguns galhos param em
dois níveis: *Comics* tem *Manga* e *Graphic novels* e nada abaixo deles. Isso é uma hierarquia
**irregular** (ragged), e é o caso comum: catálogos de produtos, organogramas e planos de contas quase
nunca têm a mesma profundidade em todo lugar.

Há um caso pior escondido nela. *Biography* é um nó do segundo nível com um filho, *Memoir*, e também
há livros arquivados diretamente em *Biography*. Um nó que é pai e folha ao mesmo tempo é onde a maior
parte do código de achatamento quebra.

## Achatando

A resposta da estrela é a que a `dim_book` já dá: **um número fixo de colunas, e um nível ausente
preenchido repetindo o nível de baixo.**

```
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT department, subcategory, category FROM dim_book WHERE department IN ('Comics', 'Fiction') GROUP BY ALL ORDER BY ALL LIMIT 6"
┌────────────┬────────────────┬────────────────┐
│ department │  subcategory   │    category    │
│  varchar   │    varchar     │    varchar     │
├────────────┼────────────────┼────────────────┤
│ Comics     │ Graphic novels │ Graphic novels │
│ Comics     │ Manga          │ Manga          │
│ Fiction    │ Crime          │ Detective      │
│ Fiction    │ Crime          │ Nordic noir    │
│ Fiction    │ Crime          │ Thriller       │
│ Fiction    │ Fantasy        │ Epic fantasy   │
└────────────┴────────────────┴────────────────┘
```

*Manga* é a sua própria subcategoria e a sua própria categoria. Um relatório que agrupa por
departamento e depois por subcategoria mostra *Manga* uma vez em cada nível, que é o que uma pessoa
espera, e nenhum total se perde nem é contado duas vezes. A decisão foi tomada uma vez, em
`12_dim_book.sql`, e nenhum relatório precisa saber que a árvore era irregular.

## Quando achatar para de funcionar

Achatar exige uma profundidade máxima. Uma árvore de categorias com três níveis é fácil; um organograma
em que um gestor pode estar qualquer número de níveis acima de um funcionário não é, porque nenhum
número de colunas basta. A resposta usual é uma **ponte de hierarquia**: uma tabela com uma linha para
cada par de ancestral e descendente, e a distância entre eles. "Tudo abaixo deste nó" vira uma junção,
em qualquer profundidade. É a ideia de tabela ponte da lição 4 aplicada a uma árvore, e vale saber que
existe; os três níveis da rede não precisam de uma.
