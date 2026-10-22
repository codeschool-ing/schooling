---
title: O Hibernate confere em vez de adivinhar
version: 1
---

As migrações agora são donas do esquema, e o Hibernate continua tendo uma opinião sobre ele. O
`ddl-auto` decide o que o Hibernate faz com essa opinião na partida. `create` e `create-drop` montam o
esquema a partir das entidades, e `update` altera o esquema na direção delas. `validate` compara os dois e
se recusa a iniciar se discordarem. `none`, que as aulas 10 e 11 usaram, não faz nada.

O tentador é o `update`, e vale saber por que ele está errado aqui. Ele acrescenta o que falta e nunca
apaga, renomeia nem muda o tipo de nada, então um campo renomeado deixa a coluna antiga para trás e uma
coluna alargada não é alargada. Pior: o esquema passa a ser o que a última entidade a iniciar pediu, o que
é um segundo autor do esquema ao lado das migrações, e um que não registra nada. **Com uma ferramenta de
migração, as migrações escrevem o esquema e o Hibernate só confere.** Isso é o `validate`. Mude a
penúltima linha do `application.properties`, para que o arquivo fique assim:

```properties
spring.application.name=bookshop

spring.datasource.url=jdbc:postgresql://localhost:5432/bookshop
spring.datasource.username=bookshop
spring.datasource.password=bookshop

spring.jpa.hibernate.ddl-auto=validate
spring.jpa.open-in-view=false
```

Compile e inicie, com o `grep` guardando a única linha que diz o porquê:

```
ana@vm:~/bookshop$ mvn -B -q package -DskipTests
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar | grep 'Caused by: org.hibernate'
Caused by: org.hibernate.tool.schema.spi.SchemaManagementException: Schema validation: wrong column type encountered in column [isbn] in table [book]; found [bpchar (Types#CHAR)], but expecting [varchar(255) (Types#VARCHAR)]
```

Leia do fim para o começo. O Hibernate esperava `varchar(255)`, que é como ele mapeia um campo `String`
quando nada diz outra coisa, e achou `bpchar`, o nome interno que o PostgreSQL dá a `char(n)`, o tipo de
tamanho fixo completado com espaços que o `isbn char(13)` declara. **Essa diferença existe desde a aula
10.** Com `none` ninguém comparava os dois, e o `validate` é a primeira configuração que olhou.

Há dois jeitos de fazê-los concordar: mudar a coluna com uma migração nova, ou dizer ao Hibernate a
verdade sobre a coluna. A coluna está certa, já que um ISBN-13 tem sempre treze caracteres, então quem
muda é o mapeamento. Em `src/main/java/com/example/bookshop/catalogue/Book.java`, o campo `isbn` ganha
duas anotações, e dois imports vêm junto:

```schooling-example
{
  "language": "java",
  "file": "Book.java",
  "parts": [
    {
      "code": "package com.example.bookshop.catalogue;\n\nimport jakarta.persistence.Column;\nimport jakarta.persistence.Entity;\nimport jakarta.persistence.FetchType;\nimport jakarta.persistence.GeneratedValue;\nimport jakarta.persistence.GenerationType;\nimport jakarta.persistence.Id;\nimport jakarta.persistence.ManyToOne;\n"
    },
    {
      "code": "import org.hibernate.annotations.JdbcTypeCode;\nimport org.hibernate.type.SqlTypes;\n",
      "note": "**Dois imports do próprio Hibernate**, não de `jakarta.persistence`. O padrão JPA não tem como dizer qual é o tipo JDBC de uma coluna, então este mapeamento é do Hibernate."
    },
    {
      "code": "@Entity\npublic class Book {\n\n    @Id\n    @GeneratedValue(strategy = GenerationType.IDENTITY)\n    private Long id;\n"
    },
    {
      "code": "    @JdbcTypeCode(SqlTypes.CHAR)\n    @Column(length = 13)\n    private String isbn;\n",
      "note": "**A correção inteira.** `@JdbcTypeCode(SqlTypes.CHAR)` diz que a coluna é um `char` de tamanho fixo, e `@Column(length = 13)` dá a ela o tamanho que a migração deu. O campo continua sendo uma `String`; só mudou a ideia que o Hibernate faz da coluna."
    },
    {
      "code": "    private String title;\n\n    @ManyToOne(fetch = FetchType.LAZY, optional = false)\n    private Author author;\n\n    @Column(name = \"price_cents\")\n    private int priceCents;\n\n    protected Book() {\n    }\n\n    public Book(String isbn, String title, Author author, int priceCents) {\n        this.isbn = isbn;\n        this.title = title;\n        this.author = author;\n        this.priceCents = priceCents;\n    }\n\n    public Long getId() {\n        return id;\n    }\n\n    public String getIsbn() {\n        return isbn;\n    }\n\n    public String getTitle() {\n        return title;\n    }\n\n    public Author getAuthor() {\n        return author;\n    }\n\n    public int getPriceCents() {\n        return priceCents;\n    }\n}",
      "note": "O resto da entidade é o da aula 10, sem mudança."
    }
  ]
}```

Compile e inicie mais uma vez. Agora é o log inteiro, como o segundo terminal o mostra:

```
ana@vm:~/bookshop$ mvn -B -q package -DskipTests
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v4.1.1)

2026-10-22T19:29:54.835-03:00  INFO 16475 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Starting BookshopApplication v0.1.0 using Java 25.0.4.1 with PID 16475 (/home/ana/bookshop/target/bookshop-0.1.0.jar started by ana in /home/ana/bookshop)
2026-10-22T19:29:54.838-03:00  INFO 16475 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : No active profile set, falling back to 1 default profile: "default"
2026-10-22T19:29:55.543-03:00  INFO 16475 --- [bookshop] [           main] .s.d.r.c.RepositoryConfigurationDelegate : Bootstrapping Spring Data JPA repositories in DEFAULT mode.
2026-10-22T19:29:55.583-03:00  INFO 16475 --- [bookshop] [           main] .s.d.r.c.RepositoryConfigurationDelegate : Finished Spring Data repository scanning in 32 ms. Found 2 JPA repository interfaces.
2026-10-22T19:29:55.972-03:00  INFO 16475 --- [bookshop] [           main] o.s.boot.tomcat.TomcatWebServer          : Tomcat initialized with port 8080 (http)
2026-10-22T19:29:55.983-03:00  INFO 16475 --- [bookshop] [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
2026-10-22T19:29:55.983-03:00  INFO 16475 --- [bookshop] [           main] o.apache.catalina.core.StandardEngine    : Starting Servlet engine: [Apache Tomcat/11.0.24]
2026-10-22T19:29:56.002-03:00  INFO 16475 --- [bookshop] [           main] b.w.c.s.WebApplicationContextInitializer : Root WebApplicationContext: initialization completed in 1128 ms
2026-10-22T19:29:56.232-03:00  INFO 16475 --- [bookshop] [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Starting...
2026-10-22T19:29:56.512-03:00  INFO 16475 --- [bookshop] [           main] com.zaxxer.hikari.pool.HikariPool        : HikariPool-1 - Added connection org.postgresql.jdbc.PgConnection@3b0d3a63
2026-10-22T19:29:56.513-03:00  INFO 16475 --- [bookshop] [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Start completed.
2026-10-22T19:29:56.530-03:00  INFO 16475 --- [bookshop] [           main] org.flywaydb.core.FlywayExecutor         : Database: jdbc:postgresql://localhost:5432/bookshop (PostgreSQL 16.15)
2026-10-22T19:29:56.583-03:00  INFO 16475 --- [bookshop] [           main] o.f.core.internal.command.DbValidate     : Successfully validated 2 migrations (execution time 00:00.017s)
2026-10-22T19:29:56.624-03:00  INFO 16475 --- [bookshop] [           main] o.f.core.internal.command.DbMigrate      : Current version of schema "public": 2
2026-10-22T19:29:56.627-03:00  INFO 16475 --- [bookshop] [           main] o.f.core.internal.command.DbMigrate      : Schema "public" is up to date. No migration necessary.
2026-10-22T19:29:56.707-03:00  INFO 16475 --- [bookshop] [           main] org.hibernate.orm.jpa                    : HHH008540: Processing PersistenceUnitInfo [name: default]
2026-10-22T19:29:56.749-03:00  INFO 16475 --- [bookshop] [           main] org.hibernate.orm.core                   : HHH000001: Hibernate ORM core version 7.4.5.Final
2026-10-22T19:29:57.082-03:00  INFO 16475 --- [bookshop] [           main] o.s.o.j.p.SpringPersistenceUnitInfo      : No LoadTimeWeaver setup: ignoring JPA class transformer
2026-10-22T19:29:57.151-03:00  INFO 16475 --- [bookshop] [           main] org.hibernate.orm.connections.pooling    : HHH10001005: Database info:
	Database JDBC URL [jdbc:postgresql://localhost:5432/bookshop]
	Database driver: PostgreSQL JDBC Driver
	Database dialect: PostgreSQLDialect
	Database version: 16.15
	Default catalog/schema: bookshop/public
	Autocommit mode: undefined/unknown
	Isolation level: READ_COMMITTED [default READ_COMMITTED]
	JDBC fetch size: none
	Pool: DataSourceConnectionProvider
	Minimum pool size: undefined/unknown
	Maximum pool size: undefined/unknown
2026-10-22T19:29:57.821-03:00  INFO 16475 --- [bookshop] [           main] org.hibernate.orm.core                   : HHH000489: No JTA platform available (set 'hibernate.transaction.jta.platform' to enable JTA platform integration)
2026-10-22T19:29:57.854-03:00  INFO 16475 --- [bookshop] [           main] j.LocalContainerEntityManagerFactoryBean : Initialized JPA EntityManagerFactory for persistence unit 'default'
2026-10-22T19:29:57.931-03:00  INFO 16475 --- [bookshop] [           main] o.s.d.j.r.query.QueryEnhancerFactories   : Hibernate is in classpath; If applicable, HQL parser will be used.
2026-10-22T19:29:58.663-03:00  INFO 16475 --- [bookshop] [           main] o.s.boot.tomcat.TomcatWebServer          : Tomcat started on port 8080 (http) with context path '/'
2026-10-22T19:29:58.675-03:00  INFO 16475 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 4.145 seconds (process running for 4.49)
2026-10-22T19:29:58.776-03:00  INFO 16475 --- [bookshop] [           main] c.e.bookshop.catalogue.CatalogueReport   : Catalogue opened on 2026-10-22 with 6 books
```

O Flyway validou as duas migrações, achou o esquema já na versão 2 e não aplicou nada; depois o Hibernate
montou a `EntityManagerFactory`, que é onde o `validate` rodou, e não disse nada, que é a cara da
concordância.

Saiba o que esse silêncio cobre. O `validate` confere se toda tabela e toda coluna que uma entidade mapeia
existe, com um tipo compatível. Ele não confere `NOT NULL`, `UNIQUE`, `CHECK` nem chaves estrangeiras, e
ignora colunas que as entidades não mapeiam. Isso pertence às migrações, o que é mais um motivo para as
migrações, e não as entidades, serem a fonte única do esquema.
