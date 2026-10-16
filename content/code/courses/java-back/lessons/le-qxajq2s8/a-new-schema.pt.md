---
title: Os autores ganham uma tabela própria
version: 1
---

Até agora um autor era uma string dentro de cada livro. Dois livros de H. G. Wells repetiam o nome
dele, e nada impedia que um erro de digitação o transformasse em duas pessoas. Esta aula dá aos
autores uma tabela própria e faz `book` apontar para ela com uma chave. É essa mudança que faz um
mapeador valer a pena: um livro agora tem algo para onde navegar. (A aula 1 de `sql-databases`
argumenta por que um fato é registrado uma vez só; aqui é simplesmente o esquema novo.)

Quatro arquivos mudam antes de qualquer Java.

## A dependência

Troque `spring-boot-starter-jdbc` por `spring-boot-starter-data-jpa`. Este é o `pom.xml` inteiro como
fica agora:

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

O starter novo traz o Hibernate e as anotações do JPA, e continua trazendo tudo o que o starter de
JDBC trazia, porque depende dele:

```
(capture tree)
```

O `spring-data-jpa` também está ali. Ele é o assunto da aula 11; esta aula usa diretamente o
mapeador que fica por baixo dele, para você ver o que o Spring Data depois faz por você.

## O esquema e os dados

Substitua `src/main/resources/schema.sql`:

```sql
CREATE TABLE IF NOT EXISTS author (
    id   bigserial PRIMARY KEY,
    name text      NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS book (
    id          bigserial PRIMARY KEY,
    isbn        char(13)  NOT NULL UNIQUE,
    title       text      NOT NULL,
    author_id   bigint    NOT NULL REFERENCES author (id),
    price_cents integer   NOT NULL CHECK (price_cents >= 0)
);
```

`author_id` é uma **chave estrangeira**: o PostgreSQL recusa um livro cujo `author_id` não aponta
para nenhum autor, e recusa apagar um autor que ainda tem livros. E substitua
`src/main/resources/data.sql`:

```sql
INSERT INTO author (name) VALUES
    ('Machado de Assis'),
    ('H. G. Wells'),
    ('Mary Shelley'),
    ('Jane Austen')
ON CONFLICT (name) DO NOTHING;

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
ORDER BY b.isbn
ON CONFLICT (isbn) DO NOTHING;
```

Os autores entram primeiro, e cada livro acha o id do seu autor com um join pelo nome, então o arquivo
nunca escreve um id. Os dois comandos terminam em `ON CONFLICT … DO NOTHING` porque o
`spring.sql.init.mode=always` da aula 9 roda este arquivo a cada inicialização, e a segunda não pode
falhar nas linhas que a primeira inseriu.

## As propriedades

Substitua `src/main/resources/application.properties`:

```properties
spring.application.name=bookshop

spring.datasource.url=jdbc:postgresql://localhost:5432/bookshop
spring.datasource.username=bookshop
spring.datasource.password=bookshop

spring.sql.init.mode=always
spring.jpa.hibernate.ddl-auto=none
spring.jpa.open-in-view=false
```

Duas linhas são novas. **`spring.jpa.hibernate.ddl-auto=none`** impede o Hibernate de mexer nas
tabelas. Ele sabe criá-las a partir das entidades (`create`) ou alterá-las para bater com elas
(`update`), e as duas opções são tentadoras no primeiro dia, mas aí o esquema passa a ser o que o Java
diz naquela manhã, sem registro de como chegou ali. Aqui quem manda nas tabelas é o `schema.sql`, e a
aula 13 as entrega a uma ferramenta de migração. **`spring.jpa.open-in-view=false`** ganha a última
seção inteira.

## O banco recomeça

O `schema.sql` diz `CREATE TABLE IF NOT EXISTS`, e a aula 9 já criou uma tabela chamada `book`, aquela
com uma coluna `author`. Então a definição nova seria pulada, a tabela velha mantida, e o `data.sql`
falharia contra ela. Um arquivo que roda a cada inicialização não consegue mudar o formato de uma
tabela que já existe; é exatamente o problema que a aula 13 resolve. Por enquanto, apague o banco e
crie de novo, vazio, com o mesmo dono:

```
(capture recreate)
```

Nenhum dos dois comandos imprime nada quando funciona. Os dados eram só os livros de exemplo, e a
aplicação os coloca de volta na próxima vez que subir.
