---
title: A chain of filters in front of the controllers
version: 1
---

Since lesson 14 the bookshop takes an order from anybody, and the order itself says who the customer
is. The server believes it. This lesson puts two questions in front of every request and keeps them
apart, because they fail differently. **Authentication** asks who is making the request; a request
that cannot answer gets **401 Unauthorized**. **Authorisation** asks whether that person may do what
the request asks; a request that may not gets **403 Forbidden**. HTTP's names are older than the
distinction and use the wrong word for the first: 401 means "not authenticated".

The lesson changes nine files. Each section shows the ones it explains. The application builds and
starts again once the section on tokens has added its four, and the last section changes three more.
Every transcript after the first was taken with all nine in place, apart from one detour that the
section on scopes marks as such.

## Where the checks run

A common picture puts security inside the controllers: an annotation on a method, an `if` at the top
of it. Spring Security can do that too, but its main mechanism runs earlier. It is a set of **servlet
filters**, objects Tomcat calls in order before it hands a request to Spring MVC's
`DispatcherServlet` (lesson 6). A request refused by a filter never reaches a controller, and never
reaches lesson 7's `ApiErrorHandler` either.

The starter alone is enough to see them work. Replace `pom.xml` with this; the one new dependency is
`spring-boot-starter-security-oauth2-resource-server`, which brings Spring Security and the part of
it that accepts JWTs. A **resource server**, in OAuth 2.0's vocabulary, is an API that takes a token
with each request and checks it:

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

Build it (`-q` keeps Maven silent unless something fails), start it in the second terminal as in
lesson 14, and ask for a book. In lesson 14 anybody could:

```
ana@vm:~/bookshop$ mvn -B -q package -DskipTests
ana@vm:~/bookshop$ curl -si -w '\n' localhost:8080/books/1
HTTP/1.1 401 
Set-Cookie: JSESSIONID=CB3589EA4E2D46C6064300D8FD44DAF0; Path=/; HttpOnly
WWW-Authenticate: Basic realm="Realm", charset="UTF-8"
X-Content-Type-Options: nosniff
X-XSS-Protection: 0
Cache-Control: no-cache, no-store, max-age=0, must-revalidate
Pragma: no-cache
Expires: 0
X-Frame-Options: DENY
Content-Length: 0
Date: Thu, 22 Oct 2026 22:12:04 GMT
```

A **401**, an empty body, and a `WWW-Authenticate` header naming the scheme the server would accept,
here HTTP Basic. That is Spring Boot's default chain: every request must be authenticated, and nothing
yet says which ones are public, so none is. Two more things arrived with the starter. A `JSESSIONID`
cookie, because the default chain keeps a session on the server; the section on sessions removes it.
And five **security headers**, sent on every response from now on: `nosniff` stops a browser guessing
a content type, `X-Frame-Options: DENY` stops another site framing these pages, and the three
`Cache-Control`, `Pragma` and `Expires` lines keep answers that may be personal out of caches.

## Two chains, one per request

A filter chain has a matcher that decides which requests it owns, and the application may have
several. `FilterChainProxy`, the one filter Spring Security registers with Tomcat, asks them in order
and hands the request to **the first chain that matches, and to no other**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 840 290\" role=\"img\" aria-label=\"A request reaches FilterChainProxy, which hands it to the first chain that matches. Chain 1 owns /auth/token and runs BasicAuthenticationFilter then AuthorizationFilter; chain 2 owns every other request and runs BearerTokenAuthenticationFilter then AuthorizationFilter. A request that passes reaches the DispatcherServlet and a controller. A failed authentication is answered 401 and a refused authorisation 403, from inside the chain.\"><defs><marker id=\"fc-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"128\" width=\"84\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"52\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a request</text><rect x=\"114\" y=\"118\" width=\"150\" height=\"64\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"189\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">FilterChainProxy</text><text x=\"189\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">first chain that matches</text><text x=\"290\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">chain 1: only /auth/token</text><rect x=\"290\" y=\"40\" width=\"210\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"395\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">BasicAuthenticationFilter</text><rect x=\"520\" y=\"40\" width=\"140\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">AuthorizationFilter</text><text x=\"290\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">chain 2: every other request</text><rect x=\"290\" y=\"212\" width=\"210\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"395\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">BearerTokenAuthenticationFilter</text><rect x=\"520\" y=\"212\" width=\"140\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">AuthorizationFilter</text><rect x=\"690\" y=\"118\" width=\"140\" height=\"64\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"760\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">DispatcherServlet</text><text x=\"760\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">your controllers</text><path d=\"M 94 150 L 112 150\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fc-ah)\"></path><path d=\"M 264 140 C 276 140, 270 62, 288 62\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fc-ah)\"></path><path d=\"M 264 160 C 276 160, 270 234, 288 234\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fc-ah)\"></path><path d=\"M 500 62 L 518 62\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fc-ah)\"></path><path d=\"M 500 234 L 518 234\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fc-ah)\"></path><path d=\"M 660 62 C 680 62, 670 135, 688 138\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fc-ah)\"></path><path d=\"M 660 234 C 680 234, 670 165, 688 162\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fc-ah)\"></path><text x=\"395\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">wrong password: 401</text><text x=\"590\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">not signed in: 401</text><text x=\"395\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">missing or bad token: 401</text><text x=\"590\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">no such authority: 403</text></svg>", "caption": "Every request goes through the filters of exactly one chain before Spring MVC sees it. A 401 or a 403 is answered from inside the chain, so no controller runs and neither does lesson 7's error handler."}
```

The bookshop has two because it has two ways in. `/auth/token` takes a user name and a password and
answers with a token; every other request takes that token. Create
`src/main/java/com/example/bookshop/security/SecurityConfig.java`:

```schooling-example
{
  "language": "java",
  "file": "SecurityConfig.java",
  "parts": [
    {
      "code": "package com.example.bookshop.security;\n\nimport java.nio.charset.StandardCharsets;\n\nimport javax.crypto.SecretKey;\nimport javax.crypto.spec.SecretKeySpec;\n\nimport org.springframework.boot.context.properties.EnableConfigurationProperties;\nimport org.springframework.context.annotation.Bean;\nimport org.springframework.context.annotation.Configuration;\nimport org.springframework.core.annotation.Order;\nimport org.springframework.http.HttpMethod;\nimport org.springframework.security.config.Customizer;\nimport org.springframework.security.config.annotation.web.builders.HttpSecurity;\nimport org.springframework.security.config.http.SessionCreationPolicy;\nimport org.springframework.security.core.userdetails.User;\nimport org.springframework.security.core.userdetails.UserDetailsService;\nimport org.springframework.security.crypto.factory.PasswordEncoderFactories;\nimport org.springframework.security.crypto.password.PasswordEncoder;\nimport org.springframework.security.oauth2.jose.jws.MacAlgorithm;\nimport org.springframework.security.oauth2.jwt.JwtDecoder;\nimport org.springframework.security.oauth2.jwt.JwtEncoder;\nimport org.springframework.security.oauth2.jwt.NimbusJwtDecoder;\nimport org.springframework.security.oauth2.jwt.NimbusJwtEncoder;\nimport org.springframework.security.provisioning.InMemoryUserDetailsManager;\nimport org.springframework.security.web.SecurityFilterChain;\n\n@Configuration\n@EnableConfigurationProperties(JwtProperties.class)\npublic class SecurityConfig {",
      "note": "**A configuration class**, as in lesson 5. `@EnableConfigurationProperties` makes `JwtProperties` a bean, bound from the `bookshop.jwt.*` properties and validated before anything else starts."
    },
    {
      "code": "\n    @Bean\n    @Order(1)\n    SecurityFilterChain tokenChain(HttpSecurity http) throws Exception {\n        http.securityMatcher(\"/auth/token\")\n                .authorizeHttpRequests(auth -> auth.anyRequest().authenticated())\n                .httpBasic(Customizer.withDefaults())\n                .csrf(csrf -> csrf.disable())\n                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS));\n        return http.build();\n    }",
      "note": "**Chain 1, for `/auth/token` alone.** `securityMatcher` decides which requests this chain owns, and `@Order(1)` makes it the first one asked. Its one way in is HTTP Basic: a user name and a password, checked against the users below."
    },
    {
      "code": "\n    @Bean\n    @Order(2)\n    SecurityFilterChain apiChain(HttpSecurity http) throws Exception {\n        http.authorizeHttpRequests(auth -> auth\n                        .requestMatchers(HttpMethod.GET, \"/books\", \"/books/**\").permitAll()\n                        .requestMatchers(HttpMethod.POST, \"/books\").hasAuthority(\"SCOPE_catalogue:write\")\n                        .requestMatchers(\"/orders\", \"/orders/**\").hasAuthority(\"SCOPE_orders\")\n                        .anyRequest().authenticated())\n                .oauth2ResourceServer(o -> o.jwt(Customizer.withDefaults()))\n                .csrf(csrf -> csrf.disable())\n                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS));\n        return http.build();\n    }",
      "note": "**Chain 2, for every other request.** It has no matcher, so it takes whatever chain 1 did not. The rules are read from the top and the first that matches decides. `oauth2ResourceServer` adds the filter that reads a bearer token."
    },
    {
      "code": "\n    @Bean\n    UserDetailsService users() {\n        return new InMemoryUserDetailsManager(\n                User.withUsername(\"ana\")\n                        .password(\"{bcrypt}$2a$10$ZGOqa4SybKybYWez.kObuOlRJidwtH0M8N11oKrIWVxl4mA422MiG\")\n                        .authorities(\"orders\")\n                        .build(),\n                User.withUsername(\"clerk\")\n                        .password(\"{bcrypt}$2a$10$IhwPr4UgX7fq7bh90QHtOeHgfrzp1Ut63qywnXNfc3YgBAKgO76hS\")\n                        .authorities(\"orders\", \"catalogue:write\")\n                        .build());\n    }",
      "note": "**Two users, kept in memory**, each with a bcrypt hash of the password and the authorities that will become the token's scopes. The next section shows how the hashes were made."
    },
    {
      "code": "\n    @Bean\n    PasswordEncoder passwordEncoder() {\n        return PasswordEncoderFactories.createDelegatingPasswordEncoder();\n    }",
      "note": "The **delegating** encoder reads the `{bcrypt}` prefix of a stored password and hands the check to the encoder that prefix names."
    },
    {
      "code": "\n    @Bean\n    SecretKey jwtKey(JwtProperties properties) {\n        return new SecretKeySpec(properties.secret().getBytes(StandardCharsets.UTF_8), \"HmacSHA256\");\n    }\n\n    @Bean\n    JwtEncoder jwtEncoder(SecretKey jwtKey) {\n        return NimbusJwtEncoder.withSecretKey(jwtKey).build();\n    }\n\n    @Bean\n    JwtDecoder jwtDecoder(SecretKey jwtKey) {\n        return NimbusJwtDecoder.withSecretKey(jwtKey).macAlgorithm(MacAlgorithm.HS256).build();\n    }\n}",
      "note": "**One key, two jobs.** The secret becomes an HMAC-SHA256 key; the encoder signs tokens with it and the decoder checks them with it. The decoder is told to accept HS256 and nothing else."
    }
  ]
}
```

Each chain is assembled from Spring's filters by the calls on `http`: `httpBasic` adds the filter that
reads a Basic header, `oauth2ResourceServer` the one that reads a bearer token, `authorizeHttpRequests`
the one that applies the rules. To see the result, start the application with one logger at
`DEBUG`. That needs the secret the section on tokens sets, so come back to this once it has.
`timeout` stops the application after forty seconds, and `grep` keeps the line that logger writes for
each chain at start-up, split at its commas:

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

Twelve filters in the first chain and thirteen in the second, in an order Spring Security fixes
rather than the order of the calls on `http`. Most of them are housekeeping every chain gets. The
three that decide are the ones in the figure: `BasicAuthenticationFilter` in the first chain,
`BearerTokenAuthenticationFilter` in the second, and `AuthorizationFilter` at the end of both. Two
more explain what you will see in the answers. `HeaderWriterFilter` writes the security headers, and
`ExceptionTranslationFilter` turns a refusal from `AuthorizationFilter` into the 401 or the 403.
`OAuth2ProtectedResourceMetadataFilter` serves a document describing this API to OAuth clients, at
the address the section on scopes finds in a `WWW-Authenticate` header.
