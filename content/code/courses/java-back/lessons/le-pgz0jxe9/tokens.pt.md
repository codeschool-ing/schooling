---
title: Um JWT, e o segredo que o assina
version: 1
---

O token com que o `/auth/token` responde é um **JSON Web Token**, um JWT: alguns fatos sobre quem o
carrega, chamados **claims**, assinados para que o servidor possa confiar neles depois sem ter
lembrado de tê-los entregado. Esta seção acrescenta os quatro arquivos que fazem um, dá ao servidor o
seu segredo e depois desmonta um token de verdade.

## Os arquivos

Crie `src/main/java/com/example/bookshop/security/TokenController.java`:

```schooling-example
{
  "language": "java",
  "file": "TokenController.java",
  "parts": [
    {
      "code": "package com.example.bookshop.security;\n\nimport java.time.Clock;\nimport java.time.Instant;\nimport java.util.stream.Collectors;\n\nimport org.springframework.security.core.Authentication;\nimport org.springframework.security.core.GrantedAuthority;\nimport org.springframework.security.oauth2.jose.jws.MacAlgorithm;\nimport org.springframework.security.oauth2.jwt.JwsHeader;\nimport org.springframework.security.oauth2.jwt.JwtClaimsSet;\nimport org.springframework.security.oauth2.jwt.JwtEncoder;\nimport org.springframework.security.oauth2.jwt.JwtEncoderParameters;\nimport org.springframework.web.bind.annotation.PostMapping;\nimport org.springframework.web.bind.annotation.RestController;\n\n@RestController\npublic class TokenController {\n\n    private final JwtEncoder encoder;\n    private final JwtProperties properties;\n    private final Clock clock;\n\n    public TokenController(JwtEncoder encoder, JwtProperties properties, Clock clock) {\n        this.encoder = encoder;\n        this.properties = properties;\n        this.clock = clock;\n    }",
      "note": "Injeção pelo construtor, como na aula 5: o encoder que o `SecurityConfig` declara, a duração do token e o bean `Clock`."
    },
    {
      "code": "\n    @PostMapping(\"/auth/token\")\n    public TokenResponse token(Authentication authentication) {",
      "note": "**Quando este método roda, a senha já foi conferida.** Quem fez isso foi o filtro Basic da cadeia 1, e o Spring MVC entrega ao método o `Authentication` resultante."
    },
    {
      "code": "        Instant now = clock.instant();\n        String scope = authentication.getAuthorities().stream()\n                .map(GrantedAuthority::getAuthority)\n                .filter(authority -> !authority.startsWith(\"FACTOR_\"))\n                .sorted()\n                .collect(Collectors.joining(\" \"));",
      "note": "As autoridades do usuário viram o claim `scope`, separadas por espaço, como o OAuth 2.0 escreve escopos. O que começa com `FACTOR_` fica de fora; a seção sobre escopos diz por quê."
    },
    {
      "code": "        JwtClaimsSet claims = JwtClaimsSet.builder()\n                .issuer(\"bookshop\")\n                .subject(authentication.getName())\n                .issuedAt(now)\n                .expiresAt(now.plus(properties.lifetime()))\n                .claim(\"scope\", scope)\n                .build();",
      "note": "Os **claims**: quem emitiu o token, de quem ele é, quando foi emitido e quando deixa de ser aceito."
    },
    {
      "code": "        JwsHeader header = JwsHeader.with(MacAlgorithm.HS256).build();\n        String token = encoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue();\n        return new TokenResponse(token, \"Bearer\", properties.lifetime().toSeconds());\n    }\n}",
      "note": "Assinado com HS256 e devolvido com o tipo e a duração em segundos."
    }
  ]
}
```

A resposta é um record, então o Jackson escreve os três componentes como JSON (aula 6). Crie
`src/main/java/com/example/bookshop/security/TokenResponse.java`:

```java
package com.example.bookshop.security;

public record TokenResponse(String accessToken, String tokenType, long expiresIn) {
}
```

O segredo e a duração são configuração, ligados a um record do jeito que a aula 4 ligou propriedades,
e conferidos pela Bean Validation (aula 6) na subida por causa do `@Validated`. Crie
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

E substitua `src/main/resources/application.properties` por este; as duas linhas novas são as duas
últimas:

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

O `15m` é lido como uma `Duration` de quinze minutos. **O segredo não está no arquivo.** O
`${BOOKSHOP_JWT_SECRET}` diz ao Spring para tirá-lo da variável de ambiente com esse nome, porque o
`application.properties` vai para o repositório junto com o código, e uma chave de assinatura num
repositório é uma chave que todo mundo com acesso de leitura tem.

## O segredo

**HS256** é HMAC com SHA-256: um hash com chave em que o mesmo segredo assina um token e o confere. A
especificação do JWT pede uma chave pelo menos do tamanho do hash, 256 bits, que são 32 bytes, e é por
isso que o `JwtProperties` recusa menos de 32 caracteres. O `openssl` faz uma a partir de 32 bytes
aleatórios, escritos em base64 para caber numa variável de ambiente:

```
ana@vm:~/bookshop$ export BOOKSHOP_JWT_SECRET=$(openssl rand -base64 32); echo ${#BOOKSHOP_JWT_SECRET}
44
```

Os 44 caracteres são a chave, como texto; a aleatoriedade neles são os 32 bytes por trás. Digite o
`export` no terminal de onde você sobe a aplicação, e então compile e suba por lá:

```sh
mvn -B -q package -DskipTests
java -jar target/bookshop-0.1.0.jar
```

Um segredo novo a cada subida serve aqui, e tem uma consequência que vale ver depois: **todo token
assinado com o segredo antigo deixa de funcionar.** Uma implantação mantém um segredo só, guardado onde
ela guarda os outros segredos.

Esqueça o `export`, num terminal novo, e a aplicação se recusa a subir:

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

O valor de que ela reclama é o próprio placeholder. Sem variável para resolvê-lo, o Spring usou o texto
literal `${BOOKSHOP_JWT_SECRET}`, 22 caracteres, e o `@Size(min = 32)` foi a única coisa que notou.
**Sem essa anotação a livraria teria subido**, e assinado todo token com uma chave que está impressa
nesta aula. Um segredo curto demais é recusado do mesmo jeito, e a linha `Origin` agora diz de onde o
valor veio:

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

## Desmontando um token

Peça um token e guarde num arquivo, para os próximos comandos o usarem. O `python3` no fim do pipe tira
o `accessToken` do JSON. **Esse arquivo é uma credencial**: quem o tiver é a ana até ele expirar,
então apague quando terminar.

```
ana@vm:~/bookshop$ curl -s -u ana:ana-reads-books -X POST localhost:8080/auth/token | python3 -c 'import json,sys; print(json.load(sys.stdin)["accessToken"])' > ana.token
ana@vm:~/bookshop$ cat ana.token
eyJraWQiOiJPWk9odmt2Ui1tOVpKOUM3N2xxUm5yN0E0VVMxdk1obkpuR0hLcDl1eGJnIiwiYWxnIjoiSFMyNTYifQ.eyJpc3MiOiJib29rc2hvcCIsInN1YiI6ImFuYSIsImV4cCI6MTc5MjcxMDIxMCwiaWF0IjoxNzkyNzA5MzEwLCJzY29wZSI6Im9yZGVycyJ9.mZduNKAMtWvUw2eCxswJiwxnX6yMaeFGcIAMr5b02yM
ana@vm:~/bookshop$ cut -d. -f1 ana.token | basenc -d --base64url; echo
{"kid":"OZOhvkvR-m9ZJ9C77lqRnr7A4US1vMhnJnGHKp9uxbg","alg":"HS256"}basenc: invalid input

ana@vm:~/bookshop$ cut -d. -f2 ana.token | basenc -d --base64url; echo
{"iss":"bookshop","sub":"ana","exp":1792710210,"iat":1792709310,"scope":"orders"}
ana@vm:~/bookshop$ cut -d. -f3 ana.token | basenc -d --base64url | wc -c
basenc: invalid input
32
```

Um JWT são três partes separadas por pontos, cada uma em **base64url**, a variante do base64 que é
segura numa URL. O `basenc` a decodifica; o `invalid input` dele é sobre o preenchimento `=` com que o
base64 normalmente termina e que o JWT deixa de fora, e o texto impresso antes da reclamação está
completo. O **cabeçalho** nomeia o algoritmo, `HS256`, e um identificador de chave que o encoder
acrescenta para que um servidor com várias chaves saiba com qual conferir. O **payload** traz os claims
que o `TokenController` definiu. `iss` é o emissor e `sub` o **subject**, de quem é o token. `iat` e
`exp` são emitido em e expira em, em segundos desde 1º de janeiro de 1970 UTC, e estão a 900 de
distância, que são os quinze minutos. Depois vem `scope`. A **assinatura** tem 32 bytes, o tamanho de uma saída do SHA-256.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 840 276\" role=\"img\" aria-label=\"Um JWT desenhado como três segmentos base64url separados por pontos: cabeçalho, payload e assinatura. O cabeçalho decodifica para o algoritmo, HS256; o payload decodifica para os claims iss, sub, iat, exp e scope; a assinatura são 32 bytes de HMAC-SHA256 calculados sobre o cabeçalho, um ponto e o payload com o segredo. Qualquer um decodifica os dois primeiros; só quem tem o segredo produz o terceiro.\"><defs><marker id=\"jw-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"105.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cabeçalho</text><rect x=\"20\" y=\"34\" width=\"170\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"105.0\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">base64url</text><text x=\"355.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">payload</text><rect x=\"230\" y=\"34\" width=\"250\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"355.0\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">base64url</text><text x=\"620.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">assinatura</text><rect x=\"540\" y=\"34\" width=\"160\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">base64url</text><text x=\"210\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--paper)\">.</text><text x=\"520\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--paper)\">.</text><rect x=\"20\" y=\"96\" width=\"170\" height=\"52\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"105\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&quot;alg&quot;:&quot;HS256&quot;</text><text x=\"105\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">&quot;kid&quot;:&quot;…&quot;</text><rect x=\"230\" y=\"96\" width=\"250\" height=\"92\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"355\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&quot;iss&quot;:&quot;bookshop&quot;</text><text x=\"355\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&quot;sub&quot;:&quot;ana&quot;</text><text x=\"355\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&quot;iat&quot;:…  &quot;exp&quot;:…</text><text x=\"355\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&quot;scope&quot;:&quot;orders&quot;</text><rect x=\"540\" y=\"96\" width=\"160\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"620\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">32 bytes</text><line x1=\"105.0\" y1=\"68\" x2=\"105.0\" y2=\"94\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"355.0\" y1=\"68\" x2=\"355.0\" y2=\"94\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"620.0\" y1=\"68\" x2=\"620.0\" y2=\"94\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"250\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">qualquer um decodifica estes dois: codificados, não cifrados</text><rect x=\"160\" y=\"226\" width=\"420\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"370\" y=\"243\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">HMAC-SHA256(secret, header + &quot;.&quot; + payload)</text><path d=\"M 580 243 C 640 243, 640 180, 630 134\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#jw-ah)\"></path><text x=\"640\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">só o segredo consegue produzi-la</text></svg>", "caption": "Três partes, unidas por pontos. O cabeçalho e o payload são só codificados; a assinatura é o que torna o payload confiável, porque mudar um caractere dele muda o HMAC.", "same": ["payload", "base64url", "32 bytes"]}
```

**Codificado não é cifrado.** Quem tiver um token lê os claims dele com o comando acima, então um claim
nunca deve guardar o que o portador não deveria ver: o subject aqui é um nome de usuário, e o payload
não leva mais nada sobre a ana.

## Mudando um claim

Ler o payload é permitido. Mudá-lo é o que a assinatura existe para impedir. Os comandos abaixo copiam o
payload, dão à ana o escopo do clerk e remontam o token em volta da assinatura original:

```
ana@vm:~/bookshop$ cut -d. -f2 ana.token | basenc -d --base64url | sed 's/"orders"/"catalogue:write orders"/' | basenc --base64url -w0 | tr -d = > payload
ana@vm:~/bookshop$ echo "$(cut -d. -f1 ana.token).$(cat payload).$(cut -d. -f3 ana.token)" > forged.token
ana@vm:~/bookshop$ cut -d. -f2 forged.token | basenc -d --base64url; echo
{"iss":"bookshop","sub":"ana","exp":1792710210,"iat":1792709310,"scope":"catalogue:write orders"}basenc: invalid input

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
Date: Thu, 22 Oct 2026 22:48:30 GMT
```

**401, `Invalid signature`.** O decoder calculou o HMAC do cabeçalho e do payload editado com o seu
próprio segredo, e os 32 bytes não bateram com os que o token levava. A ana pode reescrever o payload
como quiser; ela não consegue escrever a assinatura que combina com ele, porque isso exige o segredo.
E a resposta é 401, não 403: o token foi recusado antes de qualquer regra ser lida, então, até onde o
servidor sabe, ninguém está pedindo.
