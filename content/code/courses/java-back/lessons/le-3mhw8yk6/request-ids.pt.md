---
title: Um id por requisição, de ponta a ponta
version: 1
---

Com uma pessoa clicando, um log se lê como uma história. Com cinquenta requisições por segundo, ele se
lê como cinquenta histórias embaralhadas, e a pergunta que o suporte de fato faz, "o que aconteceu com
o checkout deste cliente?", não tem resposta ali. O nome da thread parece um jeito de separá-las e não
é: o Tomcat atende requisições com um pool de threads, então `nio-8080-exec-9` atende uma requisição,
depois outra, depois mais mil.

O que as separa é um **id de requisição**: um valor curto dado a cada requisição na entrada, escrito em
toda linha que essa requisição causa, e devolvido a quem chamou, para que uma pessoa com uma resposta
de erro na mão possa citá-lo. Pôr esse id em toda linha sem passá-lo a todo método é o trabalho do
**MDC**, o Mapped Diagnostic Context. É um mapa pequeno que pertence à thread atual: o SLF4J deixa
você preenchê-lo, e o backend o lê toda vez que escreve uma linha.

## O filtro

Crie `src/main/java/com/example/bookshop/web/RequestIdFilter.java`:

```schooling-example
{"language": "java", "file": "RequestIdFilter.java", "parts": [{"code": "package com.example.bookshop.web;\n\nimport java.io.IOException;\nimport java.util.UUID;\n\nimport jakarta.servlet.FilterChain;\nimport jakarta.servlet.ServletException;\nimport jakarta.servlet.http.HttpServletRequest;\nimport jakarta.servlet.http.HttpServletResponse;\n\nimport org.slf4j.MDC;\nimport org.springframework.core.Ordered;\nimport org.springframework.core.annotation.Order;\nimport org.springframework.stereotype.Component;\nimport org.springframework.web.filter.OncePerRequestFilter;\n"}, {"code": "@Component\n@Order(Ordered.HIGHEST_PRECEDENCE)\npublic class RequestIdFilter extends OncePerRequestFilter {\n", "note": "Um filtro `@Component` é registrado pelo Boot para toda requisição, e o `OncePerRequestFilter` o roda uma vez por requisição, mesmo quando ela é encaminhada dentro do servidor. `HIGHEST_PRECEDENCE` o põe antes dos filtros do Spring Security, então uma requisição recusada com 401 também ganha um id."}, {"code": "    static final String HEADER = \"X-Request-Id\";\n"}, {"code": "    @Override\n    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)\n            throws ServletException, IOException {"}, {"code": "        String id = request.getHeader(HEADER);\n        if (id == null || !id.matches(\"[A-Za-z0-9-]{1,64}\")) {\n            id = UUID.randomUUID().toString().substring(0, 8);\n        }", "note": "Usa o id de quem chamou se ele tiver um e for curto, só letras, dígitos e hífens. Qualquer outra coisa é trocada por oito caracteres de um UUID aleatório: um valor de fora nunca entra no log do jeito que chegou."}, {"code": "        MDC.put(\"requestId\", id);\n        response.setHeader(HEADER, id);", "note": "`MDC.put` prende o id a esta thread, e o mesmo id volta para quem chamou no cabeçalho da resposta."}, {"code": "        try {\n            chain.doFilter(request, response);\n        } finally {\n            MDC.remove(\"requestId\");\n        }\n    }\n}", "note": "O resto da cadeia roda com o id no lugar. O `finally` o retira de novo aconteça o que acontecer, porque o Tomcat entrega esta thread a outra requisição em seguida."}]}
```

A última linha do `application.properties`, acrescentada na seção anterior, é a outra metade:

@@FENCE 0@@

`%X{requestId}` é o jeito do Logback de ler a chave `requestId` do MDC, e `:-` sem nada depois diz o
que imprimir quando a chave falta: nada. O Boot põe esse padrão depois do nome da thread em toda
linha, que é o `[]` que as linhas da partida traziam. **A linha termina com um espaço**, invisível
acima e parte do valor: o Boot põe o padrão colado ao nome do logger, e sem o espaço os dois ficariam
grudados. Empacote de novo, e reinicie o segundo terminal:

@@FENCE 1@@

@@FENCE 2@@

## Seguindo uma requisição

O cabeçalho volta em toda resposta. Uma requisição sem ele ganha um id inventado, e um razoável é
mantido. Um em que o filtro não confia é trocado. Uma requisição que o Spring Security recusa ainda
ganha um id, porque o filtro roda primeiro:

@@FENCE 3@@

**Por que recusar `two words` em vez de registrar?** Porque o que estiver nesse cabeçalho seria copiado
para o log, e o log é lido por pessoas e analisado por programas que confiam nele. Um cabeçalho com uma
quebra de linha poderia acrescentar uma linha própria, com hora e nível que a aplicação nunca
escreveu. O filtro aceita só o que um id de requisição precisa ser, e isso não deixa nada com que
forjar.

Agora um pedido, com o token do `/auth/token` da aula 15:

@@FENCE 4@@

O `OrderService` nunca menciona um id de requisição, e a linha dele traz um. Toda outra linha escrita
naquela thread enquanto a requisição estava em andamento, pela livraria, pelo Spring ou pelo
Hibernate, também o traria, e `grep checkout-42` acha todas. (O id do seu pedido vai ser outro; este
rodou num banco novo.)

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"Uma sequência em quatro colunas. O curl manda X-Request-Id: checkout-42 ao RequestIdFilter, que o põe no MDC e define o cabeçalho da resposta, e chama o resto da cadeia. O OrderService registra, e a linha no log traz checkout-42. A cadeia retorna, o filtro tira o id do MDC, e a resposta chega ao curl com o cabeçalho.\"><defs><marker id=\"fid-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"0\" y=\"10\" width=\"140\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"70\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">curl</text><line x1=\"70\" y1=\"42\" x2=\"70\" y2=\"345\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><rect x=\"180\" y=\"10\" width=\"140\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"250\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">RequestIdFilter</text><line x1=\"250\" y1=\"42\" x2=\"250\" y2=\"345\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><rect x=\"380\" y=\"10\" width=\"140\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"450\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o resto da cadeia</text><line x1=\"450\" y1=\"42\" x2=\"450\" y2=\"345\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><rect x=\"560\" y=\"10\" width=\"140\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"630\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o log</text><line x1=\"630\" y1=\"42\" x2=\"630\" y2=\"345\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><line x1=\"70\" y1=\"70\" x2=\"248\" y2=\"70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fid-ah)\"></line><text x=\"160\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">X-Request-Id: checkout-42</text><rect x=\"165\" y=\"84\" width=\"170\" height=\"38\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"250\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">MDC.put(requestId)</text><text x=\"250\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">lê, ou cria um</text><rect x=\"165\" y=\"128\" width=\"170\" height=\"38\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"250\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">response.setHeader</text><text x=\"250\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">antes de a resposta ser escrita</text><line x1=\"250\" y1=\"186\" x2=\"448\" y2=\"186\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fid-ah)\"></line><text x=\"350\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">chain.doFilter</text><line x1=\"450\" y1=\"216\" x2=\"628\" y2=\"216\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fid-ah)\"></line><text x=\"540\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">log.info(...)</text><rect x=\"560\" y=\"226\" width=\"150\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"635\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">[checkout-42] Order 1</text><text x=\"635\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">toda linha nesta thread</text><line x1=\"448\" y1=\"280\" x2=\"252\" y2=\"280\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#fid-ah)\"></line><rect x=\"165\" y=\"290\" width=\"170\" height=\"38\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"250\" y=\"303\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">MDC.remove(requestId)</text><text x=\"250\" y=\"318\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">a thread volta limpa ao pool</text><line x1=\"165\" y1=\"338\" x2=\"72\" y2=\"338\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#fid-ah)\"></line><text x=\"115\" y=\"326\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">a resposta, com o cabeçalho</text></svg>", "caption": "O id vive na thread de MDC.put até MDC.remove, e toda linha registrada nesse meio o carrega, seja quem for que a escreva.", "same": []}
```

## Onde o id para

O MDC pertence a uma thread, e é por isso que funciona e é aí que acaba. Um trabalho entregue a outra
thread, um método `@Async` ou um `CompletableFuture` num pool, começa com o MDC dessa thread, que está
vazio, e as linhas dele mostram `[]`. O SLF4J deixa você levar o mapa junto à mão:
`MDC.getCopyOfContextMap()` antes da entrega e `MDC.setContextMap(...)` no começo do trabalho.

E o id para na borda desta aplicação. Se a livraria chamasse outro serviço, esse serviço inventaria o
seu próprio id, a menos que a livraria mandasse o `X-Request-Id` junto. Fazer isso em toda chamada de
saída, por muitos serviços, é o que o rastreamento distribuído faz, com o Micrometer Tracing do lado do
Spring; quando ele está no classpath, o Boot preenche esse mesmo espaço de correlação com um trace id
e um span id. Para uma aplicação só, o filtro acima é tudo.
