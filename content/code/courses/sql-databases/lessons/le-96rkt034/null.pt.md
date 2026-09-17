---
title: NULL não é um valor, e é aqui que as pessoas se machucam
version: 1
---

Toda coluna que não é declarada `NOT NULL` pode guardar `NULL`, e `NULL` se comporta diferente de
tudo o mais em SQL. Merece uma seção própria na primeira aula, antes de você ter escrito uma única
consulta, porque o mal-entendido é silencioso: as consultas não falham, elas só devolvem
caladamente as linhas erradas.

**`NULL` não significa zero. Não significa string vazia. Significa *desconhecido*.**

| linha | cidade | o que diz |
|---|---|---|
| Ana | `'Porto'` | a cidade dela é Porto |
| Bruno | `''` | a cidade dele é a string vazia — que é um valor, e um valor estranho |
| Célia | `NULL` | **ninguém sabe a cidade dela** |

São três estados diferentes e o terceiro não é um valor. É a ausência de um.

## Desconhecido comparado com qualquer coisa é desconhecido

Isso é tudo, e toda surpresa abaixo decorre disso:

```sql
SELECT NULL = NULL;
```

```
 ?column?
----------
 (null)
```

Não `true`. **`NULL = NULL` não é verdadeiro**, porque "esta coisa desconhecida é a mesma que aquela
coisa desconhecida?" não pode ser respondido por quem não conhece nenhuma das duas. A resposta é ela
própria desconhecida.

O mesmo para todo o resto:

```sql
SELECT NULL = 5,  NULL <> 5,  NULL > 5,  NULL + 1,  'a' || NULL;
```

```
 ?column? | ?column? | ?column? | ?column? | ?column?
----------+----------+----------+----------+----------
 (null)   | (null)   | (null)   | (null)   | (null)
```

Toda comparação contra um desconhecido é desconhecida, e toda aritmética sobre um desconhecido é
desconhecida. SQL tem **três** valores de verdade — verdadeiro, falso e desconhecido — e isso se
chama lógica de três valores.

## Que é por que o `WHERE` perde linhas

Uma cláusula `WHERE` mantém as linhas em que a condição é **verdadeira**. Não "não falsa" —
verdadeira. Desconhecido não é verdadeiro, então a linha cai.

Suponha dez clientes, dos quais três têm `city = NULL`:

```sql
SELECT count(*) FROM customers WHERE city = 'Porto';      -- 4
SELECT count(*) FROM customers WHERE city <> 'Porto';     -- 3
```

Quatro mais três é sete, e há dez clientes. **Os três de cidade desconhecida não estão em nenhuma
das respostas**, e nada te avisou. As duas consultas estão corretas; a aritmética que você fez de
cabeça não estava.

Esse é o formato do bug na natureza. Um relatório de "clientes fora do Porto" omite caladamente todo
mundo cuja cidade nunca foi preenchida, o número fica um pouco baixo, e continua um pouco baixo por
anos.

## Então você faz outra pergunta

Existe um operador dedicado, e é o único jeito:

```sql
SELECT count(*) FROM customers WHERE city IS NULL;        -- 3
SELECT count(*) FROM customers WHERE city IS NOT NULL;    -- 7
```

`IS NULL` e `IS NOT NULL` perguntam sobre o *estado* em vez de comparar valores, então sempre
respondem verdadeiro ou falso. `= NULL` não é erro nem engano de sintaxe — é uma expressão válida
que nunca é verdadeira, o que é muito pior, porque nada reclama.

Para incluir os desconhecidos deliberadamente:

```sql
SELECT count(*) FROM customers WHERE city <> 'Porto' OR city IS NULL;   -- 6
```

Agora é seis, três e um, que somam dez.

## Os lugares onde morde e ninguém te avisa

**Unicidade deixa passar vários `NULL`s.** Uma coluna `UNIQUE` pode guardar muitos `NULL`s, porque
não se sabe que dois desconhecidos são iguais:

```sql
CREATE TABLE people (tax_id text UNIQUE);
INSERT INTO people VALUES (NULL), (NULL), (NULL);   -- as três são aceitas
```

Correto pela lógica, e surpreendente na primeira vez. Se você precisa de no máximo uma linha sem
CPF, `UNIQUE` não é a ferramenta.

**Agregações pulam, exceto uma.** `count(*)` conta linhas; `count(city)` conta linhas em que `city`
não é nula; `avg`, `sum`, `min` e `max` ignoram nulos. Então a média de `10, 20, NULL` é **15, não
10** — três valores, dois conhecidos, e o desconhecido não é tratado como zero.

**`NOT IN` desmorona inteiro.** Este é o mais traiçoeiro:

```sql
SELECT * FROM customers WHERE id NOT IN (1, 2, NULL);
```

Zero linhas. Sempre. Não importa o que tenha na tabela. `id NOT IN (1, 2, NULL)` se desdobra em
`id <> 1 AND id <> 2 AND id <> NULL`, e esse último é desconhecido, então o `AND` inteiro nunca pode
ser verdadeiro. Uma subconsulta que devolve um `NULL` esquecido transforma um `NOT IN` numa consulta
que não devolve nada e não reporta erro. A aula 7 mostra o que escrever no lugar.

**A ordenação precisa ser instruída.** Nulos vêm por último na ordem ascendente do PostgreSQL e
primeiro na descendente — e outros bancos escolhem diferente. `ORDER BY city NULLS FIRST` diz o que
você quis dizer.

## A lição para modelagem, que é a razão de isto estar na aula 1

Cada uma das surpresas acima é evitada não tendo o `NULL` em primeiro lugar. Então:

> **Declare `NOT NULL` em tudo, e remova só onde você conseguir dizer em voz alta o que um vazio
> significa.**

Isso é o oposto de como a maioria começa, que é permitir nulos em todo lugar "por flexibilidade" e
acrescentar restrições depois. Depois nunca chega, e a essa altura a tabela tem cem mil linhas das
quais algumas têm cidade desconhecida por razões que ninguém consegue reconstruir.

E quando uma coluna é genuinamente opcional, certifique-se de que `NULL` é o que você quer dizer:

- Uma data de entrega que ainda não aconteceu — **`NULL` é certo**, é genuinamente desconhecida.
- Um nome do meio que a pessoa não tem — **`NULL` é discutível**; alguns usariam string vazia,
  porque "não tem nome do meio" é conhecido em vez de desconhecido. Escolha um e seja consistente,
  porque uma tabela com os dois é uma tabela em que toda consulta precisa de duas condições.
- Uma quantidade zero — **`NULL` é errado.** Zero é um número e uma resposta perfeitamente boa.
  Guardá-lo como desconhecido joga fora um fato que você tinha.

O hábito a construir: quando escrever uma coluna que aceita nulo, escreva numa frase o que um `NULL`
ali significa. Se a frase for difícil de escrever, a coluna provavelmente deveria ser `NOT NULL`.
