---
title: A ordem em que você escreve, e a ordem em que roda
version: 2
---

Uma ideia primeiro, porque ela explica a maior parte dos erros confusos que você vai encontrar no
próximo ano.

**Você escreve as cláusulas numa ordem. O banco as roda em outra.**

```sql
SELECT   name, price                  -- 5. and finally, pick the columns
FROM     products                     -- 1. first, which rows exist
WHERE    price > 20                   -- 2. throw away the ones that fail
GROUP BY category                     -- 3. lesson 6
HAVING   count(*) > 1                 -- 4. lesson 6
ORDER BY price DESC                   -- 6. arrange what survived
LIMIT    10;                          -- 7. take the first few
```

Os números são a ordem em que de fato acontece. `FROM` vem primeiro porque nada pode ser filtrado
antes de se saber o que existe. `SELECT` — a cláusula que você escreveu primeiro — acontece perto do
**fim**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Duas colunas. À esquerda, as cláusulas na ordem em que são escritas: SELECT, FROM, WHERE, GROUP BY, HAVING, ORDER BY, LIMIT. À direita, as mesmas cláusulas numeradas na ordem em que rodam: FROM primeiro, depois WHERE, GROUP BY, HAVING, então SELECT em quinto, e então ORDER BY e LIMIT. Curvas ligam cada cláusula à sua posição, e a curva do SELECT está acesa, atravessando do topo da coluna da esquerda até o quinto lugar.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">As cláusulas que você escreve, e a ordem em que o banco as roda.</text><text x=\"120\" y=\"42\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">como você escreve</text><text x=\"520\" y=\"42\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">como roda</text><rect x=\"40\" y=\"56\" width=\"160\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"120\" y=\"67\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--amber)\">SELECT</text><rect x=\"40\" y=\"82\" width=\"160\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"120\" y=\"93\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">FROM</text><rect x=\"40\" y=\"108\" width=\"160\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"120\" y=\"119\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">WHERE</text><rect x=\"40\" y=\"134\" width=\"160\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"120\" y=\"145\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">GROUP BY</text><rect x=\"40\" y=\"160\" width=\"160\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"120\" y=\"171\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">HAVING</text><rect x=\"40\" y=\"186\" width=\"160\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"120\" y=\"197\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">ORDER BY</text><rect x=\"40\" y=\"212\" width=\"160\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"120\" y=\"223\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">LIMIT</text><rect x=\"440\" y=\"56\" width=\"160\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"520\" y=\"67\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">1.  FROM</text><rect x=\"440\" y=\"82\" width=\"160\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"520\" y=\"93\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">2.  WHERE</text><rect x=\"440\" y=\"108\" width=\"160\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"520\" y=\"119\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">3.  GROUP BY</text><rect x=\"440\" y=\"134\" width=\"160\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"520\" y=\"145\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">4.  HAVING</text><rect x=\"440\" y=\"160\" width=\"160\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"520\" y=\"171\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--amber)\">5.  SELECT</text><rect x=\"440\" y=\"186\" width=\"160\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"520\" y=\"197\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">6.  ORDER BY</text><rect x=\"440\" y=\"212\" width=\"160\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"520\" y=\"223\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">7.  LIMIT</text><path d=\"M204 67 C300 67 340 171 436 171\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M204 93 C300 93 340 67 436 67\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M204 119 C300 119 340 93 436 93\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M204 145 C300 145 340 119 436 119\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M204 171 C300 171 340 145 436 145\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M204 197 C300 197 340 197 436 197\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M204 223 C300 223 340 223 436 223\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"14\" y=\"250\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">SELECT é escrito primeiro e roda em quinto, e é por isso que um nome que você inventa ali não serve no WHERE e serve no ORDER BY.</text></svg>", "caption": "A única linha que cruza é a ideia inteira: SELECT é escrito primeiro e calculado em quinto."}
```

## O que isso explica

Dê um nome novo a uma coluna e tente usá-lo:

```sql
SELECT price * 1.23 AS gross
FROM   products
WHERE  gross > 100;
```

```
ERROR:  column "gross" does not exist
LINE 3: WHERE  gross > 100;
               ^
```

`gross` é inventado pelo `SELECT`, e o `WHERE` rodou antes do `SELECT`. Quando o filtro estava sendo
avaliado o nome não existia. O erro está correto e não diz nada sobre o motivo.

Repita a expressão em vez disso:

```sql
SELECT price * 1.23 AS gross
FROM   products
WHERE  price * 1.23 > 100;
```

## E o que é diferente no ORDER BY

```sql
SELECT price * 1.23 AS gross
FROM   products
ORDER BY gross DESC;
```

Isso funciona. O `ORDER BY` roda **depois** do `SELECT`, então quando ele procura `gross`, o nome
existe.

Então a regra não é "apelidos nunca funcionam". É exatamente:

> **Um apelido do `SELECT` é usável no `ORDER BY`, e não no `WHERE`, `GROUP BY` nem `HAVING`.**

O que não é uma esquisitice para decorar, uma vez que você enxerga a ordem. É a ordem.

## A sequência inteira, uma vez

| | cláusula | o que faz |
|---|---|---|
| 1 | `FROM` / `JOIN` | reúne as linhas a considerar |
| 2 | `WHERE` | descarta linhas que falham um teste |
| 3 | `GROUP BY` | colapsa as sobreviventes em grupos |
| 4 | `HAVING` | descarta grupos inteiros |
| 5 | `SELECT` | calcula as colunas de saída, e as nomeia |
| 6 | `ORDER BY` | arruma o resultado |
| 7 | `LIMIT` / `OFFSET` | pega uma fatia dele |

Mais duas consequências que vale ter agora, e as duas aparecem em aulas seguintes:

**`WHERE` filtra linhas, `HAVING` filtra grupos.** Não são alternativas; rodam em momentos
diferentes sobre coisas diferentes. Aula 6.

**`LIMIT` é o último**, então ele pega uma fatia de um resultado já ordenado. Ele não faz o banco
parar cedo de nenhum jeito sobre o qual você possa raciocinar — e sem `ORDER BY` ele pega uma fatia
arbitrária de um arranjo arbitrário, que é a seção `limit-and-paging`.

## É um modelo, não uma promessa sobre a máquina

Um cuidado que importa a partir da aula 10.

A lista acima é a ordem **lógica** — o que a resposta é definida como sendo. O banco tem liberdade
para fazer o trabalho em qualquer ordem que produza a mesma resposta, e vai: ele pode usar um índice
para evitar ordenar, filtrar enquanto lê em vez de depois, ou parar de ler quando o `LIMIT` estiver
satisfeito.

Essa liberdade é o assunto inteiro do plano de execução. O que ele nunca faz é mudar a resposta.
Então use esta ordem para raciocinar sobre **o que uma consulta significa**, e o plano da aula 10
para raciocinar sobre **quanto ela custa**. Confundir as duas é como as pessoas acabam acreditando
que rearranjar as cláusulas deixa uma consulta mais rápida, o que não deixa, porque você não mudou o
que pediu.
