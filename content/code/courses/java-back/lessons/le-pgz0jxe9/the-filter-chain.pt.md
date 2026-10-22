---
title: Uma cadeia de filtros na frente dos controllers
version: 1
---

Desde a aula 14 a livraria aceita pedido de qualquer um, e o próprio pedido diz quem é o cliente. O
servidor acredita. Esta aula põe duas perguntas na frente de toda requisição e as mantém separadas,
porque elas falham de jeitos diferentes. A **autenticação** pergunta quem está fazendo a requisição;
uma requisição que não sabe responder recebe **401 Unauthorized**. A **autorização** pergunta se essa
pessoa pode fazer o que a requisição pede; uma requisição que não pode recebe **403 Forbidden**. Os
nomes do HTTP são mais antigos que essa distinção e usam a palavra errada no primeiro: 401 quer dizer
"não autenticado".

A aula muda nove arquivos. Cada seção mostra os que explica. A aplicação volta a compilar e subir
quando a seção sobre tokens acrescenta os quatro dela, e a última seção muda mais três. Toda
transcrição depois da primeira foi feita com os nove no lugar, fora um desvio que a seção sobre
escopos marca como tal.

## Onde as verificações rodam

Uma imagem comum põe a segurança dentro dos controllers: uma anotação num método, um `if` no começo
dele. O Spring Security também faz isso, mas o mecanismo principal dele roda antes. É um conjunto de
**filtros de servlet**, objetos que o Tomcat chama em ordem antes de entregar a requisição ao
`DispatcherServlet` do Spring MVC (aula 6). Uma requisição recusada por um filtro nunca chega a um
controller, e nunca chega ao `ApiErrorHandler` da aula 7 também.

Só o starter já basta para vê-los trabalhando. Substitua o `pom.xml` por este; a única dependência
nova é `spring-boot-starter-security-oauth2-resource-server`, que traz o Spring Security e a parte
dele que aceita JWTs. Um **resource server**, no vocabulário do OAuth 2.0, é uma API que recebe um
token em cada requisição e o confere:

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
    </plugins>
  </build>
</project>
```

Compile (o `-q` deixa o Maven calado a menos que algo falhe), suba a aplicação no segundo terminal
como na aula 14 e peça um livro. Na aula 14 qualquer um conseguia:

```
ana@vm:~/bookshop$ mvn -B -q package -DskipTests
ana@vm:~/bookshop$ curl -si -w '\n' localhost:8080/books/1
HTTP/1.1 401 
Set-Cookie: JSESSIONID=B2E681B3D4149A44D69DDAE867AB6FCC; Path=/; HttpOnly
WWW-Authenticate: Basic realm="Realm", charset="UTF-8"
X-Content-Type-Options: nosniff
X-XSS-Protection: 0
Cache-Control: no-cache, no-store, max-age=0, must-revalidate
Pragma: no-cache
Expires: 0
X-Frame-Options: DENY
Content-Length: 0
Date: Thu, 22 Oct 2026 22:47:31 GMT
```

Um **401**, corpo vazio e um cabeçalho `WWW-Authenticate` nomeando o esquema que o servidor aceitaria,
aqui HTTP Basic. Essa é a cadeia padrão do Spring Boot: toda requisição precisa estar autenticada, e
nada ainda diz quais são públicas, então nenhuma é. Mais duas coisas chegaram com o starter. Um cookie
`JSESSIONID`, porque a cadeia padrão guarda uma sessão no servidor; a seção sobre sessões o remove. E
cinco **cabeçalhos de segurança**, mandados em toda resposta daqui em diante: o `nosniff` impede o
navegador de adivinhar o tipo do conteúdo, o `X-Frame-Options: DENY` impede outro site de pôr estas
páginas num frame, e as três linhas `Cache-Control`, `Pragma` e `Expires` mantêm fora dos caches
respostas que podem ser pessoais.

## Duas cadeias, uma por requisição

Uma cadeia de filtros tem um matcher que decide de quais requisições ela é dona, e a aplicação pode ter
várias. O `FilterChainProxy`, o único filtro que o Spring Security registra no Tomcat, pergunta a elas
em ordem e entrega a requisição **à primeira cadeia que casa, e a nenhuma outra**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 840 290\" role=\"img\" aria-label=\"Uma requisição chega ao FilterChainProxy, que a entrega à primeira cadeia que casa. A cadeia 1 é dona de /auth/token e roda BasicAuthenticationFilter e depois AuthorizationFilter; a cadeia 2 fica com todas as outras requisições e roda BearerTokenAuthenticationFilter e depois AuthorizationFilter. Uma requisição que passa chega ao DispatcherServlet e a um controller. Uma autenticação que falha é respondida com 401 e uma autorização recusada com 403, de dentro da cadeia.\"><defs><marker id=\"fc-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"128\" width=\"84\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"52\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma requisição</text><rect x=\"114\" y=\"118\" width=\"150\" height=\"64\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"189\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">FilterChainProxy</text><text x=\"189\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">primeira cadeia que casa</text><text x=\"290\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cadeia 1: só /auth/token</text><rect x=\"290\" y=\"40\" width=\"210\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"395\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">BasicAuthenticationFilter</text><rect x=\"520\" y=\"40\" width=\"140\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">AuthorizationFilter</text><text x=\"290\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cadeia 2: todas as outras requisições</text><rect x=\"290\" y=\"212\" width=\"210\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"395\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">BearerTokenAuthenticationFilter</text><rect x=\"520\" y=\"212\" width=\"140\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">AuthorizationFilter</text><rect x=\"690\" y=\"118\" width=\"140\" height=\"64\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"760\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">DispatcherServlet</text><text x=\"760\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">seus controllers</text><path d=\"M 94 150 L 112 150\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fc-ah)\"></path><path d=\"M 264 140 C 276 140, 270 62, 288 62\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fc-ah)\"></path><path d=\"M 264 160 C 276 160, 270 234, 288 234\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fc-ah)\"></path><path d=\"M 500 62 L 518 62\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fc-ah)\"></path><path d=\"M 500 234 L 518 234\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fc-ah)\"></path><path d=\"M 660 62 C 680 62, 670 135, 688 138\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fc-ah)\"></path><path d=\"M 660 234 C 680 234, 670 165, 688 162\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fc-ah)\"></path><text x=\"395\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">senha errada: 401</text><text x=\"590\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">não autenticado: 401</text><text x=\"395\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">token ausente ou inválido: 401</text><text x=\"590\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">sem a autoridade: 403</text></svg>", "caption": "Toda requisição passa pelos filtros de exatamente uma cadeia antes de o Spring MVC a ver. Um 401 ou um 403 é respondido de dentro da cadeia, então nenhum controller roda, e o tratador de erros da aula 7 também não.", "same": []}
```

A livraria tem duas porque tem duas entradas. O `/auth/token` recebe usuário e senha e responde com um
token; toda outra requisição recebe esse token. Crie
`src/main/java/com/example/bookshop/security/SecurityConfig.java`:

```schooling-example
{
  "language": "java",
  "file": "SecurityConfig.java",
  "parts": [
    {
      "code": "package com.example.bookshop.security;\n\nimport java.nio.charset.StandardCharsets;\n\nimport javax.crypto.SecretKey;\nimport javax.crypto.spec.SecretKeySpec;\n\nimport org.springframework.boot.context.properties.EnableConfigurationProperties;\nimport org.springframework.context.annotation.Bean;\nimport org.springframework.context.annotation.Configuration;\nimport org.springframework.core.annotation.Order;\nimport org.springframework.http.HttpMethod;\nimport org.springframework.security.config.Customizer;\nimport org.springframework.security.config.annotation.web.builders.HttpSecurity;\nimport org.springframework.security.config.http.SessionCreationPolicy;\nimport org.springframework.security.core.userdetails.User;\nimport org.springframework.security.core.userdetails.UserDetailsService;\nimport org.springframework.security.crypto.factory.PasswordEncoderFactories;\nimport org.springframework.security.crypto.password.PasswordEncoder;\nimport org.springframework.security.oauth2.jose.jws.MacAlgorithm;\nimport org.springframework.security.oauth2.jwt.JwtDecoder;\nimport org.springframework.security.oauth2.jwt.JwtEncoder;\nimport org.springframework.security.oauth2.jwt.NimbusJwtDecoder;\nimport org.springframework.security.oauth2.jwt.NimbusJwtEncoder;\nimport org.springframework.security.provisioning.InMemoryUserDetailsManager;\nimport org.springframework.security.web.SecurityFilterChain;\n\n@Configuration\n@EnableConfigurationProperties(JwtProperties.class)\npublic class SecurityConfig {",
      "note": "**Uma classe de configuração**, como na aula 5. `@EnableConfigurationProperties` transforma `JwtProperties` num bean, preenchido pelas propriedades `bookshop.jwt.*` e validado antes de qualquer outra coisa subir."
    },
    {
      "code": "\n    @Bean\n    @Order(1)\n    SecurityFilterChain tokenChain(HttpSecurity http) throws Exception {\n        http.securityMatcher(\"/auth/token\")\n                .authorizeHttpRequests(auth -> auth.anyRequest().authenticated())\n                .httpBasic(Customizer.withDefaults())\n                .csrf(csrf -> csrf.disable())\n                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS));\n        return http.build();\n    }",
      "note": "**Cadeia 1, só para `/auth/token`.** O `securityMatcher` decide quais requisições são desta cadeia, e o `@Order(1)` faz dela a primeira consultada. A única entrada é HTTP Basic: usuário e senha, conferidos com os usuários mais abaixo."
    },
    {
      "code": "\n    @Bean\n    @Order(2)\n    SecurityFilterChain apiChain(HttpSecurity http) throws Exception {\n        http.authorizeHttpRequests(auth -> auth\n                        .requestMatchers(HttpMethod.GET, \"/books\", \"/books/**\").permitAll()\n                        .requestMatchers(HttpMethod.POST, \"/books\").hasAuthority(\"SCOPE_catalogue:write\")\n                        .requestMatchers(\"/orders\", \"/orders/**\").hasAuthority(\"SCOPE_orders\")\n                        .anyRequest().authenticated())\n                .oauth2ResourceServer(o -> o.jwt(Customizer.withDefaults()))\n                .csrf(csrf -> csrf.disable())\n                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS));\n        return http.build();\n    }",
      "note": "**Cadeia 2, para todas as outras requisições.** Ela não tem matcher, então fica com tudo o que a cadeia 1 não pegou. As regras são lidas de cima para baixo e a primeira que casa decide. O `oauth2ResourceServer` acrescenta o filtro que lê um token bearer."
    },
    {
      "code": "\n    @Bean\n    UserDetailsService users() {\n        return new InMemoryUserDetailsManager(\n                User.withUsername(\"ana\")\n                        .password(\"{bcrypt}$2a$10$ZGOqa4SybKybYWez.kObuOlRJidwtH0M8N11oKrIWVxl4mA422MiG\")\n                        .authorities(\"orders\")\n                        .build(),\n                User.withUsername(\"clerk\")\n                        .password(\"{bcrypt}$2a$10$IhwPr4UgX7fq7bh90QHtOeHgfrzp1Ut63qywnXNfc3YgBAKgO76hS\")\n                        .authorities(\"orders\", \"catalogue:write\")\n                        .build());\n    }",
      "note": "**Dois usuários, guardados em memória**, cada um com o hash bcrypt da senha e as autoridades que viram os escopos do token. A próxima seção mostra como os hashes foram feitos."
    },
    {
      "code": "\n    @Bean\n    PasswordEncoder passwordEncoder() {\n        return PasswordEncoderFactories.createDelegatingPasswordEncoder();\n    }",
      "note": "O codificador **delegante** lê o prefixo `{bcrypt}` da senha guardada e passa a verificação para o codificador que esse prefixo nomeia."
    },
    {
      "code": "\n    @Bean\n    SecretKey jwtKey(JwtProperties properties) {\n        return new SecretKeySpec(properties.secret().getBytes(StandardCharsets.UTF_8), \"HmacSHA256\");\n    }\n\n    @Bean\n    JwtEncoder jwtEncoder(SecretKey jwtKey) {\n        return NimbusJwtEncoder.withSecretKey(jwtKey).build();\n    }\n\n    @Bean\n    JwtDecoder jwtDecoder(SecretKey jwtKey) {\n        return NimbusJwtDecoder.withSecretKey(jwtKey).macAlgorithm(MacAlgorithm.HS256).build();\n    }\n}",
      "note": "**Uma chave, dois trabalhos.** O segredo vira uma chave HMAC-SHA256; o encoder assina os tokens com ela e o decoder os confere com ela. O decoder é configurado para aceitar HS256 e mais nada."
    }
  ]
}
```

Cada cadeia é montada com os filtros do Spring pelas chamadas em `http`: o `httpBasic` acrescenta o
filtro que lê um cabeçalho Basic, o `oauth2ResourceServer` o que lê um token bearer, o
`authorizeHttpRequests` o que aplica as regras. Para ver o resultado, suba a aplicação com um logger em
`DEBUG`. Isso precisa do segredo que a seção sobre tokens define, então volte aqui depois dela. O
`timeout` para a aplicação depois de quarenta segundos, e o `grep` fica com a linha que esse logger
escreve para cada cadeia na subida, quebrada nas vírgulas:

```
ana@vm:~/bookshop$ timeout 40 java -jar target/bookshop-0.1.0.jar --logging.level.org.springframework.security.web.DefaultSecurityFilterChain=debug | grep -o 'Will secure .*' | tr ',' '\n' | sed 's/^ *//'
Will secure Or [PathPattern [/auth/token]] with filters: DisableEncodeUrlFilter
WebAsyncManagerIntegrationFilter
SecurityContextHolderFilter
HeaderWriterFilter
LogoutFilter
BasicAuthenticationFilter
RequestCacheAwareFilter
SecurityContextHolderAwareRequestFilter
AnonymousAuthenticationFilter
SessionManagementFilter
ExceptionTranslationFilter
AuthorizationFilter
Will secure any request with filters: DisableEncodeUrlFilter
WebAsyncManagerIntegrationFilter
SecurityContextHolderFilter
HeaderWriterFilter
LogoutFilter
OAuth2ProtectedResourceMetadataFilter
BearerTokenAuthenticationFilter
RequestCacheAwareFilter
SecurityContextHolderAwareRequestFilter
AnonymousAuthenticationFilter
SessionManagementFilter
ExceptionTranslationFilter
AuthorizationFilter
```

Doze filtros na primeira cadeia e treze na segunda, numa ordem que o Spring Security fixa, e não na
ordem das chamadas em `http`. A maioria é manutenção que toda cadeia ganha. Os três que decidem são os
da figura: `BasicAuthenticationFilter` na primeira cadeia, `BearerTokenAuthenticationFilter` na
segunda e `AuthorizationFilter` no fim das duas. Mais dois explicam o que aparece nas respostas. O
`HeaderWriterFilter` escreve os cabeçalhos de segurança, e o `ExceptionTranslationFilter` transforma
uma recusa do `AuthorizationFilter` no 401 ou no 403. O `OAuth2ProtectedResourceMetadataFilter` serve
um documento que descreve esta API para clientes OAuth, no endereço que a seção sobre escopos encontra
num cabeçalho `WWW-Authenticate`.
