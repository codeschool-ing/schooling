---
title: As mesmas tabelas no Liquibase
version: 1
---

O **Liquibase** resolve o mesmo problema que o Flyway com outra unidade. A unidade do Flyway é um arquivo
SQL cujo nome é a sua versão. A do Liquibase é um **changeset**: uma entrada num **changelog**, escrito em
YAML, XML, JSON ou SQL, identificada por um `id`, um `author` e o arquivo em que está, e não por um
número. Um changeset pode conter SQL, mas é mais comum escrevê-lo como a descrição da mudança,
`createTable` ou `addColumn`, que o Liquibase transforma em SQL para o banco com que estiver falando. O
Spring Boot o roda na partida exatamente como roda o Flyway, dados o `spring-boot-starter-liquibase` e um
changelog em `db/changelog/db.changelog-master.yaml`.

Para vê-lo sem mexer na livraria, esta seção usa um projeto separado, `~/liquibase-look`, que roda o
Liquibase pelo Maven contra um esquema próprio, `look`, dentro do banco da livraria. Crie
`~/liquibase-look/pom.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>com.example</groupId>
  <artifactId>liquibase-look</artifactId>
  <version>0.1.0</version>
  <packaging>pom</packaging>

  <build>
    <plugins>
      <plugin>
        <groupId>org.liquibase</groupId>
        <artifactId>liquibase-maven-plugin</artifactId>
        <version>5.0.3</version>
        <configuration>
          <changeLogFile>changelog.yaml</changeLogFile>
          <url>jdbc:postgresql://localhost:5432/bookshop?currentSchema=look</url>
          <username>bookshop</username>
          <password>bookshop</password>
        </configuration>
        <dependencies>
          <dependency>
            <groupId>org.postgresql</groupId>
            <artifactId>postgresql</artifactId>
            <version>42.7.13</version>
          </dependency>
        </dependencies>
      </plugin>
    </plugins>
  </build>
</project>
```

Ele não compila nada; só configura o plugin do Liquibase, com o driver do PostgreSQL como dependência do
próprio plugin e `currentSchema=look` na URL, para que toda tabela que o Liquibase criar caia em `look`.
Depois o changelog, `~/liquibase-look/changelog.yaml`, com as duas tabelas da livraria e uma linha:

```yaml
databaseChangeLog:
  - changeSet:
      id: author
      author: ana
      changes:
        - createTable:
            tableName: author
            columns:
              - column:
                  name: id
                  type: bigint
                  autoIncrement: true
                  constraints:
                    primaryKey: true
              - column:
                  name: name
                  type: text
                  constraints:
                    nullable: false
                    unique: true
  - changeSet:
      id: book
      author: ana
      changes:
        - createTable:
            tableName: book
            columns:
              - column:
                  name: id
                  type: bigint
                  autoIncrement: true
                  constraints:
                    primaryKey: true
              - column:
                  name: isbn
                  type: char(13)
                  constraints:
                    nullable: false
                    unique: true
              - column:
                  name: title
                  type: text
                  constraints:
                    nullable: false
              - column:
                  name: author_id
                  type: bigint
                  constraints:
                    nullable: false
                    foreignKeyName: book_author_fk
                    references: author(id)
  - changeSet:
      id: first-author
      author: ana
      changes:
        - sql:
            sql: INSERT INTO author (name) VALUES ('Machado de Assis')
      rollback:
        - sql:
            sql: DELETE FROM author WHERE name = 'Machado de Assis'
```

Os dois primeiros changesets descrevem tabelas e nunca mencionam o PostgreSQL. O terceiro é SQL puro, e
traz um `rollback` próprio; o motivo está no fim desta seção. Crie o esquema e rode o changelog duas
vezes:

```
ana@vm:~/liquibase-look$ psql postgresql://bookshop:bookshop@localhost/bookshop -c 'CREATE SCHEMA look'
CREATE SCHEMA
ana@vm:~/liquibase-look$ mvn -B -q liquibase:update

UPDATE SUMMARY
Run:                          3
Previously run:               0
Filtered out:                 0
-------------------------------
Total change sets:            3

ana@vm:~/liquibase-look$ mvn -B -q liquibase:update

UPDATE SUMMARY
Run:                          0
Previously run:               3
Filtered out:                 0
-------------------------------
Total change sets:            3
```

A primeira execução aplicou três changesets e a segunda não aplicou nenhum, que é o "up to date" do
Flyway nas palavras do Liquibase. O histórico dele é a tabela `databasechangelog`:

```
ana@vm:~/liquibase-look$ psql postgresql://bookshop:bookshop@localhost/bookshop -c 'select id, author, filename, md5sum, exectype, orderexecuted from look.databasechangelog'
      id      | author |    filename    |               md5sum               | exectype | orderexecuted 
--------------+--------+----------------+------------------------------------+----------+---------------
 author       | ana    | changelog.yaml | 9:9f262f08622c0f18cafcf7c050aa0b36 | EXECUTED |             1
 book         | ana    | changelog.yaml | 9:9341c4015a946c2287430dcf5c96a8f3 | EXECUTED |             2
 first-author | ana    | changelog.yaml | 9:74f9aa91af47f13bc625299b866ecca3 | EXECUTED |             3
(3 rows)
```

Um changeset é conhecido pelo `id`, pelo `author` e pelo `filename` juntos, e o `md5sum` faz o papel do
checksum do Flyway: edite um changeset que já rodou e o próximo update para, pelo mesmo motivo que o
Flyway parou. O Liquibase também criou uma segunda tabela, a `databasechangeloglock`, que impede duas
cópias de uma aplicação iniciando ao mesmo tempo de aplicar o mesmo changeset duas vezes.

## Rollback

O recurso pelo qual as pessoas escolhem o Liquibase é o **rollback**: desfazer os últimos changesets, em
ordem inversa. Desfaça os dois últimos:

```
ana@vm:~/liquibase-look$ mvn -B -q liquibase:rollback -Dliquibase.rollbackCount=2
ana@vm:~/liquibase-look$ psql postgresql://bookshop:bookshop@localhost/bookshop -c 'select id from look.databasechangelog'
   id   
--------
 author
(1 row)

ana@vm:~/liquibase-look$ psql postgresql://bookshop:bookshop@localhost/bookshop -c '\dt look.*'
                 List of relations
 Schema |         Name          | Type  |  Owner   
--------+-----------------------+-------+----------
 look   | author                | table | bookshop
 look   | databasechangelog     | table | bookshop
 look   | databasechangeloglock | table | bookshop
(3 rows)

ana@vm:~/liquibase-look$ psql postgresql://bookshop:bookshop@localhost/bookshop -c 'select count(*) from look.author'
 count 
-------
     0
(1 row)
```

O histórico perdeu as duas últimas linhas, a tabela `book` sumiu e `author` voltou a ficar vazia. O
Liquibase os desfez de dois jeitos diferentes. Para o `createTable` ele **gerou** o inverso, um
`DROP TABLE`, porque uma mudança descrita diz o bastante para ser revertida. Para o changeset `sql` ele
rodou o `rollback` escrito no arquivo, porque o Liquibase não tem como saber o que um SQL qualquer fez;
sem esse bloco, o rollback se recusaria em vez de adivinhar. Entenda bem o que é um rollback: um novo
conjunto de mudanças rodado para a frente, que apaga o que foi criado. Os dados de uma coluna apagada não
voltam.

Apague o esquema quando terminar de olhar:

```
ana@vm:~/liquibase-look$ psql postgresql://bookshop:bookshop@localhost/bookshop -c 'DROP SCHEMA look CASCADE'
NOTICE:  drop cascades to 3 other objects
DETAIL:  drop cascades to table look.databasechangelog
drop cascades to table look.databasechangeloglock
drop cascades to table look.author
DROP SCHEMA
```

## Escolhendo entre os dois

| | Flyway | Liquibase |
|---|---|---|
| a unidade | um arquivo SQL, `V<versão>__<descrição>.sql` | um changeset num changelog |
| a identidade | a versão no nome do arquivo | `id`, `author` e arquivo |
| escrito em | o SQL do próprio banco | mudanças descritas, ou SQL |
| tabela de histórico | `flyway_schema_history` | `databasechangelog` |
| uma mudança já rodada que foi editada | recusada: checksum diferente | recusada: checksum diferente |
| desfazer | não na edição gratuita | gerado, ou escrito ao lado da mudança |

Eles diferem de mais um jeito, e não é técnico. A licença de cada um está no seu pom:

```
ana@vm:~$ grep -A1 '<license>' .m2/repository/org/flywaydb/flyway-parent/12.4.0/flyway-parent-12.4.0.pom .m2/repository/org/liquibase/liquibase-maven-plugin/5.0.3/liquibase-maven-plugin-5.0.3.pom
.m2/repository/org/flywaydb/flyway-parent/12.4.0/flyway-parent-12.4.0.pom:    <license>
.m2/repository/org/flywaydb/flyway-parent/12.4.0/flyway-parent-12.4.0.pom-      <name>Apache License, Version 2.0</name>
--
.m2/repository/org/liquibase/liquibase-maven-plugin/5.0.3/liquibase-maven-plugin-5.0.3.pom:        <license>
.m2/repository/org/liquibase/liquibase-maven-plugin/5.0.3/liquibase-maven-plugin-5.0.3.pom-            <name>FSL-1.1-ALv2</name>
```

O Flyway está sob a Apache License 2.0. O Liquibase 5 passou para a **Functional Source License**, cujos
termos proíbem usá-lo para construir um produto que concorra com o do próprio Liquibase e viram Apache
2.0 depois de dois anos. Essa restrição não atinge uma aplicação que só roda as próprias migrações, mas
uma organização que revisa licenças vai querer lê-la, e é o tipo de fato que muda entre versões.

Para uma equipe que escreve SQL com tranquilidade e roda um banco só, o modelo do Flyway é o menor: os
arquivos são o SQL que roda, e o histórico são os nomes deles. O Liquibase compensa o vocabulário a mais
quando um changelog tem de servir a vários bancos, ou quando vale a pena ter rollback gerado. A livraria
fica no Flyway, e a aula 14 escreve a próxima migração dela.
