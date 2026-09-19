---
title: RIGHT e FULL, brevemente e com uma recomendação
version: 1
---

## RIGHT JOIN

Mantém toda linha da tabela da **direita** em vez da esquerda:

```sql
SELECT c.name, o.id
FROM   customers c
RIGHT JOIN orders o ON o.customer_id = c.id;
```

Todo pedido aparece, incluindo o 1005 sem cliente, e o `c.name` dele é nulo.

**É exatamente um `LEFT JOIN` com as tabelas trocadas**, e a troca é a recomendação:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 192\" role=\"img\" aria-label=\"Duas caixas acesas no alto: Célia Reis, uma cliente sem pedido, e o pedido 1005, que não tem cliente. Abaixo delas, quatro painéis — JOIN, LEFT JOIN, RIGHT JOIN e FULL JOIN — cada um dizendo o que faz com os dois. JOIN derruba os dois. LEFT JOIN fica com Célia e derruba 1005. RIGHT JOIN derruba Célia e fica com 1005. FULL JOIN, desenhado aceso, fica com os dois.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Célia has no order. Order 1005 has no customer. The four joins differ only in what they do with those two.</text><rect x=\"14\" y=\"34\" width=\"150\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"46\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">3  Célia Reis</text><text x=\"176\" y=\"46\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">left orphan</text><rect x=\"400\" y=\"34\" width=\"150\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"410\" y=\"46\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">1005   —   12.00</text><text x=\"562\" y=\"46\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">right orphan</text><rect x=\"14\" y=\"76\" width=\"164\" height=\"78\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"96\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">JOIN</text><text x=\"28\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Célia</text><text x=\"164\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--paper-dim)\">cai</text><text x=\"28\" y=\"136\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1005</text><text x=\"164\" y=\"136\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--paper-dim)\">cai</text><rect x=\"190\" y=\"76\" width=\"164\" height=\"78\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"272\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">LEFT JOIN</text><text x=\"204\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Célia</text><text x=\"340\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--phosphor)\">fica</text><text x=\"204\" y=\"136\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1005</text><text x=\"340\" y=\"136\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--paper-dim)\">cai</text><rect x=\"366\" y=\"76\" width=\"164\" height=\"78\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"448\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">RIGHT JOIN</text><text x=\"380\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Célia</text><text x=\"516\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--paper-dim)\">cai</text><text x=\"380\" y=\"136\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1005</text><text x=\"516\" y=\"136\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--phosphor)\">fica</text><rect x=\"542\" y=\"76\" width=\"164\" height=\"78\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"624\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">FULL JOIN</text><text x=\"556\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Célia</text><text x=\"692\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--phosphor)\">fica</text><text x=\"556\" y=\"136\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1005</text><text x=\"692\" y=\"136\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--phosphor)\">fica</text><text x=\"14\" y=\"176\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">RIGHT é o LEFT com as tabelas trocadas, e é por isso que a recomendação é trocá-las e escrever LEFT.</text></svg>", "caption": "A única diferença entre as quatro é qual órfã sobrevive. Todo o resto nelas é a mesma junção."}
```

```sql
FROM orders o LEFT JOIN customers c ON c.id = o.customer_id
```

Mesmas linhas, mesma resposta, e lê na direção de que a consulta trata — *todo pedido, com o cliente
dele onde houver.*

> **Escreva `LEFT JOIN`. Troque as tabelas em vez de buscar o `RIGHT`.**

Não porque o `RIGHT` seja quebrado, mas porque quem percorre uma consulta monta a figura de cima para
baixo, e um `RIGHT JOIN` três tabelas adiante significa que a coisa de que a consulta trata está mais
embaixo na lista em vez de no começo. Misture os dois numa consulta e quase ninguém consegue dizer
qual é o conjunto de resultados sem resolver no papel.

Você ainda vai encontrar — normalmente numa consulta que cresceu uma tabela por vez — e reconhecer é
tudo de que você precisa.

## FULL OUTER JOIN

Mantém tudo dos dois lados:

```sql
SELECT c.name, o.id
FROM   customers c
FULL JOIN orders o ON o.customer_id = c.id;
```

```
 name       | id
------------+------
 Ana Lopes  | 1001
 Ana Lopes  | 1003
 Ana Lopes  | 1004
 Bruno Sá   | 1002
 Célia Reis | NULL    <- um cliente sem pedido
 NULL       | 1005    <- um pedido sem cliente
```

Os dois tipos de órfão, num resultado. É genuinamente raro em código de aplicação e genuinamente útil
para um trabalho: **reconciliação**.

```sql
SELECT coalesce(a.reference, b.reference) AS reference,
       a.amount AS ours,
       b.amount AS theirs
FROM   our_ledger   a
FULL JOIN their_statement b ON b.reference = a.reference
WHERE  a.reference IS NULL          -- só eles têm
   OR  b.reference IS NULL          -- só nós temos
   OR  a.amount <> b.amount;        -- os dois têm e discordam
```

Essa é a consulta para *"em que estes dois sistemas discordam"*, e ela acha os três tipos de
discordância de uma vez. Todo sistema financeiro, toda importação, toda migração acaba precisando.

Note o `coalesce` na primeira coluna: qualquer lado pode ser nulo, então nenhum sozinho te dá a
referência.

## Qual usar, como uma tabela

| você quer | escreva |
|---|---|
| só linhas que pareiam | `JOIN` |
| toda linha da tabela de que a pergunta trata | `LEFT JOIN`, com aquela tabela primeiro |
| toda linha da outra | troque as tabelas e use `LEFT JOIN` |
| os dois conjuntos de órfãos | `FULL JOIN` |
| todo par, deliberadamente | `CROSS JOIN` — a seção `the-other-joins` |

Na prática, ao longo de uma carreira: a grande maioria `JOIN`, uma minoria substancial `LEFT JOIN`,
`FULL JOIN` um punhado de vezes, e `RIGHT JOIN` principalmente lendo código dos outros.

## O MySQL não tem FULL JOIN

Vale saber antes da aula 12, porque é a lacuna em que as pessoas esbarram:

```sql
SELECT … FROM a LEFT JOIN b ON …
UNION
SELECT … FROM a RIGHT JOIN b ON …;
```

Uma junção à esquerda e uma à direita, unidas — `UNION` e não `UNION ALL`, porque as linhas pareadas
aparecem nas duas metades e as duplicatas têm que sair. Funciona, é mais lento, e é a solução padrão.
O SQLite ganhou `FULL JOIN` em 2022; o MariaDB ainda não.
