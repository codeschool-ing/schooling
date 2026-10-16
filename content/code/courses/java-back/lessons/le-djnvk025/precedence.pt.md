---
title: Qual valor vence
version: 1
---

Até aqui toda porta em que a livraria subiu veio de dentro do jar: o padrão do Boot, depois o
arquivo do perfil dev. Configurações também podem vir de fora dele, e quando dois lugares definem
a mesma propriedade, **o Boot não as mistura e não reclama: pega o valor do lugar mais forte e
ignora o resto**. A ordem é fixa, e a ideia por trás dela é simples: quanto mais perto um valor
está do momento e da máquina em que a aplicação sobe, mais forte ele é.

Suba o perfil dev com uma porta também no ambiente:

```
ana@vm:~/bookshop$ SPRING_PROFILES_ACTIVE=dev SERVER_PORT=9090 java -jar target/bookshop-0.1.0.jar > /tmp/bookshop.log 2>&1
```

```
ana@vm:~/bookshop$ grep -E 'profile|Tomcat started' /tmp/bookshop.log
2026-10-16T20:21:09.167-03:00  INFO 2452 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : The following 1 profile is active: "dev"
2026-10-16T20:21:11.108-03:00  INFO 2452 --- [bookshop] [           main] o.s.boot.tomcat.TomcatWebServer          : Tomcat started on port 9090 (http) with context path '/'
```

O perfil está ativo e o arquivo dele diz 8081, e o Tomcat está na **9090**: a variável de ambiente
supera todo arquivo dentro do jar. Agora acrescente um argumento de linha de comando por cima:

```
ana@vm:~/bookshop$ SPRING_PROFILES_ACTIVE=dev SERVER_PORT=9090 java -jar target/bookshop-0.1.0.jar --server.port=9091 > /tmp/bookshop.log 2>&1
```

```
ana@vm:~/bookshop$ grep -E 'profile|Tomcat started' /tmp/bookshop.log
2026-10-16T20:21:13.389-03:00  INFO 2599 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : The following 1 profile is active: "dev"
2026-10-16T20:21:14.721-03:00  INFO 2599 --- [bookshop] [           main] o.s.boot.tomcat.TomcatWebServer          : Tomcat started on port 9091 (http) with context path '/'
```

**9091**: o argumento supera o ambiente. Pare a aplicação.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 780 286\" role=\"img\" aria-label=\"Cinco lugares de onde uma configuração pode vir, do mais forte: um argumento de linha de comando dá 9091, uma variável de ambiente 9090, o arquivo do perfil dev 8081; o application.properties não define porta; o padrão do Boot é 8080. Um lugar mais forte esconde todos os mais fracos.\"><text x=\"36\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">onde server.port é definido, do mais forte ao mais fraco</text><text x=\"560\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sozinho, dá</text><rect x=\"20\" y=\"32\" width=\"500\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"45\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um argumento de linha de comando</text><text x=\"36\" y=\"61\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">--server.port=9091</text><rect x=\"540\" y=\"32\" width=\"140\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">9091</text><rect x=\"34\" y=\"82\" width=\"486\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"50\" y=\"95\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma variável de ambiente</text><text x=\"50\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">SERVER_PORT=9090</text><rect x=\"540\" y=\"82\" width=\"140\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">9090</text><rect x=\"48\" y=\"132\" width=\"472\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"64\" y=\"145\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o arquivo do perfil ativo</text><text x=\"64\" y=\"161\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">application-dev.properties</text><rect x=\"540\" y=\"132\" width=\"140\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">8081</text><rect x=\"62\" y=\"182\" width=\"458\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"78\" y=\"195\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o arquivo principal de propriedades</text><text x=\"78\" y=\"211\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">application.properties</text><rect x=\"540\" y=\"182\" width=\"140\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">não define porta</text><rect x=\"76\" y=\"232\" width=\"444\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"92\" y=\"245\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o padrão do próprio Boot</text><text x=\"92\" y=\"261\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\"></text><rect x=\"540\" y=\"232\" width=\"140\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">8080</text><path d=\"M 700 40 L 700 264\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></path><text x=\"712\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">vence</text><text x=\"712\" y=\"264\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">perde</text></svg>", "caption": "As portas em que a livraria subiu nesta aula, cada lugar sozinho. Quando vários definem a mesma propriedade, vence o mais alto."}
```

A lista completa na documentação do Spring Boot tem mais degraus que esta, propriedades de teste
e arquivos fora do jar entre eles, e estes quatro mais o padrão são os que uma implantação
encontra todo dia. Um arquivo fora do jar vale conhecer já: um `application.properties` no
diretório de onde a aplicação é iniciada também é lido, e vence a cópia de dentro do jar.

Dois detalhes fazem a ordem funcionar na prática. A mesma propriedade é alcançada com grafias
diferentes, `server.port` num arquivo, `SERVER_PORT` no ambiente, `--server.port` na linha de
comando, porque o Boot liga nomes com folga: maiúsculas, pontos, hifens e sublinhados são
comparados por uma regra, e não caractere a caractere. Isso se chama **relaxed binding**, ligação
flexível, e é também o que transforma `SPRING_PROFILES_ACTIVE` em `spring.profiles.active`.

E a ordem é o motivo de o jar nunca precisar de um segredo dentro dele. Uma senha pertence ao
ambiente da máquina que roda o jar, onde ela supera tudo o que o jar traz, e a aula 23 entrega à
livraria a senha do banco e a chave de assinatura dos tokens exatamente assim.
