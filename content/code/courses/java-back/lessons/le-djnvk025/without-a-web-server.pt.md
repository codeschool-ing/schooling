---
title: "Um desvio: a mesma aplicação sem o starter web"
version: 1
---

O jeito mais rápido de ver que a autoconfiguração segue o classpath é tirar algo dele. Esta seção
é um desvio: muda o pom, olha, e põe o pom de volta.

Troque o bloco `<dependencies>` do `pom.xml` pelo starter do núcleo sozinho, aquele de que todos
os outros starters dependem:

```xml
  <dependencies>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter</artifactId>
    </dependency>
  </dependencies>
```

Faça o build, e desta vez rode no primeiro terminal, porque a aplicação não vai continuar no ar:

```
ana@vm:~/bookshop$ mvn -B -q package
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v4.1.1)

2026-10-16T20:20:49.830-03:00  INFO 1664 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Starting BookshopApplication v0.1.0 using Java 25.0.4.1 with PID 1664 (/home/ana/bookshop/target/bookshop-0.1.0.jar started by ana in /home/ana/bookshop)
2026-10-16T20:20:49.833-03:00  INFO 1664 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : No active profile set, falling back to 1 default profile: "default"
2026-10-16T20:20:50.294-03:00  INFO 1664 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 0.88 seconds (process running for 1.198)
```

O mesmo banner, o mesmo `Started BookshopApplication`, e o prompt volta. Nada falhou. Sem servidor
web no classpath, as condições da configuração do Tomcat não valeram, nenhum servidor foi criado,
e o contexto não tinha mais nada a fazer depois de subir. O `SpringApplication.run` retornou, o
`main` terminou, e a JVM saiu porque **nenhuma thread ficou rodando**. Com o starter web, são as
threads do Tomcat, esperando conexões, que mantêm o processo vivo.

A árvore fica menor por tudo o que o starter web trazia:

```
ana@vm:~/bookshop$ mvn -q dependency:tree -DoutputFile=/tmp/tree.txt && grep -c ':compile' /tmp/tree.txt
21
```

Esse formato não é uma aplicação web quebrada. É o formato certo para um programa que faz um
trabalho e para, uma importação noturna ou um relatório, que ainda ganha as propriedades, o log e
a injeção de dependências do Boot. A livraria é uma API web, então ponha o bloco `<dependencies>`
de volta como a primeira seção o mostra, com o `spring-boot-starter-webmvc`, e rode
`mvn -B -q package` de novo antes da próxima seção.
