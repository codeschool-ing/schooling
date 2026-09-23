---
title: LEFT JOIN, e as linhas que estavam sumindo
version: 2
---

A Célia nunca pediu. Uma junção interna a deixa de fora, e nada avisa.

Na maior parte do tempo isso está errado, porque as perguntas que as pessoas de fato fazem são sobre
todo mundo:

- *Quanto cada cliente gastou?* — a Célia gastou zero, e zero é uma resposta.
- *Quais produtos nunca venderam?* — pergunta inteiramente sobre linhas sem parceiro.
- *Mostre todo pedido com o envio dele* — pedidos ainda não enviados são o que alguém procura.

```sql
SELECT c.name, o.id, o.total
FROM   customers c
LEFT JOIN orders o ON o.customer_id = c.id;
```

```
 name       | id   | total
------------+------+-------
 Ana Lopes  | 1001 | 34.90
 Ana Lopes  | 1003 | 51.00
 Ana Lopes  | 1004 | 34.90
 Bruno Sá   | 1002 | 69.80
 Célia Reis | NULL | NULL
```

Cinco linhas. **Toda linha da tabela da esquerda aparece pelo menos uma vez**; onde não há parceiro,
as colunas da direita são preenchidas com `NULL`.

## O que `LEFT` significa, exatamente

> **Mantenha toda linha da tabela da esquerda. Pareie onde der. Onde não der, invente um par com
> nulos à direita.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Os mesmos três clientes e quatro pedidos. Linhas curvas pareiam três pedidos com Ana e um com Bruno. A caixa da Célia está acesa como as outras, e uma linha tracejada leva dela a um par de nulos. À direita, o resultado tem cinco linhas: Ana três vezes, Bruno uma, e Célia uma com nulo nas duas colunas de pedido.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">customers c  LEFT JOIN  orders o  ON o.customer_id = c.id</text><text x=\"14\" y=\"42\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">customers</text><rect x=\"14\" y=\"56\" width=\"150\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"69\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1  Ana Lopes</text><rect x=\"14\" y=\"88\" width=\"150\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"101\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2  Bruno Sá</text><rect x=\"14\" y=\"120\" width=\"150\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"133\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">3  Célia Reis</text><text x=\"300\" y=\"42\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">orders</text><rect x=\"300\" y=\"56\" width=\"168\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"308\" y=\"68\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1001  Ana    34.90</text><rect x=\"300\" y=\"82\" width=\"168\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"308\" y=\"94\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1003  Ana    51.00</text><rect x=\"300\" y=\"108\" width=\"168\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"308\" y=\"120\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1004  Ana    34.90</text><rect x=\"300\" y=\"134\" width=\"168\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"308\" y=\"146\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1002  Bruno  69.80</text><path d=\"M164 69 C204 69 260 68 300 68\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M164 69 C204 69 260 94 300 94\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M164 69 C204 69 260 120 300 120\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M164 101 C204 101 260 146 300 146\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M164 133 C204 133 260 173 300 173\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><text x=\"308\" y=\"173\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">NULL   NULL</text><text x=\"506\" y=\"42\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">resultado</text><rect x=\"506\" y=\"56\" width=\"200\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"514\" y=\"66\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Ana Lopes   1001  34.90</text><rect x=\"506\" y=\"80\" width=\"200\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"514\" y=\"90\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Ana Lopes   1003  51.00</text><rect x=\"506\" y=\"104\" width=\"200\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"514\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Ana Lopes   1004  34.90</text><rect x=\"506\" y=\"128\" width=\"200\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"514\" y=\"138\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Bruno Sá    1002  69.80</text><rect x=\"506\" y=\"152\" width=\"200\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"514\" y=\"162\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">Célia Reis  NULL  NULL</text><text x=\"14\" y=\"196\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Cinco linhas. Todo cliente aparece ao menos uma vez; onde não há par, as colunas da direita ficam nulas.</text></svg>", "caption": "A linha tracejada é o par que o banco inventa para que Célia tenha um. É o que LEFT quer dizer, inteiro.", "same": ["customers", "orders"]}
```

`LEFT OUTER JOIN` é a grafia completa; o `OUTER` é opcional e quase ninguém escreve.

**Os lados agora significam coisas diferentes**, que é a diferença para a junção interna:

```sql
FROM customers c LEFT JOIN orders o ON …    -- every customer, orders where there are some
FROM orders o LEFT JOIN customers c ON …    -- every order, customers where there are some
```

São consultas diferentes. A primeira mantém a Célia; a segunda mantém o pedido 1005, a compra sem
conta. Qual você quer depende da pergunta, e inverter produz um resultado que parece bom e responde
outra coisa.

O hábito: **ponha na esquerda a tabela de que a pergunta trata.**

## Os nulos que ela cria não estão nos dados

Isso pega todo mundo uma vez. `o.total` é `NOT NULL` na tabela — a aula 3 declarou — e aqui está ele,
nulo.

O nulo não foi lido de lugar nenhum. **A junção o inventou**, porque não havia linha de onde tirar um
valor. O que significa que toda regra da aula 1 se aplica a ele:

```sql
SELECT c.name, sum(o.total) FROM customers c LEFT JOIN orders o ON … GROUP BY c.name;
```

A soma da Célia é `NULL`, não `0` — porque `sum` de nada é desconhecido e não zero. Quase sempre o
que você quer mostrar é zero:

```sql
SELECT c.name, coalesce(sum(o.total), 0) AS spent
FROM   customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.name;
```

E a contagem precisa de cuidado pelo mesmo motivo:

```sql
count(*)        -- 1 for Célia: there is one row, the invented one
count(o.id)     -- 0 for Célia: the column is null and count ignores nulls
```

**`count(*)` depois de um `LEFT JOIN` quase sempre é o bug.** Ele conta linhas, e a Célia tem uma
linha. `count(o.id)` conta pedidos, que é o que alguém queria. Esta é a coisa mais útil a lembrar
sobre contar depois de uma junção externa.

## Lendo uma

Quando você vir um `LEFT JOIN`, três perguntas:

1. **Qual é a tabela da esquerda?** É o conjunto de linhas de que a resposta trata.
2. **Quais colunas agora podem ser nulas e não eram?** Todas as do lado direito.
3. **Alguma coisa adiante trata esses nulos corretamente?** O `count(*)`, o `sum`, o `WHERE` — cada
   um tem uma regra da aula 1 e cada uma se aplica.

Essa terceira pergunta é a próxima seção inteira, porque existe um lugar onde uma condição pode ir
que transforma um `LEFT JOIN` de volta numa junção interna sem avisar.
