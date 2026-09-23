---
title: Você criou o índice e nada mudou
version: 2
---

Esta é a seção que mais poupa tempo, porque todo item da lista parece um bug do banco e não é. O
índice existe, a consulta nomeia a coluna, e o plano lê a tabela inteira assim mesmo.

São cerca de sete razões. Seis são coisas que você fez, e a sétima é o planejador estar certo.

## Uma função em volta da coluna

```sql
WHERE lower(email) = 'ana@example.com'      -- index on (email): unused
WHERE date(created_at) = DATE '2026-03-01'  -- index on (created_at): unused
WHERE coalesce(price, 0) > 100              -- index on (price): unused
```

O índice guarda `email`, ordenado. Ele não guarda `lower(email)`, e o banco não tem como descobrir
onde `lower(email)` ficaria na ordem sem calcular para toda linha — que é a varredura que você
estava tentando evitar.

A aula 4 alertou sobre o terceiro e prometeu o mecanismo aqui. É este: **envolva uma coluna em
qualquer coisa e a cópia ordenada daquela coluna deixa de se aplicar.**

Duas correções, e prefira a segunda onde ela existir:

```sql
CREATE INDEX ON customers (lower(email));           -- index the expression instead

WHERE created_at >= DATE '2026-03-01'               -- rewrite as a range on the bare column
  AND created_at <  DATE '2026-03-02';
```

A reescrita é melhor quando está disponível, porque usa o índice que você já tem e continua correta
entre fusos horários, o que `date(created_at)` caladamente não faz.

## `LIKE` com curinga no começo

```sql
WHERE name LIKE 'ana%'     -- fast: a prefix is a range in a sorted list
WHERE name LIKE '%ana'     -- a scan, and no ordinary index can help
WHERE name LIKE '%ana%'    -- the same
```

A cópia está ordenada a partir do começo da string. Tudo que começa com `ana` fica junto; tudo que
*termina* com isso está espalhado de A a Z. Não existe arranjo de árvore B que conserte, então a
resposta é outro tipo de índice — um índice de trigramas, que a seção `the-other-types` cobre.

## Um tipo que não bate

```sql
WHERE phone = 5551234      -- phone is text
```

O banco precisa fazer os tipos concordarem, e qual lado ele converte decide tudo. Converta o literal
e o índice funciona. Converta a **coluna** — que é o que o MySQL faz ao comparar uma coluna de texto
com um número — e toda linha precisa ser convertida para ser comparada, então o índice sai e a
varredura entra. É um par de aspas faltando e é invisível numa revisão de código.

O mesmo acontece numa junção em que uma chave estrangeira é `integer` de um lado e `bigint` ou `text`
do outro, que é um erro de esquema que se esconde como mistério de desempenho por anos.

## A coluna dentro de uma conta

```sql
WHERE price * 1.1 > 100        -- unused
WHERE price > 100 / 1.1        -- the same question, and the index applies
```

Mesma regra da função: os valores ordenados são `price`, e não `price * 1.1`. Mova a aritmética para
o outro lado da comparação e o índice volta. **Mantenha a coluna crua do lado dela do operador** é o
hábito que cobre este item e o primeiro juntos.

## `OR` entre colunas diferentes

```sql
WHERE email = 'a@b.c' OR phone = '555'
```

Dois índices, duas condições, e nenhuma sozinha estreita a resposta. O PostgreSQL consegue combinar
os dois com um mapa de bits, o que funciona; outros bancos costumam desistir e varrer. Onde importa,
duas consultas unidas por `UNION` vão cada uma usar o índice delas, e isso lê pior e roda melhor.

`NOT` e `<>` são o caso extremo da mesma coisa: *"tudo menos isto"* em geral casa a maior parte da
tabela, e a maior parte da tabela é uma varredura.

## Os valores não são seletivos o bastante

```sql
WHERE active        -- 600 000 of a million rows
```

Coberto na seção anterior, e está nesta lista porque é o item com que as pessoas discutem. O índice
está ótimo. Usá-lo significaria seguir seiscentos mil ponteiros para páginas espalhadas, e ler a
tabela direto é mais rápido. **O planejador não está ignorando o seu índice; ele precificou os dois
planos e escolheu um.**

O índice parcial é a ferramenta para a outra metade disso — os 3% de linhas em que `status =
'pending'` — e tem seção própria.

## As estatísticas estão velhas

O planejador não conta linhas; ele as estima a partir de estatísticas coletadas por um processo de
fundo. Se essas estatísticas dizem que uma coluna tem três valores distintos e ela agora tem três
milhões, a estimativa está errada e o plano segue a estimativa.

```sql
ANALYZE customers;      -- recollect them now
```

É a razão por trás de *"ontem estava rápido"* depois de uma importação em massa: o dado mudou de
formato mais rápido que as estatísticas. Também é a primeira coisa a conferir antes de acreditar em
qualquer outra desta lista.

## Ver qual delas é

Todo item acima é visível em vez de adivinhável:

```sql
EXPLAIN SELECT … ;
```

Ele imprime o plano, diz `Seq Scan` ou `Index Scan`, e diz quantas linhas esperava. A aula 10 trata
inteiramente de ler essa saída, e é a diferença entre esta lista ser um conjunto de regras a
decorar e um conjunto de coisas que você confere em dez segundos.
