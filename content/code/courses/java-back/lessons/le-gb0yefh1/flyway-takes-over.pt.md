---
title: O Flyway assume o esquema
version: 1
---

O modelo do Flyway cabe numa frase. **Ele lê arquivos SQL com nomes `V<versão>__<descrição>.sql` de
`db/migration` no classpath, aplica em ordem de versão os que este banco ainda não recebeu e registra cada
um numa tabela própria, a `flyway_schema_history`.** Todo o resto desta aula é consequência dessa frase.

O nome carrega a ordem. `V1__catalogue.sql` é a versão 1 com a descrição `catalogue`;
`V2__first_titles.sql` é a versão 2, `first titles`, com os sublinhados virando espaços. O separador são
**dois** sublinhados, e as versões são comparadas como números, então `V10` vem depois de `V9` e não
depois de `V1`; uma versão também pode ter ponto, `V1.1`. Um segundo tipo de arquivo,
`R__<descrição>.sql`, é **repetível**: não tem versão e roda de novo sempre que o conteúdo muda, o que
serve para uma view ou uma função que é sempre substituída inteira. A livraria não precisa de nenhum.

## O pom

Substitua o `pom.xml` por este. Duas dependências são novas:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>4.1.1</version>
    <relativePath/>
  </parent>

  <groupId>com.example</groupId>
  <artifactId>bookshop</artifactId>
  <version>0.1.0</version>

  <properties>
    <java.version>25</java.version>
  </properties>

  <dependencies>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-webmvc</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-flyway</artifactId>
    </dependency>
    <dependency>
      <groupId>org.flywaydb</groupId>
      <artifactId>flyway-database-postgresql</artifactId>
    </dependency>
    <dependency>
      <groupId>org.postgresql</groupId>
      <artifactId>postgresql</artifactId>
      <scope>runtime</scope>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
      </plugin>
    </plugins>
  </build>
</project>
```

O `spring-boot-starter-flyway` traz o Flyway e a autoconfiguração que o roda na partida, antes de a
`EntityManagerFactory` da aula 10 ser montada, para que o Hibernate nunca veja um esquema no meio de uma
migração. O `flyway-database-postgresql` é o suporte do Flyway ao PostgreSQL em particular: o Flyway
distribui cada família de banco como um módulo separado, e o fim desta seção mostra o que acontece sem
ele. Nenhuma das duas tem versão, porque o parent as gerencia, como a aula 4 explicou; aqui isso resolve
para o Flyway 12.4.0.

## As migrações

O `schema.sql` e o `data.sql` saem, e duas migrações entram no lugar. Apague os dois arquivos, depois crie
o diretório `src/main/resources/db/migration` e escreva a primeira migração,
`src/main/resources/db/migration/V1__catalogue.sql`:

```sql
CREATE TABLE author (
    id   bigserial PRIMARY KEY,
    name text      NOT NULL UNIQUE
);

CREATE TABLE book (
    id          bigserial PRIMARY KEY,
    isbn        char(13)  NOT NULL UNIQUE,
    title       text      NOT NULL,
    author_id   bigint    NOT NULL REFERENCES author (id),
    price_cents integer   NOT NULL CHECK (price_cents >= 0)
);
```

e a segunda, `src/main/resources/db/migration/V2__first_titles.sql`:

```sql
INSERT INTO author (name) VALUES
    ('Machado de Assis'),
    ('H. G. Wells'),
    ('Mary Shelley'),
    ('Jane Austen');

INSERT INTO book (isbn, title, author_id, price_cents)
SELECT b.isbn, b.title, a.id, b.price_cents
FROM (VALUES
    ('9786500000016', 'Dom Casmurro', 'Machado de Assis', 3990),
    ('9786500000023', 'The Time Machine', 'H. G. Wells', 2950),
    ('9786500000030', 'Frankenstein', 'Mary Shelley', 3500),
    ('9786500000047', 'Persuasion', 'Jane Austen', 3100),
    ('9786500000054', 'Quincas Borba', 'Machado de Assis', 3690),
    ('9786500000061', 'The War of the Worlds', 'H. G. Wells', 3200)
) AS b (isbn, title, author, price_cents)
JOIN author a ON a.name = b.author
ORDER BY b.isbn;
```

São os dois arquivos antigos sem as guardas. `IF NOT EXISTS` e `ON CONFLICT` estavam lá porque os
arquivos rodavam a cada partida; uma migração roda uma vez, então uma guarda nela só esconderia um erro.
Esquema e dados ficam em arquivos separados porque são mudanças separadas: algum banco, algum dia, pode
precisar das tabelas sem estas seis linhas.

Por fim, o `src/main/resources/application.properties` perde a linha que rodava os arquivos antigos:

```properties
spring.application.name=bookshop

spring.datasource.url=jdbc:postgresql://localhost:5432/bookshop
spring.datasource.username=bookshop
spring.datasource.password=bookshop

spring.jpa.hibernate.ddl-auto=none
spring.jpa.open-in-view=false
```

Compile e procure as migrações dentro do jar, que é de onde o Flyway as lê:

```
ana@vm:~/bookshop$ mvn -B -q package -DskipTests
ana@vm:~/bookshop$ jar tf target/bookshop-0.1.0.jar | grep db/migration
BOOT-INF/classes/db/migration/
BOOT-INF/classes/db/migration/V1__catalogue.sql
BOOT-INF/classes/db/migration/V2__first_titles.sql
```

## Um banco que já tem tabelas

Inicie no segundo terminal. O log é longo, então desta vez ele passa pelo `grep`, que guarda a única linha
que importa:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar | grep FlywayException
Caused by: org.flywaydb.core.api.FlywayException: Found non-empty schema(s) "public" but no schema history table. Use baseline() or set baselineOnMigrate to true to initialize the schema history table.
```

O Flyway achou tabelas e **nenhuma tabela de histórico**, e se recusa a adivinhar. Essas tabelas podem
ser o que o V1 e o V2 criam, ou outra coisa completamente diferente; aplicar o V1 sobre elas falharia no
primeiro `CREATE TABLE`, e supor que batem poderia esconder uma diferença para sempre. A mensagem cita as
duas saídas, e qual é a certa depende de os dados importarem ou não.

**Um baseline é para um banco cujos dados importam.** Ele diz ao Flyway: este banco já contém tudo até a
versão N. O Flyway cria a tabela de histórico com uma linha dizendo isso e, daí em diante, aplica só as
versões acima de N. É assim que uma equipe adota o Flyway num banco de produção com anos de linhas. O
banco da livraria foi feito pelo `schema.sql` e pelo `data.sql`, que fazem exatamente o que o V1 e o V2
fazem, então o baseline dele é 2. Experimente uma vez, com as duas configurações na linha de comando:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.flyway.baseline-on-migrate=true --spring.flyway.baseline-version=2 | grep -E 'o\.f\.|Started'
2026-10-22T19:29:26.879-03:00  INFO 14768 --- [bookshop] [           main] o.f.c.i.s.JdbcTableSchemaHistory         : Schema history table "public"."flyway_schema_history" does not exist yet
2026-10-22T19:29:26.883-03:00  INFO 14768 --- [bookshop] [           main] o.f.core.internal.command.DbValidate     : Successfully validated 2 migrations (execution time 00:00.019s)
2026-10-22T19:29:26.901-03:00  INFO 14768 --- [bookshop] [           main] o.f.c.i.s.JdbcTableSchemaHistory         : Creating Schema History table "public"."flyway_schema_history" with baseline ...
2026-10-22T19:29:26.939-03:00  INFO 14768 --- [bookshop] [           main] o.f.core.internal.command.DbBaseline     : Successfully baselined schema with version: 2
2026-10-22T19:29:26.973-03:00  INFO 14768 --- [bookshop] [           main] o.f.core.internal.command.DbMigrate      : Current version of schema "public": 2
2026-10-22T19:29:26.978-03:00  INFO 14768 --- [bookshop] [           main] o.f.core.internal.command.DbMigrate      : Schema "public" is up to date. No migration necessary.
2026-10-22T19:29:29.883-03:00  INFO 14768 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 5.625 seconds (process running for 6.106)
ana@vm:~/bookshop$ psql postgresql://bookshop:bookshop@localhost/bookshop -c 'select installed_rank, version, description, type, success from flyway_schema_history'
 installed_rank | version |      description      |   type   | success 
----------------+---------+-----------------------+----------+---------
              1 | 2       | << Flyway Baseline >> | BASELINE | t
(1 row)
```

O Flyway criou o histórico com uma linha de **baseline** na versão 2 e não aplicou nada. A versão é uma
afirmação sua que o Flyway não tem como conferir: um baseline 2 num banco que na verdade parou na 1
pularia o V2 para sempre, em silêncio. É também por isso que o `baseline-on-migrate` pertence a uma linha
de comando usada uma vez, e nunca ao `application.properties`, onde faria em silêncio o baseline de
qualquer banco não vazio para onde a aplicação apontasse, inclusive o errado.

**Apagar é para um banco cujos dados não importam**, e este guarda três aulas de linhas de teste. Pare a
aplicação com Ctrl+C e crie o banco de novo, vazio, como a aula 10 fez:

```sh
sudo -u postgres dropdb bookshop
sudo -u postgres createdb -O bookshop bookshop
```

Inicie de novo. Num banco vazio não há o que recusar, e as linhas do Flyway contam a história inteira:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar | grep -E 'o\.f\.|Started'
2026-10-22T19:29:36.300-03:00  INFO 15121 --- [bookshop] [           main] o.f.c.i.s.JdbcTableSchemaHistory         : Schema history table "public"."flyway_schema_history" does not exist yet
2026-10-22T19:29:36.304-03:00  INFO 15121 --- [bookshop] [           main] o.f.core.internal.command.DbValidate     : Successfully validated 2 migrations (execution time 00:00.039s)
2026-10-22T19:29:36.323-03:00  INFO 15121 --- [bookshop] [           main] o.f.c.i.s.JdbcTableSchemaHistory         : Creating Schema History table "public"."flyway_schema_history" ...
2026-10-22T19:29:36.417-03:00  INFO 15121 --- [bookshop] [           main] o.f.core.internal.command.DbMigrate      : Current version of schema "public": << Empty Schema >>
2026-10-22T19:29:36.433-03:00  INFO 15121 --- [bookshop] [           main] o.f.core.internal.command.DbMigrate      : Migrating schema "public" to version "1 - catalogue"
2026-10-22T19:29:36.576-03:00  INFO 15121 --- [bookshop] [           main] o.f.core.internal.command.DbMigrate      : Migrating schema "public" to version "2 - first titles"
2026-10-22T19:29:36.627-03:00  INFO 15121 --- [bookshop] [           main] o.f.core.internal.command.DbMigrate      : Successfully applied 2 migrations to schema "public", now at version v2 (execution time 00:00.080s)
2026-10-22T19:29:39.408-03:00  INFO 15121 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 7.082 seconds (process running for 7.743)
```

Ele criou a tabela de histórico, achou o esquema vazio, aplicou a versão 1 e depois a 2, e só então
deixou o resto da aplicação iniciar. A próxima partida não aplica nada, e a seção depois da próxima lê a
tabela que torna isso possível.

A segunda dependência do pom é fácil de esquecer, porque o projeto compila sem ela. Esta é a partida sem
ela, contra o mesmo banco:

```
ana@vm:~/bookshop$ mvn -B -q package -DskipTests
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar | grep 'Caused by: org.flywaydb'
Caused by: org.flywaydb.core.api.FlywayException: Unsupported Database: PostgreSQL 16.15
```

O Flyway conhece o nome do PostgreSQL e mais nada sobre ele. Ponha a dependência de volta.
