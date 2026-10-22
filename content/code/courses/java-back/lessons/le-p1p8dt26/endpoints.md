---
title: Actuator, on a port of its own
version: 1
---

A process that is running is not the same as an application that works. `ps` can say that the
bookshop's JVM exists; it cannot say whether that JVM still reaches PostgreSQL, how long `GET /books`
takes, or whether orders are being refused. Only the application knows those things, so the
application has to be asked. **Spring Boot Actuator** is the module that answers: a set of
**endpoints** under `/actuator` that report on the application itself rather than on books.

Some of those endpoints say a great deal. `env` lists every configuration property and where it came
from; `heapdump` hands over a copy of the process's memory, where the JWT secret and the database
password sit in plain text. So the first decision is not which endpoints to turn on but **who can
reach them**, and the bookshop's answer is: nobody outside the machine.

## Two dependencies and one plugin goal

Replace `pom.xml` with this. The notes mark the two places that changed:

```schooling-example
{
  "language": "xml",
  "file": "pom.xml",
  "parts": [
    {
      "code": "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<project xmlns=\"http://maven.apache.org/POM/4.0.0\"\n         xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n         xsi:schemaLocation=\"http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd\">\n  <modelVersion>4.0.0</modelVersion>\n\n  <parent>\n    <groupId>org.springframework.boot</groupId>\n    <artifactId>spring-boot-starter-parent</artifactId>\n    <version>4.1.1</version>\n    <relativePath/>\n  </parent>\n\n  <groupId>com.example</groupId>\n  <artifactId>bookshop</artifactId>\n  <version>0.1.0</version>\n\n  <properties>\n    <java.version>25</java.version>\n    <springdoc.version>3.1.1</springdoc.version>\n    <rest-assured.version>6.1.0</rest-assured.version>\n    <cucumber.version>8.0.4</cucumber.version>\n  </properties>\n\n  <dependencyManagement>\n    <dependencies>\n      <dependency>\n        <groupId>io.cucumber</groupId>\n        <artifactId>cucumber-bom</artifactId>\n        <version>${cucumber.version}</version>\n        <type>pom</type>\n        <scope>import</scope>\n      </dependency>\n    </dependencies>\n  </dependencyManagement>\n\n  <dependencies>\n    <dependency>\n      <groupId>org.springframework.boot</groupId>\n      <artifactId>spring-boot-starter-webmvc</artifactId>\n    </dependency>\n    <dependency>\n      <groupId>org.springframework.boot</groupId>\n      <artifactId>spring-boot-starter-validation</artifactId>\n    </dependency>\n    <dependency>\n      <groupId>org.springframework.boot</groupId>\n      <artifactId>spring-boot-starter-data-jpa</artifactId>\n    </dependency>\n    <dependency>\n      <groupId>org.springframework.boot</groupId>\n      <artifactId>spring-boot-starter-flyway</artifactId>\n    </dependency>\n    <dependency>\n      <groupId>org.flywaydb</groupId>\n      <artifactId>flyway-database-postgresql</artifactId>\n    </dependency>\n    <dependency>\n      <groupId>org.springframework.boot</groupId>\n      <artifactId>spring-boot-starter-security-oauth2-resource-server</artifactId>\n    </dependency>",
      "note": "As lesson 21 left it: the parent that manages the versions, the properties, and the starters for the web, validation, JPA, Flyway and the resource server."
    },
    {
      "code": "    <dependency>\n      <groupId>org.springframework.boot</groupId>\n      <artifactId>spring-boot-starter-actuator</artifactId>\n    </dependency>\n    <dependency>\n      <groupId>io.micrometer</groupId>\n      <artifactId>micrometer-registry-prometheus</artifactId>\n    </dependency>",
      "note": "New. `spring-boot-starter-actuator` brings the endpoints and **Micrometer**, the library that keeps the numbers. `micrometer-registry-prometheus` adds one more way to hand them over, the `/actuator/prometheus` endpoint. Neither has a version: the parent manages both."
    },
    {
      "code": "    <dependency>\n      <groupId>org.springdoc</groupId>\n      <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>\n      <version>${springdoc.version}</version>\n    </dependency>\n\n    <dependency>\n      <groupId>org.springframework.boot</groupId>\n      <artifactId>spring-boot-starter-test</artifactId>\n      <scope>test</scope>\n    </dependency>\n    <dependency>\n      <groupId>org.springframework.boot</groupId>\n      <artifactId>spring-boot-starter-data-jpa-test</artifactId>\n      <scope>test</scope>\n    </dependency>\n    <dependency>\n      <groupId>org.springframework.boot</groupId>\n      <artifactId>spring-boot-testcontainers</artifactId>\n      <scope>test</scope>\n    </dependency>\n    <dependency>\n      <groupId>org.testcontainers</groupId>\n      <artifactId>testcontainers-junit-jupiter</artifactId>\n      <scope>test</scope>\n    </dependency>\n    <dependency>\n      <groupId>org.testcontainers</groupId>\n      <artifactId>testcontainers-postgresql</artifactId>\n      <scope>test</scope>\n    </dependency>\n    <dependency>\n      <groupId>io.rest-assured</groupId>\n      <artifactId>rest-assured</artifactId>\n      <version>${rest-assured.version}</version>\n      <scope>test</scope>\n    </dependency>\n    <dependency>\n      <groupId>io.cucumber</groupId>\n      <artifactId>cucumber-java</artifactId>\n      <scope>test</scope>\n    </dependency>\n    <dependency>\n      <groupId>io.cucumber</groupId>\n      <artifactId>cucumber-spring</artifactId>\n      <scope>test</scope>\n    </dependency>\n    <dependency>\n      <groupId>io.cucumber</groupId>\n      <artifactId>cucumber-junit-platform-engine</artifactId>\n      <scope>test</scope>\n    </dependency>\n    <dependency>\n      <groupId>org.junit.platform</groupId>\n      <artifactId>junit-platform-suite</artifactId>\n      <scope>test</scope>\n    </dependency>\n    <dependency>\n      <groupId>org.postgresql</groupId>\n      <artifactId>postgresql</artifactId>\n      <scope>runtime</scope>\n    </dependency>\n  </dependencies>\n\n  <build>\n    <plugins>",
      "note": "Unchanged: springdoc, and the test dependencies of lessons 18 to 21."
    },
    {
      "code": "      <plugin>\n        <groupId>org.springframework.boot</groupId>\n        <artifactId>spring-boot-maven-plugin</artifactId>\n        <executions>\n          <execution>\n            <goals>\n              <goal>build-info</goal>\n            </goals>\n          </execution>\n        </executions>\n      </plugin>",
      "note": "New: the `build-info` goal of Spring Boot's plugin writes `META-INF/build-info.properties` into the jar on every build. The `info` endpoint reads it, so a running application can say which build it is."
    },
    {
      "code": "      <plugin>\n        <groupId>org.apache.maven.plugins</groupId>\n        <artifactId>maven-dependency-plugin</artifactId>\n        <executions>\n          <execution>\n            <goals>\n              <goal>properties</goal>\n            </goals>\n          </execution>\n        </executions>\n      </plugin>\n      <plugin>\n        <groupId>org.apache.maven.plugins</groupId>\n        <artifactId>maven-surefire-plugin</artifactId>\n        <configuration>\n          <argLine>-javaagent:${org.mockito:mockito-core:jar} --enable-native-access=ALL-UNNAMED</argLine>\n        </configuration>\n      </plugin>\n      <plugin>\n        <groupId>org.apache.maven.plugins</groupId>\n        <artifactId>maven-failsafe-plugin</artifactId>\n        <configuration>\n          <argLine>-javaagent:${org.mockito:mockito-core:jar} --enable-native-access=ALL-UNNAMED</argLine>\n        </configuration>\n        <executions>\n          <execution>\n            <goals>\n              <goal>integration-test</goal>\n              <goal>verify</goal>\n            </goals>\n          </execution>\n        </executions>\n      </plugin>\n      <plugin>\n        <groupId>org.apache.maven.plugins</groupId>\n        <artifactId>maven-javadoc-plugin</artifactId>\n        <configuration>\n          <show>public</show>\n          <doclint>all,-missing</doclint>\n        </configuration>\n      </plugin>\n    </plugins>\n  </build>\n</project>",
      "note": "Unchanged: the plugins of lessons 17 and 19."
    }
  ]
}
```

## The properties

Replace `src/main/resources/application.properties`:

```schooling-example
{
  "language": "properties",
  "file": "application.properties",
  "parts": [
    {
      "code": "spring.application.name=bookshop\n\nspring.datasource.url=jdbc:postgresql://localhost:5432/bookshop\nspring.datasource.username=bookshop\nspring.datasource.password=bookshop\nspring.datasource.hikari.pool-name=bookshop-pool\nspring.datasource.hikari.maximum-pool-size=10\nspring.datasource.hikari.connection-timeout=5000\n\nspring.jpa.hibernate.ddl-auto=validate\nspring.jpa.open-in-view=false\n\nbookshop.jwt.secret=${BOOKSHOP_JWT_SECRET}\nbookshop.jwt.lifetime=15m\n\nlogging.pattern.correlation=[%X{requestId:-}] \n",
      "note": "Unchanged from lesson 16."
    },
    {
      "code": "management.server.port=8081\nmanagement.server.address=127.0.0.1",
      "note": "The endpoints get a Tomcat of their own, on port 8081, listening only on the loopback address. Nothing outside the machine can open a connection to it."
    },
    {
      "code": "management.endpoints.web.exposure.include=health,info,metrics,prometheus",
      "note": "Which endpoints answer over HTTP. Without this line only `health` does."
    },
    {
      "code": "management.endpoint.health.show-details=always",
      "note": "`health` lists what it checked and what each check found, to anybody who reaches the port. The default, `never`, gives only the overall status."
    },
    {
      "code": "management.endpoint.health.probes.enabled=true",
      "note": "Adds the `liveness` and `readiness` groups. Boot turns them on by itself when it detects Kubernetes; this line turns them on everywhere."
    },
    {
      "code": "management.info.java.enabled=true",
      "note": "Adds the Java runtime to what `info` reports."
    }
  ]
}
```

The first two `management` lines are the decision from the top of this section. With
**`management.server.port`** set, Boot starts a second web server inside the same process, for the
endpoints and nothing else, and **`management.server.address`** binds it to `127.0.0.1`. Whatever
listens on the loopback address can only be reached from the machine itself, so the endpoints need no
password: the network is the lock. An agent that collects the numbers runs beside the application,
and lesson 23 shows how a container publishes this port to its own machine and to nobody else.

The exposure line is the second fence. Actuator has more than twenty endpoints, and an endpoint that
is not in `management.endpoints.web.exposure.include` has no URL at all. Four are listed here:
`health`, `info`, `metrics` and `prometheus`. `env`, `beans`, `heapdump` and the rest stay off, even on
the private port, because something that does not exist cannot be misconfigured later.

## The security rule

The private port is still inside the application, and lesson 15's filter chain covers it too. Without
a rule of its own, every endpoint would ask for a bearer token. Replace
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
      "note": "New: `EndpointRequest` is a request matcher that knows where the Actuator endpoints are, whatever port and base path they were given."
    },
    {
      "code": "import org.springframework.context.annotation.Bean;\nimport org.springframework.context.annotation.Configuration;\nimport org.springframework.core.annotation.Order;\nimport org.springframework.http.HttpMethod;\nimport org.springframework.security.config.Customizer;\nimport org.springframework.security.config.annotation.web.builders.HttpSecurity;\nimport org.springframework.security.config.http.SessionCreationPolicy;\nimport org.springframework.security.core.userdetails.User;\nimport org.springframework.security.core.userdetails.UserDetailsService;\nimport org.springframework.security.crypto.factory.PasswordEncoderFactories;\nimport org.springframework.security.crypto.password.PasswordEncoder;\nimport org.springframework.security.oauth2.jose.jws.MacAlgorithm;\nimport org.springframework.security.oauth2.jwt.JwtDecoder;\nimport org.springframework.security.oauth2.jwt.JwtEncoder;\nimport org.springframework.security.oauth2.jwt.NimbusJwtDecoder;\nimport org.springframework.security.oauth2.jwt.NimbusJwtEncoder;\nimport org.springframework.security.provisioning.InMemoryUserDetailsManager;\nimport org.springframework.security.web.SecurityFilterChain;\n\n@Configuration\n@EnableConfigurationProperties(JwtProperties.class)\npublic class SecurityConfig {\n\n    @Bean\n    @Order(1)\n    SecurityFilterChain tokenChain(HttpSecurity http) throws Exception {\n        http.securityMatcher(\"/auth/token\")\n                .authorizeHttpRequests(auth -> auth.anyRequest().authenticated())\n                .httpBasic(Customizer.withDefaults())\n                .csrf(csrf -> csrf.disable())\n                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS));\n        return http.build();\n    }\n\n    @Bean\n    @Order(2)\n    SecurityFilterChain apiChain(HttpSecurity http) throws Exception {\n        http.authorizeHttpRequests(auth -> auth\n                        .requestMatchers(HttpMethod.GET, \"/books\", \"/books/**\").permitAll()\n                        .requestMatchers(\"/v3/api-docs/**\", \"/swagger-ui/**\", \"/swagger-ui.html\").permitAll()"
    },
    {
      "code": "                        .requestMatchers(EndpointRequest.toAnyEndpoint()).permitAll()",
      "note": "New: every exposed endpoint is open, with no token. The API's rules below it are unchanged."
    },
    {
      "code": "                        .requestMatchers(HttpMethod.POST, \"/books\").hasAuthority(\"SCOPE_catalogue:write\")\n                        .requestMatchers(\"/orders\", \"/orders/**\").hasAuthority(\"SCOPE_orders\")\n                        .anyRequest().authenticated())\n                .oauth2ResourceServer(o -> o.jwt(Customizer.withDefaults()))\n                .csrf(csrf -> csrf.disable())\n                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS));\n        return http.build();\n    }\n\n    @Bean\n    UserDetailsService users() {\n        return new InMemoryUserDetailsManager(\n                User.withUsername(\"ana\")\n                        .password(\"{bcrypt}$2a$10$ZGOqa4SybKybYWez.kObuOlRJidwtH0M8N11oKrIWVxl4mA422MiG\")\n                        .authorities(\"orders\")\n                        .build(),\n                User.withUsername(\"clerk\")\n                        .password(\"{bcrypt}$2a$10$IhwPr4UgX7fq7bh90QHtOeHgfrzp1Ut63qywnXNfc3YgBAKgO76hS\")\n                        .authorities(\"orders\", \"catalogue:write\")\n                        .build());\n    }\n\n    @Bean\n    PasswordEncoder passwordEncoder() {\n        return PasswordEncoderFactories.createDelegatingPasswordEncoder();\n    }\n\n    @Bean\n    SecretKey jwtKey(JwtProperties properties) {\n        return new SecretKeySpec(properties.secret().getBytes(StandardCharsets.UTF_8), \"HmacSHA256\");\n    }\n\n    @Bean\n    JwtEncoder jwtEncoder(SecretKey jwtKey) {\n        return NimbusJwtEncoder.withSecretKey(jwtKey).build();\n    }\n\n    @Bean\n    JwtDecoder jwtDecoder(SecretKey jwtKey) {\n        return NimbusJwtDecoder.withSecretKey(jwtKey).macAlgorithm(MacAlgorithm.HS256).build();\n    }\n}",
      "note": "Unchanged from lesson 17."
    }
  ]
}
```

`EndpointRequest.toAnyEndpoint()` matches the exposed endpoints, wherever they live, so the rule
survives a change of port or of base path. It is worth seeing the line earn its place. With it
removed, rebuilt and restarted, the private port answers like the API:

```
ana@vm:~/bookshop$ curl -s -i localhost:8081/actuator/health | head -n 3
HTTP/1.1 401 
WWW-Authenticate: Bearer resource_metadata="http://localhost:8081/.well-known/oauth-protected-resource"
X-Content-Type-Options: nosniff
```

## Building and starting

The tests run as part of `package`, and one of them had to change: `OrderService` now takes one more
constructor argument, which the section on counting orders explains. The two lines before the second
prompt are the unit tests running: a warning the JVM prints when lesson 19's Mockito agent is loaded,
and the log line of `OrderServiceTest`. Then look inside the jar for what the new plugin goal wrote:

```
ana@vm:~/bookshop$ mvn -q package
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
20:06:16.893 [main] INFO com.example.bookshop.ordering.OrderService -- Order 7 placed by ana: 1 line(s), 3500 cents
ana@vm:~/bookshop$ unzip -p target/bookshop-0.1.0.jar META-INF/build-info.properties
build.artifact=bookshop
build.group=com.example
build.name=bookshop
build.time=2026-10-22T23\:06\:13.402Z
build.version=0.1.0
```

Start the application in the second terminal, with `BOOKSHOP_JWT_SECRET` exported as in lesson 15. Two
Tomcats now start, one after the other:

```
2026-10-22T20:06:23.274-03:00  INFO 6003 --- [bookshop] [           main] [] o.s.boot.tomcat.TomcatWebServer          : Tomcat started on port 8080 (http) with context path '/'
2026-10-22T20:06:23.340-03:00  INFO 6003 --- [bookshop] [           main] [] o.s.b.a.e.web.EndpointLinksResolver      : Exposing 4 endpoints beneath base path '/actuator'
2026-10-22T20:06:23.376-03:00  INFO 6003 --- [bookshop] [           main] [] o.s.boot.tomcat.TomcatWebServer          : Tomcat started on port 8081 (http) with context path '/'
```

`/actuator` itself lists what is exposed, with a link to each:

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

## What answers where

The address is the boundary, and it is worth testing from both sides. In the lab the machine's own
address on the network is `192.0.2.2`; yours will be different, and `hostname -I` prints it.

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

From the machine itself both ports answer. Through the network address, the API still answers and the
management port does not even accept the connection: curl's `000` means no HTTP status ever arrived,
and `-S` makes it say why. That refusal comes from the operating system, before any Java runs.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 264\" role=\"img\" aria-label=\"One bookshop process runs two web servers. Port 8080 listens on every address and serves the API behind its token rules; a client elsewhere on the network reaches it. Port 8081 listens only on 127.0.0.1 and serves the Actuator endpoints; the same client is refused, and only a command on the machine itself reaches it.\"><defs><marker id=\"p2-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"p2-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"170\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"105\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a client on the network</text><text x=\"105\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.0.2.x</text><rect x=\"20\" y=\"180\" width=\"170\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"105\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a command on this machine</text><text x=\"105\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">curl localhost:8081</text><rect x=\"300\" y=\"14\" width=\"380\" height=\"236\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"490\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the bookshop: one process, two servers</text><rect x=\"320\" y=\"48\" width=\"340\" height=\"72\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"490\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0.0.0.0:8080</text><text x=\"490\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">/books   /orders   /auth/token</text><text x=\"490\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the API, with its token rules</text><rect x=\"320\" y=\"150\" width=\"340\" height=\"82\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"490\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">127.0.0.1:8081</text><text x=\"490\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">/actuator/health   /info   /metrics</text><text x=\"490\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">/actuator/prometheus</text><text x=\"490\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Actuator</text><line x1=\"190\" y1=\"62\" x2=\"318\" y2=\"80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#p2-ah)\"></line><line x1=\"190\" y1=\"76\" x2=\"268\" y2=\"150\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#p2-am)\"></line><line x1=\"262\" y1=\"138\" x2=\"280\" y2=\"156\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><line x1=\"280\" y1=\"138\" x2=\"262\" y2=\"156\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><text x=\"240\" y=\"166\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">refused</text><line x1=\"190\" y1=\"205\" x2=\"318\" y2=\"195\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#p2-ah)\"></line></svg>", "caption": "One process, two servers. The management server's address is the boundary: a client on the network has no route to it at all."}
```

The public port has no Actuator on it, and its first answer can mislead:

```
ana@vm:~/bookshop$ curl -s -o /dev/null -w "%{http_code}\n" localhost:8080/actuator/health
401
ana@vm:~/bookshop$ curl -s -u ana:ana-reads-books -X POST localhost:8080/auth/token | python3 -c 'import json,sys; print(json.load(sys.stdin)["accessToken"])' > ana.token
ana@vm:~/bookshop$ curl -s -o /dev/null -w "%{http_code}\n" -H "Authorization: Bearer $(cat ana.token)" localhost:8080/actuator/health
404
ana@vm:~/bookshop$ curl -s -o /dev/null -w "%{http_code}\n" localhost:8081/actuator/env
401
```

The first `401` does not mean the endpoint is there and locked. The API's filter chain asks for a token
before anything looks for a handler, so every unknown path on 8080 answers 401 to an anonymous
client. With ana's token the same request reaches the dispatcher and finds nothing: `404`. The last
line is the private port's version of the same thing. `env` is not exposed, so it is not an endpoint,
so the `EndpointRequest` rule does not match it, and it falls to `anyRequest().authenticated()`.

## The `dev` profile needs a port too

Lesson 4's `dev` profile moves the API to 8081, which is now the management server's port. Start it
as before, and the application stops during start-up:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.profiles.active=dev | grep -o 'IllegalStateException: .*'
IllegalStateException: Management-specific server address cannot be configured as the management server is not listening on a separate port
IllegalStateException: Management-specific server address cannot be configured as the management server is not listening on a separate port
```

When `server.port` and `management.server.port` are the same number, Boot starts no second server:
the endpoints join the API's, on every address it listens on. With `management.server.address`
asking for loopback only, those two settings contradict each other, and Boot stops rather than pick
one. Give the profile a management port of its own. Replace
`src/main/resources/application-dev.properties`:

```properties
server.port=8081
management.server.port=8082
logging.level.org.springframework.web=debug
```

Rebuild and start it again. The second terminal shows both servers, each one port up:

@@FENCE:dev-fixed-log@@

and the endpoints answer on the new port:

```
2026-10-22T20:07:44.726-03:00  INFO 13893 --- [bookshop] [           main] [] o.s.boot.tomcat.TomcatWebServer          : Tomcat started on port 8081 (http) with context path '/'
2026-10-22T20:07:44.876-03:00  INFO 13893 --- [bookshop] [           main] [] o.s.boot.tomcat.TomcatWebServer          : Tomcat started on port 8082 (http) with context path '/'
ana@vm:~/bookshop$ curl -s -o /dev/null -w "%{http_code}\n" localhost:8082/actuator/health
200
```

## Which build is this?

`info` answers the first question anybody asks during an incident:

```
ana@vm:~/bookshop$ curl -s localhost:8081/actuator/info | python3 -m json.tool
{
    "build": {
        "artifact": "bookshop",
        "name": "bookshop",
        "time": "2026-10-22T23:06:13.402Z",
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

The `build` part is the file the plugin goal wrote, read back, and `build.time` is when `mvn package`
ran, in UTC. The `java` part is the line `management.info.java.enabled=true` added. Neither changes
while the process runs, so the endpoint is cheap, and it settles "is the fix deployed?" without
anybody reading a log.
