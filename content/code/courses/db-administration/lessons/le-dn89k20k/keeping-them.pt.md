---
title: Manter as extensões através de atualizações e upgrades
version: 1
---

Uma extensão tem **duas versões que andam separadas**: os arquivos no disco, que o `apt` substitui,
e os objetos em cada banco, que ficam como o `CREATE EXTENSION` os fez até alguém atualizá-los. A
maior parte dos problemas que extensões causam no dia do upgrade vem de esquecer a segunda.

## Instalada e padrão

O `pg_available_extensions` mostra as duas. Uma versão antiga instalada de propósito deixa a
diferença visível:

```
ana=# CREATE EXTENSION pg_trgm VERSION '1.5';
CREATE EXTENSION

ana=# SELECT name, default_version, installed_version
ana-#   FROM pg_available_extensions
ana-#  WHERE installed_version IS NOT NULL
ana-#  ORDER BY name;
   name   | default_version | installed_version 
----------+-----------------+-------------------
 pg_trgm  | 1.6             | 1.5
 pgcrypto | 1.3             | 1.3
 plpgsql  | 1.0             | 1.0
 postgis  | 3.4.2           | 3.4.2
(4 rows)

ana=# ALTER EXTENSION pg_trgm UPDATE;
ALTER EXTENSION

ana=# \dx pg_trgm
                                  List of installed extensions
  Name   | Version | Schema |                            Description                            
---------+---------+--------+-------------------------------------------------------------------
 pg_trgm | 1.6     | public | text similarity measurement and index searching based on trigrams
(1 row)
```

`default_version` é o que os arquivos no disco instalariam hoje; `installed_version` é o que este
banco tem. **O `ALTER EXTENSION … UPDATE` roda os scripts de atualização** entre as duas, aqui o
`pg_trgm--1.5--1.6.sql`, um dos arquivos listados na primeira seção. A mesma coisa acontece sem
ninguém pedir uma versão antiga: uma atualização de pacote traz arquivos novos e um padrão novo, e
cada banco mantém os objetos antigos até ser mandado atualizar. Uma consulta que lista as linhas em
que as duas colunas diferem, rodada em cada banco depois de uma atualização, é uma boa linha num
checklist de manutenção.

**A biblioteca é a exceção.** Um arquivo `.so` é substituído pelo pacote e carregado do zero pelo
próximo backend que precisar dele, ou no próximo restart para o que estiver em
`shared_preload_libraries`. As notas de lançamento do PostGIS dizem quando uma atualização menor
pede também um `ALTER EXTENSION postgis UPDATE`; leia-as antes da atualização, não depois.

## O que um dump carrega

O `pg_dump` escreve **uma linha `CREATE EXTENSION` por extensão**, e não os objetos que ela criou:

```
ana@db:~$ pg_dump --schema-only ana | grep -i extension
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';
ana@db:~$ pg_dump --schema-only ana | wc -l
112
```

O esquema inteiro do `ana`, PostGIS incluído, tem 112 linhas, contra os 893 objetos que o PostGIS
sozinho criou. É isso que torna um dump portável, e é também a sua condição: **o servidor que
restaura o dump precisa ter os arquivos da extensão instalados**, ou a restauração para nessa linha
com um erro. As lições de backup de db-reliability restauram exatamente dumps assim.

## Antes de um upgrade maior

Um upgrade maior, do 16 para o 17, põe um segundo servidor ao lado do primeiro, e o segundo tem o
seu próprio diretório de arquivos de extensão. O `postgresql-16-postgis-3` serve o 16 e mais nada;
**o 17 precisa do `postgresql-17-postgis-3` instalado antes de o upgrade começar**, e o mesmo vale
para toda extensão que veio de um pacote próprio. Os módulos contrib chegam com o servidor novo.

Então o inventário vem primeiro: `\dx` em cada banco e, para cada extensão, se a versão nova tem
pacote e se a versão instalada pode ser atualizada para ela. A lição 20 faz o upgrade e volta a esta
lista depois.

## Devolvendo o servidor

O resto do curso não usa nada disto, então a lição deixa o servidor como o encontrou: as tabelas e
as extensões removidas, o papel apagado, e o `shared_preload_libraries` de volta a vazio com mais um
restart.

```
ana=# DROP TABLE app_users, warehouses;
DROP TABLE

ana=# DROP EXTENSION pgcrypto, postgis, pg_trgm;
DROP EXTENSION

ana=# REVOKE CREATE ON DATABASE ana FROM clerk;
REVOKE

ana=# DROP ROLE clerk;
DROP ROLE

ana=# \c shop
You are now connected to database "shop" as user "ana".

shop=# DROP EXTENSION pg_stat_statements;
DROP EXTENSION

shop=# ALTER SYSTEM RESET shared_preload_libraries;
ALTER SYSTEM
```

```
ana@db:~$ sudo systemctl restart postgresql@16-main
```

```
shop=# SHOW shared_preload_libraries;
 shared_preload_libraries 
--------------------------
 pg_stat_statements
(1 row)
```

O pacote `postgresql-16-postgis-3` pode continuar instalado: arquivos no disco não fazem nada até um
banco pedir por eles.
