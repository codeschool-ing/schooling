---
title: A senha vem do ambiente
version: 1
---

O jar deve ser o mesmo arquivo em todo lugar onde roda: na sua máquina, num servidor de testes e em
produção. O que muda entre esses lugares é a configuração, sobretudo o endereço do banco e a senha
dele, e **a configuração que muda de lugar para lugar vem do lugar, e não do jar**. A aula 4 ordenou
de onde uma propriedade pode vir e mostrou que uma variável de ambiente tem precedência sobre o
`application.properties`; a aula 9 deu uma senha à livraria e disse que esta aula a tiraria dos
arquivos do projeto.

## Qualquer um com o jar consegue lê-la

A senha ainda está no `application.properties`, e esse arquivo está dentro do jar:

```
ana@vm:~/bookshop$ unzip -p target/bookshop-0.1.0.jar BOOT-INF/classes/application.properties | grep password
spring.datasource.password=bookshop
```

Um jar viaja. É copiado para servidores, guardado num repositório de artefatos, anexado a um relato
de bug e, numa seção mais adiante, embutido numa imagem que qualquer pessoa com acesso ao registro
consegue baixar. Toda cópia leva a senha junto, e trocar a senha significa construir e entregar um
jar novo.

## Tirando a senha

Substitua `src/main/resources/application.properties` por este. A única mudança é a linha que
sumiu, `spring.datasource.password=bookshop`:

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

O endereço e o usuário ficam. Não são segredo, e os valores aqui servem para a sua máquina, então
rodar o jar ali exige uma variável a menos. Construa de novo e inicie o jar como na aula 4, em
primeiro plano, guardando só a linha que interessa:

```
ana@vm:~/bookshop$ mvn -q package -DskipTests
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar | grep -m 1 '^Message'
Message    : The server requested SCRAM-based authentication, but no password was provided.
```

`BOOKSHOP_JWT_SECRET` continua exportada neste terminal desde a aula 15, então a chave dos tokens é
encontrada. A senha, não. O PostgreSQL que a aula 9 instalou pede uma senha a todo cliente que se
conecta por TCP, por um método chamado SCRAM, e o driver não tinha nenhuma para dar. O Flyway é o
primeiro componente a abrir uma conexão, então a falha chega como um erro do Flyway, e a aplicação
para antes de atender qualquer coisa.

Dê a senha a ela como um servidor daria, pelo ambiente:

```
ana@vm:~/bookshop$ export SPRING_DATASOURCE_PASSWORD=bookshop
```

Uma variável pertence ao shell que a exportou e aos programas que esse shell inicia, então inicie o
jar de novo a partir deste mesmo terminal. Desta vez ele chega até o catálogo:

```
2026-10-22T20:09:19.023-03:00  INFO 17633 --- [bookshop] [           main] [] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 5.709 seconds (process running for 6.095)
2026-10-22T20:09:19.149-03:00  INFO 17633 --- [bookshop] [           main] [] c.e.bookshop.catalogue.CatalogueReport   : Catalogue opened on 2026-10-22 with 6 books
```

e, de um segundo terminal, a livraria responde:

```
ana@vm:~/bookshop$ curl -s localhost:8080/books/1
{"id":1,"isbn":"9786500000016","title":"Dom Casmurro","author":"Machado de Assis","priceCents":3990,"stock":5}
```

## Os nomes que uma variável pode ter

O Spring Boot encontrou `SPRING_DATASOURCE_PASSWORD` e a associou a `spring.datasource.password`. É a
**associação flexível** (*relaxed binding*) da aula 4, e a regra para uma variável de ambiente é
mecânica: pegue o nome da propriedade, troque cada ponto por um sublinhado, tire os hifens e escreva
em maiúsculas.

| propriedade | variável de ambiente |
| --- | --- |
| `spring.datasource.password` | `SPRING_DATASOURCE_PASSWORD` |
| `spring.datasource.url` | `SPRING_DATASOURCE_URL` |
| `management.server.address` | `MANAGEMENT_SERVER_ADDRESS` |
| `spring.datasource.hikari.maximum-pool-size` | `SPRING_DATASOURCE_HIKARI_MAXIMUMPOOLSIZE` |

`bookshop.jwt.secret` é definida pelo caminho inverso: o arquivo diz
`bookshop.jwt.secret=${BOOKSHOP_JWT_SECRET}`, um placeholder que lê a variável pelo nome. A associação
flexível teria encontrado `BOOKSHOP_JWT_SECRET` sem ele; a linha está ali para que o arquivo diga,
com todas as letras, o que todo ambiente de implantação precisa fornecer.

O ambiente não é um cofre. Qualquer processo rodando com o mesmo usuário, e o root, consegue ler o
ambiente de outro processo, e um valor digitado depois de `export` fica no histórico do shell. O que
ele garante é a propriedade de que trata esta seção: **o segredo fica com a máquina que roda o jar, e
nunca com o jar**. O `$(openssl rand -base64 32)` da aula 15 também tira o valor do histórico, e a
seção sobre o Compose grava os dois segredos num arquivo que só você consegue ler.
