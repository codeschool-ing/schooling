---
title: A multiplicação, que é de onde vêm as respostas erradas
version: 1
---

Esta é a seção mais importante da aula, e é sobre contar.

A Ana tem três pedidos. Junte `customers` com `orders` e **a linha da Ana aparece três vezes**. O
nome dela, o email, a cidade — três cópias, em três linhas do resultado.

Isso está correto. É o que "uma linha por par" significa. E é a origem de quase todo número errado em
SQL, porque no momento em que você conta ou soma essas linhas, você está contando a Ana três vezes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"À esquerda, uma tabela customers com três linhas: Ana, Bruno e Célia. No meio, uma tabela orders com quatro linhas, três da Ana e uma do Bruno. À direita, o resultado da junção: quatro linhas, em que o nome da Ana aparece três vezes e o do Bruno uma, enquanto a Célia não aparece. Uma nota diz: entraram três clientes e saíram quatro linhas.\"><text x=\"14\" y=\"24\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">customers</text>\n<rect x=\"14\" y=\"32\" width=\"124\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"24\" y=\"45\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1  Ana</text>\n<rect x=\"14\" y=\"58\" width=\"124\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"24\" y=\"71\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2  Bruno</text>\n<rect x=\"14\" y=\"84\" width=\"124\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"24\" y=\"97\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3  Celia</text>\n<text x=\"14\" y=\"130\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3 linhas</text>\n<text x=\"250\" y=\"24\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">orders</text>\n<rect x=\"250\" y=\"32\" width=\"150\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"260\" y=\"45\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1001  c=1  34.90</text>\n<rect x=\"250\" y=\"58\" width=\"150\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"260\" y=\"71\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1002  c=2  69.80</text>\n<rect x=\"250\" y=\"84\" width=\"150\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"260\" y=\"97\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1003  c=1  51.00</text>\n<rect x=\"250\" y=\"110\" width=\"150\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"260\" y=\"123\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1004  c=1  34.90</text>\n<text x=\"250\" y=\"156\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">4 linhas</text>\n<text x=\"520\" y=\"24\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">a junção</text>\n<rect x=\"520\" y=\"32\" width=\"186\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"530\" y=\"45\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Ana    1001   34.90</text>\n<rect x=\"520\" y=\"58\" width=\"186\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"530\" y=\"71\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Ana    1003   51.00</text>\n<rect x=\"520\" y=\"84\" width=\"186\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"530\" y=\"97\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Ana    1004   34.90</text>\n<rect x=\"520\" y=\"110\" width=\"186\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"530\" y=\"123\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Bruno  1002   69.80</text>\n<text x=\"520\" y=\"156\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">4 linhas, e a Ana está em três</text>\n<path d=\"M144 45 L244 45\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M236 40 L244 45 L236 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path>\n<path d=\"M406 72 L514 72\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M506 67 L514 72 L506 77\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path>\n<line x1=\"14\" y1=\"184\" x2=\"706\" y2=\"184\" stroke=\"var(--wire)\" stroke-width=\"1\"></line>\n<text x=\"14\" y=\"208\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">O que cada contagem significa depois</text>\n<text x=\"14\" y=\"232\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">count(*)</text><text x=\"200\" y=\"232\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">4</text><text x=\"240\" y=\"232\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">pares, não clientes e não pedidos</text>\n<text x=\"14\" y=\"254\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">count(DISTINCT c.id)</text><text x=\"200\" y=\"254\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">2</text><text x=\"240\" y=\"254\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">clientes que pediram — a Célia está ausente</text>\n<text x=\"14\" y=\"276\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sum(c.credit_limit)</text><text x=\"200\" y=\"276\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">errado</text><text x=\"280\" y=\"276\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o limite da Ana é somado três vezes</text>\n</svg>", "caption": "Três clientes e quatro pedidos produzem quatro linhas. A Ana está em três delas, então qualquer total sobre uma coluna de cliente a conta três vezes."}
```
## As respostas erradas que isso produz

**Contar.**

```sql
SELECT count(*) FROM customers c JOIN orders o ON o.customer_id = c.id;
```

Quatro. Não o número de clientes, que é 3, e não o de quem pediu, que é 2. É o número de **pares**, e
essa raramente é a pergunta que alguém fez.

**Somar uma coluna da tabela do lado de um.**

```sql
SELECT sum(c.credit_limit) FROM customers c JOIN orders o ON o.customer_id = c.id;
```

O limite de crédito da Ana é somado três vezes. O número não significa nada e parece completamente
comum, que é por que ninguém pega a olho. Esta é a versão que chega a um relatório de diretoria.

**E o `DISTINCT` escondendo**, que a aula 4 avisou e aqui é onde acontece:

```sql
SELECT DISTINCT c.name FROM customers c JOIN orders o ON o.customer_id = c.id;
```

Duas linhas, resposta correta, e o defeito continua lá — a consulta construiu quatro linhas e jogou
uma fora. Acrescente uma coluna e ele volta. Acrescente um `count(*)` e o `DISTINCT` não salva nada.

## A multiplicação é propriedade da relação

Se uma junção multiplica é decidido por qual lado é "muitos", e a aula 1 te deu a ferramenta:

| junção | linhas por linha da esquerda |
|---|---|
| um muitos-para-um, na chave estrangeira — `orders` para `customers` | exatamente uma |
| um um-para-muitos — `customers` para `orders` | quantas houver |
| através de uma tabela de ligação — `orders` para `products` | uma por linha |
| dois um-para-muitos a partir da mesma tabela | **o produto dos dois**, e este é o traiçoeiro |

Essa última linha merece demonstração própria, porque é o bug de junção que sobrevive à revisão:

```sql
SELECT o.id, sum(l.quantity), sum(p.amount)
FROM   orders o
JOIN   order_lines l ON l.order_id = o.id
JOIN   payments    p ON p.order_id = o.id
GROUP BY o.id;
```

Um pedido com 3 linhas e 2 pagamentos produz **seis** linhas. Toda quantidade é contada duas vezes e
todo pagamento três. Os dois totais estão errados, nenhum obviamente, e a consulta lê perfeitamente.

## O que fazer sobre isso

**Saiba o que é uma linha do seu resultado**, e diga em voz alta. *"Uma linha por pedido por linha
por pagamento"* torna o problema audível antes de você rodar qualquer coisa.

**Agregue cada lado separadamente** em vez de juntar os dois e torcer. As subconsultas da aula 7 são
a ferramenta, e o formato é:

```sql
SELECT o.id, l.total_quantity, p.total_paid
FROM   orders o
LEFT JOIN (SELECT order_id, sum(quantity) AS total_quantity FROM order_lines GROUP BY order_id) l
       ON l.order_id = o.id
LEFT JOIN (SELECT order_id, sum(amount)   AS total_paid     FROM payments    GROUP BY order_id) p
       ON p.order_id = o.id;
```

Cada subconsulta produz **uma linha por pedido**, então nenhuma multiplica a outra. É mais longa e
está certa.

**E confira a contagem antes de confiar no número.** `SELECT count(*)` na consulta juntada, contra a
contagem da tabela sobre a qual você acha que está reportando. Se diferirem e você não esperava, a
multiplicação é o motivo.
