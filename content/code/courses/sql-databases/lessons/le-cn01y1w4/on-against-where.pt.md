---
title: ON contra WHERE, que é o bug deste curso
version: 1
---

Esta seção é um bug. Ele não produz erro, parece uma consulta funcionando, e é o engano mais comum em
SQL depois de esquecer que `NULL` existe.

Você quer todo cliente, com os pedidos dele de março.

```sql
SELECT c.name, o.id
FROM   customers c
LEFT JOIN orders o ON o.customer_id = c.id
WHERE  o.ordered_on >= '2026-03-01';
```

**A Célia sumiu.** E todo cliente que não pediu em março também. O `LEFT JOIN` continua lá e não está
fazendo nada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 292\" role=\"img\" aria-label=\"Dois painéis mostrando as mesmas quatro linhas unidas: três pedidos reais e a linha inventada da Célia com nulos. À esquerda, a condição de data está escrita no ON: a linha cuja data está fora de março apaga, e Célia sobrevive, marcada com nulo comparado a uma data é desconhecido. À direita, a condição está no WHERE: a mesma linha apaga e a linha da Célia fica acesa como derrubada, porque desconhecido não é verdadeiro. Notas dizem que o LEFT JOIN continua lá nas duas e que na segunda ele não faz nada, sem erro e sem aviso.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Todo cliente, com seus pedidos de março. As duas consultas diferem por onde a condição de data está escrita.</text><rect x=\"14\" y=\"44\" width=\"330\" height=\"194\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"179\" y=\"62\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--phosphor)\">ON o.customer_id = c.id AND o.ordered_on >= …</text><text x=\"28\" y=\"84\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que a junção produziu</text><rect x=\"28\" y=\"96\" width=\"240\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"106\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Ana Lopes   1001  03-04</text><rect x=\"28\" y=\"120\" width=\"240\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"36\" y=\"130\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Ana Lopes   1003  02-11</text><rect x=\"28\" y=\"144\" width=\"240\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"154\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Bruno Sá    1002  03-20</text><rect x=\"28\" y=\"168\" width=\"240\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"178\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Célia Reis  NULL   NULL</text><text x=\"28\" y=\"198\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">o NULL dela >= data é desconhecido</text><text x=\"28\" y=\"222\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">a condição rodou no pareamento: Célia fica com a linha inventada</text><rect x=\"376\" y=\"44\" width=\"330\" height=\"194\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"541\" y=\"62\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--amber)\">ON o.customer_id = c.id  …  WHERE o.ordered_on >= …</text><text x=\"390\" y=\"84\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que a junção produziu</text><rect x=\"390\" y=\"96\" width=\"240\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"398\" y=\"106\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Ana Lopes   1001  03-04</text><rect x=\"390\" y=\"120\" width=\"240\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"398\" y=\"130\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Ana Lopes   1003  02-11</text><rect x=\"390\" y=\"144\" width=\"240\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"398\" y=\"154\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Bruno Sá    1002  03-20</text><rect x=\"390\" y=\"168\" width=\"240\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"398\" y=\"178\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Célia Reis  NULL   NULL</text><text x=\"390\" y=\"198\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">o NULL dela >= data é desconhecido</text><text x=\"390\" y=\"222\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">a condição rodou depois: a linha inventada da Célia reprova nela e cai</text><text x=\"14\" y=\"260\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">O LEFT JOIN continua lá nas duas, e na segunda ele não está fazendo nada.</text><text x=\"14\" y=\"278\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">Sem erro, sem aviso, e um resultado com cara de consulta que funciona.</text></svg>", "caption": "As duas consultas são válidas, as duas rodam, e uma delas responde em silêncio a outra pergunta. A cláusula em que a condição está é a diferença inteira."}
```

## Por quê

Volte à ordem em que as cláusulas rodam, da aula 4. A junção roda primeiro, e faz o trabalho dela:

```
 Ana Lopes  | 1001
 Ana Lopes  | 1003
 Bruno Sá   | 1002
 Célia Reis | NULL      <- a linha inventada
```

Aí o `WHERE` roda sobre esse resultado. O `o.ordered_on` da Célia é `NULL`, porque todo o lado
direito da linha dela é nulo. `NULL >= '2026-03-01'` é **desconhecido**, e o `WHERE` mantém linhas em
que a condição é verdadeira.

A linha dela é descartada. O `LEFT JOIN` produziu e o `WHERE` jogou fora.

> **Uma condição sobre a tabela da direita no `WHERE` transforma um `LEFT JOIN` num `INNER JOIN`.**

## O conserto, que é uma palavra mudada de lugar

```sql
SELECT c.name, o.id
FROM   customers c
LEFT JOIN orders o ON o.customer_id = c.id
                  AND o.ordered_on >= '2026-03-01';
```

O `ON` decide **quais pares são feitos**. O `WHERE` decide **quais linhas sobrevivem depois**. Pôr a
condição no `ON` significa que a Célia nunca ganha parceiro em primeiro lugar — então ela ganha a
linha nula inventada, e está na resposta.

```
 Ana Lopes  | 1004
 Bruno Sá   | NULL      <- pediu, mas não em março
 Célia Reis | NULL      <- nunca pediu
```

Leia essas duas últimas linhas, porque são o ponto: **a consulta já não consegue distinguir uma da
outra** só pela saída, e muitas vezes tudo bem. Quando não está, você precisa de uma coluna que diga
qual caso é, e os agregados da aula 6 são como.

## A regra, e a única exceção

> **Num `LEFT JOIN`: condições sobre a tabela da direita vão no `ON`. Condições sobre a tabela da
> esquerda vão no `WHERE`.**

`WHERE c.city = 'Porto'` é sobre clientes — o lado esquerdo — então pertence ao `WHERE` e se comporta
exatamente como você espera.

E a exceção, que é técnica e não engano:

```sql
WHERE o.id IS NULL
```

Isso é deliberado. Mantém só as linhas em que a junção não achou nada — uma **anti-junção**, que é a
seção `finding-what-is-missing`. Transforma o `LEFT JOIN` num filtro de ausência, e é a única vez em
que você quer um `WHERE` sobre a tabela da direita.

## Numa junção interna não faz diferença

```sql
FROM customers c JOIN orders o ON o.customer_id = c.id AND o.total > 50
FROM customers c JOIN orders o ON o.customer_id = c.id WHERE o.total > 50
```

Resultados idênticos. Não há linha inventada para perder, então filtrar durante e filtrar depois dão
na mesma.

**Que é exatamente por que o bug sobrevive.** Alguém aprende junções com junções internas, aprende
que `ON` e `WHERE` são intercambiáveis, e leva isso para um `LEFT JOIN` onde é falso. A regra não é
"depende" — é que as duas cláusulas sempre significaram coisas diferentes, e a junção interna é o
caso em que a diferença não aparece.

## Como pegar

**Conte a tabela da esquerda antes e depois.** Se `customers` tem 3 linhas e sua consulta com
`LEFT JOIN` devolve 2, você perdeu uma e o `WHERE` é para onde ela foi.

**Procure colunas da direita no `WHERE`.** Lendo qualquer consulta com `LEFT JOIN`, percorra o
`WHERE` atrás de uma coluna da tabela da direita. Cada uma é ou este bug ou um `IS NULL` deliberado, e
você deve saber dizer qual.
