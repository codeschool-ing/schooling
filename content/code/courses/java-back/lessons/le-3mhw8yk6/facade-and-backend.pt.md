---
title: A fachada e o backend
version: 1
---

A imagem comum de logging em Java é uma biblioteca que o seu código importa e que escreve as linhas.
**São duas metades, e o seu código só encontra uma delas.** A metade que o seu código chama é uma
**fachada**: uma interface com métodos como `info` e `warn` e nenhuma opinião sobre para onde vai uma
linha. A metade que formata a linha e a escreve em algum lugar é o **backend**. Neste curso a fachada
é o **SLF4J**, a Simple Logging Facade for Java, e o backend é o **Logback**, porque é o que o Spring
Boot traz.

A divisão existe porque uma aplicação Java é, em boa parte, código dos outros. Spring, Hibernate,
HikariCP e Tomcat registram logs, foram escritos por equipes diferentes em anos diferentes, e escolheram
APIs de logging diferentes. Se cada um trouxesse o seu backend, um programa escreveria em quatro
formatos, em quatro lugares, com quatro conjuntos de níveis. A fachada deixa toda biblioteca registrar
por uma interface só e deixa a escolha do backend para quem monta a aplicação, que é você.

## O que a livraria já carrega

A aula 4 encontrou o `spring-boot-starter-logging` na árvore de dependências do starter. Pedir ao
Maven só as bibliotecas de logging mostra de onde vem cada uma:

@@FENCE 0@@

Leia de baixo para cima. `slf4j-api` é a fachada, e o Maven a coloca sob o HikariCP só porque foi o
primeiro lugar onde a encontrou; o Logback também depende dela. `logback-classic` é o backend. Todo o
resto é uma porta de entrada: as classes do próprio Spring registram pelo `commons-logging`, o
validador do Hibernate pelo `jboss-logging`, e duas **pontes** pegam o resto. O `log4j-to-slf4j` recebe
chamadas feitas à API do Log4j e as passa ao SLF4J, e o `jul-to-slf4j` faz o mesmo com o
`java.util.logging`, o logger que vem no JDK. Repare no que falta: `log4j-core`, o backend do Log4j. A
última seção desta aula conta por que essa ausência já importou para todo mundo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Cinco origens de chamadas de log à esquerda: o seu código pela API do SLF4J, as classes do Spring pelo commons-logging, o Hibernate pelo jboss-logging, uma biblioteca da API do Log4j pelo log4j-to-slf4j e o java.util.logging pelo jul-to-slf4j. As cinco setas chegam ao slf4j-api, que tem uma seta para o logback-classic, que escreve no console.\"><defs><marker id=\"ffb-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"14\" y=\"14\" width=\"240\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"134\" y=\"29\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o seu código</text><text x=\"134\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">LoggerFactory.getLogger</text><line x1=\"254\" y1=\"36\" x2=\"368\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#ffb-ah)\"></line><rect x=\"14\" y=\"70\" width=\"240\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"134\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">as classes do Spring</text><text x=\"134\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">commons-logging</text><line x1=\"254\" y1=\"92\" x2=\"368\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#ffb-ah)\"></line><rect x=\"14\" y=\"126\" width=\"240\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"134\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o Hibernate</text><text x=\"134\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">jboss-logging</text><line x1=\"254\" y1=\"148\" x2=\"368\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#ffb-ah)\"></line><rect x=\"14\" y=\"182\" width=\"240\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"134\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma biblioteca na API do Log4j</text><text x=\"134\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">log4j-to-slf4j</text><line x1=\"254\" y1=\"204\" x2=\"368\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#ffb-ah)\"></line><rect x=\"14\" y=\"238\" width=\"240\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"134\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma biblioteca no java.util.logging</text><text x=\"134\" y=\"269\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">jul-to-slf4j</text><line x1=\"254\" y1=\"260\" x2=\"368\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#ffb-ah)\"></line><rect x=\"370\" y=\"118\" width=\"130\" height=\"64\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"435\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">slf4j-api</text><text x=\"435\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a fachada</text><line x1=\"500\" y1=\"150\" x2=\"538\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#ffb-ah)\"></line><rect x=\"540\" y=\"118\" width=\"166\" height=\"64\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"623\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">logback-classic</text><text x=\"623\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o único backend</text><line x1=\"623\" y1=\"182\" x2=\"623\" y2=\"236\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#ffb-ah)\"></line><rect x=\"553\" y=\"238\" width=\"140\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"623\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o console</text></svg>", "caption": "Cinco entradas, uma saída. Cada biblioteca registra pela API que escolheu; as pontes do starter de logging do Boot mandam tudo para o SLF4J, e o SLF4J para o único backend do classpath.", "same": []}
```

## A fachada sozinha

O jeito mais limpo de ver as duas metades é um programa pequeno o bastante para rodar com cada backend
por vez. Crie `~/logging-look/pom.xml`. Ele não tem código para compilar: existe para o Maven montar
um classpath, e cada **perfil** acrescenta um backend à única dependência que todas as variantes
compartilham:

@@FENCE 1@@

As versões são as que o Boot 4.1.1 gerencia para a livraria, então as duas primeiras variantes não
baixam nada novo. Ao lado dele, `~/logging-look/Hello.java`, que importa o SLF4J e mais nada:

@@FENCE 2@@

`LoggerFactory.getLogger(Hello.class)` pede um **logger**, e a classe recebida vira o **nome** do
logger: `Hello` aqui, `com.example.bookshop.ordering.OrderService` na livraria. Toda linha traz esse
nome, e a próxima seção o usa para escolher quais linhas aparecem.

`mvn dependency:build-classpath` resolve os jars de que um projeto precisa e junta os caminhos deles
com dois-pontos, exatamente o que `java -cp` recebe; `-Dmdep.outputFile=cp.txt` grava essa string num
arquivo, e `-q` deixa o Maven calado a menos que algo falhe. O `java` então roda o arquivo-fonte
direto com esse classpath. Primeiro sem perfil, com a fachada sozinha (o `cp.txt` não tem quebra de
linha no fim, daí o `echo`):

@@FENCE 3@@

O programa compilou, rodou e terminou, e **nenhuma das quatro linhas foi escrita, nem a de erro.** O
SLF4J procurou um **provider**, que é como o SLF4J chama um backend, não achou nenhum, avisou três
vezes, e trocou todo logger por um que descarta tudo. É a fachada fazendo exatamente o seu trabalho:
ela não tem ideia de como escrever uma linha. Um servidor iniciado assim rodaria por meses com um log
vazio, então vale reconhecer esses três avisos.

Agora com o Logback:

@@FENCE 4@@

O mesmo arquivo-fonte, mais três jars, e agora toda linha chega: a hora, a thread, o nível, o nome do
logger e a mensagem, com o stack trace da exceção depois da última. Nada no `Hello.java` mudou entre as
duas execuções. **Escolher um backend é uma mudança no classpath, nunca no código**, e essa é toda a
promessa de uma fachada. O formato acima é o padrão do próprio Logback, usado quando ninguém o
configurou; as linhas da livraria são diferentes porque o Spring Boot configura o Logback antes de a
primeira ser escrita, e é daí que a próxima seção parte.
