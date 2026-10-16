---
title: Quarkus, Micronaut, Javalin e Play
version: 1
---

Dois dos quatro fazem o trabalho do Spring mais cedo, um recusa o trabalho, e um vem de outra
linguagem. Cada parágrafo abaixo diz para que o framework serve, que cara o código dele tem para quem
conhece Spring e onde é provável você o encontrar. Nada disto foi executado para o curso, exceto o
Javalin, que a próxima seção constrói.

O **Quarkus** (Red Hat, lançado em 2019) liga a aplicação **durante o build**. Cada biblioteca que ele
suporta, do Hibernate ao cliente do Kafka, vem como uma **extensão** do Quarkus, e as extensões rodam
dentro do build do Maven ou do Gradle: varrem as classes, leem as anotações e gravam o que a aplicação
vai fazer ao iniciar, de modo que o início só reproduz essa gravação. O código é escrito contra os
padrões Jakarta, então dá para ler no primeiro dia: `@Path("/books")` e `@GET`, do Jakarta REST, marcam
as rotas, e `@ApplicationScoped` e `@Inject`, do CDI, marcam os beans e os pontos de injeção. O modo dev
(`mvn quarkus:dev`) recompila a cada vez que você salva, e os Dev Services sobem sozinhos um PostgreSQL
num contêiner para os testes, o trabalho que a aula 19 faz à mão com Testcontainers. Você encontra o
Quarkus no mundo da Red Hat, em OpenShift e Kubernetes, e em equipes saindo de um servidor de aplicação
Jakarta EE. O gerador de projetos dele, `code.quarkus.io`, faz o papel que o `start.spring.io` faz para
o Spring.

O Quarkus também é o framework mais associado às **imagens nativas**. O `native-image` do GraalVM
compila a aplicação, as bibliotecas dela e as partes do JDK que elas usam num executável só, para um
sistema operacional, antes da hora, de modo que nada é carregado nem compilado quando ele inicia. Uma
imagem nativa inicia muito mais rápido e usa menos memória que o mesmo programa numa JVM; custa um build
de vários minutos, e tudo o que o programa alcança por reflexão tem de ser declarado antes desse build.
Essa última condição é fácil para um framework que já decidiu a ligação no build, e é o motivo pelo qual
o Spring precisou do passo AOT.

O **Micronaut** (Object Computing, 2018, da equipe por trás do Grails) liga a aplicação **enquanto ela
compila**. Os processadores de anotação dele rodam dentro do `javac` e escrevem, para cada bean, uma
classe pequena que sabe construí-lo, então o início não tem nada para varrer nem para refletir. As
anotações lembram as do Spring de propósito: `@Controller("/books")` na classe, `@Get("/{id}")` no
método, `@Singleton` e `@Inject` para os beans. O Micronaut Data vai um passo além e transforma o nome de
um método de repositório na consulta dele durante a compilação, então um método cujo nome cita um campo
que não existe falha no build, e não no início. O preço é uma compilação mais lenta, e um build que
precisa ter os processadores de anotação configurados, ou produz uma aplicação que não encontra nenhum
dos seus beans. Você o encontra em funções serverless, em que um usuário espera pelo cold start, e nas
ferramentas de nuvem da Oracle, que são construídas sobre ele.

O **Javalin** (2017, começou como um fork do pequeno framework SparkJava) **recusa o trabalho**. Ele é
uma biblioteca: um servidor Jetty embutido, uma tabela de rotas e um objeto `Context` para cada
requisição. Não há contêiner, nem varredura, nem anotação. Uma rota é um lambda que você registra, e os
objetos de que os handlers precisam são construídos com `new` no seu `main`, o que faz do `main` toda a
ligação da aplicação, em Java puro. O que você abre mão é de tudo o que o Spring acrescenta em volta do
handler: o Bean Validation da aula 6, os problem details da aula 7, segurança, transações. Cada um é uma
biblioteca que você escolhe e liga por conta própria. Você encontra o Javalin em serviços e ferramentas
internas pequenas, em equipes de Kotlin (ele é escrito em Kotlin e tem uma API Kotlin ao lado da Java),
e onde quer que uma equipe queira ler cada linha entre o socket e o próprio código.

O **Play** (2007, criado por Guillaume Bort, depois mantido pela Lightbend e pela comunidade desde 2022)
vem do **Scala**, com uma API Java ao lado da Scala. As rotas dele moram num arquivo `conf/routes`, uma
linha por rota, como `GET /books/:id controllers.Books.show(id: Long)`, e esse arquivo é compilado para
código, então uma rota que cita um método inexistente falha no build. Ele é não bloqueante de ponta a
ponta, sobre o Apache Pekko desde o Play 3 (sobre o Akka antes de o Akka mudar de licença), e durante o
desenvolvimento recompila o código alterado quando chega a próxima requisição. A API Java dele liga os
controllers com o Guice, no início, por reflexão. Ele é construído com o sbt, a ferramenta de build do
Scala, mesmo num projeto Java. Você o encontra em empresas de Scala e em bases de código Java dos anos
2010, mais do que em projetos novos.

| | ligado | beans | uma rota se parece com | build com | versão, outubro de 2026 |
|---|---|---|---|---|---|
| Spring Boot | no início, por reflexão | o contêiner do Spring | `@GetMapping("/{id}")` | Maven ou Gradle | 4.1 |
| Quarkus | no build, pelas extensões | CDI | `@GET @Path("/{id}")` | Maven ou Gradle | 3.40, 4.0 em beta |
| Micronaut | no compilador, por processadores de anotação | os dele, gerados | `@Get("/{id}")` | Maven ou Gradle | 5.2 |
| Javalin | por você, no `main` | nenhum | `config.routes.get("/books/{id}", ...)` | qualquer coisa que gere um jar | 7.2 |
| Play | no início, pelo Guice | Guice | uma linha em `conf/routes` | sbt | 3.0, 3.1 em milestones |

A coluna de versões vai envelhecer antes desta aula; ela está aí para que você distinga uma versão atual
de uma antiga num anúncio de vaga ou num pom.
