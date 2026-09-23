---
title: INNER JOIN, o que você mais escreve
version: 2
---

```sql
SELECT c.name, o.id, o.total
FROM   customers c
INNER JOIN orders o ON o.customer_id = c.id;
```

`INNER` é o padrão, então quase ninguém escreve:

```sql
FROM customers c JOIN orders o ON o.customer_id = c.id
```

**Só pares que satisfazem a condição sobrevivem.** Uma linha de qualquer lado sem parceiro não está
no resultado, e nada avisa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Três clientes à esquerda — Ana, Bruno e Célia — e quatro pedidos à direita. Linhas curvas pareiam cada pedido com seu cliente: três chegam a Ana e uma chega a Bruno. A caixa da Célia está apagada e não tem linha nenhuma. À direita, o resultado tem quatro linhas: Ana três vezes e Bruno uma. Célia não está nele.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">customers c  JOIN  orders o  ON o.customer_id = c.id</text><text x=\"14\" y=\"42\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">customers</text><rect x=\"14\" y=\"56\" width=\"150\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"69\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1  Ana Lopes</text><rect x=\"14\" y=\"88\" width=\"150\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"101\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2  Bruno Sá</text><rect x=\"14\" y=\"120\" width=\"150\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"24\" y=\"133\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3  Célia Reis</text><text x=\"300\" y=\"42\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">orders</text><rect x=\"300\" y=\"56\" width=\"168\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"308\" y=\"68\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1001  Ana    34.90</text><rect x=\"300\" y=\"82\" width=\"168\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"308\" y=\"94\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1003  Ana    51.00</text><rect x=\"300\" y=\"108\" width=\"168\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"308\" y=\"120\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1004  Ana    34.90</text><rect x=\"300\" y=\"134\" width=\"168\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"308\" y=\"146\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1002  Bruno  69.80</text><path d=\"M164 69 C204 69 260 68 300 68\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M164 69 C204 69 260 94 300 94\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M164 69 C204 69 260 120 300 120\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M164 101 C204 101 260 146 300 146\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"506\" y=\"42\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">resultado</text><rect x=\"506\" y=\"56\" width=\"200\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"514\" y=\"66\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Ana Lopes   1001  34.90</text><rect x=\"506\" y=\"80\" width=\"200\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"514\" y=\"90\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Ana Lopes   1003  51.00</text><rect x=\"506\" y=\"104\" width=\"200\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"514\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Ana Lopes   1004  34.90</text><rect x=\"506\" y=\"128\" width=\"200\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"514\" y=\"138\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Bruno Sá    1002  69.80</text><text x=\"14\" y=\"196\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Quatro pares, quatro linhas. Célia não tem par, então não está aqui — e nada avisa.</text></svg>", "caption": "Um par sobrevive ou não está no resultado. Célia cai em silêncio, que é do que tratam as duas seções seguintes.", "same": ["customers", "orders"]}
```

## Os apelidos não são decoração

```sql
SELECT c.name, o.id
FROM   customers c
JOIN   orders o ON o.customer_id = c.id;
```

As duas tabelas têm `id`. Escrever `SELECT id` é erro — *column reference "id" is ambiguous* — e esse
erro é o caso bom. O caso ruim são duas tabelas em que só uma tem a coluna hoje, então o nome sem
qualificação funciona, e alguém acrescenta aquela coluna na outra tabela no ano que vem. A consulta
continua válida e agora lê a errada.

> **Qualifique toda coluna numa junção. Mesmo as inequívocas.**

E os apelidos deixam legível: `c` e `o` numa consulta de duas tabelas, nomes curtos com significado
numa de cinco. `customers AS c` é a grafia padrão e `customers c` é a mesma coisa.

## A sintaxe antiga, e por que vale reconhecer

Você vai encontrar isto em código existente:

```sql
SELECT c.name, o.id
FROM   customers c, orders o
WHERE  o.customer_id = c.id;
```

Uma vírgula entre tabelas significa todo par, e o `WHERE` então joga a maioria fora. Produz a mesma
resposta que a junção explícita acima e é pior em dois aspectos:

- **A condição de junção e os filtros ficam misturados.** Lendo uma consulta de cinco tabelas nesse
  estilo, você não distingue de relance quais condições conectam as tabelas e quais selecionam
  linhas.
- **Esquecer uma não é erro.** Omita `WHERE o.customer_id = c.id` e você recebe todo cliente pareado
  com todo pedido — três vezes cinco linhas aqui, e três milhões vezes cinco milhões num sistema
  real. A consulta roda, devolve absurdo, e leva o banco junto.

`JOIN … ON` explícito não pode ser esquecido do mesmo jeito: o `ON` é parte da sintaxe. Use.

## Uma junção interna é simétrica

```sql
FROM customers c JOIN orders o ON o.customer_id = c.id
FROM orders o JOIN customers c ON c.id = o.customer_id
```

Mesmas linhas, mesma resposta. Nada no `INNER JOIN` prefere um lado, então qual tabela vem primeiro é
decisão de legibilidade — comece pela coisa de que a consulta *trata*, e junte o que a decora.

**Isso deixa de ser verdade no `LEFT JOIN`**, onde os lados significam coisas diferentes. É a seção
depois da próxima, e é a razão de quem aprendeu junções como "combinar tabelas" travar.

## A condição pode ser qualquer coisa, e normalmente não é

Quase toda junção que você escrever será uma igualdade sobre uma chave estrangeira:

```sql
ON o.customer_id = c.id
```

Isso não é regra do SQL; é o que um esquema normalizado torna natural, e vale notar que as aulas 1 e
2 estavam construindo exatamente para isto. Uma tabela com uma lista numa célula, ou um nome repetido
em vez de uma referência, não pode ser juntada — que é o custo prático dos formatos que aquelas aulas
recusaram.

Quando a condição é outra coisa, vale um comentário:

```sql
-- a price valid at the time of the order, not the current one
JOIN price_history p
  ON p.product_id = l.product_id
 AND o.ordered_on BETWEEN p.valid_from AND p.valid_to
```

Isso é uma junção por faixa, é um padrão real, e é também onde a multiplicação da próxima seção morde
mais forte — se duas linhas de `price_history` se sobrepõem, todo pedido na sobreposição é contado
duas vezes, e nada recusa.
