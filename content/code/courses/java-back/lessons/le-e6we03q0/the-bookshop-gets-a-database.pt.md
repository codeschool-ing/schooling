---
title: A livraria ganha um banco de dados
version: 1
---

Agora o mesmo trabalho dentro da livraria. Ela parte de como a aula 7 a deixou, e a mudança é menor
do que parece, porque a aula 5 pôs o catálogo atrás de uma interface: o `BookService` pede a um
`BookRepository` e não sabe o que há atrás dele. Esta seção e a próxima trocam o que está atrás, e
nada acima muda.

## As dependências

Substitua o `pom.xml` por este. Duas dependências são novas, no fim da lista:

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
      <artifactId>spring-boot-starter-jdbc</artifactId>
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

O **`spring-boot-starter-jdbc`** traz o suporte do Spring a JDBC e um pool de conexões. O driver
**`postgresql`** tem escopo `runtime`: o código compila contra o `java.sql` e as classes do Spring e
nunca nomeia uma classe do PostgreSQL, então o driver é necessário quando a aplicação roda, e não
quando ela compila. Nenhuma das linhas tem versão, porque o parent gerencia as duas. Pergunte ao
Maven o que chegou; o `grep` separa as linhas que importam da árvore inteira:

```
ana@vm:~/bookshop$ mvn dependency:tree | grep -E 'jdbc|postgresql|Hikari'
[INFO] +- org.springframework.boot:spring-boot-starter-jdbc:jar:4.1.1:compile
[INFO] |  +- org.springframework.boot:spring-boot-jdbc:jar:4.1.1:compile
[INFO] |  |  \- org.springframework:spring-jdbc:jar:7.0.9:compile
[INFO] |  \- com.zaxxer:HikariCP:jar:7.0.2:compile
[INFO] \- org.postgresql:postgresql:jar:42.7.13:runtime
```

O driver é o mesmo 42.7.13 que o `Jdbc.java` usou. Debaixo do starter estão o `spring-jdbc`, o
suporte a JDBC do Spring Framework, e o **HikariCP**, o pool.

## Onde está o banco

Substitua `src/main/resources/application.properties` por este:

```properties
spring.application.name=bookshop

spring.datasource.url=jdbc:postgresql://localhost:5432/bookshop
spring.datasource.username=bookshop
spring.datasource.password=bookshop

spring.sql.init.mode=always
```

As três linhas `spring.datasource` são a URL, o usuário e a senha que o `Jdbc.java` passava ao
`DriverManager`, levados para a configuração. A aula 4 mostrou que um argumento de linha de comando
sobrepõe uma linha deste arquivo, e a última seção desta aula usa isso para quebrar cada uma das
três de propósito.

## O esquema e as primeiras linhas

O Spring Boot procura dois scripts no class path e os roda contra o banco na subida, o `schema.sql`
e depois o `data.sql`. Crie `src/main/resources/schema.sql`:

```sql
CREATE TABLE IF NOT EXISTS book (
    id          bigserial PRIMARY KEY,
    isbn        char(13)  NOT NULL UNIQUE,
    title       text      NOT NULL,
    author      text      NOT NULL,
    price_cents integer   NOT NULL CHECK (price_cents >= 0)
);
```

e `src/main/resources/data.sql`:

```sql
INSERT INTO book (isbn, title, author, price_cents) VALUES
    ('9786500000016', 'Dom Casmurro', 'Machado de Assis', 3990),
    ('9786500000023', 'The Time Machine', 'H. G. Wells', 2950),
    ('9786500000030', 'Frankenstein', 'Mary Shelley', 3500)
ON CONFLICT (isbn) DO NOTHING;
```

Por padrão o Boot só os roda para um banco **embutido**, um que vive dentro da JVM e começa vazio
toda vez. O PostgreSQL é um servidor de verdade, então `spring.sql.init.mode=always` pede os scripts
a cada subida. Os dois foram escritos para aguentar isso: `CREATE TABLE IF NOT EXISTS` deixa em paz
uma tabela que já existe, e `ON CONFLICT (isbn) DO NOTHING` pula qualquer linha cujo ISBN a regra
`UNIQUE` já tenha. Rodar scripts a cada subida é um quebra-galho; a aula 13 mostra onde ele deixa de
servir e troca os dois arquivos por migrações.

A tabela que você criou à mão no `psql` tem as mesmas colunas, mas guarda Wise Blood e The War of
the Worlds, que o `data.sql` não tem. Apague-a, para que o que você vê em seguida seja o que a
aplicação constrói do zero:

```
ana@vm:~/bookshop$ psql postgresql://bookshop:bookshop@localhost:5432/bookshop -c 'DROP TABLE book'
DROP TABLE
```

## Um pool no lugar do DriverManager

O `Jdbc.java` abria uma conexão, usava uma vez e fechava, e o fim daquela seção contou quanto cada
uma custa. Uma aplicação web não pode pagar isso a cada requisição, então o Boot não usa o
`DriverManager`. Ele monta um **`DataSource`**, o outro jeito do JDBC de obter uma conexão, uma
interface de `javax.sql` cujo único trabalho é `getConnection()`. O que o Boot monta a partir das
três propriedades `spring.datasource` é o do HikariCP, um **pool de conexões**, que abre conexões
antes da hora e as empresta. Quando o código chama `close()` numa delas, a conexão volta para o
pool em vez de ser fechada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 372\" role=\"img\" aria-label=\"Dois programas lado a lado. À esquerda, Jdbc.java chama o DriverManager, que abre uma conexão nova a cada chamada. À direita, o JdbcBookRepository da livraria chama o JdbcClient do Spring, que pega conexões emprestadas de um pool HikariCP. Os dois passam depois pelas mesmas interfaces java.sql e pelo mesmo jar do driver do PostgreSQL, por TCP até localhost na porta 5432, até um único servidor PostgreSQL 16.\"><defs><marker id=\"jl9-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"175\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o primeiro programa desta aula</text><text x=\"525\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a livraria</text><rect x=\"30\" y=\"26\" width=\"290\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"175\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Jdbc.java</text><text x=\"175\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o seu código</text><rect x=\"30\" y=\"82\" width=\"290\" height=\"96\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"175\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">DriverManager.getConnection(…)</text><text x=\"175\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma conexão nova a cada chamada</text><rect x=\"380\" y=\"26\" width=\"290\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"525\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">JdbcBookRepository</text><text x=\"525\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o seu código</text><rect x=\"380\" y=\"82\" width=\"290\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"525\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">JdbcClient</text><text x=\"525\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Spring: SQL entra, records saem</text><rect x=\"380\" y=\"134\" width=\"290\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"525\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">HikariDataSource</text><text x=\"525\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o pool de conexões abertas do Boot</text><line x1=\"175\" y1=\"70\" x2=\"175\" y2=\"80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#jl9-ah)\"></line><line x1=\"525\" y1=\"70\" x2=\"525\" y2=\"80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#jl9-ah)\"></line><line x1=\"525\" y1=\"126\" x2=\"525\" y2=\"132\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#jl9-ah)\"></line><line x1=\"175\" y1=\"178\" x2=\"175\" y2=\"196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#jl9-ah)\"></line><line x1=\"525\" y1=\"178\" x2=\"525\" y2=\"196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#jl9-ah)\"></line><rect x=\"30\" y=\"198\" width=\"640\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">java.sql: Connection, PreparedStatement, ResultSet</text><text x=\"350\" y=\"231\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">JDBC, as interfaces contra as quais os dois programas são escritos</text><line x1=\"350\" y1=\"242\" x2=\"350\" y2=\"252\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#jl9-ah)\"></line><rect x=\"30\" y=\"254\" width=\"640\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">postgresql-42.7.13.jar</text><text x=\"350\" y=\"287\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o driver: chamadas JDBC viram o protocolo do PostgreSQL</text><line x1=\"350\" y1=\"298\" x2=\"350\" y2=\"324\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#jl9-ah)\"></line><text x=\"360\" y=\"311\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">TCP, localhost:5432</text><rect x=\"30\" y=\"326\" width=\"640\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"346\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">servidor PostgreSQL 16</text></svg>", "caption": "Os dois programas chegam ao PostgreSQL pelas mesmas interfaces JDBC e pelo mesmo driver. O JdbcClient e o pool são o que o Spring põe por cima, e eles não substituem o que está embaixo."}
```

Tudo o que está debaixo do `JdbcClient` na figura é o JDBC que o `Jdbc.java` chamava à mão. O que o
Spring acrescenta é o pool e a classe que escreve a parte repetitiva por você, que a próxima seção
lê.
