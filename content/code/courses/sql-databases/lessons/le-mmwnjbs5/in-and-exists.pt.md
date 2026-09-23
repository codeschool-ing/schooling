---
title: IN, EXISTS, e aquele que não devolve nada
version: 2
---

Dois jeitos de perguntar "esta linha está naquele conjunto", e eles parecem intercambiáveis:

```sql
SELECT * FROM products p WHERE p.category_id IN     (SELECT id FROM categories WHERE active);
SELECT * FROM products p WHERE EXISTS (SELECT 1 FROM categories c WHERE c.id = p.category_id AND c.active);
```

Mesma resposta, na maioria dos dias. A diferença é o que cada um pergunta:

- **`IN` compara valores.** Ele monta o conjunto que a subconsulta devolve e testa pertinência.
- **`EXISTS` pergunta se existe uma linha.** Ele não olha coluna nenhuma — o `SELECT 1` está ali
  porque algo tem que ser escrito, e `SELECT *` é idêntico. Quem lhe disser que um é mais rápido que
  o outro está repetindo folclore; todo planejador descarta essa lista.

Para a forma positiva, escolha a que lê melhor. Para a forma negativa, elas não são a mesma coisa, e
a aula 4 prometeu que esta seção diria por quê.

## `NOT IN` com um nulo não devolve linha nenhuma

```sql
SELECT * FROM products WHERE category_id NOT IN (1, 2, NULL);
```

Zero linhas, seja lá o que a tabela tenha, para sempre. Desdobrar é a explicação inteira:

```localised
category_id NOT IN (1, 2, NULL)
category_id <> 1  AND  category_id <> 2  AND  category_id <> NULL
                                              └─ desconhecido, sempre
```

Um `AND` com um desconhecido dentro pode ser falso, ou desconhecido, e nunca verdadeiro. Então
nenhuma linha se qualifica. É SQL correto, lógica de três valores correta, e uma resposta vazia que
parece uma descoberta.

Ninguém escreve um `NULL` literal numa lista. Subconsultas produzem um o tempo todo:

```sql
SELECT * FROM products
WHERE  category_id NOT IN (SELECT category_id FROM discontinued_lines);
```

Uma linha de `discontinued_lines` com `category_id` nulo — uma coluna que ninguém pensou em
restringir — e esta consulta não devolve nada. Funcionou nos testes, funcionou por um ano, e para no
dia em que alguém insere uma linha com um campo em branco. **Nenhum erro é levantado e nenhum aviso
é impresso.**

## `NOT EXISTS` não consegue fazer isso

```sql
SELECT * FROM products p
WHERE  NOT EXISTS (SELECT 1 FROM discontinued_lines d WHERE d.category_id = p.category_id);
```

A comparação está lá dentro, uma linha por vez. `d.category_id = p.category_id` contra um nulo é
desconhecido, então aquela linha não casa, então ela não contribui com uma existência — e o produto
é mantido, que é a resposta certa. Nada se propaga para fora, porque `EXISTS` devolve verdadeiro ou
falso e nunca desconhecido.

> **Use `NOT EXISTS` para "não está naquele conjunto", a menos que você tenha provado que a coluna
> não é anulável.**

E "provado" quer dizer uma restrição `NOT NULL`, da aula 3, e não uma crença. Uma crença sobre
nulidade é exatamente do que este bug é feito.

## A terceira forma, que você já conhece

A antijunção da aula 5 diz a mesma coisa de novo:

```sql
SELECT p.*
FROM   products p
LEFT JOIN discontinued_lines d ON d.category_id = p.category_id
WHERE  d.category_id IS NULL;
```

Mantenha todo produto, pareie onde der, e depois fique só com as linhas em que o pareamento falhou.
Também é imune à armadilha do nulo, pela mesma razão que `NOT EXISTS` é — a comparação acontece no
`ON`, por linha.

Três grafias de uma pergunta, então:

| | seguro com nulo | lê como |
|---|---|---|
| `NOT IN (subconsulta)` | **não** | pertinência a um conjunto |
| `NOT EXISTS (correlacionada)` | sim | existe alguma destas |
| `LEFT JOIN … IS NULL` | sim | pareie e fique com as falhas |

A do meio diz o que quer dizer do modo mais direto, que é por que é o hábito que vale formar. A
terceira aparece em código antigo e em geradores de consulta que não têm outro jeito de expressar.

## `ANY` e `ALL`

Dois operadores que quase ninguém escreve e todo mundo acaba lendo:

```sql
x = ANY (SELECT …)      -- identical to x IN (SELECT …)
x <> ALL (SELECT …)     -- identical to x NOT IN (SELECT …), null trap and all
x > ALL (SELECT price FROM products WHERE category_id = 3)
```

O último é a razão de eles existirem: uma comparação que não é igualdade contra toda linha de um
conjunto. *"Custa mais que tudo da categoria 3"* é uma linha aqui e uma subconsulta com `max()` de
outro jeito — e os dois divergem quando o conjunto é vazio, onde `> ALL` é **verdadeiro** e
`> (SELECT max(...))` é nulo. Conjuntos vazios são onde esses operadores deixam de concordar com a
intuição, e vale conferir qual comportamento você quer em vez de descobrir depois.

## E quanto à velocidade

Vão lhe dizer que `IN` é lento, ou que `EXISTS` é mais rápido, ou o contrário. As duas afirmações
foram verdade de algum banco em algum ano. No PostgreSQL de hoje, `IN`, `EXISTS` e a antijunção em
geral produzem o mesmo plano, porque o planejador reescreve os três na mesma semijunção ou
antijunção. O MySQL era genuinamente ruim com `IN (subconsulta)` antes da versão 8 e não é mais.

Então a regra deste curso: **escolha por correção e pelo que lê claro, e meça o resto.** A aula 10 é
onde se mede, e é o único lugar a que uma afirmação sobre velocidade pertence.
