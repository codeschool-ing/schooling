---
title: Casando texto, e quanto cada jeito custa
version: 1
---

Igualdade exata foi a seção anterior. Esta são os vários jeitos de pedir "algo parecido".

## `LIKE` e `ILIKE`

```sql
WHERE name LIKE 'Kettle%'      -- começa com
WHERE name LIKE '%kettle%'     -- contém
WHERE name LIKE '_ettle'       -- um caractere, depois ettle
WHERE name ILIKE '%kettle%'    -- o mesmo, ignorando caixa
```

Dois curingas e é toda a linguagem: `%` é qualquer sequência de caracteres incluindo nenhuma, `_` é
exatamente um.

`ILIKE` é a versão insensível a caixa do PostgreSQL e não é SQL padrão. A grafia portável é
`WHERE lower(name) LIKE lower('%kettle%')`, que faz o mesmo e carrega o problema de função da seção
anterior.

**E existe um precipício de desempenho entre os dois primeiros**, que vale saber antes de a aula 9
explicar por quê:

| | |
|---|---|
| `LIKE 'Kettle%'` | consegue usar um índice comum — é uma faixa de valores que ordenam juntos |
| `LIKE '%kettle%'` | não consegue. Toda linha tem que ser examinada |

Um `%` no começo significa que o casamento pode começar em qualquer lugar, e um índice é ordenado
pelo início do valor, então não há o que buscar. Numa tabela grande, uma caixa de busca que gera
`LIKE '%…%'` é a consulta que acaba derrubando o site.

O PostgreSQL tem respostas — um índice de trigramas, ou busca textual — e são da aula 9 em diante. O
que levar agora é que **os dois padrões parecem quase idênticos e custam quantias completamente
diferentes.**

## Escapar, quando o padrão contém um curinga

Para procurar um `%` ou `_` literal, diga qual caractere escapa:

```sql
WHERE code LIKE '100\%%' ESCAPE '\'    -- começa com o texto 100%
```

Este importa mais onde é menos visível: uma caixa de busca que passa a entrada do usuário direto
para um `LIKE`. Alguém digitando `%` casa com tudo, e alguém digitando `_` casa com qualquer
caractere — então a busca se comporta de forma estranha e ninguém consegue reproduzir. A entrada tem
que ser escapada antes de virar padrão.

## `IN`, e a lista

```sql
WHERE category IN ('kitchen', 'garden', 'office')
```

Atalho para três `OR`, e mais claro. Também aceita uma subconsulta, que é a aula 7:

```sql
WHERE category_id IN (SELECT id FROM categories WHERE active)
```

**`NOT IN` tem o problema de `NULL` da aula 1**, e é grave o bastante para repetir aqui: se a lista —
ou a subconsulta — contiver um único `NULL`, o `NOT IN` devolve nenhuma linha, sem erro. A próxima
seção é sobre isso.

## Expressões regulares

Quando dois curingas não bastam:

```sql
WHERE sku ~ '^[A-Z]{3}-[0-9]{4}$'     -- casa
WHERE sku !~ '^[A-Z]{3}'              -- não casa
WHERE sku ~* 'kettle'                 -- casa, ignorando caixa
```

`~` é o operador do PostgreSQL e o do padrão é `SIMILAR TO`, que quase ninguém usa. São poderosas,
não são indexáveis no caso geral, e são a ferramenta certa para validar um formato, não para buscar
numa tabela.

**Uma casa melhor para uma regra de formato é uma restrição `CHECK`**, da aula 3: conferir o formato
de um SKU uma vez na escrita é mais barato e mais forte que filtrar por ele na leitura, e significa
que o valor ruim nunca entrou.

## Qual buscar

| você quer | use |
|---|---|
| exatamente este valor | `=` |
| um de uma lista curta | `IN` |
| começa com | `LIKE 'x%'` — indexável |
| contém, tabela pequena | `ILIKE '%x%'` |
| contém, tabela grande | índice de trigramas ou busca textual — aula 9 |
| uma regra de formato | uma expressão regular, e melhor ainda um `CHECK` |

O que exige cuidado é o quarto. É o mais fácil de escrever, funciona perfeitamente em
desenvolvimento onde a tabela tem duzentas linhas, e é o que não sobrevive ao contato com uma tabela
real.
