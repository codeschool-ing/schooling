---
title: A JWT, and the secret that signs it
version: 1
---

The token `/auth/token` answers with is a **JSON Web Token**, a JWT: a few facts about its holder,
called **claims**, signed so that the server can trust them later without having remembered handing
them out. This section adds the four files that make one, gives the server its secret, and then takes
a real token apart.

## The files

Create `src/main/java/com/example/bookshop/security/TokenController.java`:

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

The answer is a record, so Jackson writes its three components as JSON (lesson 6). Create
`src/main/java/com/example/bookshop/security/TokenResponse.java`:

```java
package com.example.bookshop.security;

public record TokenResponse(String accessToken, String tokenType, long expiresIn) {
}
```

The secret and the lifetime are configuration, bound to a record the way lesson 4 bound properties,
and checked by Bean Validation (lesson 6) at start-up because of `@Validated`. Create
`src/main/java/com/example/bookshop/security/JwtProperties.java`:

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

And replace `src/main/resources/application.properties` with this; the two new lines are the last
two:

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

`15m` is read as a `Duration` of fifteen minutes. **The secret is not in the file.**
`${BOOKSHOP_JWT_SECRET}` tells Spring to take it from the environment variable of that name, because
`application.properties` is committed with the code, and a signing key in a repository is a signing
key everybody with read access holds.

## The secret

**HS256** is HMAC with SHA-256: a keyed hash in which the same secret signs a token and checks it. The
JWT specification asks for a key at least as long as the hash, 256 bits, which is 32 bytes and why
`JwtProperties` refuses fewer than 32 characters. `openssl` makes one from 32 random bytes, written
in base64 so that it can live in an environment variable:

```
ana@vm:~/bookshop$ export BOOKSHOP_JWT_SECRET=$(openssl rand -base64 32); echo ${#BOOKSHOP_JWT_SECRET}
44
```

The 44 characters are the key, as text; the randomness in them is the 32 bytes behind them. Type
the `export` in the terminal you start the application from, then build and start it there:

```sh
mvn -B -q package -DskipTests
java -jar target/bookshop-0.1.0.jar
```

A new secret on every start is acceptable here, and it has a consequence worth seeing later: **every
token signed with the old secret stops working.** A deployment keeps one secret, in whatever holds its
other secrets.

Forget the `export`, in a new terminal, and the application refuses to start:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar | grep -A 10 'APPLICATION FAILED'
APPLICATION FAILED TO START
***************************

Description:

Binding to target com.example.bookshop.security.JwtProperties failed:

    Property: bookshop.jwt.secret
    Value: "${BOOKSHOP_JWT_SECRET}"
    Origin: class path resource [application.properties] from bookshop-0.1.0.jar - 13:21
    Reason: size must be between 32 and 2147483647
```

The value it complains about is the placeholder itself. With no variable to resolve it, Spring bound
the literal text `${BOOKSHOP_JWT_SECRET}`, 22 characters, and `@Size(min = 32)` was the only thing
that noticed. **Without that annotation the bookshop would have started**, and signed every token
with a key that is printed in this lesson. A secret that is too short is refused the same way, and
the `Origin` line now says where the value came from:

```
ana@vm:~/bookshop$ BOOKSHOP_JWT_SECRET=too-short java -jar target/bookshop-0.1.0.jar | grep -A 10 'APPLICATION FAILED'
APPLICATION FAILED TO START
***************************

Description:

Binding to target com.example.bookshop.security.JwtProperties failed:

    Property: bookshop.jwt.secret
    Value: "too-short"
    Origin: System Environment Property "BOOKSHOP_JWT_SECRET"
    Reason: size must be between 32 and 2147483647
```

## Taking a token apart

Ask for a token and keep it in a file, so the next commands can use it. The `python3` at the end of
the pipe picks `accessToken` out of the JSON. **That file is a credential**: anybody who holds it is
ana until it expires, so delete it when you are done.

```
ana@vm:~/bookshop$ curl -s -u ana:ana-reads-books -X POST localhost:8080/auth/token | python3 -c 'import json,sys; print(json.load(sys.stdin)["accessToken"])' > ana.token
ana@vm:~/bookshop$ cat ana.token
eyJraWQiOiJPWk9odmt2Ui1tOVpKOUM3N2xxUm5yN0E0VVMxdk1obkpuR0hLcDl1eGJnIiwiYWxnIjoiSFMyNTYifQ.eyJpc3MiOiJib29rc2hvcCIsInN1YiI6ImFuYSIsImV4cCI6MTc5MjcwODE0NSwiaWF0IjoxNzkyNzA3MjQ1LCJzY29wZSI6Im9yZGVycyJ9.MpSSa089W22PreCSDmsz487vOif-x5m4WV5aRyScMgQ
ana@vm:~/bookshop$ cut -d. -f1 ana.token | basenc -d --base64url; echo
{"kid":"OZOhvkvR-m9ZJ9C77lqRnr7A4US1vMhnJnGHKp9uxbg","alg":"HS256"}basenc: invalid input

ana@vm:~/bookshop$ cut -d. -f2 ana.token | basenc -d --base64url; echo
{"iss":"bookshop","sub":"ana","exp":1792708145,"iat":1792707245,"scope":"orders"}
ana@vm:~/bookshop$ cut -d. -f3 ana.token | basenc -d --base64url | wc -c
basenc: invalid input
32
```

A JWT is three parts separated by dots, each in **base64url**, the variant of base64 that is safe in a
URL. `basenc` decodes it; its `invalid input` is about the `=` padding that base64 normally ends with
and a JWT leaves out, and the text printed before the complaint is complete. The **header** names the
algorithm, `HS256`, and a key id the encoder adds so that a server with several keys knows which one
to check with. The **payload** holds the claims `TokenController` set: `iss`, the issuer; `sub`, the
**subject**, whose token this is; `iat` and `exp`, issued at and expires at, in seconds since 1 January
1970 UTC, 900 apart, which is the fifteen minutes; and `scope`. The **signature** is 32 bytes, the
size of a SHA-256 output.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 840 276\" role=\"img\" aria-label=\"A JWT drawn as three base64url segments separated by dots: header, payload and signature. The header decodes to the algorithm, HS256; the payload decodes to the claims iss, sub, iat, exp and scope; the signature is 32 bytes of HMAC-SHA256 computed over the header, a dot and the payload with the secret. Anyone can decode the first two; only the holder of the secret can produce the third.\"><defs><marker id=\"jw-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"105.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">header</text><rect x=\"20\" y=\"34\" width=\"170\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"105.0\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">base64url</text><text x=\"355.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">payload</text><rect x=\"230\" y=\"34\" width=\"250\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"355.0\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">base64url</text><text x=\"620.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">signature</text><rect x=\"540\" y=\"34\" width=\"160\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">base64url</text><text x=\"210\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--paper)\">.</text><text x=\"520\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--paper)\">.</text><rect x=\"20\" y=\"96\" width=\"170\" height=\"52\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"105\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&quot;alg&quot;:&quot;HS256&quot;</text><text x=\"105\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">&quot;kid&quot;:&quot;…&quot;</text><rect x=\"230\" y=\"96\" width=\"250\" height=\"92\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"355\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&quot;iss&quot;:&quot;bookshop&quot;</text><text x=\"355\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&quot;sub&quot;:&quot;ana&quot;</text><text x=\"355\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&quot;iat&quot;:…  &quot;exp&quot;:…</text><text x=\"355\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&quot;scope&quot;:&quot;orders&quot;</text><rect x=\"540\" y=\"96\" width=\"160\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"620\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">32 bytes</text><line x1=\"105.0\" y1=\"68\" x2=\"105.0\" y2=\"94\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"355.0\" y1=\"68\" x2=\"355.0\" y2=\"94\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"620.0\" y1=\"68\" x2=\"620.0\" y2=\"94\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"250\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">anyone can decode these two: encoded, not encrypted</text><rect x=\"160\" y=\"226\" width=\"420\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"370\" y=\"243\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">HMAC-SHA256(secret, header + &quot;.&quot; + payload)</text><path d=\"M 580 243 C 640 243, 640 180, 630 134\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#jw-ah)\"></path><text x=\"640\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">only the secret can make it</text></svg>", "caption": "Three parts, joined by dots. The header and the payload are only encoded; the signature is what makes the payload trustworthy, because changing one character of it changes the HMAC."}
```

**Encoded is not encrypted.** Anybody who holds a token reads its claims with the command above, so a
claim must never hold what its holder should not see: the subject is a user name here, and the
payload carries nothing else about ana.

## Changing one claim

Reading the payload is allowed. Changing it is what the signature is for. The commands below copy the
payload, give ana the clerk's scope, and put the token back together around the original signature:

```
ana@vm:~/bookshop$ cut -d. -f2 ana.token | basenc -d --base64url | sed 's/"orders"/"catalogue:write orders"/' | basenc --base64url -w0 | tr -d = > payload
ana@vm:~/bookshop$ echo "$(cut -d. -f1 ana.token).$(cat payload).$(cut -d. -f3 ana.token)" > forged.token
ana@vm:~/bookshop$ cut -d. -f2 forged.token | basenc -d --base64url; echo
{"iss":"bookshop","sub":"ana","exp":1792708145,"iat":1792707245,"scope":"catalogue:write orders"}basenc: invalid input

ana@vm:~/bookshop$ curl -si -H "Authorization: Bearer $(cat forged.token)" -H 'Content-Type: application/json' -d '{"isbn":"9786500000078","title":"Emma","author":"Jane Austen","priceCents":3300,"stock":2}' localhost:8080/books
HTTP/1.1 401 
WWW-Authenticate: Bearer error="invalid_token", error_description="An error occurred while attempting to decode the Jwt: Signed JWT rejected: Invalid signature", error_uri="https://tools.ietf.org/html/rfc6750#section-3.1", resource_metadata="http://localhost:8080/.well-known/oauth-protected-resource"
X-Content-Type-Options: nosniff
X-XSS-Protection: 0
Cache-Control: no-cache, no-store, max-age=0, must-revalidate
Pragma: no-cache
Expires: 0
X-Frame-Options: DENY
Content-Length: 0
Date: Thu, 22 Oct 2026 22:14:05 GMT
```

**401, `Invalid signature`.** The decoder computed the HMAC of the header and the edited payload with
its own secret, and the 32 bytes did not match the ones the token carried. Ana can rewrite the
payload however she likes; she cannot write the signature that goes with it, because that takes the
secret. And the answer is 401 rather than 403: the token was refused before any rule was read, so as
far as the server knows, nobody is asking.
