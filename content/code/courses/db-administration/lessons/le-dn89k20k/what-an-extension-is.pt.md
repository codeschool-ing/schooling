---
title: O que é uma extensão
version: 1
---

Uma **extensão** é um pacote de objetos SQL, às vezes acompanhado de uma biblioteca compilada, que
outra pessoa escreveu e que o PostgreSQL sabe instalar, atualizar e remover como uma coisa só. A
imagem errada é a de um plugin baixado de um site. A maioria das que um DBA usa chegou junto com o
servidor, no mesmo pacote, e está esperando um comando.

O servidor sabe o que poderia instalar:

```
shop=# SELECT count(*) FROM pg_available_extensions;
 count 
-------
    47
(1 row)

shop=# SELECT name, default_version, installed_version, comment
shop-#   FROM pg_available_extensions
shop-#  WHERE name IN ('pg_stat_statements', 'pgcrypto', 'pg_trgm', 'plpgsql', 'postgis')
shop-#  ORDER BY name;
        name        | default_version | installed_version |                                comment                                 
--------------------+-----------------+-------------------+------------------------------------------------------------------------
 pg_stat_statements | 1.10            |                   | track planning and execution statistics of all SQL statements executed
 pg_trgm            | 1.6             |                   | text similarity measurement and index searching based on trigrams
 pgcrypto           | 1.3             |                   | cryptographic functions
 plpgsql            | 1.0             | 1.0               | PL/pgSQL procedural language
(4 rows)
```

São quarenta e sete, e só o `plpgsql` tem `installed_version` no `shop`. As outras são os módulos
**contrib**: extensões mantidas dentro do próprio projeto PostgreSQL, lançadas a cada versão e
empacotadas com o servidor no Ubuntu. O `postgis` não aparece na lista porque não faz parte do
projeto e ainda não está instalado; ele tem um pacote próprio, e a seção depois da próxima o instala.

## Arquivos no disco

Cada extensão disponível é um punhado de arquivos. Um **arquivo de controle** diz como ela se chama,
qual versão é a padrão e se precisa de uma biblioteca; um **script** para cada versão cria os seus
objetos; e um **script de atualização** para cada passo entre versões leva uma instalação antiga
adiante:

```
ana@db:~$ ls /usr/share/postgresql/16/extension/pgcrypto*
/usr/share/postgresql/16/extension/pgcrypto--1.0--1.1.sql
/usr/share/postgresql/16/extension/pgcrypto--1.1--1.2.sql
/usr/share/postgresql/16/extension/pgcrypto--1.2--1.3.sql
/usr/share/postgresql/16/extension/pgcrypto--1.3.sql
/usr/share/postgresql/16/extension/pgcrypto.control
ana@db:~$ cat /usr/share/postgresql/16/extension/pgcrypto.control
# pgcrypto extension
comment = 'cryptographic functions'
default_version = '1.3'
module_pathname = '$libdir/pgcrypto'
relocatable = true
trusted = true
ana@db:~$ ls -l /usr/lib/postgresql/16/lib/pgcrypto.so
-rw-r--r-- 1 root root 125920 Aug 13 16:12 /usr/lib/postgresql/16/lib/pgcrypto.so
```

O `module_pathname` aponta para a metade compilada, `pgcrypto.so`, que guarda o código que as
funções chamam. O `trusted = true` é a linha a que esta seção volta mais abaixo.

**Nenhum desses arquivos faz nada só por estar lá.** Eles pertencem ao servidor e ao pacote que os
colocou ali; o `apt` os substitui numa atualização e nada muda em banco nenhum.

## CREATE EXTENSION, um banco de cada vez

O `CREATE EXTENSION` lê o arquivo de controle, roda o script da versão padrão **dentro do banco em
que você está conectado** e registra que os objetos que criou pertencem à extensão:

```
ana=# CREATE EXTENSION pgcrypto;
CREATE EXTENSION

ana=# \dx
                  List of installed extensions
   Name   | Version |   Schema   |         Description          
----------+---------+------------+------------------------------
 pgcrypto | 1.3     | public     | cryptographic functions
 plpgsql  | 1.0     | pg_catalog | PL/pgSQL procedural language
(2 rows)

ana=# \c shop
You are now connected to database "shop" as user "ana".

shop=# \dx
                 List of installed extensions
  Name   | Version |   Schema   |         Description          
---------+---------+------------+------------------------------
 plpgsql | 1.0     | pg_catalog | PL/pgSQL procedural language
(1 row)
```

O `ana` tem pgcrypto e o `shop` não. Um banco é um conjunto separado de catálogos, então uma
extensão instalada num é invisível do outro, e um servidor com dez bancos que precisam todos de
pgcrypto precisa de dez comandos `CREATE EXTENSION`. Um banco novo é copiado do `template1`, então
uma extensão criada no `template1` aparece em todo banco criado depois, e em nenhum criado antes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"Diagrama. À esquerda, os arquivos de que uma extensão é feita, uma cópia por servidor: pgcrypto.control e os scripts SQL em /usr/share/postgresql/16/extension, e pgcrypto.so em /usr/lib/postgresql/16/lib. À direita, dois bancos. No ana, o CREATE EXTENSION rodou o script e a extensão pgcrypto 1.3 guarda as suas funções; a biblioteca é carregada num backend quando uma função precisa dela. O shop não tem nada até um CREATE EXTENSION rodar lá também.\"><defs><marker id=\"arr\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"300\" height=\"250\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Arquivos: uma cópia por servidor, vinda do pacote</text><text x=\"36\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">/usr/share/postgresql/16/extension/</text><text x=\"48\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pgcrypto.control</text><text x=\"48\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">pgcrypto--1.3.sql</text><text x=\"48\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pgcrypto--1.2--1.3.sql</text><text x=\"48\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">…</text><text x=\"36\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">/usr/lib/postgresql/16/lib/</text><text x=\"48\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">pgcrypto.so</text><rect x=\"430\" y=\"20\" width=\"270\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"446\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">banco ana</text><rect x=\"446\" y=\"58\" width=\"238\" height=\"74\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"458\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">extensão pgcrypto 1.3</text><text x=\"458\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">digest(), crypt(), gen_salt(), …</text><rect x=\"430\" y=\"190\" width=\"270\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"446\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">banco shop</text><text x=\"446\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">nada até um CREATE EXTENSION</text><path d=\"M 324 116 C 370 116, 390 80, 444 80\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#arr)\"></path><path d=\"M 324 218 C 390 218, 400 120, 444 118\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#arr)\" stroke-dasharray=\"5 4\"></path><text x=\"330\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">o CREATE EXTENSION roda o script aqui</text><text x=\"330\" y=\"320\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">um backend carrega a biblioteca quando precisa dela</text></svg>", "caption": "Os arquivos são do servidor; a extensão é do banco. O CREATE EXTENSION copia um para o outro, um banco de cada vez."}
```

## Carregada quando precisa, ou carregada na partida

A biblioteca é um assunto à parte do SQL. A biblioteca da maioria das extensões é carregada **num
backend, na primeira vez que uma das suas funções é chamada**, e fica carregada até a conexão
terminar. Isso não precisa de configuração nenhuma.

Algumas extensões precisam observar tudo o que o servidor faz desde o momento em que ele sobe. Elas
se penduram no executor, ou precisam de memória compartilhada dimensionada antes de a primeira
conexão chegar. Essas vão em **`shared_preload_libraries`**, lido só na partida, e por isso mudá-lo
exige um restart; a lição 5 o colocou entre os parâmetros de contexto `postmaster`. O
`pg_stat_statements` é a que todo DBA encontra, e é a próxima.

## Extensões confiáveis

Criar uma extensão exigia um superusuário, porque um script pode criar funções escritas em C, e C
roda com os direitos do próprio servidor. Desde o PostgreSQL 13 um arquivo de controle pode dizer
**`trusted = true`**: a extensão é considerada segura o bastante para que **qualquer papel com o
privilégio `CREATE` no banco** a instale, e os objetos continuam sendo criados com direitos de
superusuário por trás. O pgcrypto é confiável; o pageinspect, que lê páginas cruas do disco, não é:

```
ana=# CREATE ROLE clerk;
CREATE ROLE

ana=# GRANT CREATE ON DATABASE ana TO clerk;
GRANT

ana=# DROP EXTENSION pgcrypto;
DROP EXTENSION

ana=# SET ROLE clerk;
SET

ana=> CREATE EXTENSION pgcrypto;
CREATE EXTENSION

ana=> CREATE EXTENSION pageinspect;
ERROR:  permission denied to create extension "pageinspect"
HINT:  Must be superuser to create this extension.

ana=> RESET ROLE;
RESET

ana=# \dx pgcrypto
             List of installed extensions
   Name   | Version | Schema |       Description       
----------+---------+--------+-------------------------
 pgcrypto | 1.3     | public | cryptographic functions
(1 row)
```

O `SET ROLE clerk` fez a sessão agir como um papel comum, e o `>` do prompt diz isso. A diferença
pesa mais onde você nunca é superusuário, como nos serviços gerenciados da lição 3. Os papéis
predefinidos da lição 13, `pg_monitor` entre eles, cobrem boa parte do resto do que o dono de uma
aplicação pede a um superusuário.
