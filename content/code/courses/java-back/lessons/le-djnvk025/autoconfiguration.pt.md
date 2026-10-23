---
title: Autoconfiguração, e o relatório que a explica
version: 1
---

Nada na livraria criou um Tomcat, um mapeador de JSON ou um `DispatcherServlet`, e os três
existem. A imagem comum é que o Boot "simplesmente sabe", e ela deixa você travado na primeira vez
que ele erra. O mecanismo real é mais sem graça e muito mais útil: **uma lista de classes de
configuração comuns, cada uma guardada por condições, e um relatório que diz quais condições
valeram**.

## De onde vem a lista

O Boot 4 divide a autoconfiguração em módulos, um por tecnologia, e o jar de cada módulo traz um
arquivo que nomeia as classes de configuração que ele oferece. Este é o que está dentro do módulo
de Spring MVC que o starter trouxe:

```
ana@vm:~/bookshop$ unzip -p ~/.m2/repository/org/springframework/boot/spring-boot-webmvc/4.1.1/spring-boot-webmvc-4.1.1.jar META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports
org.springframework.boot.webmvc.autoconfigure.DispatcherServletAutoConfiguration
org.springframework.boot.webmvc.autoconfigure.WebMvcAutoConfiguration
org.springframework.boot.webmvc.autoconfigure.WebMvcObservationAutoConfiguration
org.springframework.boot.webmvc.autoconfigure.actuate.endpoint.web.WebMvcHealthEndpointExtensionAutoConfiguration
org.springframework.boot.webmvc.autoconfigure.actuate.web.mappings.WebMvcMappingsAutoConfiguration
org.springframework.boot.webmvc.autoconfigure.error.ErrorMvcAutoConfiguration
```

Na inicialização, o `@EnableAutoConfiguration` lê esse arquivo **em todo jar do classpath** e trata
cada linha como uma candidata. Uma candidata é uma classe como qualquer outra classe de
configuração: ela declara beans, a fábrica do Tomcat ou o mapeador do Jackson, exatamente como você
vai fazer na aula 5. Só jars presentes conseguem listar alguma coisa, então o classpath é o
primeiro filtro. Um módulo que a livraria não tem, o `spring-boot-jdbc` por exemplo, não é
recusado: as candidatas dele nunca são lidas. O contrário também acontece. Três das seis
linhas acima são do Actuator e das métricas dele, que chegam na aula 22: o módulo as oferece, e
as condições delas as recusam por enquanto.

O módulo ausente é o que pega quem lê material mais antigo. Um guia escrito para o Spring Boot 3 mostra
`DataSourceAutoConfiguration` como negative match em toda aplicação sem banco. No Boot 4 ela mora no
`spring-boot-jdbc`, então o relatório da livraria nem a menciona até a aula 9 acrescentar um
starter de JDBC.

## Condições

Toda candidata traz anotações que decidem se ela se aplica. Três tipos fazem quase todo o
trabalho, e a inicialização da livraria avalia os três:

- `@ConditionalOnClass`: aplica só se uma classe estiver no classpath. É assim que a presença de
  um jar vira um recurso, e é por isso que acrescentar uma dependência costuma ser toda a
  configuração de que um recurso precisa.
- `@ConditionalOnBooleanProperty` e `@ConditionalOnProperty`: aplica só se uma propriedade tiver
  um valor dado, e assim um recurso pode ser ligado no `application.properties`.
- `@ConditionalOnMissingBean`: aplica só se você não definiu um bean daquele tipo. É esta que faz
  do Boot um conjunto de padrões, e não de decisões: **declare o seu e o do Boot recua**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 352\" role=\"img\" aria-label=\"Todo jar no classpath lista configurações candidatas. Cada candidata traz condições: uma classe precisa estar presente, um bean precisa faltar, uma propriedade precisa estar ligada. A configuração do Tomcat e o bean da fábrica são aplicados; os conversores do Gson e os problem details são ignorados.\"><defs><marker id=\"l4f2-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"680\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">todo jar no classpath pode listar candidatas em</text><text x=\"684\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">META-INF/spring/…AutoConfiguration.imports</text><text x=\"36\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">candidata</text><text x=\"300\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a condição pergunta</text><text x=\"560\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">resultado</text><rect x=\"20\" y=\"100\" width=\"260\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">TomcatServletWebServer…</text><rect x=\"290\" y=\"100\" width=\"250\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"300\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">esta classe está no classpath?</text><text x=\"300\" y=\"131\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">org.apache.catalina.startup.Tomcat</text><rect x=\"560\" y=\"100\" width=\"140\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"630\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">aplicada</text><path d=\"M 280 122 L 288 122\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l4f2-ah)\"></path><path d=\"M 540 122 L 558 122\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l4f2-ah)\"></path><rect x=\"20\" y=\"156\" width=\"260\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">…#tomcatServletWebServerFactory</text><rect x=\"290\" y=\"156\" width=\"250\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"300\" y=\"171\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ninguém definiu um bean deste tipo?</text><text x=\"300\" y=\"187\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ServletWebServerFactory</text><rect x=\"560\" y=\"156\" width=\"140\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"630\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">aplicada</text><path d=\"M 280 178 L 288 178\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l4f2-ah)\"></path><path d=\"M 540 178 L 558 178\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l4f2-ah)\"></path><rect x=\"20\" y=\"212\" width=\"260\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"234\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">GsonHttpMessageConverters…</text><rect x=\"290\" y=\"212\" width=\"250\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"300\" y=\"227\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">esta classe está no classpath?</text><text x=\"300\" y=\"243\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">com.google.gson.Gson</text><rect x=\"560\" y=\"212\" width=\"140\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"630\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ignorada</text><path d=\"M 280 234 L 288 234\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l4f2-ah)\"></path><path d=\"M 540 234 L 558 234\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l4f2-ah)\"></path><rect x=\"20\" y=\"268\" width=\"260\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"290\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">…ProblemDetailsErrorHandling…</text><rect x=\"290\" y=\"268\" width=\"250\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"300\" y=\"283\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">esta propriedade vale true?</text><text x=\"300\" y=\"299\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">spring.mvc.problemdetails.enabled</text><rect x=\"560\" y=\"268\" width=\"140\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"630\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ignorada</text><path d=\"M 280 290 L 288 290\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l4f2-ah)\"></path><path d=\"M 540 290 L 558 290\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l4f2-ah)\"></path><text x=\"360\" y=\"336\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">aplicada: um positive match no relatório · ignorada: um negative match, com o motivo</text></svg>", "caption": "A autoconfiguração é uma lista de candidatas, cada uma com condições. O relatório imprime a resposta de cada uma."}
```

## O relatório de avaliação das condições

O Boot imprime cada decisão quando sobe com `--debug`. O relatório é longo, então desta vez o
segundo terminal manda o log para um arquivo em vez da tela:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --debug > /tmp/bookshop.log 2>&1
```

E o primeiro terminal procura nele uma candidata que se aplicou e duas que não:

```
ana@vm:~/bookshop$ grep -A2 -E '^   (TomcatServletWebServerAutoConfiguration#tomcatServletWebServerFactory|GsonHttpMessageConvertersConfiguration|WebMvcAutoConfiguration.ProblemDetailsErrorHandlingConfiguration)( matched)?:' /tmp/bookshop.log
   TomcatServletWebServerAutoConfiguration#tomcatServletWebServerFactory matched:
      - @ConditionalOnMissingBean (types: org.springframework.boot.web.server.servlet.ServletWebServerFactory; SearchStrategy: current) did not find any beans (OnBeanCondition)

--
   GsonHttpMessageConvertersConfiguration:
      Did not match:
         - @ConditionalOnClass did not find required class 'com.google.gson.Gson' (OnClassCondition)
--
   WebMvcAutoConfiguration.ProblemDetailsErrorHandlingConfiguration:
      Did not match:
         - @ConditionalOnBooleanProperty (spring.mvc.problemdetails.enabled=true) did not find property 'spring.mvc.problemdetails.enabled' (OnPropertyCondition)
```

Cada entrada nomeia a candidata e dá o motivo, com a classe da condição entre parênteses. O
`tomcatServletWebServerFactory` é o bean que monta o Tomcat, e foi criado porque o
`@ConditionalOnMissingBean` **não encontrou** um `ServletWebServerFactory` seu. Os conversores do
Gson foram ignorados porque `com.google.gson.Gson` não está no classpath: o Jackson é a biblioteca
de JSON da livraria, e acrescentar o jar do Gson tornaria essa linha positiva. E a
`ProblemDetailsErrorHandlingConfiguration` foi ignorada porque uma propriedade não estava
definida, um interruptor ao qual a aula 7 volta.

O relatório é longo porque é completo:

```
ana@vm:~/bookshop$ grep -cE '^   [A-Za-z0-9.#]+ matched:$' /tmp/bookshop.log
52
ana@vm:~/bookshop$ sed -n '/^Negative matches:/,/^Exclusions:/p' /tmp/bookshop.log | grep -cE '^   [A-Za-z0-9.#]+:$'
39
```

A primeira contagem são os positive matches e a segunda os negative. Você nunca o lê inteiro. Você
procura nele quando **algo que esperava está faltando** — nenhum JSON, nenhum Tomcat, um bean que
não está lá — e a entrada daquela candidata diz, numa frase, qual condição falhou. O `debug=true`
no `application.properties` imprime o mesmo relatório. Pare a aplicação antes da próxima seção.
