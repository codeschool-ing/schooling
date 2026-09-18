---
title: Views materializadas, que guardam a resposta
version: 1
---

```sql
CREATE MATERIALIZED VIEW monthly_revenue AS
SELECT   date_trunc('month', ordered_on) AS month,
         sum(total)                     AS revenue,
         count(*)                       AS orders
FROM     orders
GROUP BY 1;
```

Uma palavra diferente da seção anterior e um objeto completamente diferente. Esta aqui **roda a
consulta agora e guarda as linhas**. Ler dela é ler dado guardado, na velocidade de uma tabela
pequena, por mais que a consulta de baixo tenha demorado.

Que é a graça: um relatório que agrega dez milhões de pedidos vira uma tabela com sessenta linhas.
Você pode indexá-la, juntá-la, e consultá-la mil vezes por hora.

## E ela está desatualizada desde o instante em que existe

Nada a atualiza. Um pedido feito um segundo depois de você criá-la não está lá, e não vai estar até
alguém dizer:

```sql
REFRESH MATERIALIZED VIEW monthly_revenue;
```

que roda a consulta inteira de novo e substitui o conteúdo. Essa instrução toma um bloqueio
exclusivo — **ninguém consegue ler a view enquanto ela atualiza**, o que numa view grande são
minutos de um painel mostrando nada.

```sql
CREATE UNIQUE INDEX ON monthly_revenue (month);
REFRESH MATERIALIZED VIEW CONCURRENTLY monthly_revenue;
```

`CONCURRENTLY` monta o conteúdo novo ao lado e troca as linhas, então quem lê continua funcionando o
tempo todo. Ele exige um índice único — é assim que ele descobre quais linhas mudaram — e é mais
lento no total. Em qualquer coisa que uma pessoa olhe, é o que você quer.

Você também pode criar uma vazia e enchê-la depois, que é como uma implantação evita rodar uma
consulta de vinte minutos enquanto segura uma migração aberta:

```sql
CREATE MATERIALIZED VIEW monthly_revenue AS SELECT … WITH NO DATA;
```

Até ser atualizada, ler dela é erro em vez de resultado vazio — uma pequena gentileza, já que uma
resposta vazia seria indistinguível de um mês parado.

## É a cópia da aula 2, então faça a pergunta da aula 2

A aula 2 disse que uma cópia guardada é um bug com agenda, a menos que algo a mantenha verdadeira.
Uma view materializada é exatamente esse tipo de cópia, e o mecanismo é a atualização, então as
perguntas são:

1. **Quão defasada isto pode estar?** Em minutos, e respondido por quem lê, não por você.
2. **O que atualiza isto?** Um cron, uma tarefa agendada, o fim de uma importação. Dê nome à coisa.
3. **O que acontece quando a atualização falha?** Servir em silêncio a receita da terça passada como
   se fosse a de hoje é pior que um erro, porque ninguém consegue ver.

A terceira é onde isso dá errado na prática. Um número confiantemente errado ganha de nenhum número
pelo tempo que ninguém conferir. Se a view carregar uma coluna `refreshed_at`, todo relatório pode
imprimi-la, e isso custa uma linha:

```sql
SELECT …, now() AS refreshed_at FROM orders GROUP BY 1;
```

## Onde você não pode ter uma

O PostgreSQL tem views materializadas. A Oracle tem há décadas, com um reescritor de consultas que
usa uma delas automaticamente para uma consulta que você escreveu contra as tabelas de base — que é
um recurso genuinamente diferente e vale conhecer antes que alguém lhe diga que a Oracle não tem
nada a ensinar.

**MySQL, MariaDB e SQLite não têm nenhuma.** Ali você constrói a mesma coisa à mão: uma tabela de
verdade, um `INSERT … SELECT` que a preenche, e uma tarefa agendada que a esvazia e reenche — ou um
`INSERT … ON DUPLICATE KEY UPDATE` que atualiza só os meses que mudaram.

Essa versão à mão tem uma vantagem que vale notar mesmo onde views materializadas existem. Um
`REFRESH` recalcula **tudo**, inclusive quatro anos de meses que não tinham como mudar. Uma tabela
de resumo que você mantém pode atualizar só ontem, que é cem vezes menos trabalho — e numa tabela
grande o bastante é a diferença entre uma tarefa noturna que termina e uma que não.

## As quatro ferramentas, lado a lado

A aula inteira, como a pergunta que cada uma responde:

| | guarda | sempre atual | serve para |
|---|---|---|---|
| **tabela derivada** | não | sim | um passo de uma consulta |
| **CTE (`WITH`)** | não | sim | nomear os passos para uma pessoa conseguir ler |
| **view** | não | sim | uma definição, compartilhada, escrita uma vez |
| **view materializada** | **sim** | **não** | uma resposta cara que pode estar um pouco velha |

As três primeiras não custam nada e não mudam dado; escolha entre elas por legibilidade. A quarta é
uma decisão de outra natureza, porque troca correção-neste-instante por velocidade, e essa troca é
de alguém aprovar, não sua para fazer em silêncio.

E uma regra que sobrevive às quatro: **se uma consulta está lenta, descubra por quê antes de
guardá-la em cache.** Uma view materializada sobre uma consulta a que faltava um índice é uma tarefa
noturna, uma janela de defasagem e um novo modo de falha, comprados em troca de um problema que um
`CREATE INDEX` teria removido. Índices são a aula 9 e descobrir por quê é a aula 10 — nessa ordem, e
as duas antes da ferramenta desta seção.
