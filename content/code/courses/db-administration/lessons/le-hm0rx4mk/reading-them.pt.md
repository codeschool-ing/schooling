---
title: Lendo os padrões
version: 1
---

Os privilégios padrão são invisíveis no `\dp`, que mostra o que os objetos têm, não o que vão
receber. O psql os lista com **`\ddp`**:

```
shop=# \ddp
              Default access privileges
   Owner    | Schema | Type  |   Access privileges    
------------+--------+-------+------------------------
 shop_owner | public | table | reporting=r/shop_owner+
            |        |       | app=arwd/shop_owner
(1 row)
```

Uma linha por combinação de papel criador, esquema e tipo de objeto. A lista de acesso se lê como
qualquer outra, com o papel criador como grantor: as tabelas que o `shop_owner` criar no `public` vão
receber `r` para o `reporting` e `arwd` para o `app`. Uma coluna `Schema` vazia significa que a linha
vale em todo esquema.

## Os padrões que ninguém escreveu

O `\ddp` só lista os padrões que alguém mudou. **Os embutidos não são linhas, e por isso não
aparecem**: uma tabela nova não dá nada a ninguém além do dono, e uma função nova dá `EXECUTE` ao
`PUBLIC`, como dizia a tabela da lição 12 sobre o que o `PUBLIC` tem. O segundo é um padrão que vale
mudar num banco onde as funções podem fazer coisas que quem chama não deveria, e mudá-lo faz com que
ele apareça:

```
shop=# ALTER DEFAULT PRIVILEGES FOR ROLE shop_owner REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
ALTER DEFAULT PRIVILEGES

shop=# \ddp
                Default access privileges
   Owner    | Schema |   Type   |    Access privileges    
------------+--------+----------+-------------------------
 shop_owner | public | table    | reporting=r/shop_owner +
            |        |          | app=arwd/shop_owner
 shop_owner |        | function | shop_owner=X/shop_owner
(2 rows)
```

A linha nova não tem esquema, então vale para as funções que o `shop_owner` criar em qualquer lugar
do `shop`. A lista de acesso dela é `shop_owner=X/shop_owner`, sendo `X` executar: o dono mantém o
direito e **a entrada do `PUBLIC`, que estava lá sem aparecer, sumiu**. Toda função que o
`shop_owner` criar daqui em diante só pode ser chamada pelo dono até que alguém conceda.

Mais duas coisas sobre lê-los. Um padrão definido `IN SCHEMA` só consegue acrescentar ao que vale em
todo lugar; ele não consegue tirar um grant que um padrão sem esquema dá. E o `\ddp` mostra os padrões
do banco em que você está conectado, então um cluster com dez bancos tem dez listas para ler.

## O que o catálogo guarda

O `\ddp` lê a tabela de catálogo `pg_default_acl`, que tem uma linha por linha daquela listagem, com
o papel criador, o esquema e o tipo de objeto em códigos. Um script que confere um banco contra o
desenho pretendido lê essa tabela, como leria o `has_table_privilege` para os grants que os objetos
já têm. Entre os dois, toda permissão que um papel tem hoje ou vai ter amanhã está a uma consulta de
distância.
