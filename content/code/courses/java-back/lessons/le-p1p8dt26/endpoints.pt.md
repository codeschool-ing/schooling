---
title: O Actuator, numa porta só dele
version: 1
---

Um processo rodando não é a mesma coisa que uma aplicação funcionando. O `ps` consegue dizer que a JVM
da livraria existe; não consegue dizer se essa JVM ainda alcança o PostgreSQL, quanto tempo um
`GET /books` leva, ou se pedidos estão sendo recusados. Só a aplicação sabe disso, então é a ela que
se pergunta. O **Spring Boot Actuator** é o módulo que responde: um conjunto de **endpoints** abaixo
de `/actuator` que falam da própria aplicação, e não de livros.

Alguns desses endpoints contam muita coisa. O `env` lista cada propriedade de configuração e de onde
ela veio; o `heapdump` entrega uma cópia da memória do processo, onde o segredo do JWT e a senha do
banco estão em texto puro. Por isso a primeira decisão não é quais endpoints ligar, e sim **quem
consegue alcançá-los**, e a resposta da livraria é: ninguém fora da máquina.

## Duas dependências e um goal de plugin

Substitua o `pom.xml` por este. As notas marcam os dois lugares que mudaram:

```schooling-example
{
  "language": "xml",
  "file": "pom.xml",
  "parts": [
    {
      "code": "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<project xmlns=\"http://maven.apache.org/POM/4.0.0\"\n         xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n         xsi:schemaLocation=\"http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd\">\n  <modelVersion>4.0.0</modelVersion>\n\n  <parent>\n    <groupId>org.springframework.boot</groupId>\n    <artifactId>spring-boot-starter-parent</artifactId>\n    <version>4.1.1</version>\n    <relativePath/>\n  </parent>\n\n  <groupId>com.example</groupId>\n  <artifactId>bookshop</artifactId>\n  <version>0.1.0</version>\n\n  <properties>\n    <java.version>25</java.version>\n    <springdoc.version>3.1.1</springdoc.version>\n    <rest-assured.version>6.1.0</rest-assured.version>\n    <cucumber.version>8.0.4</cucumber.version>\n  </properties>\n\n  <dependencyManagement>\n    <dependencies>\n      <dependency>\n        <groupId>io.cucumber</groupId>\n        <artifactId>cucumber-bom</artifactId>\n        <version>${cucumber.version}</version>\n        <type>pom</type>\n        <scope>import</scope>\n      </dependency>\n    </dependencies>\n  </dependencyManagement>\n\n  <dependencies>\n    <dependency>\n      <groupId>org.springframework.boot</groupId>\n      <artifactId>spring-boot-starter-webmvc</artifactId>\n    </dependency>\n    <dependency>\n      <groupId>org.springframework.boot</groupId>\n      <artifactId>spring-boot-starter-validation</artifactId>\n    </dependency>\n    <dependency>\n      <groupId>org.springframework.boot</groupId>\n      <artifactId>spring-boot-starter-data-jpa</artifactId>\n    </dependency>\n    <dependency>\n      <groupId>org.springframework.boot</groupId>\n      <artifactId>spring-boot-starter-flyway</artifactId>\n    </dependency>\n    <dependency>\n      <groupId>org.flywaydb</groupId>\n      <artifactId>flyway-database-postgresql</artifactId>\n    </dependency>\n    <dependency>\n      <groupId>org.springframework.boot</groupId>\n      <artifactId>spring-boot-starter-security-oauth2-resource-server</artifactId>\n    </dependency>",
      "note": "Como a aula 21 deixou: o parent que gerencia as versões, as propriedades e os starters de web, validação, JPA, Flyway e resource server."
    },
    {
      "code": "    <dependency>\n      <groupId>org.springframework.boot</groupId>\n      <artifactId>spring-boot-starter-actuator</artifactId>\n    </dependency>\n    <dependency>\n      <groupId>io.micrometer</groupId>\n      <artifactId>micrometer-registry-prometheus</artifactId>\n    </dependency>",
      "note": "Novo. `spring-boot-starter-actuator` traz os endpoints e o **Micrometer**, a biblioteca que guarda os números. `micrometer-registry-prometheus` acrescenta mais uma forma de entregá-los, o endpoint `/actuator/prometheus`. Nenhum dos dois tem versão: o parent cuida das duas."
    },
    {
      "code": "    <dependency>\n      <groupId>org.springdoc</groupId>\n      <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>\n      <version>${springdoc.version}</version>\n    </dependency>\n\n    <dependency>\n      <groupId>org.springframework.boot</groupId>\n      <artifactId>spring-boot-starter-test</artifactId>\n      <scope>test</scope>\n    </dependency>\n    <dependency>\n      <groupId>org.springframework.boot</groupId>\n      <artifactId>spring-boot-starter-data-jpa-test</artifactId>\n      <scope>test</scope>\n    </dependency>\n    <dependency>\n      <groupId>org.springframework.boot</groupId>\n      <artifactId>spring-boot-testcontainers</artifactId>\n      <scope>test</scope>\n    </dependency>\n    <dependency>\n      <groupId>org.testcontainers</groupId>\n      <artifactId>testcontainers-junit-jupiter</artifactId>\n      <scope>test</scope>\n    </dependency>\n    <dependency>\n      <groupId>org.testcontainers</groupId>\n      <artifactId>testcontainers-postgresql</artifactId>\n      <scope>test</scope>\n    </dependency>\n    <dependency>\n      <groupId>io.rest-assured</groupId>\n      <artifactId>rest-assured</artifactId>\n      <version>${rest-assured.version}</version>\n      <scope>test</scope>\n    </dependency>\n    <dependency>\n      <groupId>io.cucumber</groupId>\n      <artifactId>cucumber-java</artifactId>\n      <scope>test</scope>\n    </dependency>\n    <dependency>\n      <groupId>io.cucumber</groupId>\n      <artifactId>cucumber-spring</artifactId>\n      <scope>test</scope>\n    </dependency>\n    <dependency>\n      <groupId>io.cucumber</groupId>\n      <artifactId>cucumber-junit-platform-engine</artifactId>\n      <scope>test</scope>\n    </dependency>\n    <dependency>\n      <groupId>org.junit.platform</groupId>\n      <artifactId>junit-platform-suite</artifactId>\n      <scope>test</scope>\n    </dependency>\n    <dependency>\n      <groupId>org.postgresql</groupId>\n      <artifactId>postgresql</artifactId>\n      <scope>runtime</scope>\n    </dependency>\n  </dependencies>\n\n  <build>\n    <plugins>",
      "note": "Sem mudança: o springdoc e as dependências de teste das aulas 18 a 21."
    },
    {
      "code": "      <plugin>\n        <groupId>org.springframework.boot</groupId>\n        <artifactId>spring-boot-maven-plugin</artifactId>\n        <executions>\n          <execution>\n            <goals>\n              <goal>build-info</goal>\n            </goals>\n          </execution>\n        </executions>\n      </plugin>",
      "note": "Novo: o goal `build-info` do plugin do Spring Boot grava `META-INF/build-info.properties` dentro do jar a cada build. O endpoint `info` lê esse arquivo, e assim uma aplicação rodando consegue dizer de qual build ela é."
    },
    {
      "code": "      <plugin>\n        <groupId>org.apache.maven.plugins</groupId>\n        <artifactId>maven-dependency-plugin</artifactId>\n        <executions>\n          <execution>\n            <goals>\n              <goal>properties</goal>\n            </goals>\n          </execution>\n        </executions>\n      </plugin>\n      <plugin>\n        <groupId>org.apache.maven.plugins</groupId>\n        <artifactId>maven-surefire-plugin</artifactId>\n        <configuration>\n          <argLine>-javaagent:${org.mockito:mockito-core:jar} --enable-native-access=ALL-UNNAMED</argLine>\n        </configuration>\n      </plugin>\n      <plugin>\n        <groupId>org.apache.maven.plugins</groupId>\n        <artifactId>maven-failsafe-plugin</artifactId>\n        <configuration>\n          <argLine>-javaagent:${org.mockito:mockito-core:jar} --enable-native-access=ALL-UNNAMED</argLine>\n        </configuration>\n        <executions>\n          <execution>\n            <goals>\n              <goal>integration-test</goal>\n              <goal>verify</goal>\n            </goals>\n          </execution>\n        </executions>\n      </plugin>\n      <plugin>\n        <groupId>org.apache.maven.plugins</groupId>\n        <artifactId>maven-javadoc-plugin</artifactId>\n        <configuration>\n          <show>public</show>\n          <doclint>all,-missing</doclint>\n        </configuration>\n      </plugin>\n    </plugins>\n  </build>\n</project>",
      "note": "Sem mudança: os plugins das aulas 17 e 19."
    }
  ]
}
```

## As propriedades

Substitua `src/main/resources/application.properties`:

```schooling-example
{
  "language": "properties",
  "file": "application.properties",
  "parts": [
    {
      "code": "spring.application.name=bookshop\n\nspring.datasource.url=jdbc:postgresql://localhost:5432/bookshop\nspring.datasource.username=bookshop\nspring.datasource.password=bookshop\nspring.datasource.hikari.pool-name=bookshop-pool\nspring.datasource.hikari.maximum-pool-size=10\nspring.datasource.hikari.connection-timeout=5000\n\nspring.jpa.hibernate.ddl-auto=validate\nspring.jpa.open-in-view=false\n\nbookshop.jwt.secret=${BOOKSHOP_JWT_SECRET}\nbookshop.jwt.lifetime=15m\n\nlogging.pattern.correlation=[%X{requestId:-}] \n",
      "note": "Sem mudança desde a aula 16."
    },
    {
      "code": "management.server.port=8081\nmanagement.server.address=127.0.0.1",
      "note": "Os endpoints ganham um Tomcat só deles, na porta 8081, escutando apenas no endereço de loopback. Nada fora da máquina consegue abrir uma conexão com ele."
    },
    {
      "code": "management.endpoints.web.exposure.include=health,info,metrics,prometheus",
      "note": "Quais endpoints respondem por HTTP. Sem esta linha, só o `health` responde."
    },
    {
      "code": "management.endpoint.health.show-details=always",
      "note": "O `health` lista o que verificou e o que cada verificação encontrou, para quem alcançar a porta. O padrão, `never`, mostra só o status geral."
    },
    {
      "code": "management.endpoint.health.probes.enabled=true",
      "note": "Acrescenta os grupos `liveness` e `readiness`. O Boot liga esses grupos sozinho quando detecta o Kubernetes; esta linha liga em qualquer lugar."
    },
    {
      "code": "management.info.java.enabled=true",
      "note": "Acrescenta o runtime Java ao que o `info` informa."
    }
  ]
}
```

As duas primeiras linhas de `management` são a decisão do começo desta seção. Com
**`management.server.port`** definido, o Boot sobe um segundo servidor web dentro do mesmo processo,
só para os endpoints, e **`management.server.address`** prende esse servidor a `127.0.0.1`. O que
escuta no endereço de loopback só pode ser alcançado da própria máquina, então os endpoints não
precisam de senha: a rede é a tranca. Um agente que coleta os números roda ao lado da aplicação, e a
aula 23 mostra como um contêiner publica esta porta para a própria máquina e para mais ninguém.

A linha de exposição é a segunda cerca. O Actuator tem mais de vinte endpoints, e um endpoint que não
está em `management.endpoints.web.exposure.include` não tem URL nenhuma. Quatro estão na lista:
`health`, `info`, `metrics` e `prometheus`. `env`, `beans`, `heapdump` e o resto continuam desligados,
mesmo na porta privada, porque o que não existe não tem como ser mal configurado mais tarde.

## A regra de segurança

A porta privada continua dentro da aplicação, e a filter chain da aula 15 também a cobre. Sem uma
regra própria, todo endpoint pediria um bearer token. Substitua
`src/main/java/com/example/bookshop/security/SecurityConfig.java`:

```schooling-example
{
  "language": "java",
  "file": "SecurityConfig.java",
  "parts": [
    {
      "code": "package com.example.bookshop.security;\n\nimport java.nio.charset.StandardCharsets;\n\nimport javax.crypto.SecretKey;\nimport javax.crypto.spec.SecretKeySpec;\n\nimport org.springframework.boot.context.properties.EnableConfigurationProperties;"
    },
    {
      "code": "import org.springframework.boot.security.autoconfigure.actuate.web.servlet.EndpointRequest;",
      "note": "Novo: `EndpointRequest` é um request matcher que sabe onde estão os endpoints do Actuator, qualquer que seja a porta e o caminho base que receberam."
    },
    {
      "code": "import org.springframework.context.annotation.Bean;\nimport org.springframework.context.annotation.Configuration;\nimport org.springframework.core.annotation.Order;\nimport org.springframework.http.HttpMethod;\nimport org.springframework.security.config.Customizer;\nimport org.springframework.security.config.annotation.web.builders.HttpSecurity;\nimport org.springframework.security.config.http.SessionCreationPolicy;\nimport org.springframework.security.core.userdetails.User;\nimport org.springframework.security.core.userdetails.UserDetailsService;\nimport org.springframework.security.crypto.factory.PasswordEncoderFactories;\nimport org.springframework.security.crypto.password.PasswordEncoder;\nimport org.springframework.security.oauth2.jose.jws.MacAlgorithm;\nimport org.springframework.security.oauth2.jwt.JwtDecoder;\nimport org.springframework.security.oauth2.jwt.JwtEncoder;\nimport org.springframework.security.oauth2.jwt.NimbusJwtDecoder;\nimport org.springframework.security.oauth2.jwt.NimbusJwtEncoder;\nimport org.springframework.security.provisioning.InMemoryUserDetailsManager;\nimport org.springframework.security.web.SecurityFilterChain;\n\n@Configuration\n@EnableConfigurationProperties(JwtProperties.class)\npublic class SecurityConfig {\n\n    @Bean\n    @Order(1)\n    SecurityFilterChain tokenChain(HttpSecurity http) throws Exception {\n        http.securityMatcher(\"/auth/token\")\n                .authorizeHttpRequests(auth -> auth.anyRequest().authenticated())\n                .httpBasic(Customizer.withDefaults())\n                .csrf(csrf -> csrf.disable())\n                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS));\n        return http.build();\n    }\n\n    @Bean\n    @Order(2)\n    SecurityFilterChain apiChain(HttpSecurity http) throws Exception {\n        http.authorizeHttpRequests(auth -> auth\n                        .requestMatchers(HttpMethod.GET, \"/books\", \"/books/**\").permitAll()\n                        .requestMatchers(\"/v3/api-docs/**\", \"/swagger-ui/**\", \"/swagger-ui.html\").permitAll()"
    },
    {
      "code": "                        .requestMatchers(EndpointRequest.toAnyEndpoint()).permitAll()",
      "note": "Novo: todo endpoint exposto fica aberto, sem token. As regras da API abaixo dele não mudam."
    },
    {
      "code": "                        .requestMatchers(HttpMethod.POST, \"/books\").hasAuthority(\"SCOPE_catalogue:write\")\n                        .requestMatchers(\"/orders\", \"/orders/**\").hasAuthority(\"SCOPE_orders\")\n                        .anyRequest().authenticated())\n                .oauth2ResourceServer(o -> o.jwt(Customizer.withDefaults()))\n                .csrf(csrf -> csrf.disable())\n                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS));\n        return http.build();\n    }\n\n    @Bean\n    UserDetailsService users() {\n        return new InMemoryUserDetailsManager(\n                User.withUsername(\"ana\")\n                        .password(\"{bcrypt}$2a$10$ZGOqa4SybKybYWez.kObuOlRJidwtH0M8N11oKrIWVxl4mA422MiG\")\n                        .authorities(\"orders\")\n                        .build(),\n                User.withUsername(\"clerk\")\n                        .password(\"{bcrypt}$2a$10$IhwPr4UgX7fq7bh90QHtOeHgfrzp1Ut63qywnXNfc3YgBAKgO76hS\")\n                        .authorities(\"orders\", \"catalogue:write\")\n                        .build());\n    }\n\n    @Bean\n    PasswordEncoder passwordEncoder() {\n        return PasswordEncoderFactories.createDelegatingPasswordEncoder();\n    }\n\n    @Bean\n    SecretKey jwtKey(JwtProperties properties) {\n        return new SecretKeySpec(properties.secret().getBytes(StandardCharsets.UTF_8), \"HmacSHA256\");\n    }\n\n    @Bean\n    JwtEncoder jwtEncoder(SecretKey jwtKey) {\n        return NimbusJwtEncoder.withSecretKey(jwtKey).build();\n    }\n\n    @Bean\n    JwtDecoder jwtDecoder(SecretKey jwtKey) {\n        return NimbusJwtDecoder.withSecretKey(jwtKey).macAlgorithm(MacAlgorithm.HS256).build();\n    }\n}",
      "note": "Sem mudança desde a aula 17."
    }
  ]
}
```

`EndpointRequest.toAnyEndpoint()` casa com os endpoints expostos, onde quer que estejam, então a
regra sobrevive a uma troca de porta ou de caminho base. Vale ver a linha fazer diferença. Sem ela,
depois de recompilar e reiniciar, a porta privada responde como a API:

```
ana@vm:~/bookshop$ curl -s -i localhost:8081/actuator/health | head -n 3
HTTP/1.1 401 
WWW-Authenticate: Bearer resource_metadata="http://localhost:8081/.well-known/oauth-protected-resource"
X-Content-Type-Options: nosniff
```

## Compilando e subindo

Os testes rodam dentro do `package`, e um deles precisou mudar: o `OrderService` agora recebe mais um
argumento no construtor, que a seção sobre contar pedidos explica. As duas linhas antes do segundo
prompt são os testes unitários rodando: um aviso que a JVM imprime quando o agente do Mockito da aula
19 é carregado, e a linha de log do `OrderServiceTest`. Depois, olhe dentro do jar o que o novo goal
do plugin gravou:

```
ana@vm:~/bookshop$ mvn -q package
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
20:34:21.881 [main] INFO com.example.bookshop.ordering.OrderService -- Order 7 placed by ana: 1 line(s), 3500 cents
ana@vm:~/bookshop$ unzip -p target/bookshop-0.1.0.jar META-INF/build-info.properties
build.artifact=bookshop
build.group=com.example
build.name=bookshop
build.time=2026-10-22T23\:34\:15.997Z
build.version=0.1.0
```

Suba a aplicação no segundo terminal, com `BOOKSHOP_JWT_SECRET` exportado como na aula 15. Agora dois
Tomcats sobem, um depois do outro:

```
2026-10-22T20:34:29.674-03:00  INFO 13286 --- [bookshop] [           main] [] o.s.boot.tomcat.TomcatWebServer          : Tomcat started on port 8080 (http) with context path '/'
2026-10-22T20:34:29.759-03:00  INFO 13286 --- [bookshop] [           main] [] o.s.b.a.e.web.EndpointLinksResolver      : Exposing 4 endpoints beneath base path '/actuator'
2026-10-22T20:34:29.826-03:00  INFO 13286 --- [bookshop] [           main] [] o.s.boot.tomcat.TomcatWebServer          : Tomcat started on port 8081 (http) with context path '/'
```

O próprio `/actuator` lista o que está exposto, com um link para cada um:

```
ana@vm:~/bookshop$ curl -s localhost:8081/actuator | python3 -m json.tool
{
    "_links": {
        "self": {
            "href": "http://localhost:8081/actuator",
            "templated": false
        },
        "info": {
            "href": "http://localhost:8081/actuator/info",
            "templated": false
        },
        "prometheus": {
            "href": "http://localhost:8081/actuator/prometheus",
            "templated": false
        },
        "health": {
            "href": "http://localhost:8081/actuator/health",
            "templated": false
        },
        "health-path": {
            "href": "http://localhost:8081/actuator/health/{*path}",
            "templated": true
        },
        "metrics": {
            "href": "http://localhost:8081/actuator/metrics",
            "templated": false
        },
        "metrics-requiredMetricName": {
            "href": "http://localhost:8081/actuator/metrics/{requiredMetricName}",
            "templated": true
        }
    }
}
```

## O que responde onde

O endereço é a fronteira, e vale testar dos dois lados. No laboratório, o endereço da máquina na rede
é `192.0.2.2`; o seu será outro, e o `hostname -I` mostra qual.

```
ana@vm:~/bookshop$ curl -s -o /dev/null -w "%{http_code}\n" localhost:8080/books
200
ana@vm:~/bookshop$ curl -s -o /dev/null -w "%{http_code}\n" localhost:8081/actuator/health
200
ana@vm:~/bookshop$ curl -s -o /dev/null -w "%{http_code}\n" 192.0.2.2:8080/books
200
ana@vm:~/bookshop$ curl -s -o /dev/null -w "%{http_code}\n" 192.0.2.2:8081/actuator/health
000
ana@vm:~/bookshop$ curl -sS 192.0.2.2:8081/actuator/health
curl: (7) Failed to connect to 192.0.2.2 port 8081 after 0 ms: Couldn't connect to server
```

Da própria máquina, as duas portas respondem. Pelo endereço de rede, a API continua respondendo e a
porta de gerenciamento nem aceita a conexão: o `000` do curl quer dizer que nenhum status HTTP chegou,
e o `-S` faz o curl dizer por quê. Essa recusa vem do sistema operacional, antes de qualquer Java
rodar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 264\" role=\"img\" aria-label=\"Um processo da livraria roda dois servidores web. A porta 8080 escuta em todos os endereços e serve a API com suas regras de token; um cliente em outro ponto da rede chega a ela. A porta 8081 escuta só em 127.0.0.1 e serve os endpoints do Actuator; o mesmo cliente é recusado, e só um comando na própria máquina chega a ela.\"><defs><marker id=\"p2-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"p2-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"170\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"105\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um cliente na rede</text><text x=\"105\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.0.2.x</text><rect x=\"20\" y=\"180\" width=\"170\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"105\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um comando nesta máquina</text><text x=\"105\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">curl localhost:8081</text><rect x=\"300\" y=\"14\" width=\"380\" height=\"236\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"490\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a livraria: um processo, dois servidores</text><rect x=\"320\" y=\"48\" width=\"340\" height=\"72\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"490\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0.0.0.0:8080</text><text x=\"490\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">/books   /orders   /auth/token</text><text x=\"490\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a API, com suas regras de token</text><rect x=\"320\" y=\"150\" width=\"340\" height=\"82\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"490\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">127.0.0.1:8081</text><text x=\"490\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">/actuator/health   /info   /metrics</text><text x=\"490\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">/actuator/prometheus</text><text x=\"490\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Actuator</text><line x1=\"190\" y1=\"62\" x2=\"318\" y2=\"80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#p2-ah)\"></line><line x1=\"190\" y1=\"76\" x2=\"268\" y2=\"150\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#p2-am)\"></line><line x1=\"262\" y1=\"138\" x2=\"280\" y2=\"156\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><line x1=\"280\" y1=\"138\" x2=\"262\" y2=\"156\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><text x=\"240\" y=\"166\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">recusado</text><line x1=\"190\" y1=\"205\" x2=\"318\" y2=\"195\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#p2-ah)\"></line></svg>", "caption": "Um processo, dois servidores. O endereço do servidor de gerenciamento é a fronteira: um cliente na rede não tem caminho nenhum até ele.", "same": ["Actuator"]}
```

A porta pública não tem Actuator, e a primeira resposta dela pode enganar:

```
ana@vm:~/bookshop$ curl -s -o /dev/null -w "%{http_code}\n" localhost:8080/actuator/health
401
ana@vm:~/bookshop$ curl -s -u ana:ana-reads-books -X POST localhost:8080/auth/token | python3 -c 'import json,sys; print(json.load(sys.stdin)["accessToken"])' > ana.token
ana@vm:~/bookshop$ curl -s -o /dev/null -w "%{http_code}\n" -H "Authorization: Bearer $(cat ana.token)" localhost:8080/actuator/health
404
ana@vm:~/bookshop$ curl -s -o /dev/null -w "%{http_code}\n" localhost:8081/actuator/env
401
```

O primeiro `401` não quer dizer que o endpoint está lá e trancado. A filter chain da API pede um token
antes de qualquer coisa procurar um handler, então todo caminho desconhecido na 8080 responde 401 a
um cliente anônimo. Com o token da ana, a mesma requisição chega ao dispatcher e não encontra nada:
`404`. A última linha é a versão da porta privada da mesma coisa. O `env` não está exposto, então não
é um endpoint, então a regra do `EndpointRequest` não casa com ele, e ele cai em
`anyRequest().authenticated()`.

## O perfil `dev` também precisa de uma porta

O perfil `dev` da aula 4 leva a API para a 8081, que agora é a porta do servidor de gerenciamento.
Suba com ele como antes, e a aplicação para durante a inicialização:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.profiles.active=dev | grep -o 'IllegalStateException: .*'
IllegalStateException: Management-specific server address cannot be configured as the management server is not listening on a separate port
IllegalStateException: Management-specific server address cannot be configured as the management server is not listening on a separate port
```

Quando `server.port` e `management.server.port` têm o mesmo número, o Boot não sobe um segundo
servidor: os endpoints entram no servidor da API, em todos os endereços em que ele escuta. Com o
`management.server.address` pedindo só loopback, as duas configurações se contradizem, e o Boot para
em vez de escolher uma. Dê ao perfil uma porta de gerenciamento própria. Substitua
`src/main/resources/application-dev.properties`:

```properties
server.port=8081
management.server.port=8082
logging.level.org.springframework.web=debug
```

Recompile e suba de novo. O segundo terminal mostra os dois servidores, cada um uma porta acima:

```
2026-10-22T20:35:54.469-03:00  INFO 21347 --- [bookshop] [           main] [] o.s.boot.tomcat.TomcatWebServer          : Tomcat started on port 8081 (http) with context path '/'
2026-10-22T20:35:54.692-03:00  INFO 21347 --- [bookshop] [           main] [] o.s.boot.tomcat.TomcatWebServer          : Tomcat started on port 8082 (http) with context path '/'
```

e os endpoints respondem na porta nova:

```
ana@vm:~/bookshop$ curl -s -o /dev/null -w "%{http_code}\n" localhost:8082/actuator/health
200
```

## Que build é este?

O `info` responde a primeira pergunta que alguém faz durante um incidente:

```
ana@vm:~/bookshop$ curl -s localhost:8081/actuator/info | python3 -m json.tool
{
    "build": {
        "artifact": "bookshop",
        "name": "bookshop",
        "time": "2026-10-22T23:34:15.997Z",
        "version": "0.1.0",
        "group": "com.example"
    },
    "java": {
        "jvm": {
            "name": "OpenJDK 64-Bit Server VM",
            "vendor": "Ubuntu",
            "version": "25.0.4.1+1-1-24.04.4-Ubuntu"
        },
        "runtime": {
            "name": "OpenJDK Runtime Environment",
            "version": "25.0.4.1+1-1-24.04.4-Ubuntu"
        },
        "vendor": {
            "name": "Ubuntu"
        },
        "version": "25.0.4.1"
    }
}
```

A parte `build` é o arquivo que o goal do plugin gravou, lido de volta, e `build.time` é quando o
`mvn package` rodou, em UTC. A parte `java` é o que a linha `management.info.java.enabled=true`
acrescentou. Nenhuma das duas muda enquanto o processo roda, então o endpoint é barato, e resolve o
"a correção já está no ar?" sem ninguém ler um log.
