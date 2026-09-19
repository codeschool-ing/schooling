---
title: Os três lugares em que uma subconsulta cabe
version: 1
---

Uma subconsulta é um `SELECT` escrito dentro de outra instrução, entre parênteses. Há três lugares
em que uma pode ir, elas se comportam de modo diferente, e saber qual você está olhando é a maior
parte de ler a consulta de outra pessoa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"O esqueleto de um comando SELECT escrito à esquerda: SELECT, FROM e WHERE. Ao lado de cada palavra-chave, um encaixe aceso lendo abre parêntese SELECT reticências fecha parêntese, com uma seta levando à direita para o que aquele encaixe exige. Na lista do SELECT é um valor: exatamente uma coluna e exatamente uma linha. No FROM é uma tabela: precisa de um nome e se comporta como qualquer tabela. No WHERE é um conjunto: uma coluna e qualquer número de linhas.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Um comando, três encaixes. Em qual deles a subconsulta está decide o que ela tem de devolver e com que frequência roda.</text><text x=\"20\" y=\"64\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">SELECT</text><text x=\"96\" y=\"64\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">c.name,</text><rect x=\"170\" y=\"50\" width=\"132\" height=\"28\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"236\" y=\"64\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--phosphor)\">( SELECT … )</text><path d=\"M302 64 L342 64\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\" fill=\"none\"></path><path d=\"M342 64 L335 60 L335 68 Z\" fill=\"var(--phosphor)\"></path><text x=\"352\" y=\"54\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">um valor</text><text x=\"352\" y=\"72\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">exatamente uma coluna, exatamente uma linha</text><text x=\"20\" y=\"104\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">FROM</text><text x=\"96\" y=\"104\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">customers c</text><rect x=\"202\" y=\"90\" width=\"132\" height=\"28\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"268\" y=\"104\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--phosphor)\">( SELECT … )</text><path d=\"M334 104 L374 104\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\" fill=\"none\"></path><path d=\"M374 104 L367 100 L367 108 Z\" fill=\"var(--phosphor)\"></path><text x=\"384\" y=\"94\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">uma tabela</text><text x=\"384\" y=\"112\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">precisa de um nome, e se comporta como tabela</text><text x=\"20\" y=\"144\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">WHERE</text><text x=\"96\" y=\"144\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">c.active</text><rect x=\"178\" y=\"130\" width=\"132\" height=\"28\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"244\" y=\"144\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--phosphor)\">( SELECT … )</text><path d=\"M310 144 L350 144\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\" fill=\"none\"></path><path d=\"M350 144 L343 140 L343 148 Z\" fill=\"var(--phosphor)\"></path><text x=\"360\" y=\"134\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">um conjunto</text><text x=\"360\" y=\"152\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma coluna, qualquer número de linhas</text><text x=\"14\" y=\"178\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Saber qual dos três você está lendo é a maior parte de ler a consulta de outra pessoa.</text></svg>", "caption": "Os três são a mesma sintaxe em três posições, e a posição é o que muda as regras. Todo o resto desta aula é consequência de em qual encaixe você está."}
```

```sql
-- 1 · na lista do SELECT, como um valor
SELECT c.name, (SELECT count(*) FROM orders o WHERE o.customer_id = c.id) AS orders
FROM   customers c;

-- 2 · no FROM, como uma tabela
SELECT t.customer_id, t.orders
FROM   (SELECT customer_id, count(*) AS orders FROM orders GROUP BY customer_id) t
WHERE  t.orders > 3;

-- 3 · no WHERE, como parte de uma condição
SELECT * FROM products
WHERE  category_id IN (SELECT id FROM categories WHERE archived);
```

Você já escreveu a segunda delas quatro vezes neste curso, nas aulas 5 e 6, sem que ela recebesse um
nome. Este é o nome.

## Uma subconsulta escalar devolve exatamente um valor

A primeira forma é a mais rigorosa. Onde se espera um único valor, uma subconsulta tem que produzir
uma linha e uma coluna, e o banco confere:

```sql
SELECT name, (SELECT price FROM products WHERE id = 7) FROM customers;
```

Se a consulta de dentro casar duas linhas:

```
ERROR:  more than one row returned by a subquery used as an expression
```

que é um bom erro, porque está lhe dizendo que uma suposição feita em silêncio estava errada. Se ela
casar **nenhuma** linha, não há erro nenhum — o valor é `NULL`, caladamente, e a seção inteira da
aula 4 sobre desconhecidos se aplica a ele.

Essa assimetria vale guardar. Linhas demais é barulhento; linha nenhuma é silencioso.

## Uma subconsulta no `FROM` precisa de nome

```sql
SELECT * FROM (SELECT customer_id, count(*) AS orders FROM orders GROUP BY customer_id) t;
```

O `t` no fim não é enfeite. PostgreSQL e MySQL recusam uma tabela derivada sem apelido, porque toda
coluna dela tem que ser alcançável como `algo.coluna`. O SQLite é relaxado quanto a isso; escreva o
apelido de todo jeito, para a consulta querer dizer o mesmo em todo lugar.

A mesma regra vale para as colunas de dentro: `count(*)` sem `AS` lhe dá uma coluna cujo nome fica a
cargo do banco, e você não consegue se referir a ela de fora com segurança. Nomeie tudo o que uma
tabela derivada produz.

## Uma subconsulta no `WHERE` devolve um conjunto

```sql
WHERE category_id IN (SELECT id FROM categories WHERE archived)
```

Aqui exige-se uma coluna e qualquer número de linhas serve — a graça é justamente haver várias.
`IN`, `NOT IN`, `ANY` e `ALL` todos têm este formato, e `EXISTS` recebe uma subconsulta cujas
colunas ninguém olha. A próxima seção trata de qual deles usar, e daquele que não devolve nada
quando um nulo entra.

## Onde uma subconsulta não cabe

Dois lugares, e os dois surpreendem.

**No `GROUP BY` não**, em banco nenhum. Se você se pegar querendo, o que quer é uma tabela derivada
com a expressão calculada dentro, e o agrupamento por fora.

**No `LIMIT` não, com utilidade**, na maioria dos bancos. `LIMIT (SELECT n FROM settings)` é
rejeitado pelo MySQL e aceito pelo PostgreSQL, que é exatamente o tipo de diferença que torna uma
consulta não portável sem benefício nenhum.

## Elas aninham, e é esse o problema

Nada impede uma subconsulta de conter uma subconsulta que contém outra. A sintaxe está certa e o
banco não se incomoda:

```sql
SELECT * FROM (
    SELECT * FROM (
        SELECT customer_id, count(*) AS n FROM orders GROUP BY customer_id
    ) a WHERE a.n > 3
) b JOIN customers c ON c.id = b.customer_id;
```

Três níveis, e para entender você lê de dentro para fora enquanto a página lê de fora para dentro.
No quarto nível as pessoas param de ler e começam a confiar, que é onde moram as consultas erradas.

`WITH` é a resposta para isso, e é a mesma consulta com os passos nomeados e deitados. Ele tem a
própria seção logo adiante, porque a legibilidade é o recurso — mas antes, as duas formas de
subconsulta no `WHERE` que não são intercambiáveis, e a diferença entre elas custa correção, não
clareza.
