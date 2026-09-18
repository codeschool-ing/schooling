---
title: Montando uma, e lendo a de outra pessoa
version: 1
---

Tudo desta aula, como o jeito que você de fato trabalha e não como uma lista de cláusulas.

## Monte de dentro para fora, uma cláusula por vez

Ninguém escreve uma consulta correta de primeira, e tentar é como você acaba com uma que não devolve
nada e não te dá ideia de qual parte está errada.

**Comece pelas linhas.**

```sql
SELECT * FROM products LIMIT 10;
```

Você está conferindo que a tabela é o que você pensa, e o `LIMIT` é para um engano não custar nada.

**Acrescente uma condição e confira a contagem.**

```sql
SELECT count(*) FROM products WHERE category = 'kitchen';
```

`count(*)` em vez das linhas, porque um número te diz na hora se o filtro está fazendo algo. Zero
significa que o filtro está errado, ou que o dado não é o que você esperava, e de qualquer jeito você
descobriu com uma condição em vez de com seis.

**Acrescente a próxima, e veja o número se mover.**

```sql
SELECT count(*) FROM products WHERE category = 'kitchen' AND price > 20;
```

Se o número não mudar, aquela condição não faz nada. Se cair a zero, aquela condição é o problema. É
essa a técnica inteira de depuração, e funciona porque você acrescentou uma coisa.

**Depois as colunas, depois a ordem, depois o limite.**

```sql
SELECT name, price
FROM   products
WHERE  category = 'kitchen' AND price > 20
ORDER BY price DESC, id
LIMIT  20;
```

O `, id` é a regra da seção anterior, e acrescentá-lo no mesmo momento que o `LIMIT` é como você para
de esquecer.

## Conferindo uma resposta que você não verifica a olho

Uma consulta sobre mil linhas te dá um número que você não tem como saber se está certo. Três coisas
que pegam a maioria dos erros:

**Conte os dois lados de um filtro.** Se `category = 'kitchen'` dá 40 e `category <> 'kitchen'` dá
55, e a tabela tem 100 linhas, cinco linhas estão em nenhum dos dois — e são os nulos, da seção
`null-in-a-query`. A aritmética não fechar é o sinal.

**Peça os extremos.** `ORDER BY price DESC LIMIT 5` e `ORDER BY price LIMIT 5`. Se o produto mais
caro é €4.000.000 ou o mais barato é negativo, o filtro não é o problema e o dado tem algo que você
não sabia.

**Olhe uma linha que você consiga verificar à mão.** Um cliente, um pedido, uma fatura — algo que
você possa conferir contra outra fonte. Uma consulta errada em geral normalmente está errada numa
linha que você consegue ler.

## Lendo a de outra pessoa

Leia as cláusulas na ordem em que rodam, não na ordem em que estão escritas:

1. **`FROM`** — sobre o que é isto? Uma tabela, ou várias juntadas, que é a aula 5.
2. **`WHERE`** — quais linhas sobrevivem? É aqui que normalmente está a regra de negócio.
3. **`GROUP BY` / `HAVING`** — isto é sobre grupos e não sobre linhas? Aula 6.
4. **`SELECT`** — o que sai, e o que é calculado.
5. **`ORDER BY` / `LIMIT`** — existe um limite sem ordem total? Isso é bug, e é o primeiro a
   procurar.

E duas coisas de que desconfiar de imediato, as duas desta aula:

- **`DISTINCT`** — de onde vieram as duplicatas?
- **uma função em volta de uma coluna filtrada** — `WHERE lower(email) = …`,
  `WHERE extract(year FROM created_at) = …`. Funciona e não consegue usar índice.

## O que esta aula não cobriu

Nomeado, porque a regra da aula 2 sobre fronteiras vale para uma aula tanto quanto para um curso:
uma fronteira enunciada é legítima, e uma que é só ausência é um buraco.

- **Mais de uma tabela.** Tudo aqui lê uma tabela só. Aula 5.
- **Resumir.** Contagens, totais e médias por grupo. Aula 6.
- **Consultas dentro de consultas.** `EXISTS` apareceu duas vezes nesta aula como a resposta certa a
  algo, e é explicado na aula 7.
- **Mudar dados.** `INSERT`, `UPDATE`, `DELETE` — compartilham o `WHERE` com o `SELECT`, e a
  diferença é que um engano não se recupera rodando de novo. Aula 8, com transações, que é o lugar
  certo porque é o que torna um engano recuperável.
- **Por que uma consulta é lenta.** Aulas 9 e 10. Esta aula apontou três lugares em que o formato de
  uma condição decide se um índice pode ser usado; é todo o necessário até lá.

## As seis regras desta aula

1. **Roda `FROM`, `WHERE`, `SELECT`, `ORDER BY`, `LIMIT`** — que é por que um apelido funciona num
   lugar e não noutro.
2. **Nomeie as colunas**, não `*`, em qualquer coisa que não seja um terminal.
3. **Ponha parênteses em `AND` com `OR`.**
4. **Deixe a coluna pelada** de um lado da comparação.
5. **`LIMIT` precisa de um `ORDER BY` total** — termine na chave.
6. **`DISTINCT` é uma pergunta**, não uma resposta: de onde vieram as duplicatas?
