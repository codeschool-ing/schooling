---
title: stub
version: 1
---

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
