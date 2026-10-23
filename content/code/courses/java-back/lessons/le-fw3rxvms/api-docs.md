---
title: An OpenAPI document from the running application
version: 1
---

The second reader calls the bookshop over HTTP and never opens a Java file: somebody writing the
shop's web page, a partner's team, a program that generates client code. Javadoc is no use to
them. They need to know which paths exist, which methods each path takes, what goes in the query
string and the body, and what comes back, including when it goes wrong.

**OpenAPI** is the standard way to write that down: one document, in JSON or YAML, that describes
every operation of an HTTP API. The specification was called Swagger until it was given to the
OpenAPI Initiative, and the tools around it, Swagger UI among them, kept the old name. The data
inside follows JSON Schema, so a document says not only that `priceCents` is an integer but that
it cannot be negative.

You could write the document by hand, and the last section of this lesson is about teams that do.
This one has a library write it. **springdoc-openapi** looks at the running application, at the
same table of mappings the `DispatcherServlet` uses since lesson 6, and turns it into a document
served at `/v3/api-docs`.

## The dependency

Replace `pom.xml` with this one. The new dependency is `springdoc-openapi-starter-webmvc-ui`, and
its `<build>` is the one from the previous section:

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
    <springdoc.version>3.1.1</springdoc.version>
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
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-flyway</artifactId>
    </dependency>
    <dependency>
      <groupId>org.flywaydb</groupId>
      <artifactId>flyway-database-postgresql</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-security-oauth2-resource-server</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springdoc</groupId>
      <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
      <version>${springdoc.version}</version>
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
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-javadoc-plugin</artifactId>
        <configuration>
          <show>public</show>
          <doclint>all,-missing</doclint>
        </configuration>
      </plugin>
    </plugins>
  </build>
</project>
```

This is the first dependency in the bookshop that carries a version. springdoc is not a Spring
project and the Boot parent does not manage it, so the pom names `3.1.1` once, in a property, as a
team would for any version it has to keep up with by hand. The `-ui` in the name brings Swagger
UI along with the document, and the section on Swagger UI uses it.

Build, restart the application in the second terminal, and ask for the document:

```
ana@vm:~/bookshop$ curl -si -w '\n' localhost:8080/v3/api-docs
HTTP/1.1 401 
X-Request-Id: ebb8c78d
WWW-Authenticate: Bearer resource_metadata="http://localhost:8080/.well-known/oauth-protected-resource"
X-Content-Type-Options: nosniff
X-XSS-Protection: 0
Cache-Control: no-cache, no-store, max-age=0, must-revalidate
Pragma: no-cache
Expires: 0
X-Frame-Options: DENY
Content-Length: 0
Date: Thu, 22 Oct 2026 23:23:07 GMT
```

**401.** The bookshop's `apiChain` from lesson 15 ends with `.anyRequest().authenticated()`, so
any path it does not name is closed, and nobody named this one. That is the default you want: a
new endpoint is locked until somebody decides otherwise. Here somebody decides. Replace
`src/main/java/com/example/bookshop/security/SecurityConfig.java` with this version, where one
line is new, the third `requestMatchers` of `apiChain`:

```java
package com.example.bookshop.security;

import java.nio.charset.StandardCharsets;

import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.factory.PasswordEncoderFactories;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableConfigurationProperties(JwtProperties.class)
public class SecurityConfig {

    @Bean
    @Order(1)
    SecurityFilterChain tokenChain(HttpSecurity http) throws Exception {
        http.securityMatcher("/auth/token")
                .authorizeHttpRequests(auth -> auth.anyRequest().authenticated())
                .httpBasic(Customizer.withDefaults())
                .csrf(csrf -> csrf.disable())
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS));
        return http.build();
    }

    @Bean
    @Order(2)
    SecurityFilterChain apiChain(HttpSecurity http) throws Exception {
        http.authorizeHttpRequests(auth -> auth
                        .requestMatchers(HttpMethod.GET, "/books", "/books/**").permitAll()
                        .requestMatchers("/v3/api-docs/**", "/swagger-ui/**", "/swagger-ui.html").permitAll()
                        .requestMatchers(HttpMethod.POST, "/books").hasAuthority("SCOPE_catalogue:write")
                        .requestMatchers("/orders", "/orders/**").hasAuthority("SCOPE_orders")
                        .anyRequest().authenticated())
                .oauth2ResourceServer(o -> o.jwt(Customizer.withDefaults()))
                .csrf(csrf -> csrf.disable())
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS));
        return http.build();
    }

    @Bean
    UserDetailsService users() {
        return new InMemoryUserDetailsManager(
                User.withUsername("ana")
                        .password("{bcrypt}$2a$10$ZGOqa4SybKybYWez.kObuOlRJidwtH0M8N11oKrIWVxl4mA422MiG")
                        .authorities("orders")
                        .build(),
                User.withUsername("clerk")
                        .password("{bcrypt}$2a$10$IhwPr4UgX7fq7bh90QHtOeHgfrzp1Ut63qywnXNfc3YgBAKgO76hS")
                        .authorities("orders", "catalogue:write")
                        .build());
    }

    @Bean
    PasswordEncoder passwordEncoder() {
        return PasswordEncoderFactories.createDelegatingPasswordEncoder();
    }

    @Bean
    SecretKey jwtKey(JwtProperties properties) {
        return new SecretKeySpec(properties.secret().getBytes(StandardCharsets.UTF_8), "HmacSHA256");
    }

    @Bean
    JwtEncoder jwtEncoder(SecretKey jwtKey) {
        return NimbusJwtEncoder.withSecretKey(jwtKey).build();
    }

    @Bean
    JwtDecoder jwtDecoder(SecretKey jwtKey) {
        return NimbusJwtDecoder.withSecretKey(jwtKey).macAlgorithm(MacAlgorithm.HS256).build();
    }
}
```

`/v3/api-docs/**` covers the document and the paths below it, which springdoc also uses;
`/swagger-ui/**` and `/swagger-ui.html` are the page the section on Swagger UI opens. They are
open to anyone, like the catalogue.

## The first document

Build, restart, and ask again. `python3 -m json.tool` lays the JSON out one value per line:

```
ana@vm:~/bookshop$ curl -s localhost:8080/v3/api-docs | python3 -m json.tool | head -14
{
    "openapi": "3.1.0",
    "info": {
        "title": "OpenAPI definition",
        "version": "v0"
    },
    "servers": [
        {
            "url": "http://localhost:8080",
            "description": "Generated server url"
        }
    ],
    "paths": {
        "/orders": {
```

`"openapi": "3.1.0"` is the version of the specification the document follows. `info` is a
placeholder, because nothing has told springdoc what this API is called. `servers` is the address
it was asked on.

The whole document runs to a few hundred lines, so save it to a file and read it a piece at a time:

```
ana@vm:~/bookshop$ curl -s localhost:8080/v3/api-docs | python3 -m json.tool > ~/api.json
ana@vm:~/bookshop$ wc -l ~/api.json
457 /home/ana/api.json
ana@vm:~/bookshop$ python3 -c 'import json; [print(m.upper(), p) for p, ops in json.load(open("/home/ana/api.json"))["paths"].items() for m in ops]'
POST /orders
GET /books
POST /books
POST /auth/token
GET /orders/{id}
GET /books/{id}
GET /books/search
GET /books/by-author
```

Eight operations, and every one is real. springdoc found the two controllers of the catalogue and
the orders, and the `TokenController` of lesson 15, without an annotation of its own anywhere.

To read one piece, this short program walks into the JSON by the keys you give it and prints what
it finds. Save it as `~/oapi.py`:

```python
import json
import sys

doc = json.load(open(sys.argv[1]))
for key in sys.argv[2:]:
    doc = doc[key]
print(json.dumps(doc, indent=2))
```

## What springdoc worked out on its own

```
ana@vm:~/bookshop$ python3 ~/oapi.py ~/api.json paths /books/{id} get
{
  "tags": [
    "book-controller"
  ],
  "operationId": "get_1",
  "parameters": [
    {
      "name": "id",
      "in": "path",
      "required": true,
      "schema": {
        "type": "integer",
        "format": "int64"
      }
    }
  ],
  "responses": {
    "200": {
      "description": "OK",
      "content": {
        "*/*": {
          "schema": {
            "$ref": "#/components/schemas/BookResponse"
          }
        }
      }
    }
  }
}
```

Everything here came from the code. The path and the `id` parameter come from
`@GetMapping("/{id}")` and `@PathVariable`, and `required` is true because a path variable cannot be
left out. `long` became `integer` with `format: int64`, which is how JSON Schema names a 64-bit whole
number. The one response is a 200 whose body is a `BookResponse`, read from the method's return
type, and its media type is `*/*` because the controller never declared one. The tag
`book-controller` is the class's name, and `get_1` is an operation id made unique because
`OrderController` has a method called `get` too.

What is missing is the 404. The method throws `BookNotFoundException`, lesson 7's handler turns it
into a 404, and none of that shows in a signature that returns a `BookResponse`.

The request body of `POST /books` is described by a schema. springdoc built it from the `BookRequest`
record of lesson 6, with the `stock` that lesson 14 added, and from its Bean Validation constraints:

```
ana@vm:~/bookshop$ python3 ~/oapi.py ~/api.json components schemas BookRequest
{
  "type": "object",
  "properties": {
    "isbn": {
      "type": "string"
    },
    "title": {
      "type": "string",
      "maxLength": 200,
      "minLength": 0
    },
    "author": {
      "type": "string",
      "maxLength": 120,
      "minLength": 0
    },
    "priceCents": {
      "type": "integer",
      "format": "int32",
      "minimum": 0
    },
    "stock": {
      "type": "integer",
      "format": "int32",
      "minimum": 0
    }
  },
  "required": [
    "author",
    "isbn",
    "priceCents",
    "stock",
    "title"
  ]
}
```

Each component became a property, and each constraint became the nearest JSON Schema keyword:
`@Size(max = 200)` is `maxLength`, `@PositiveOrZero` is `minimum: 0`, and every `@NotNull` and
`@NotBlank` put its field in `required`. The translation is not exact. `@NotBlank` refuses a title
of three spaces, and the schema says only `minLength: 0`, which three spaces satisfy. `@ValidIsbn`,
lesson 6's own constraint, is not there at all: springdoc knows the standard annotations and
nothing about one somebody wrote. A client that obeys this schema to the letter can still get a
400.

## What it got wrong

A document built from code says what the code says, and some things the code does not say, or
says in a way springdoc cannot read. Three of them are in this document already.

```
ana@vm:~/bookshop$ python3 ~/oapi.py ~/api.json paths /books get parameters
[
  {
    "name": "pageable",
    "in": "query",
    "required": true,
    "schema": {
      "$ref": "#/components/schemas/Pageable"
    }
  }
]
```

One parameter called `pageable`, required, whose value is an object. No client can send that. A
query string holds names and values, and Spring builds the `Pageable` out of three of them, `page`,
`size` and `sort`, each optional, with the defaults from `@PageableDefault`. springdoc saw a
parameter of type `Pageable` and described the type, and a client built from this document would
send a parameter the server never reads.

```
ana@vm:~/bookshop$ python3 ~/oapi.py ~/api.json paths /orders post responses
{
  "200": {
    "description": "OK",
    "content": {
      "*/*": {
        "schema": {
          "$ref": "#/components/schemas/OrderResponse"
        }
      }
    }
  }
}
```

A 200, where `OrderController.place` answers 201, through `ResponseEntity.created(...)`, as `POST
/books` does. The status is chosen at run time, inside the method, and the declaration
`ResponseEntity<OrderResponse>` says nothing about which one it will be. springdoc falls back to
200.

And no operation in the document mentions a token. springdoc reads controllers, not the security
filter chain, so it cannot know that `POST /books` needs `catalogue:write` and that the orders need
`orders`. The next section tells it.

One more thing that is not springdoc's fault. The document is also served as YAML, at
`/v3/api-docs.yaml`, and the rule you just added does not name that path:

```
ana@vm:~/bookshop$ curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/v3/api-docs.yaml
401
```

`/v3/api-docs/**` matches `/v3/api-docs` and everything under it, and `/v3/api-docs.yaml` is
neither. It stays closed, the safe way to be wrong, and this lesson uses the JSON.
