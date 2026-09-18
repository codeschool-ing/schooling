---
title: O que os quatro são de fato
version: 1
---

Onze aulas se passaram quase sem um nome de produto dentro delas. Isso não foi esquecimento. O
modelo relacional, `SELECT`, as junções, `GROUP BY`, transações, índices e o plano são um assunto
só, e o motor que roda isso é um detalhe em quase tudo.

Esta aula é sobre o resto — os lugares onde o motor deixa de ser um detalhe. São quatro aqui, e a
primeira coisa a acertar é o que cada um **é**, porque dois deles não são o mesmo tipo de coisa
que os outros dois.

## PostgreSQL

Um servidor de banco de dados, desenvolvido desde 1996 por um grupo distribuído de colaboradores
sem nenhuma empresa por trás, sob uma licença permissiva própria. É o mais rigoroso dos quatro
sobre o que aceita, o mais amplo no que consegue guardar, e o que tem um mecanismo de extensões em
cima do qual outros projetos são construídos — PostGIS para geografia, TimescaleDB para séries
temporais, `pgvector` para embeddings são todos Postgres com algo carregado dentro.

O nome se lê *post-gres-quiu-éle*, e o projeto atende por `postgres` em todo comando que você
digita, que é o que o resto desta aula usa.

## MySQL

Um servidor de banco de dados, lançado em 1995, comprado pela Sun em 2008 e, junto com a Sun, pela
Oracle em 2010. Tem licença dupla: GPL para a edição comunitária, e uma licença comercial para o
resto. É o motor por trás de uma parte enorme da web — WordPress, a maioria das hospedagens
compartilhadas, boa parte do que foi construído entre 2000 e 2015 — e essa base instalada é o
principal motivo pelo qual você vai encontrá-lo.

## MariaDB

O fork do MySQL que os autores originais começaram em 2009, quando a Oracle adquiriu a Sun. É GPL,
sem edição comercial do motor, e por vários anos foi um substituto direto: o mesmo protocolo, o
mesmo cliente, o mesmo SQL. Quinze anos de desenvolvimento separado afastaram os dois, e a seção
sobre o fork é sobre o quanto.

## SQLite

**Não é um servidor.** É uma biblioteca C contra a qual seu programa é ligado, e o banco é um
arquivo no disco. Não há processo para subir, porta para conectar, usuário para criar. Está em
domínio público, é o banco de dados mais instalado do mundo por uma margem enorme — todo celular
Android, todo iPhone, todo navegador, a maioria das aplicações de desktop — e é aquele cujo lugar
na lista é mais mal compreendido.

## A forma da comparação

Três dos quatro são servidores com quem você fala por um socket; um é uma biblioteca dentro do seu
processo. Dois dos servidores compartilham um ancestral e a maior parte de um dialeto; o terceiro
não.

| | PostgreSQL | MySQL | MariaDB | SQLite |
|---|---|---|---|---|
| o que é | servidor | servidor | servidor | biblioteca |
| primeiro lançamento | 1996 | 1995 | 2009 | 2000 |
| licença | licença PostgreSQL | GPL + comercial | GPL | domínio público |
| cuidado por | nenhum dono único | Oracle | MariaDB Foundation e MariaDB plc | nenhum dono único |
| motor de armazenamento padrão | o próprio | InnoDB | InnoDB | o próprio |

Tudo daqui em diante decorre dessa tabela. As versões contra as quais esta aula foi escrita são as
das transcrições: PostgreSQL 16.13, MySQL 8.0.46, MariaDB 10.11.14 e SQLite 3.45.1, cada um
rodando a loja da aula 1.

Existe um quinto motor que você vai encontrar num emprego corporativo, e ele é diferente o
bastante — no que custa, em como é comprado, e no que faz com a forma de um sistema — para ganhar
a aula 13 só para ele.
