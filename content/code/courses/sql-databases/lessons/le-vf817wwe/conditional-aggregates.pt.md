---
title: Contar só algumas linhas, na mesma passada
version: 1
---

Um `WHERE` vale para a consulta inteira. Mas a pergunta em geral não é *"quantos pedidos pagos"* —
é *"quantos pedidos, e desses quantos pagos, e quanto deram os cancelados"*, que são três números
sobre um mesmo conjunto de linhas.

Você pode rodar três consultas. Também pode pedir a cada agregação que olhe para um subconjunto
diferente, e ler a tabela uma vez:

```sql
SELECT count(*)                                   AS orders,
       count(*) FILTER (WHERE status = 'paid')    AS paid,
       count(*) FILTER (WHERE status = 'cancelled') AS cancelled,
       sum(total) FILTER (WHERE status = 'paid')  AS revenue
FROM   orders
WHERE  ordered_on >= DATE '2026-01-01';
```

O `WHERE` lá embaixo escolhe as linhas de que a consulta trata. Cada `FILTER` estreita mais, para
uma agregação só. Quatro números, uma varredura, e as definições visíveis lado a lado em vez de
espalhadas por três arquivos.

`FILTER` é SQL padrão. O PostgreSQL tem, o SQLite tem desde a 3.30, e **MySQL e MariaDB não têm** —
que é por que a forma seguinte é a que você mais vai ver.

## A forma portável, e a armadilha dela

```sql
SELECT count(*)                                      AS orders,
       count(CASE WHEN status = 'paid' THEN 1 END)   AS paid
FROM   orders;
```

`CASE` sem `ELSE` devolve `NULL` para as linhas que não casam, e `count` ignora nulos. Então as
linhas não pagas não contribuem com nada. O mecanismo inteiro é a regra da primeira seção, usada de
propósito.

Agora a armadilha, que tem uma palavra:

```sql
count(CASE WHEN status = 'paid' THEN 1 ELSE 0 END)   -- conta TODAS as linhas
```

`0` não é nulo. O `count` conta. Isso devolve o número total de pedidos, seja qual for o status, e é
um bug que sobrevive à revisão porque lê como se devesse funcionar — alguém acrescentou o `ELSE 0`
por capricho e mudou a resposta.

`sum` é o hábito mais seguro exatamente por isso, porque com `sum` o zero está certo:

```sql
sum(CASE WHEN status = 'paid' THEN 1 ELSE 0 END)     -- correto
count(CASE WHEN status = 'paid' THEN 1 END)          -- correto
count(CASE WHEN status = 'paid' THEN 1 ELSE 0 END)   -- sempre o número de linhas
```

Duas dessas três estão certas. Quando encontrar uma no código, confira qual.

## Taxas, que são uma média de uns e zeros

Uma proporção é uma soma condicional dividida por uma contagem, e `avg` faz as duas de uma vez:

```sql
SELECT avg(CASE WHEN status = 'paid' THEN 1.0 ELSE 0 END) AS paid_rate
FROM   orders;
```

`0.62` — a fatia de pedidos que foram pagos. O `1.0` importa: com `1` e colunas inteiras alguns
bancos fazem divisão inteira no caminho e lhe entregam um `0` seco. No PostgreSQL dá para pular o
`CASE` inteiro, porque um booleano converte:

```sql
SELECT avg((status = 'paid')::int) AS paid_rate FROM orders;
```

E repare no que acontece se você escrever `avg(CASE WHEN status = 'paid' THEN 1.0 END)` sem o
`ELSE` — as linhas não pagas viram nulas, o `avg` as ignora, e a resposta é `1.0` para toda tabela
que tenha um único pedido pago. Aqui o `ELSE` é obrigatório, onde dois trechos atrás ele era o bug.
É a diferença entre contar linhas e tirar a média de valores, e vale conseguir dizer qual das duas
você está fazendo.

## Transformar linhas em colunas

A mesma técnica com um `GROUP BY` embaixo é como se faz um pivô, ou seja, como se produz a tabela
que uma pessoa realmente quer olhar:

```sql
SELECT   c.region,
         count(*) FILTER (WHERE o.status = 'paid')      AS paid,
         count(*) FILTER (WHERE o.status = 'pending')   AS pending,
         count(*) FILTER (WHERE o.status = 'cancelled') AS cancelled
FROM     orders o
JOIN     customers c ON c.id = o.customer_id
GROUP BY c.region;
```

Uma linha por região, uma coluna por status. `GROUP BY status` daria os mesmos fatos como três
linhas por região, o que está correto e é mais difícil de ler de través. Qual formato você quer
depende de quem vai ler, e a agregação condicional é como você escolhe.

O limite merece ser dito com todas as letras: **as colunas são escritas à mão.** Um status que
ninguém previu não aparece, e nenhum erro diz isso. Se o conjunto de valores muda, agrupe por ele em
linhas e deixe a ferramenta da outra ponta dispor — SQL devolve um conjunto fixo de colunas, sempre,
e uma consulta não pode descobrir o próprio formato.

## O que isso substitui

O formato que isso mais costuma substituir é uma consulta com vários `LEFT JOIN` para a mesma
tabela, um por status, cada um com a sua condição no `ON`. Essa versão multiplica — todos os
problemas da aula 5, três vezes — e é mais lenta, porque lê `orders` uma vez por junção. A agregação
condicional lê uma vez só e não tem como abrir leque, porque não existe uma segunda cópia da tabela
contra a qual abrir.
