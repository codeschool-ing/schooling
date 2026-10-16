---
title: Propriedades e perfis por ambiente
version: 1
---

A livraria vai rodar em mais de um lugar: na sua máquina enquanto você a escreve, nos testes, num
servidor. Algumas configurações precisam mudar entre eles, e o jeito errado de conseguir isso é um
jar por lugar, ou uma linha que alguém edita antes de cada build. **O Boot lê as configurações
quando o jar sobe, de vários lugares, e um perfil escolhe um conjunto delas pelo nome**, então um
jar serve a todos os ambientes.

## application.properties

Tudo o que um starter configura tem uma propriedade, e o
`src/main/resources/application.properties` é onde a aplicação guarda as suas. O da livraria tem
uma linha por enquanto:

```properties
spring.application.name=bookshop
```

A documentação de referência do Spring Boot lista cada propriedade que cada módulo lê, com o
padrão: `server.port` é 8080 até alguém dizer outra coisa. O arquivo também pode ser YAML,
`application.yaml`, com os mesmos nomes aninhados; este curso fica com properties, uma
configuração por linha, que é mais fácil de procurar com `grep`.

## Um perfil é um segundo arquivo, lido por cima

Um **perfil** é um nome, e para cada perfil ativo o Boot também lê o
`application-<nome>.properties` ao lado do arquivo principal. Crie
`src/main/resources/application-dev.properties`:

```properties
server.port=8081
logging.level.org.springframework.web=debug
```

Na máquina de quem desenvolve, a livraria escuta na 8081, o que deixa a 8080 livre para outra
coisa, e a camada web do Spring registra em `DEBUG`, então o tratamento de cada requisição fica
visível. O arquivo do perfil não substitui o principal: **os dois são lidos, e onde discordam o
perfil vence**, então o `spring.application.name` continua vindo do arquivo principal.

Refaça o build, já que os dois arquivos vão dentro do jar, e suba no segundo terminal com o perfil
nomeado:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.profiles.active=dev

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v4.1.1)

2026-10-16T20:20:57.167-03:00  INFO 2023 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Starting BookshopApplication v0.1.0 using Java 25.0.4.1 with PID 2023 (/home/ana/bookshop/target/bookshop-0.1.0.jar started by ana in /home/ana/bookshop)
2026-10-16T20:20:57.172-03:00  INFO 2023 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : The following 1 profile is active: "dev"
2026-10-16T20:20:58.341-03:00  INFO 2023 --- [bookshop] [           main] o.s.boot.tomcat.TomcatWebServer          : Tomcat initialized with port 8081 (http)
2026-10-16T20:20:58.354-03:00  INFO 2023 --- [bookshop] [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
2026-10-16T20:20:58.355-03:00  INFO 2023 --- [bookshop] [           main] o.apache.catalina.core.StandardEngine    : Starting Servlet engine: [Apache Tomcat/11.0.24]
2026-10-16T20:20:58.377-03:00  INFO 2023 --- [bookshop] [           main] b.w.c.s.WebApplicationContextInitializer : Root WebApplicationContext: initialization completed in 1048 ms
2026-10-16T20:20:58.642-03:00 DEBUG 2023 --- [bookshop] [           main] s.w.s.m.m.a.RequestMappingHandlerMapping : 2 mappings in 'requestMappingHandlerMapping'
2026-10-16T20:20:58.656-03:00 DEBUG 2023 --- [bookshop] [           main] o.s.w.s.handler.SimpleUrlHandlerMapping  : Patterns [/webjars/**, /**] in 'resourceHandlerMapping'
2026-10-16T20:20:58.668-03:00 DEBUG 2023 --- [bookshop] [           main] s.w.s.m.m.a.RequestMappingHandlerAdapter : ControllerAdvice beans: 0 @ModelAttribute, 0 @InitBinder, 2 RequestBodyAdvice, 1 ResponseBodyAdvice
2026-10-16T20:20:58.700-03:00 DEBUG 2023 --- [bookshop] [           main] .m.m.a.ExceptionHandlerExceptionResolver : ControllerAdvice beans: 0 @ExceptionHandler, 1 ResponseBodyAdvice
2026-10-16T20:20:58.739-03:00  INFO 2023 --- [bookshop] [           main] o.s.boot.tomcat.TomcatWebServer          : Tomcat started on port 8081 (http) with context path '/'
2026-10-16T20:20:58.751-03:00  INFO 2023 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 2.112 seconds (process running for 2.704)
```

O `The following 1 profile is active: "dev"` substitui o `No active profile set` da primeira
execução, o Tomcat está na 8081, e as linhas `DEBUG` vêm do `org.springframework.web` trabalhando.
Pare a aplicação.

## Escolhendo o perfil sem a linha de comando

Um servidor costuma ser iniciado por algo que não é uma pessoa digitando, uma definição de serviço
ou um contêiner, e o lugar onde esse algo entrega configurações é o ambiente. Toda propriedade pode
vir como **variável de ambiente**, escrita em maiúsculas com sublinhados no lugar dos pontos, então
`spring.profiles.active` é `SPRING_PROFILES_ACTIVE`. Daqui em diante o segundo terminal manda o
log para um arquivo, como no relatório, e o primeiro procura nele:

```
ana@vm:~/bookshop$ SPRING_PROFILES_ACTIVE=dev java -jar target/bookshop-0.1.0.jar > /tmp/bookshop.log 2>&1
```

```
ana@vm:~/bookshop$ grep -E 'profile|Tomcat started' /tmp/bookshop.log
2026-10-16T20:21:00.778-03:00  INFO 2199 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : The following 1 profile is active: "dev"
2026-10-16T20:21:02.443-03:00  INFO 2199 --- [bookshop] [           main] o.s.boot.tomcat.TomcatWebServer          : Tomcat started on port 8081 (http) with context path '/'
```

O mesmo perfil, escolhido pelo ambiente. Pare de novo.

## Um perfil que ninguém escreveu

Agora digite errado:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.profiles.active=dve > /tmp/bookshop.log 2>&1
```

```
ana@vm:~/bookshop$ grep -E 'profile|Tomcat started' /tmp/bookshop.log
2026-10-16T20:21:04.531-03:00  INFO 2294 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : The following 1 profile is active: "dve"
2026-10-16T20:21:06.852-03:00  INFO 2294 --- [bookshop] [           main] o.s.boot.tomcat.TomcatWebServer          : Tomcat started on port 8080 (http) with context path '/'
```

Ela subiu, diz que o perfil `dve` está ativo, e está na 8080. **Um perfil sem arquivo não é um
erro**: um perfil também pode ligar e desligar beans com `@Profile`, então um nome sem arquivo de
propriedades é legal, e o Boot não tem uma lista dos nomes que você quis dizer. Nada avisa. A
linha do perfil é a única evidência, e é por isso que vale lê-la depois de toda inicialização que
importa.
