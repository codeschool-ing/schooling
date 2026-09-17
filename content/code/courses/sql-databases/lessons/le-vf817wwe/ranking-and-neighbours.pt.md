---
title: Ranquear, e olhar a linha anterior a esta
version: 1
---

As funções desta seção só existem como funções de janela — não há versão com `GROUP BY` delas,
porque cada uma trata do lugar de uma linha entre as vizinhas. Também são as que você mais vai usar,
então vale aprender direito as pequenas diferenças.

## Três jeitos de numerar linhas

```sql
SELECT name, score,
       row_number() OVER (ORDER BY score DESC) AS n,
       rank()       OVER (ORDER BY score DESC) AS r,
       dense_rank() OVER (ORDER BY score DESC) AS d
FROM   players;
```

```
name    score   n   r   d
Ana      90     1   1   1
Bruno    85     2   2   2
Célia    85     3   2   2
Dario    70     4   4   3
```

- **`row_number()`** numera toda linha, 1, 2, 3, sem empate — Bruno e Célia ficam com 2 e 3, e qual
  deles fica com qual é arbitrário sem um critério de desempate no `ORDER BY`.
- **`rank()`** dá o mesmo número aos empatados e depois pula: 1, 2, 2, **4**. É como o esporte
  classifica, e é o que alguém quer dizer com "segundo lugar empatado".
- **`dense_rank()`** dá o mesmo número aos empatados e não pula: 1, 2, 2, **3**.

Escolha pelo que você está fazendo. Exibir um ranking: `rank()`. Pegar exatamente três linhas:
`row_number()`, porque `rank()` pode devolver quatro linhas para "os três primeiros" e o seu layout
não vai esperar por isso.

As três ignoram a moldura por completo — a cláusula de moldura não muda nada para elas, então
escrever uma é ruído.

## Os N primeiros de cada grupo

A pergunta que a aula 4 não conseguiu responder, e que a aula 5 respondeu com uma auto-junção e uma
subconsulta correlacionada. Eis ela feita direito:

```sql
SELECT * FROM (
    SELECT o.*,
           row_number() OVER (PARTITION BY customer_id ORDER BY placed_at DESC) AS n
    FROM   orders o
) t
WHERE t.n <= 3;
```

Os três pedidos mais recentes de cada cliente. Troque `3` por `1` e é "o último pedido por cliente",
que é o formato mais comum desta aula inteira — todo painel que mostra um estado atual sobre uma
tabela de eventos é esta consulta.

O PostgreSQL tem uma grafia mais curta para o caso `n = 1`, o `DISTINCT ON`, que a aula 4 mencionou e
para o qual prometeu uma alternativa portável. É esta. `DISTINCT ON` é mais conciso onde você o tem;
a versão com janela funciona em todo lugar e se estende para três sem ser reescrita.

O envelope não é opcional, pela razão que a última seção deu: você não pode filtrar por uma função
de janela no `WHERE`, porque ela ainda não rodou.

## Remover duplicatas, que é a mesma consulta

Uma vez que você consegue numerar linhas dentro de um grupo, tirar duplicatas é uma condição:

```sql
DELETE FROM contacts
WHERE  id IN (
    SELECT id FROM (
        SELECT id, row_number() OVER (PARTITION BY lower(email) ORDER BY created_at) AS n
        FROM   contacts
    ) t
    WHERE t.n > 1
);
```

Particione pelo que deveria ter sido único, ordene por qual você quer manter, apague o resto. Rode o
`SELECT` primeiro e olhe para ele — isto é um `DELETE`, e as transações da aula 8 são a rede de
proteção que você vai querer em volta.

Depois, acrescente a restrição de unicidade que a aula 3 descreveu, ou você vai rodar isso de novo
em seis meses.

## A linha de antes e a de depois

`lag()` alcança para trás, `lead()` para a frente:

```sql
SELECT month, revenue,
       lag(revenue)  OVER (ORDER BY month) AS previous,
       revenue - lag(revenue) OVER (ORDER BY month) AS change
FROM   monthly;
```

Variação mês a mês, sem juntar a tabela com ela mesma em `month - 1` — o que quebra num mês sem
linhas, onde o `lag` simplesmente pega a linha anterior que existe.

A primeira linha não tem nada antes dela, então o `lag` é nulo ali e `change` também. Forneça um
padrão se preferir que não seja:

```sql
lag(revenue, 1, 0) OVER (ORDER BY month)    -- deslocamento 1, padrão 0 na borda
```

O mesmo par responde "quanto tempo entre estes eventos", que de outro jeito é desajeitado:

```sql
SELECT user_id, at,
       at - lag(at) OVER (PARTITION BY user_id ORDER BY at) AS since_previous
FROM   events;
```

E o `lead` é como você encontra lacunas: uma linha cujo `lead(at)` esteja a mais de uma hora é o
último evento de uma sessão.

## `first_value`, `last_value`, e a armadilha da segunda

```sql
first_value(total) OVER (PARTITION BY customer_id ORDER BY placed_at)   -- o primeiro pedido dele
last_value (total) OVER (PARTITION BY customer_id ORDER BY placed_at)   -- NÃO o último
```

`last_value` devolve o total da própria linha atual, todas as vezes. É a moldura padrão de novo: com
um `ORDER BY` a moldura termina na linha atual, então a última linha que ela consegue ver **é** a
linha atual.

Duas correções, e a segunda é a que se deve preferir:

```sql
last_value(total) OVER (PARTITION BY customer_id ORDER BY placed_at
                        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)

first_value(total) OVER (PARTITION BY customer_id ORDER BY placed_at DESC)
```

A segunda diz o que quer dizer sem cláusula de moldura, e é mais difícil de errar depois.

## `ntile`, para baldes

```sql
ntile(4) OVER (ORDER BY spent DESC) AS quartile
```

Divide as linhas em quatro grupos do tamanho mais parecido que conseguir, numerados de 1 a 4. É como
você obtém quartis ou decis sem calcular fronteira nenhuma. Seja claro sobre o que ele faz: divide
por **contagem de linhas**, não por valor, então a fronteira entre o quartil 1 e o 2 cai onde as
contagens mandarem — dois clientes que gastaram quase o mesmo podem cair em lados opostos dela.

## O que elas substituem

Toda função daqui tem uma versão pré-janela que ainda aparece em código antigo: uma auto-junção à
mesma tabela em "a linha anterior", uma subconsulta correlacionada por coluna, uma segunda consulta e
um laço na aplicação. Essas versões são mais lentas, porque leem a tabela mais de uma vez, e são mais
longas. Quando você encontrar uma, a reescrita costuma ser uma única função de janela — e o jeito de
reconhecer a oportunidade é a expressão no requisito: *anterior, próximo, acumulado, ranking, N por
grupo, comparado com, desde o último.* Cada uma delas está nesta seção.
