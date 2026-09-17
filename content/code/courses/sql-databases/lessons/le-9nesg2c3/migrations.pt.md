---
title: O esquema como uma sequência de mudanças
version: 1
---

A aula 3 mudou tabelas num prompt. Um sistema real não pode: o esquema tem que ser o mesmo na
máquina de cada pessoa que desenvolve, em homologação e em produção, e tem que mudar em sintonia
com o código que o usa. Uma **migração** é uma mudança no esquema, escrita como arquivo,
versionada com o código, e aplicada exatamente uma vez a cada banco.

```
migrations/
    0001_create_customers.sql
    0002_create_orders.sql
    0003_add_orders_status.sql
    0004_index_orders_customer_id.sql
```

Toda ferramenta de migração — a do Django, a do Rails, Flyway, Liquibase, Alembic, Prisma Migrate,
`golang-migrate` — é esta pasta mais uma tabela. A tabela mora no próprio banco e registra quais
migrações rodaram:

```
version | applied_at
--------+---------------------
   0001 | 2026-03-01 10:00:00
   0002 | 2026-03-01 10:00:00
   0003 | 2026-04-12 09:30:00
```

Rode a ferramenta e ela aplica todo arquivo que a tabela ainda não lista, em ordem, e registra
cada um. Rode de novo e ela não faz nada. É esse o mecanismo inteiro, e todo o resto é
consequência dele.

## Cada uma roda uma vez, então cada uma tem que estar certa

A aula 3 disse que `CREATE TABLE IF NOT EXISTS` esconde o fato de um script ter rodado duas vezes.
Com migrações um script não pode rodar duas vezes, então o `IF NOT EXISTS` não tem nada a esconder
e só remove uma conferência. Uma migração que encontra sua tabela já lá foi rodada contra um
banco que não está no estado que a versão dele diz, e isso deveria falhar alto em vez de passar.

O que leva à regra que todo time aprende uma vez quebrando-a:

> **Uma migração que foi aplicada em qualquer lugar nunca é editada.** Corrija com a próxima.

Edite a `0003` depois de produção tê-la rodado e agora há dois bancos que dizem que a `0003` foi
aplicada e têm esquemas diferentes. Nada detecta isso, e a diferença aparece como uma consulta que
funciona num lugar e não no outro. Uma migração nova, `0005`, roda em todo lugar em que não rodou,
que é a garantia que a tabela dá e a edição tira.

## Up, down, e só para a frente

A maioria das ferramentas deixa uma migração carregar o inverso — `up` acrescenta a coluna, `down`
a derruba — para que um deploy ruim possa ser revertido. Vale escrever onde é barato, e ser honesto
sobre onde não é: `down` de uma coluna apagada não traz o dado de volta, e `down` de uma migração
que rodou há um mês é uma migração que ninguém testou contra as linhas que chegaram desde então.
Na prática produção anda **para a frente**: a correção de uma migração ruim é outra migração, e
`down` é para a máquina de quem desenvolve.

## Uma migração é uma transação, exceto quando não pode ser

A maioria das ferramentas roda cada migração dentro de uma transação, para que uma migração que
falha no meio deixe o esquema como estava. O PostgreSQL consegue fazer isso com DDL e o MySQL em
geral não, que é uma das diferenças que a aula 12 percorre — no MySQL uma migração que falhou está
aplicada pela metade e tem que ser consertada à mão.

E a construção de índice da aula 9 é a exceção nos dois:

```
shop=# BEGIN;
BEGIN

shop=*# CREATE INDEX CONCURRENTLY ON orders (total);
ERROR:  CREATE INDEX CONCURRENTLY cannot run inside a transaction block
```

`CONCURRENTLY` se recusa a rodar dentro de uma transação, então a migração que constrói um índice
numa tabela viva tem que ser marcada como uma que a ferramenta não deve envolver. Toda ferramenta
tem um jeito de dizer isso — o `atomic = False` do Django, o `disable_ddl_transaction!` do Rails,
o bloco de autocommit do Alembic — e uma migração que não diz falha na hora do deploy com a linha
acima, que é o desfecho bom. O ruim é uma ferramenta que deixa cair o `CONCURRENTLY` em silêncio e
pega o bloqueio.

## As perigosas, e a ferramenta que o impede

A lista da aula 3 — acrescentar uma coluna `NOT NULL` a uma tabela grande, renomear, mudar um
tipo, acrescentar uma restrição que varre — é onde uma migração pega um bloqueio e o segura por
minutos com a fila da aula 3 se formando atrás. As ferramentas aprenderam isso: o
`strong_migrations` para Rails, o `squawk` para qualquer coisa que emita SQL, as verificações do
Django, recusam ou avisam exatamente nessas operações e sugerem a forma segura.

A forma segura de uma renomeação é a que a ferramenta não consegue escrever por você, porque ela
atravessa três deploys:

1. **Expandir.** Acrescente a coluna nova. Escreva nas duas colunas a partir do código. Preencha
   as linhas antigas.
2. **Migrar os leitores.** Mude o código para ler a coluna nova.
3. **Contrair.** Pare de escrever na antiga; derrube-a.

Três migrações, três deploys, e em momento nenhum uma versão do código em execução nomeia uma
coluna que não existe. Um único `ALTER TABLE … RENAME` é uma migração e um deploy, e entre o
momento em que a coluna é renomeada e o momento em que o código novo está rodando, toda requisição
falha. Que é o ponto da aula 3 de que uma mudança numa tabela viva é uma mudança no código que
está lendo dela agora.

## Migrações de esquema e migrações de dados

Uma migração que muda a forma — uma coluna, um índice, uma restrição — é um tipo. Uma que muda as
linhas — preencher a coluna nova, dividir um nome em dois, corrigir um status que foi escrito
errado — é outro, e misturá-los é o erro.

Uma migração de dados numa tabela grande é um `UPDATE` sobre milhões de linhas numa transação só,
que a aula 8 precificou: bloqueios mantidos pela duração, e toda versão de linha guardada até o
fim. Ela é escrita em lotes, é escrita para poder rodar de novo, e é escrita na linguagem da
aplicação em vez de na ferramenta de migração, porque precisa de um laço e de tratamento de erro e
de um jeito de retomar. Mantenha-a fora da migração de esquema que um deploy roda de forma
síncrona, ou o deploy é o que fica esperando os milhões de linhas.

## O que a ferramenta não sabe

Ela aplica arquivos em ordem e registra que aplicou. Não sabe se o arquivo é seguro, se o `down`
funciona, ou se uma coluna que está prestes a derrubar ainda é lida pela versão do código que está
rodando durante o deploy. Essas são as perguntas da aula 3, e o aviso da ferramenta é o momento de
respondê-las em vez do momento de acrescentar a opção que o silencia.
