---
title: Um documento OpenAPI tirado da aplicação rodando
version: 1
---

O segundo leitor chama a livraria pelo HTTP e nunca abre um arquivo Java: quem escreve a página web
da loja, a equipe de um parceiro, um programa que gera código cliente. O Javadoc não serve para essas
pessoas. Elas precisam saber que caminhos existem, que métodos cada caminho aceita, o que vai na
query string e no corpo, e o que volta, inclusive quando algo dá errado.

**OpenAPI** é o jeito padrão de escrever isso: um documento, em JSON ou YAML, que descreve cada
operação de uma API HTTP. A especificação se chamava Swagger até ser entregue à OpenAPI Initiative,
e as ferramentas em volta dela, o Swagger UI entre elas, ficaram com o nome antigo. Os dados dentro
dele seguem o JSON Schema, então um documento diz não só que `priceCents` é um inteiro, mas também
que ele não pode ser negativo.

Você poderia escrever o documento à mão, e a última seção desta aula trata das equipes que fazem
isso. Esta deixa uma biblioteca escrevê-lo. O **springdoc-openapi** olha para a aplicação rodando,
para a mesma tabela de mapeamentos que o `DispatcherServlet` usa desde a aula 6, e a transforma num
documento servido em `/v3/api-docs`.

## A dependência

Substitua o `pom.xml` por este. A dependência nova é `springdoc-openapi-starter-webmvc-ui`, e o
`<build>` é o da seção anterior:

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

É a primeira dependência da livraria que traz uma versão. O springdoc não é um projeto Spring e o
parent do Boot não o gerencia, então o pom escreve `3.1.1` uma vez, numa propriedade, como uma
equipe faria com qualquer versão que precisa acompanhar à mão. O `-ui` no nome traz o Swagger UI
junto com o documento, e a seção sobre o Swagger UI o usa.

Gere o build, reinicie a aplicação no segundo terminal e peça o documento:

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

**401.** O `apiChain` da livraria, da aula 15, termina com `.anyRequest().authenticated()`, então
todo caminho que ele não nomeia fica fechado, e ninguém nomeou este. É o padrão que você quer: um
endpoint novo fica trancado até alguém decidir o contrário. Aqui alguém decide. Substitua
`src/main/java/com/example/bookshop/security/SecurityConfig.java` por esta versão, em que uma linha
é nova, o terceiro `requestMatchers` do `apiChain`:

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

`/v3/api-docs/**` cobre o documento e os caminhos abaixo dele, que o springdoc também usa;
`/swagger-ui/**` e `/swagger-ui.html` são a página que a seção sobre o Swagger UI abre. Ficam
abertos a qualquer um, como o catálogo.

## O primeiro documento

Gere o build, reinicie e peça de novo. `python3 -m json.tool` dispõe o JSON com um valor por linha:

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

`"openapi": "3.1.0"` é a versão da especificação que o documento segue. `info` é um texto
provisório, porque nada disse ao springdoc como esta API se chama. `servers` é o endereço em que ele
foi consultado.

O documento inteiro tem algumas centenas de linhas, então salve-o num arquivo e leia um pedaço
de cada vez:

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

Oito operações, e todas são reais. O springdoc encontrou os dois controllers, o do catálogo e o dos
pedidos, e o `TokenController` da aula 15, sem nenhuma anotação própria em lugar algum.

Para ler um pedaço, este programa curto entra no JSON pelas chaves que você passa e imprime o que
encontra. Salve-o como `~/oapi.py`:

```python
import json
import sys

doc = json.load(open(sys.argv[1]))
for key in sys.argv[2:]:
    doc = doc[key]
print(json.dumps(doc, indent=2))
```

## O que o springdoc deduziu sozinho

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

Tudo aqui veio do código. O caminho e o parâmetro `id` vêm de `@GetMapping("/{id}")` e de
`@PathVariable`, e `required` é verdadeiro porque uma variável de caminho não pode faltar. `long`
virou `integer` com `format: int64`, que é como o JSON Schema chama um número inteiro de 64 bits. A
única resposta é um 200 cujo corpo é um `BookResponse`, lido do tipo de retorno do método, e o tipo
de mídia é `*/*` porque o controller nunca declarou um. A tag `book-controller` é o nome da classe,
e `get_1` é um id de operação tornado único porque o `OrderController` também tem um método chamado
`get`.

O que falta é o 404. O método lança `BookNotFoundException`, o tratador da aula 7 a transforma num
404, e nada disso aparece numa assinatura que devolve um `BookResponse`.

O corpo da requisição de `POST /books` é descrito por um schema, montado a partir do record
`BookRequest` da aula 6, com o `stock` que a aula 14 acrescentou, e das restrições de Bean
Validation que ele carrega:

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

Cada componente virou uma propriedade, e cada restrição virou a palavra-chave de JSON Schema mais
próxima: `@Size(max = 200)` é `maxLength`, `@PositiveOrZero` é `minimum: 0`, e todo `@NotNull` e
`@NotBlank` pôs seu campo em `required`. A tradução não é exata. `@NotBlank` recusa um título de
três espaços, e o schema diz só `minLength: 0`, que três espaços satisfazem. `@ValidIsbn`, a
restrição própria da aula 6, nem aparece: o springdoc conhece as anotações padrão e nada sobre uma
que alguém escreveu. Um cliente que obedeça a este schema à risca ainda pode receber um 400.

## O que ele errou

Um documento montado a partir do código diz o que o código diz, e algumas coisas o código não diz,
ou diz de um jeito que o springdoc não consegue ler. Três delas já estão neste documento.

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

Um parâmetro chamado `pageable`, obrigatório, cujo valor é um objeto. Nenhum cliente consegue
enviar isso. Uma query string guarda nomes e valores, e o Spring monta o `Pageable` a partir de três
deles, `page`, `size` e `sort`, todos opcionais, com os padrões de `@PageableDefault`. O springdoc
viu um parâmetro do tipo `Pageable` e descreveu o tipo, e um cliente montado a partir deste
documento enviaria um parâmetro que o servidor nunca lê.

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

Um 200, quando `OrderController.place` responde 201, por meio de `ResponseEntity.created(...)`, como
`POST /books` faz. O status é escolhido em tempo de execução, dentro do método, e a declaração
`ResponseEntity<OrderResponse>` não diz nada sobre qual será. O springdoc recorre ao 200.

E nenhuma operação do documento menciona um token. O springdoc lê os controllers, não a cadeia de
filtros de segurança, então não tem como saber que `POST /books` precisa de `catalogue:write` e que
os pedidos precisam de `orders`. A próxima seção conta isso a ele.

Mais uma coisa, que não é culpa do springdoc. O documento também é servido em YAML, em
`/v3/api-docs.yaml`, e a regra que você acabou de acrescentar não nomeia esse caminho:

```
ana@vm:~/bookshop$ curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/v3/api-docs.yaml
401
```

`/v3/api-docs/**` casa com `/v3/api-docs` e com tudo abaixo dele, e `/v3/api-docs.yaml` não é
nenhum dos dois. Ele continua fechado, que é o jeito seguro de errar, e esta aula usa o JSON.
