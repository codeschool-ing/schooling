---
title: WITH, que é a mesma consulta com os passos nomeados
version: 1
---

Esta é a consulta aninhada de duas seções atrás, e esta é ela de novo:

```sql
SELECT * FROM (
    SELECT * FROM (
        SELECT customer_id, count(*) AS n FROM orders GROUP BY customer_id
    ) a WHERE a.n > 3
) b JOIN customers c ON c.id = b.customer_id;
```

```sql
WITH per_customer AS (
    SELECT customer_id, count(*) AS n FROM orders GROUP BY customer_id
),
frequent AS (
    SELECT * FROM per_customer WHERE n > 3
)
SELECT c.name, f.n
FROM   frequent f
JOIN   customers c ON c.id = f.customer_id;
```

Mais longa, e é a versão que você quer às quatro da tarde daqui a seis meses. Ela lê de cima para
baixo na ordem em que o trabalho acontece, cada passo tem um nome que diz o que é, e nenhuma parte
exige segurar três níveis de parêntese na cabeça.

É esse o recurso inteiro. Uma **expressão de tabela comum** é uma subconsulta nomeada escrita antes
da instrução que a usa, e ela não calcula nada que uma tabela derivada não calculasse.

## A sintaxe

```sql
WITH a AS (SELECT …),
     b AS (SELECT … FROM a …),
     c AS (SELECT … FROM a JOIN b …)
SELECT * FROM c;
```

Um `WITH`, depois uma vírgula entre cada definição e nenhuma antes da instrução final. **Uma
definição posterior pode usar uma anterior**, que é o que permite a uma consulta ser uma sequência
de passos; uma anterior não pode usar uma posterior.

A instrução final não precisa ser um `SELECT`. `INSERT`, `UPDATE` e `DELETE` aceitam um `WITH` na
frente, que é como um `DELETE` complicado fica legível:

```sql
WITH stale AS (
    SELECT id FROM sessions WHERE last_seen < now() - INTERVAL '90 days'
)
DELETE FROM sessions WHERE id IN (SELECT id FROM stale);
```

O PostgreSQL tem isso desde a 8.4, o SQLite desde a 3.8.3, o MySQL desde a 8.0 e o MariaDB desde a
10.2. É seguro assumir hoje, e é a razão de muito SQL escrito antes de 2018 parecer pior do que
precisava.

## O que uma tabela derivada não faz

Referir-se ao mesmo passo duas vezes sem escrevê-lo duas vezes:

```sql
WITH monthly AS (
    SELECT date_trunc('month', ordered_on) AS month, sum(total) AS revenue
    FROM   orders
    GROUP BY 1
)
SELECT   this.month, this.revenue, prev.revenue AS previous
FROM     monthly this
LEFT JOIN monthly prev ON prev.month = this.month - INTERVAL '1 month';
```

`monthly` é definido uma vez e usado duas. Como tabela derivada isso são as mesmas vinte linhas
escritas duas vezes, e a segunda cópia é a que alguém esquece de mudar.

Poder nomear não significa que seja calculado uma vez — isso é a próxima seção, e é o único pedaço
de folclore desta aula que vale desmontar.

## Escrever um que valha a pena

Os nomes são a graça, então eles têm que carregar informação. `t1`, `t2`, `sub` e `dados` jogam o
recurso fora e deixam você com uma consulta aninhada mais longa.

```sql
WITH paid_orders   AS (…),
     monthly_totals AS (…),
     growth         AS (…)
SELECT * FROM growth;
```

Uma pessoa lê essas quatro linhas e sabe o que a consulta faz sem ler nenhum dos corpos. É esse o
teste: **se a lista de nomes não descreve a consulta, renomeie.**

Mais dois hábitos que valem. Deixe cada passo fazendo uma coisa — um CTE que agrupa e junta e filtra
e ranqueia é uma consulta aninhada com um nome em cima. E quando um passo merece conferência, você
pode rodá-lo sozinho selecionando dele, que é a razão prática de esta forma ser mais fácil de depurar
que a aninhada.

## CTEs que modificam dados

O PostgreSQL permite uma coisa que os outros não, e ela é genuinamente útil:

```sql
WITH moved AS (
    DELETE FROM sessions
    WHERE  last_seen < now() - INTERVAL '90 days'
    RETURNING *
)
INSERT INTO sessions_archive SELECT * FROM moved;
```

Apagar e arquivar numa instrução só, com o `RETURNING` entregando as linhas apagadas ao insert. As
linhas são movidas ou a instrução falha; não há janela em que elas não estejam em nenhuma das duas
tabelas.

Uma regra rege isso tudo, e ela surpreende: **toda parte da instrução vê o mesmo instantâneo dos
dados.** Um `SELECT` num CTE não vê as linhas que um `UPDATE` num CTE irmão escreveu. Eles não são
passos de um programa, por mais que o layout sugira — são partes de uma instrução, e a ordem em que
rodam não é definida. Dois CTEs que modificam a mesma linha são uma consulta cujo resultado não dá
para raciocinar.

MySQL e SQLite não permitem `INSERT`, `UPDATE` ou `DELETE` dentro de um `WITH`. Ali são duas
instruções numa transação, que é a aula 8.
