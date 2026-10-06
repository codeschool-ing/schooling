---
title: É um fato ou uma dimensão?
version: 1
---

A maioria das tabelas se classifica sozinha: uma venda é um fato, um livro é uma dimensão. Algumas
não, e a escolha errada é cara de desfazer, porque todo relatório é escrito em cima dela. Três testes
resolvem a maioria das discussões.

**Acontece, ou descreve?** Um evento tem data e acontece de novo amanhã; uma descrição vale para algo
por um tempo. Uma venda acontece. A cidade de uma loja descreve a loja.

**Você somaria, ou agruparia por ele?** O preço cobrado num item é uma medida: é somado, na
granularidade do item. O preço de tabela de um livro é um atributo do livro: serve para filtrar e
agrupar ("livros abaixo de R$ 50"), e somá-lo entre livros não significa nada.

**Cresce com a atividade ou com o número de coisas?** Uma tabela fato fica mais comprida a cada dia em
que o negócio funciona. Uma dimensão só cresce quando há uma coisa nova para descrever.

## A que parece um fato

O banco da rede tem uma tabela com um timestamp em cada linha, e ela cresce todo dia:

```
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT field, count(*) AS changes FROM staging.customer_changes GROUP BY ALL ORDER BY changes DESC"
┌─────────┬─────────┐
│  field  │ changes │
│ varchar │  int64  │
├─────────┼─────────┤
│ tier    │    7686 │
│ city    │    1624 │
│ email   │     825 │
│ state   │     622 │
│ name    │     508 │
└─────────┴─────────┘
```

`customer_changes` tem o formato de uma tabela de transação: um evento, uma data, uma linha a cada
vez. **Mas não é um processo de negócio que alguém mede.** Ninguém pede "mudanças de nível por mês"
num relatório. O que se pergunta é quanto um *patron* gasta, ou quanto se vendeu a clientes no Paraná
— e para responder qualquer das duas corretamente sobre o ano passado é preciso saber em que nível e
em que estado cada cliente estava **na hora de cada venda**.

Então essas 11.265 linhas são o histórico de uma dimensão, e não um fato. Elas vão para a dimensão de
clientes, como uma versão de cada cliente para cada período em que nada do que se acompanha mudou, e
a lição 5 constrói exatamente isso. Um warehouse que as carregasse como tabela fato responderia
"quantos clientes se mudaram", que ninguém perguntou, e ainda assim não responderia "onde moravam
quando compraram", que todo mundo pergunta.

**O teste que decide: o que as pessoas vão pôr no `WHERE` e no `GROUP BY`, e o que vão pôr dentro de
`sum()`?** O primeiro é dimensão. O segundo é fato.
