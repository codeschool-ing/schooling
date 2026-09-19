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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Três linhas, cada uma mostrando um valor entrando na condição preço maior que vinte e o veredito que sai. Preço trinta dá VERDADEIRO e fica. Preço cinco dá FALSO e cai. Preço nulo dá DESCONHECIDO, aceso, e também cai. Uma nota diz que isto é lógica de três valores e que a negação de desconhecido é desconhecido, então NOT não traz a linha nula de volta.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">WHERE guarda uma linha por um veredito entre três, e um nulo produz o terceiro.</text><rect x=\"14\" y=\"48\" width=\"150\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"89\" y=\"63\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">price = 30</text><path d=\"M168 63 L224 63\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M224 63 L216.0 67.0 L216.0 59.0 Z\" fill=\"var(--wire)\"></path><rect x=\"228\" y=\"48\" width=\"130\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"293\" y=\"63\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">price > 20</text><path d=\"M362 63 L418 63\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M418 63 L410.0 67.0 L410.0 59.0 Z\" fill=\"var(--wire)\"></path><rect x=\"422\" y=\"48\" width=\"120\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"482\" y=\"63\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--phosphor)\">TRUE</text><path d=\"M546 63 L592 63\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M592 63 L584.0 67.0 L584.0 59.0 Z\" fill=\"var(--phosphor)\"></path><text x=\"600\" y=\"63\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">fica</text><rect x=\"14\" y=\"92\" width=\"150\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"89\" y=\"107\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">price = 5</text><path d=\"M168 107 L224 107\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M224 107 L216.0 111.0 L216.0 103.0 Z\" fill=\"var(--wire)\"></path><rect x=\"228\" y=\"92\" width=\"130\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"293\" y=\"107\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">price > 20</text><path d=\"M362 107 L418 107\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M418 107 L410.0 111.0 L410.0 103.0 Z\" fill=\"var(--wire)\"></path><rect x=\"422\" y=\"92\" width=\"120\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"482\" y=\"107\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">FALSE</text><path d=\"M546 107 L592 107\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><path d=\"M592 107 L584.0 111.0 L584.0 103.0 Z\" fill=\"var(--wire)\"></path><text x=\"600\" y=\"107\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cai</text><rect x=\"14\" y=\"136\" width=\"150\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"89\" y=\"151\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">price = NULL</text><path d=\"M168 151 L224 151\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M224 151 L216.0 155.0 L216.0 147.0 Z\" fill=\"var(--wire)\"></path><rect x=\"228\" y=\"136\" width=\"130\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"293\" y=\"151\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">price > 20</text><path d=\"M362 151 L418 151\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M418 151 L410.0 155.0 L410.0 147.0 Z\" fill=\"var(--wire)\"></path><rect x=\"422\" y=\"136\" width=\"120\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"482\" y=\"151\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--amber)\">UNKNOWN</text><path d=\"M546 151 L592 151\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><path d=\"M592 151 L584.0 155.0 L584.0 147.0 Z\" fill=\"var(--wire)\"></path><text x=\"600\" y=\"151\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cai</text><text x=\"14\" y=\"190\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Isto é lógica de três valores: verdadeiro, falso e desconhecido. Comparar qualquer coisa com um nulo dá o terceiro.</text><text x=\"14\" y=\"208\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">Então NOT (price > 20) não traz a linha nula de volta — a negação de desconhecido é desconhecido.</text></svg>", "caption": "O terceiro veredito é a dificuldade inteira. A linha não reprova na condição — a condição não tem resposta sobre ela, e o WHERE guarda só as linhas para as quais disse sim."}
```

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
