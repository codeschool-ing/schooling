---
title: Starters, e um pai que guarda as versões
version: 1
---

O Spring Boot não é algo que se instala. Não há comando `spring` neste curso nem servidor para
baixar: **o Boot é um conjunto de bibliotecas nomeadas num pom, mais um pom pai que decide as
versões delas**, e tudo o que ele faz acontece dentro do seu próprio processo `java`.

A maioria dos projetos começa no **start.spring.io**, um formulário no site do Spring que pede um
nome, uma versão do Java e uma lista de recursos, e devolve um zip com um pom, uma classe
principal e um arquivo de propriedades vazio. É um bom jeito de começar um projeto de verdade.
Este curso escreve esses arquivos à mão, porque um pom gerado é um arquivo que ninguém lê, e cada
linha deste vai importar.

O projeto mora em `~/bookshop`, e as aulas 4 a 23 o constroem. Crie os diretórios dele:

```sh
mkdir -p ~/bookshop/src/main/java/com/example/bookshop ~/bookshop/src/main/resources
cd ~/bookshop
```

Depois o `pom.xml`, no topo do projeto:

```schooling-example
{
  "language": "xml",
  "file": "pom.xml",
  "parts": [
    {
      "code": "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<project xmlns=\"http://maven.apache.org/POM/4.0.0\"\n         xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n         xsi:schemaLocation=\"http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd\">\n  <modelVersion>4.0.0</modelVersion>\n",
      "note": "**A mesma abertura do pom da aula 1.** Nada nas primeiras linhas é do Spring."
    },
    {
      "code": "  <parent>\n    <groupId>org.springframework.boot</groupId>\n    <artifactId>spring-boot-starter-parent</artifactId>\n    <version>4.1.1</version>\n    <relativePath/>\n  </parent>\n",
      "note": "**O pai.** Este pom herda do `spring-boot-starter-parent` 4.1.1, e é assim que um número aqui escolhe a versão de todas as bibliotecas abaixo. O `<relativePath/>` diz ao Maven para não procurar o pai num diretório acima deste e buscá-lo no repositório."
    },
    {
      "code": "  <groupId>com.example</groupId>\n  <artifactId>bookshop</artifactId>\n  <version>0.1.0</version>\n",
      "note": "**As coordenadas**, como na aula 1. Não há `<packaging>`, porque `jar` é o padrão."
    },
    {
      "code": "  <properties>\n    <java.version>25</java.version>\n  </properties>\n",
      "note": "**Só a versão do Java.** O pai já define o release do compilador a partir de `java.version`, a codificação das fontes e mais; o padrão dele é 17, e esta linha o sobe para o JDK que este curso usa."
    },
    {
      "code": "  <dependencies>\n    <dependency>\n      <groupId>org.springframework.boot</groupId>\n      <artifactId>spring-boot-starter-webmvc</artifactId>\n    </dependency>\n  </dependencies>\n",
      "note": "**Uma dependência, e nenhuma versão.** O starter traz a pilha web e o pai fornece a versão: os próximos parágrafos mostram as duas metades."
    },
    {
      "code": "  <build>\n    <plugins>\n      <plugin>\n        <groupId>org.springframework.boot</groupId>\n        <artifactId>spring-boot-maven-plugin</artifactId>\n      </plugin>\n    </plugins>\n  </build>\n</project>",
      "note": "**O plugin que torna o jar executável**, também sem versão e sem configuração própria. O pai liga o goal `repackage` dele à fase `package`, que é o assunto da próxima seção."
    }
  ]
}
```

## O que um starter traz

Um **starter** é uma dependência cujo propósito inteiro são as dependências dela. Você nomeia o
recurso, web com Spring MVC aqui, e o starter nomeia as bibliotecas de que esse recurso precisa.
Pergunte ao Maven o que chegou; o `-q` tira as linhas do próprio Maven, e o `-DoutputFile`
escreve a árvore num arquivo sem o `[INFO]` na frente de cada linha:

```
ana@vm:~/bookshop$ mvn -q dependency:tree -DoutputFile=/tmp/tree.txt && cat /tmp/tree.txt
com.example:bookshop:jar:0.1.0
\- org.springframework.boot:spring-boot-starter-webmvc:jar:4.1.1:compile
   +- org.springframework.boot:spring-boot-starter:jar:4.1.1:compile
   |  +- org.springframework.boot:spring-boot-starter-logging:jar:4.1.1:compile
   |  |  +- ch.qos.logback:logback-classic:jar:1.5.38:compile
   |  |  |  +- ch.qos.logback:logback-core:jar:1.5.38:compile
   |  |  |  \- org.slf4j:slf4j-api:jar:2.0.18:compile
   |  |  +- org.apache.logging.log4j:log4j-to-slf4j:jar:2.25.5:compile
   |  |  |  \- org.apache.logging.log4j:log4j-api:jar:2.25.5:compile
   |  |  \- org.slf4j:jul-to-slf4j:jar:2.0.18:compile
   |  +- org.springframework.boot:spring-boot-autoconfigure:jar:4.1.1:compile
   |  +- jakarta.annotation:jakarta.annotation-api:jar:3.0.0:compile
   |  \- org.yaml:snakeyaml:jar:2.6:compile
   +- org.springframework.boot:spring-boot-starter-jackson:jar:4.1.1:compile
   |  \- org.springframework.boot:spring-boot-jackson:jar:4.1.1:compile
   |     \- tools.jackson.core:jackson-databind:jar:3.1.5:compile
   |        +- com.fasterxml.jackson.core:jackson-annotations:jar:2.21:compile
   |        \- tools.jackson.core:jackson-core:jar:3.1.5:compile
   +- org.springframework.boot:spring-boot-starter-tomcat:jar:4.1.1:compile
   |  +- org.springframework.boot:spring-boot-starter-tomcat-runtime:jar:4.1.1:compile
   |  |  +- org.springframework.boot:spring-boot-web-server:jar:4.1.1:compile
   |  |  +- org.apache.tomcat.embed:tomcat-embed-core:jar:11.0.24:compile
   |  |  +- org.apache.tomcat.embed:tomcat-embed-el:jar:11.0.24:compile
   |  |  \- org.apache.tomcat.embed:tomcat-embed-websocket:jar:11.0.24:compile
   |  \- org.springframework.boot:spring-boot-tomcat:jar:4.1.1:compile
   +- org.springframework.boot:spring-boot-http-converter:jar:4.1.1:compile
   |  +- org.springframework.boot:spring-boot:jar:4.1.1:compile
   |  |  +- org.springframework:spring-core:jar:7.0.9:compile
   |  |  |  +- commons-logging:commons-logging:jar:1.3.6:compile
   |  |  |  \- org.jspecify:jspecify:jar:1.0.1:compile
   |  |  \- org.springframework:spring-context:jar:7.0.9:compile
   |  \- org.springframework:spring-web:jar:7.0.9:compile
   |     +- org.springframework:spring-beans:jar:7.0.9:compile
   |     \- io.micrometer:micrometer-observation:jar:1.17.1:compile
   |        \- io.micrometer:micrometer-commons:jar:1.17.1:compile
   \- org.springframework.boot:spring-boot-webmvc:jar:4.1.1:compile
      +- org.springframework.boot:spring-boot-servlet:jar:4.1.1:compile
      \- org.springframework:spring-webmvc:jar:7.0.9:compile
         +- org.springframework:spring-aop:jar:7.0.9:compile
         \- org.springframework:spring-expression:jar:7.0.9:compile
ana@vm:~/bookshop$ grep -c ':compile' /tmp/tree.txt
39
```

Uma linha no pom, e cada linha dessa árvore está no classpath. Leia de cima: o
`spring-boot-starter` é o núcleo que todo starter compartilha, e ele traz o log (Logback por
trás do SLF4J, que a aula 16 desmonta) e o `spring-boot-autoconfigure`, assunto da seção
depois da próxima. Depois o Jackson 3, que transforma objetos em JSON, o Tomcat 11,
embutido, de modo que o servidor é uma biblioteca dentro da aplicação, e não algo onde a aplicação
é implantada, e o Spring MVC, que entrega cada requisição ao seu código.

O próprio starter não contribui código nenhum:

```
ana@vm:~/bookshop$ unzip -l ~/.m2/repository/org/springframework/boot/spring-boot-starter-webmvc/4.1.1/spring-boot-starter-webmvc-4.1.1.jar
Archive:  /home/ana/.m2/repository/org/springframework/boot/spring-boot-starter-webmvc/4.1.1/spring-boot-starter-webmvc-4.1.1.jar
  Length      Date    Time    Name
---------  ---------- -----   ----
        0  1980-02-01 00:00   META-INF/
      252  1980-02-01 00:00   META-INF/MANIFEST.MF
    11359  1980-02-01 00:00   META-INF/LICENSE.txt
      210  1980-02-01 00:00   META-INF/NOTICE.txt
---------                     -------
    11821                     4 files
```

Um manifesto, uma licença e um aviso. O jar existe porque o Maven precisa de um artefato para
resolver, e o valor está inteiro na lista de dependências que o pom dele declara.

## Por que o pom não nomeia versão

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" aria-label=\"O pom nomeia um pai com versão e um starter sem versão. O pai fornece uma lista de versões de bibliotecas; o starter fornece as bibliotecas; cada biblioteca chega na versão que a lista lhe dá.\"><defs><marker id=\"l4f1-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"250\" height=\"170\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"145\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o seu pom.xml</text><text x=\"36\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">&lt;parent&gt;</text><text x=\"36\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">spring-boot-starter-parent</text><text x=\"36\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">4.1.1</text><text x=\"36\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">&lt;dependency&gt;</text><text x=\"36\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">spring-boot-starter-webmvc</text><text x=\"36\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nenhuma versão escrita</text><rect x=\"380\" y=\"20\" width=\"300\" height=\"112\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"530\" y=\"10\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">qual versão: o pai</text><text x=\"396\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">spring-framework.version</text><text x=\"664\" y=\"44\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">7.0.9</text><text x=\"396\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">tomcat.version</text><text x=\"664\" y=\"64\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">11.0.24</text><text x=\"396\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">jackson-bom.version</text><text x=\"664\" y=\"84\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">3.1.5</text><text x=\"396\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">logback.version</text><text x=\"664\" y=\"104\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">1.5.38</text><text x=\"530\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">… 195 destas ao todo</text><rect x=\"380\" y=\"168\" width=\"300\" height=\"112\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"530\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o quê: o starter</text><text x=\"396\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">spring-webmvc</text><text x=\"664\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">7.0.9</text><text x=\"396\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">tomcat-embed-core</text><text x=\"664\" y=\"210\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">11.0.24</text><text x=\"396\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">jackson-databind</text><text x=\"664\" y=\"230\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">3.1.5</text><text x=\"396\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">logback-classic</text><text x=\"664\" y=\"250\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">1.5.38</text><text x=\"530\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">… 39 na árvore</text><path d=\"M 270 95 C 320 95, 330 76, 378 76\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l4f1-ah)\"></path><path d=\"M 270 168 C 320 168, 330 224, 378 224\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l4f1-ah)\"></path><path d=\"M 690 110 C 712 140, 712 170, 690 200\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l4f1-ah)\"></path><text x=\"326\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">qual versão</text><text x=\"326\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o quê</text></svg>", "caption": "Duas linhas do pom, dois trabalhos diferentes: o starter decide o que chega, o pai decide em qual versão."}
```

A outra metade é o `<parent>`. O `spring-boot-starter-parent` herda do
`spring-boot-dependencies`, cujo `<dependencyManagement>` nomeia uma versão para cada biblioteca
que o Boot sabe configurar, como uma propriedade. Uma dependência que aparece ali pode ser
declarada sem versão, aqui ou no pom de qualquer starter, e recebe a que a lista diz:

```
ana@vm:~/bookshop$ grep -c '\.version>' ~/.m2/repository/org/springframework/boot/spring-boot-dependencies/4.1.1/spring-boot-dependencies-4.1.1.pom
195
ana@vm:~/bookshop$ mvn -q help:evaluate -Dexpression=tomcat.version -DforceStdout; echo
11.0.24
ana@vm:~/bookshop$ mvn -q help:evaluate -Dexpression=jackson-bom.version -DforceStdout; echo
3.1.5
```

195 propriedades de versão, para as bibliotecas e também para os plugins do Maven, e é por isso
que este pom não fixa nenhum dos plugins que a aula 1 precisou fixar. Cada uma foi escolhida pela
equipe do Spring e **testada junto** com as outras antes de o Boot 4.1.1 sair, e esse é o
argumento de verdade a favor do pai. Sem ele, escolher um Jackson que funcione com este Spring
Framework, e um Tomcat que funcione com os dois, é um trabalho que você faz a cada atualização, e
erra uma vez.

Duas consequências valem saber já. **Atualizar o Spring Boot é um número**: mude o `4.1.1` no pai e
toda biblioteca gerenciada vai para as versões testadas com a nova versão. E quando uma biblioteca
precisa de uma correção antes de o Boot a publicar, uma versão de segurança do Tomcat, por
exemplo, você sobrepõe **a propriedade**, `<tomcat.version>` nas suas próprias `<properties>`, e
todos os jars do Tomcat mudam juntos. Escrever um `<version>` numa dependência só muda aquele jar
e deixa os irmãos para trás. As duas coisas são exceções; a livraria não sobrepõe nada.
