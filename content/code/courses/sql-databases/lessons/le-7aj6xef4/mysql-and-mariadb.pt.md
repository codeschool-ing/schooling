---
title: O fork, e o quanto ele já foi longe
version: 1
---

Em 2008 a Sun Microsystems comprou a MySQL AB. Em 2009 a Oracle anunciou que comprava a Sun, e
Michael Widenius — que escreveu a primeira versão do MySQL e a batizou com o nome da filha, My —
forkou o código e começou o MariaDB, com o nome da outra filha. Essa é a origem inteira, e ela
explica as duas coisas que as pessoas erram sobre a dupla.

**Não são duas marcas do mesmo produto.** São desenvolvidos separadamente há mais de quinze anos por times
diferentes com prioridades diferentes.

**Também não são dois bancos diferentes.** Compartilham um ancestral, um protocolo de rede, um
cliente, um dialeto e um motor de armazenamento, e a esmagadora maioria do código de aplicação roda
nos dois sem um caractere mudar.

## O que ainda é igual

O mesmo `CREATE TABLE` carregou nos dois sem edição. `AUTO_INCREMENT`, `DESCRIBE`,
`SHOW CREATE TABLE`, `||` como OU, `5 / 2` como `2.5000`, a collation padrão que ignora caixa, o
InnoDB como motor de armazenamento, o DDL confirmando implicitamente — tudo compartilhado, porque
tudo herdado. Onde esta aula capturou o MariaDB, foi para mostrar onde os dois se separam:
`sql_mode`, `GROUP BY` e `RETURNING`.

O cliente também é compartilhado: o `mysql` conecta num servidor MariaDB e o `mariadb` conecta num
MySQL, porque o protocolo é o mesmo. A maioria dos drivers lista um e fala com os dois.

## Onde eles de fato divergiram

| | MySQL 8 | MariaDB 10.11 |
|---|---|---|
| `ONLY_FULL_GROUP_BY` por padrão | sim | **não** |
| `INSERT … RETURNING` | não | **sim**, desde a 10.5 |
| largura de exibição de inteiro | removida: `int` | mantida: `int(11)` |
| JSON | um tipo `JSON` de verdade, com armazenamento binário | um apelido para `LONGTEXT`, mais funções |
| funções de janela, CTEs | 8.0 | 10.2 |
| tabelas versionadas pelo sistema | não | sim |
| motores de armazenamento oferecidos | InnoDB | InnoDB, Aria, ColumnStore, outros |
| licença do motor | GPL, mais uma edição comercial | só GPL |
| replicação | a própria, mais Group Replication | a própria, mais Galera |

A captura do `DESCRIBE` da seção anterior mostra a metade do MySQL na terceira linha sem que
ninguém peça: `int`, sem número depois. O MariaDB mantém o número e imprime `int(11)`. O número nunca foi um limite de largura — é
uma dica de exibição que quase nada jamais usou — e o MySQL 8 a removeu enquanto o MariaDB a
manteve. É a menor diferença possível e é um bom exemplo da forma: cosmética, inofensiva, e
suficiente para deixar um diff de esquema entre os dois barulhento.

A linha do JSON é a que custa. No MySQL uma coluna `JSON` é parseada uma vez e guardada num formato
binário, então extrair um campo não reparsea o documento. No MariaDB o nome do tipo é aceito e é um
apelido para `LONGTEXT` com um `CHECK` de que é JSON válido, então as funções funcionam e as
características de desempenho não batem. O código migra; o plano de consulta não.

## Qual escolher, se você estiver escolhendo

Na maior parte do tempo esta não é uma decisão técnica, e fingir o contrário desperdiça a reunião.

**MySQL** se você quer a base instalada maior, a oferta gerenciada do fornecedor em toda nuvem, e o
conjunto maior de gente que já o operou. A Oracle o publica sob a GPL e não há sinal de que isso vá
mudar; o desconforto que as pessoas expressam é sobre quem é o dono, e não sobre um termo de
licença que alguém consiga apontar.

**MariaDB** se você quer um motor sob a GPL sem edição comercial atrás dele, ou quer o Galera para
replicação multi-primária. Ou porque sua distribuição Linux entrega MariaDB como padrão, o que
muitas fazem, e é assim que a maioria das pessoas acaba nele sem nunca escolher.

**Nenhum dos dois, se a decisão estiver mesmo aberta.** Soa cínico, e é a leitura honesta desta aula
até aqui. Se nada te obriga, as seções sobre rigor são um argumento a favor do PostgreSQL. O
motivo de estar no MySQL ou no MariaDB quase sempre é que você já está.

## Migrar entre os dois

Fácil numa direção e cada vez mais difícil na outra. O MariaDB acompanhou o MySQL de perto por
anos, então levar uma aplicação MySQL 5.x para o MariaDB costuma ser um dump e um restore. Ir do
MariaDB de volta para o MySQL, ou do MySQL 8 adiante para o MariaDB, esbarra na tabela acima — na
linha do JSON em particular, e em qualquer coisa que use um recurso só do MariaDB, como tabelas
versionadas pelo sistema.

O conselho prático é o mesmo da seção da aula 11 sobre o que um ORM esconde: **saiba em que motor
você está e escreva para ele.** Um esquema que evita cuidadosamente tudo que falta em qualquer um
dos dois é um esquema escrito para uma migração que provavelmente nunca vai acontecer.
