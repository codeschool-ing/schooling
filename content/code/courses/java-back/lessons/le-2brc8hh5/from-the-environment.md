---
title: The password comes from the environment
version: 1
---

The jar is meant to be the same file everywhere it runs: on your machine, on a test server and in
production. What differs between those places is configuration, the database's address and its
password above all, and **configuration that differs between places comes from the place, not from
the jar**. Lesson 4 ranked where a property can come from and showed that an environment variable
outranks `application.properties`; lesson 9 gave the bookshop a password and said this lesson would
take it out of the project's files.

## Anyone with the jar can read it

The password is still in `application.properties`, and that file is inside the jar:

```
ana@vm:~/bookshop$ unzip -p target/bookshop-0.1.0.jar BOOT-INF/classes/application.properties | grep password
spring.datasource.password=bookshop
```

A jar travels. It is copied to servers, stored in an artefact repository, attached to a bug report,
and in a later section baked into an image that anybody with access to the registry can pull. Every
copy carries the password, and changing the password means building and shipping a new jar.

## Taking it out

Replace `src/main/resources/application.properties` with this. The only change is the line that
is gone, `spring.datasource.password=bookshop`:

```properties
spring.application.name=bookshop

spring.datasource.url=jdbc:postgresql://localhost:5432/bookshop
spring.datasource.username=bookshop
spring.datasource.hikari.pool-name=bookshop-pool
spring.datasource.hikari.maximum-pool-size=10
spring.datasource.hikari.connection-timeout=5000

spring.jpa.hibernate.ddl-auto=validate
spring.jpa.open-in-view=false

bookshop.jwt.secret=${BOOKSHOP_JWT_SECRET}
bookshop.jwt.lifetime=15m

logging.pattern.correlation=[%X{requestId:-}] 

management.server.port=8081
management.server.address=127.0.0.1
management.endpoints.web.exposure.include=health,info,metrics,prometheus
management.endpoint.health.show-details=always
management.endpoint.health.probes.enabled=true
management.info.java.enabled=true
```

The address and the user stay. They are not secret, and the values here are right for your machine,
so running the jar there needs one variable less. Build again and start the jar the way lesson 4 did,
in the foreground, keeping only the line that matters:

```
ana@vm:~/bookshop$ mvn -q package -DskipTests
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar | grep -m 1 '^Message'
Message    : The server requested SCRAM-based authentication, but no password was provided.
```

`BOOKSHOP_JWT_SECRET` is still exported in this terminal from lesson 15, so the token key is found.
The password is not. The PostgreSQL that lesson 9 installed asks any client connecting over TCP
for a password, by a method called SCRAM, and the driver had none to give. Flyway is the first component to open a connection, so the failure
arrives as a Flyway error, and the application stops before it serves anything.

Give it the password the way a server would, through the environment:

```
ana@vm:~/bookshop$ export SPRING_DATASOURCE_PASSWORD=bookshop
```

A variable belongs to the shell that exported it and to the programs that shell starts, so start the
jar again from this same terminal. This time it gets as far as the catalogue:

```
2026-10-22T20:09:19.023-03:00  INFO 17633 --- [bookshop] [           main] [] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 5.709 seconds (process running for 6.095)
2026-10-22T20:09:19.149-03:00  INFO 17633 --- [bookshop] [           main] [] c.e.bookshop.catalogue.CatalogueReport   : Catalogue opened on 2026-10-22 with 6 books
```

and from a second terminal, the bookshop answers:

```
ana@vm:~/bookshop$ curl -s localhost:8080/books/1
{"id":1,"isbn":"9786500000016","title":"Dom Casmurro","author":"Machado de Assis","priceCents":3990,"stock":5}
```

## The names a variable may take

Spring Boot found `SPRING_DATASOURCE_PASSWORD` and bound it to `spring.datasource.password`. That is
lesson 4's **relaxed binding**, and the rule for an environment variable is mechanical: take the
property's name, replace every dot with an underscore, remove the dashes and write it in capitals.

| property | environment variable |
| --- | --- |
| `spring.datasource.password` | `SPRING_DATASOURCE_PASSWORD` |
| `spring.datasource.url` | `SPRING_DATASOURCE_URL` |
| `management.server.address` | `MANAGEMENT_SERVER_ADDRESS` |
| `spring.datasource.hikari.maximum-pool-size` | `SPRING_DATASOURCE_HIKARI_MAXIMUMPOOLSIZE` |

`bookshop.jwt.secret` is set the other way round: the file says
`bookshop.jwt.secret=${BOOKSHOP_JWT_SECRET}`, a placeholder that reads the variable by name. Relaxed
binding would have found `BOOKSHOP_JWT_SECRET` without it; the line is there so that the file says,
in so many words, what every deployment has to provide.

The environment is not a vault. Any process running as the same user, and root, can read another
process's environment, and a value typed after `export` stays in the shell's history. What it does
guarantee is the property this section is about: **the secret is held by the machine that runs the
jar, and never by the jar**. Lesson 15's `$(openssl rand -base64 32)` keeps the value out of the
history as well, and the section on Compose writes both secrets to a file only you can read.
