---
title: Um jar que carrega as suas bibliotecas
version: 1
---

Um servidor precisa de uma coisa só deste curso: um arquivo que ele consiga iniciar com Java e mais
nada. A aula 4 executou a livraria com `java -jar` e prometeu uma olhada lá dentro; esta seção cumpre
a promessa, porque tudo o que vem depois nesta aula, as camadas e a imagem, é feito do que está ali.

A imagem comum de um jar executável é a de um jar com as classes de todas as bibliotecas despejadas
dentro dele. É o que o **maven-shade-plugin** da aula 8 faz, e não é o que o Spring Boot faz. O Boot
mantém cada biblioteca como um jar inteiro, dentro do jar da livraria, e acrescenta um pequeno
programa cujo único trabalho é lê-las dali.

## Dois arquivos de um build

Construa a livraria como a aula 22 a deixou. O `-q` deixa o Maven calado a menos que algo dê errado,
e o `-DskipTests` deixa os testes de fora, porque esta aula é sobre o arquivo e a aula 19 já os
executa:

```
ana@vm:~/bookshop$ mvn -q package -DskipTests
ana@vm:~/bookshop$ ls -lh target/bookshop-0.1.0.jar*
-rw-r--r-- 1 ana ana 66M Oct 22 20:09 target/bookshop-0.1.0.jar
-rw-r--r-- 1 ana ana 47K Oct 22 20:09 target/bookshop-0.1.0.jar.original
```

Dois jars. `bookshop-0.1.0.jar.original` é o que o plugin de jar do próprio Maven fez: as classes e os
recursos da livraria, 47 KiB. Depois o `spring-boot-maven-plugin` executou o seu goal `repackage`,
renomeou esse arquivo para o lado e escreveu o de 66 MiB no lugar dele. O pequeno não roda sozinho:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar.original
no main manifest attribute, in target/bookshop-0.1.0.jar.original
```

O manifesto dele não indica classe alguma para iniciar, e as classes que ele tem falhariam logo de
qualquer forma, sem o Spring em lugar nenhum do class path. Esse era o problema da aula 1, e o class
path digitado à mão foi a resposta da aula 1 para ele.

## O que tem dentro

Um jar é um arquivo zip, então a ferramenta `jar` do JDK consegue listá-lo. Agrupado pelos dois
primeiros diretórios, deixando de fora as entradas que são os próprios diretórios:

```
ana@vm:~/bookshop$ jar tf target/bookshop-0.1.0.jar | grep -v '/$' | cut -d/ -f1-2 | sort | uniq -c
     42 BOOT-INF/classes
      1 BOOT-INF/classpath.idx
      1 BOOT-INF/layers.idx
    112 BOOT-INF/lib
      1 META-INF/MANIFEST.MF
      1 META-INF/build-info.properties
      2 META-INF/maven
      1 META-INF/services
     99 org/springframework
```

Quatro tipos de coisa, e dois deles são grandes:

- **`BOOT-INF/lib`**, 112 entradas: cada biblioteca de que a livraria precisa em execução, um jar
  cada. As bibliotecas de teste não estão entre elas; o escopo `test` do Maven as deixa de fora.
- **`BOOT-INF/classes`**, 42 arquivos: as classes da própria livraria, os seus arquivos de
  propriedades e as migrações do Flyway, como `target/classes` os tinha.
- **`org/springframework`**, 99 classes: o carregador do Spring Boot, como classes comuns no topo do
  jar.
- **`META-INF`** e dois arquivos de índice: o manifesto, as informações de build que a aula 22
  publicou e as listas que as próximas seções leem.

As bibliotecas são jars, com as versões no nome:

```
ana@vm:~/bookshop$ jar tf target/bookshop-0.1.0.jar | grep '^BOOT-INF/lib/' | head -n 5
BOOT-INF/lib/
BOOT-INF/lib/logback-classic-1.5.38.jar
BOOT-INF/lib/logback-core-1.5.38.jar
BOOT-INF/lib/log4j-to-slf4j-2.25.5.jar
BOOT-INF/lib/log4j-api-2.25.5.jar
```

## O manifesto indica duas classes

```
ana@vm:~/bookshop$ unzip -p target/bookshop-0.1.0.jar META-INF/MANIFEST.MF
Manifest-Version: 1.0
Created-By: Maven JAR Plugin 3.5.1
Java-Version: 25
Build-Jdk-Spec: 25
Implementation-Title: bookshop
Implementation-Version: 0.1.0
Main-Class: org.springframework.boot.loader.launch.JarLauncher
Start-Class: com.example.bookshop.BookshopApplication
Spring-Boot-Version: 4.1.1
Spring-Boot-Classes: BOOT-INF/classes/
Spring-Boot-Lib: BOOT-INF/lib/
Spring-Boot-Classpath-Index: BOOT-INF/classpath.idx
Spring-Boot-Layers-Index: BOOT-INF/layers.idx
```

`Main-Class` é o atributo que a JVM lê, o mesmo que o jar sombreado da aula 8 tinha. Aqui ele não
aponta para a livraria. Aponta para `JarLauncher`, e a classe da livraria fica em `Start-Class`, um
atributo que só o Spring Boot lê. `Spring-Boot-Classes` e `Spring-Boot-Lib` dizem ao inicializador
onde está o resto.

O desvio existe porque **o class loader da JVM não carrega uma classe de um jar que está dentro de
outro jar**. Ele lê diretórios e arquivos jar no class path, e um jar aninhado não é nenhum dos dois.
Então o `java -jar` inicia a única classe que consegue alcançar, `JarLauncher`, que é uma classe comum
no topo do jar. O inicializador monta um class loader próprio sobre `BOOT-INF/classes` e cada jar de
`BOOT-INF/lib`, e então chama `BookshopApplication.main` por meio dele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"O jar executável guarda quatro coisas: o manifesto, o inicializador do Spring Boot como classes comuns, as classes da livraria em BOOT-INF/classes e 112 jars de bibliotecas guardados inteiros em BOOT-INF/lib. O java -jar lê Main-Class e executa o inicializador, o inicializador monta um class loader sobre as classes e os jars aninhados e então chama o método main da Start-Class.\"><defs><marker id=\"l23-ah\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">bookshop-0.1.0.jar</text><rect x=\"20\" y=\"30\" width=\"430\" height=\"262\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"36\" y=\"44\" width=\"398\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"48\" y=\"57\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">META-INF/MANIFEST.MF</text><text x=\"48\" y=\"73\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Main-Class e Start-Class</text><rect x=\"36\" y=\"96\" width=\"398\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"48\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">org/springframework/boot/loader/</text><text x=\"48\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o inicializador, como classes comuns</text><rect x=\"36\" y=\"148\" width=\"398\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"48\" y=\"161\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">BOOT-INF/classes/</text><text x=\"48\" y=\"177\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">as classes e arquivos da livraria</text><rect x=\"36\" y=\"200\" width=\"398\" height=\"80\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"48\" y=\"213\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">BOOT-INF/lib/</text><text x=\"48\" y=\"229\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">112 jars, cada um guardado inteiro, sem compressão</text><rect x=\"48\" y=\"242\" width=\"180\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"56\" y=\"255\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">spring-core-7.0.9.jar</text><rect x=\"238\" y=\"242\" width=\"180\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"246\" y=\"255\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">hibernate-core-7.4.5.Final.jar</text><text x=\"482\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1  o java -jar lê Main-Class</text><text x=\"482\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2  o JarLauncher monta um class loader</text><text x=\"482\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3  ele chama o main() da Start-Class</text><path d=\"M 478 64 L 438 64\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l23-ah)\"></path><path d=\"M 478 116 L 438 116\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l23-ah)\"></path><path d=\"M 478 168 L 438 168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l23-ah)\"></path><text x=\"498\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sobre classes/ e lib/</text><path d=\"M 678 116 L 700 116\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M 700 116 L 700 250\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M 700 250 L 438 250\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l23-ah)\" stroke-dasharray=\"3 3\"></path><text x=\"482\" y=\"236\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">e lê os jars aninhados no lugar</text></svg>", "caption": "Um arquivo, lido em três passos. Só o inicializador é uma classe que a JVM consegue carregar sozinha; todo o resto é alcançado por meio dele."}
```

Para isso ser rápido, um jar aninhado precisa poder ser lido onde está, sem ser desempacotado antes.
O `unzip -v` mostra como cada entrada está guardada:

```
ana@vm:~/bookshop$ unzip -v target/bookshop-0.1.0.jar | grep -E 'hibernate-core|BookshopApplication.class'
     753  Defl:N      421  44% 2026-10-22 20:09 ff19c656  BOOT-INF/classes/com/example/bookshop/BookshopApplication.class
15279748  Stored 15279748   0% 1980-02-01 00:00 e10da7f3  BOOT-INF/lib/hibernate-core-7.4.5.Final.jar
```

A classe da livraria está `Defl:N`, comprimida como qualquer arquivo num zip. O jar do Hibernate, com
15 MB, está **`Stored`**: os bytes exatos, numa posição conhecida do arquivo externo, que o
inicializador abre no lugar. Comprimi-lo de novo quase não ganharia nada, já que um jar já é
comprimido por dentro. Repare também na data: todo jar aninhado leva `1980-02-01 00:00`, igual em todo
build, então as mesmas bibliotecas dão os mesmos bytes sempre que são empacotadas. Duas seções adiante,
é isso que deixa o Docker reconhecer uma camada que ele já tem.

O inicializador é um punhado de classes, e `JarLauncher` é uma de três:

```
ana@vm:~/bookshop$ jar tf target/bookshop-0.1.0.jar | grep 'loader/launch/.*Launcher.class'
org/springframework/boot/loader/launch/ExecutableArchiveLauncher.class
org/springframework/boot/loader/launch/JarLauncher.class
org/springframework/boot/loader/launch/Launcher.class
org/springframework/boot/loader/launch/PropertiesLauncher.class
org/springframework/boot/loader/launch/WarLauncher.class
```

`WarLauncher` inicia o mesmo tipo de arquivo empacotado como `.war`, e `PropertiesLauncher` lê o seu
class path de propriedades na inicialização. A livraria não precisa de nenhuma das duas.

Então o entregável é **um arquivo, e um servidor só precisa de um runtime Java 25 para iniciá-lo**:
sem Maven, sem um Tomcat instalado à parte, sem um diretório de bibliotecas ao lado.
