---
title: O que muda quando você escreve SQL para Oracle
version: 1
---

Tudo das aulas 4 a 7 funciona. As diferenças são específicas e são do tipo que se encontra uma vez,
e três delas mudam o que uma consulta *significa* em vez de como ela é escrita.

**Toda afirmação desta seção é comportamento documentado do Oracle, descrito e não capturado**: não
há uma instância de Oracle por trás deste curso para rodar isso, e o resto desta aula diz isso onde
de outro modo mostraria saída.

## As três que mudam o significado

**Uma string vazia é NULL.** Esta é a maior da linguagem e não tem equivalente em nenhum outro
lugar deste curso.

```sql
INSERT INTO customers (name, email, city) VALUES ('Ana', 'ana@example.com', '');
```

No PostgreSQL, no MySQL e no SQLite isso guarda uma cidade vazia, e `city IS NULL` é falso para
ela. No Oracle a string vazia **é** nula, então a linha não tem cidade nenhuma, `city IS NULL` é
verdadeiro, e uma restrição `NOT NULL` na coluna teria recusado o insert.

Tudo que a aula 4 disse sobre `NULL` então se aplica onde você não esperava: `WHERE city = ''` não
casa com nada, nunca, porque é `WHERE city = NULL`. Código levado para o Oracle que distingue "em
branco" de "não informado" deixa de conseguir fazer isso.

**Um `DATE` tem hora dentro.** O `DATE` do Oracle é uma data *e* uma hora até o segundo — é mais
próximo do `timestamp` dos outros motores que do `date` deles. Então isto é um bug no Oracle e não
nos outros:

```sql
SELECT count(*) FROM orders WHERE ordered_on = DATE '2026-03-19';
```

Ele casa apenas com as linhas cuja parte de hora é exatamente meia-noite. A correção é a que a aula
9 já defendia, uma faixa em vez de uma função sobre a coluna:

```sql
SELECT count(*) FROM orders
 WHERE ordered_on >= DATE '2026-03-19' AND ordered_on < DATE '2026-03-20';
```

`TRUNC(ordered_on) = DATE '2026-03-19'` também funciona e derruba um índice comum sobre a coluna,
exatamente pelo motivo que a aula 9 deu.

**Há um tipo numérico, e ele é exato.** `NUMBER` é um decimal de precisão variável, e
`NUMBER(10,2)` é o que uma coluna de dinheiro deve ser, como a aula 3 pediu. `INTEGER` é aceito e é
um `NUMBER(38)` por baixo. `BINARY_FLOAT` e `BINARY_DOUBLE` existem para quando você de fato quer
ponto flutuante, o que para dinheiro você não quer. Esta é uma surpresa agradável em vez de uma
armadilha: o padrão aqui é o cuidadoso.

## As consultas

| | Oracle | PostgreSQL |
|---|---|---|
| uma consulta sem tabela | `SELECT 1 FROM dual` | `SELECT 1` |
| as primeiras n linhas | `FETCH FIRST n ROWS ONLY`, ou `ROWNUM <= n` em versões antigas | `LIMIT n` |
| chave autonumerada | `GENERATED AS IDENTITY`, ou uma sequência e `seq.NEXTVAL` | `GENERATED ALWAYS AS IDENTITY` |
| concatenar | `\|\|` ou `concat()` | o mesmo |
| hora atual | `SYSDATE`, `SYSTIMESTAMP` | `now()`, `current_timestamp` |
| substring | `SUBSTR` | `substring` ou `substr` |
| substituir nulo | `NVL(a, b)`, `COALESCE(a, b)` | `COALESCE(a, b)` |
| inserir ou atualizar | `MERGE` | `ON CONFLICT … DO UPDATE`, e `MERGE` desde a 15 |
| descrever uma tabela | `DESC employees` no SQL\*Plus | `\d employees` no psql |
| o plano | `EXPLAIN PLAN FOR …` e depois `SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY)` | `EXPLAIN` |

**O `DUAL` é o que parece piada e não é.** O `SELECT` do Oracle sempre exigiu um `FROM`, então há
uma tabela de uma linha e uma coluna em todo banco cujo propósito inteiro é ser selecionada quando
você não tem de onde selecionar. `SELECT SYSDATE FROM dual` é como se pergunta a hora. A linha 23ai
relaxa a exigência, e o `DUAL` está em todo sistema escrito antes dela, que é todo sistema que você
vai encontrar.

**O `ROWNUM` é o que causa bugs.** Ele é atribuído conforme as linhas são produzidas, *antes* da
ordenação, então isto não devolve os três pedidos mais recentes:

```sql
SELECT * FROM orders WHERE ROWNUM <= 3 ORDER BY ordered_on DESC;
```

Ele pega as três primeiras linhas que a consulta por acaso produziu e então ordena essas três. A
grafia antiga correta envolve a consulta ordenada e filtra do lado de fora, e na 12c em diante o
`FETCH FIRST 3 ROWS ONLY` faz a coisa certa direto. Prefira-o em qualquer versão que o tenha.

## O plano, para o qual a aula 10 te preparou

O Oracle tem toda a maquinaria da aula 10 com outros nomes. `EXPLAIN PLAN FOR` uma instrução
escreve o plano numa tabela, e o `DBMS_XPLAN.DISPLAY` formata. Para o plano de uma instrução que de
fato rodou, com as contagens reais ao lado das estimativas, a chamada é o
`DBMS_XPLAN.DISPLAY_CURSOR` com o formato `ALLSTATS LAST` — e a instrução precisa ter sido rodada
com a dica `GATHER_PLAN_STATISTICS`.

Descrita e não mostrada, a saída é uma tabela de linhas de plano. Cada uma traz um id, um pai, uma
operação como `TABLE ACCESS FULL` ou `INDEX RANGE SCAN`, o objeto que ela toca, e as linhas e o
custo estimados. Onde as estatísticas foram coletadas, as contagens estimada e real ficam em
colunas vizinhas. A indentação é a árvore, exatamente como a aula 10 descreveu para o PostgreSQL.

**Então o método atravessa sem mudança**, e os dois hábitos da aula 10 são os dois hábitos aqui:
ponha a contagem estimada e a real lado a lado em cada linha, e trate a primeira linha em que elas
divergem feio como o lugar onde a consulta deu errado. Só os nomes mudaram: `TABLE ACCESS FULL` é
uma varredura sequencial, `INDEX RANGE SCAN` é uma varredura por índice, e `NESTED LOOPS`,
`HASH JOIN` e `SORT MERGE JOIN` são as três junções que a aula 10 já nomeou.
