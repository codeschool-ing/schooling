---
title: stub
version: 1
---

```schooling-example
{
  "language": "java",
  "file": "TokenController.java",
  "parts": [
    {
      "code": "package com.example.bookshop.security;\n\nimport java.time.Clock;\nimport java.time.Instant;\nimport java.util.stream.Collectors;\n\nimport org.springframework.security.core.Authentication;\nimport org.springframework.security.core.GrantedAuthority;\nimport org.springframework.security.oauth2.jose.jws.MacAlgorithm;\nimport org.springframework.security.oauth2.jwt.JwsHeader;\nimport org.springframework.security.oauth2.jwt.JwtClaimsSet;\nimport org.springframework.security.oauth2.jwt.JwtEncoder;\nimport org.springframework.security.oauth2.jwt.JwtEncoderParameters;\nimport org.springframework.web.bind.annotation.PostMapping;\nimport org.springframework.web.bind.annotation.RestController;\n\n@RestController\npublic class TokenController {\n\n    private final JwtEncoder encoder;\n    private final JwtProperties properties;\n    private final Clock clock;\n\n    public TokenController(JwtEncoder encoder, JwtProperties properties, Clock clock) {\n        this.encoder = encoder;\n        this.properties = properties;\n        this.clock = clock;\n    }",
      "note": "Constructor injection, as in lesson 5: the encoder `SecurityConfig` declares, the token's lifetime, and the `Clock` bean."
    },
    {
      "code": "\n    @PostMapping(\"/auth/token\")\n    public TokenResponse token(Authentication authentication) {",
      "note": "**By the time this method runs, the password has been checked.** Chain 1's Basic filter did that, and Spring MVC hands the method the resulting `Authentication`."
    },
    {
      "code": "        Instant now = clock.instant();\n        String scope = authentication.getAuthorities().stream()\n                .map(GrantedAuthority::getAuthority)\n                .filter(authority -> !authority.startsWith(\"FACTOR_\"))\n                .sorted()\n                .collect(Collectors.joining(\" \"));",
      "note": "The user's authorities become the `scope` claim, separated by spaces, as OAuth 2.0 writes scopes. Anything starting with `FACTOR_` is left out; the section on scopes says why."
    },
    {
      "code": "        JwtClaimsSet claims = JwtClaimsSet.builder()\n                .issuer(\"bookshop\")\n                .subject(authentication.getName())\n                .issuedAt(now)\n                .expiresAt(now.plus(properties.lifetime()))\n                .claim(\"scope\", scope)\n                .build();",
      "note": "The **claims**: who issued the token, whose it is, when it was issued and when it stops being accepted."
    },
    {
      "code": "        JwsHeader header = JwsHeader.with(MacAlgorithm.HS256).build();\n        String token = encoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue();\n        return new TokenResponse(token, \"Bearer\", properties.lifetime().toSeconds());\n    }\n}",
      "note": "Signed with HS256, and returned with its type and its lifetime in seconds."
    }
  ]
}
```

```java
package com.example.bookshop.security;

public record TokenResponse(String accessToken, String tokenType, long expiresIn) {
}
```

```java
package com.example.bookshop.security;

import java.time.Duration;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

@Validated
@ConfigurationProperties("bookshop.jwt")
public record JwtProperties(@NotNull @Size(min = 32) String secret, @NotNull Duration lifetime) {
}
```

```properties
spring.application.name=bookshop

spring.datasource.url=jdbc:postgresql://localhost:5432/bookshop
spring.datasource.username=bookshop
spring.datasource.password=bookshop
spring.datasource.hikari.pool-name=bookshop-pool
spring.datasource.hikari.maximum-pool-size=10
spring.datasource.hikari.connection-timeout=5000

spring.jpa.hibernate.ddl-auto=validate
spring.jpa.open-in-view=false

bookshop.jwt.secret=${BOOKSHOP_JWT_SECRET}
bookshop.jwt.lifetime=15m
```
