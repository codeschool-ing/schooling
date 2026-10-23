---
title: Plugins, repositórios, e rodar o resultado
version: 1
---

Cada linha do build da seção anterior citava um plugin **e uma versão**, e as versões vinham do
bloco `<build>` do pom. Esse bloco parece cerimônia. É a diferença entre um build que significa a
mesma coisa em qualquer máquina e um que depende de qual Maven calhou de estar instalado.

## O que o Maven escolhe quando o pom não diz

O Maven 3.8.7 traz uma lista própria de versões de plugin para o ciclo de vida, escolhidas quando
essa versão do Maven foi feita, e a usa para todo plugin que o pom não fixa. Para ver essa lista em
ação, guarde o pom, apague o elemento `<build>` dele, faça o build e ponha o pom de volta:

```
ana@vm:~/isbn-check$ cp pom.xml pom.xml.keep
ana@vm:~/isbn-check$ sed -i '/<build>/,/<\/build>/d' pom.xml
ana@vm:~/isbn-check$ mvn -q clean package
[ERROR] COMPILATION ERROR : 
[ERROR] Source option 5 is no longer supported. Use 8 or later.
[ERROR] Target option 5 is no longer supported. Use 8 or later.
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-compiler-plugin:3.1:compile (default-compile) on project isbn-check: Compilation failure: Compilation failure: 
[ERROR] Source option 5 is no longer supported. Use 8 or later.
[ERROR] Target option 5 is no longer supported. Use 8 or later.
[ERROR] -> [Help 1]
[ERROR] 
[ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch.
[ERROR] Re-run Maven using the -X switch to enable full debug logging.
[ERROR] 
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/MojoFailureException
```

Sem o `<build>`, todo plugin é escolha do Maven 3.8.7, e o primeiro que importa é o compilador, na
versão 3.1. Essa versão é mais antiga que o `maven.compiler.release`, então ela ignora a
propriedade, cai num padrão próprio, Java 5, e o JDK 25 se recusa a compilar para Java 5.

Essa falha pelo menos é barulhenta. Dê ao compilador antigo as duas configurações que ele entende,
`source` e `target`, e o build passa. Agora veja o que mais mudou:

```
ana@vm:~/isbn-check$ mvn clean package -Dmaven.compiler.source=25 -Dmaven.compiler.target=25 | grep -E 'plugin:|Tests run|BUILD'
[INFO] --- maven-clean-plugin:2.5:clean (default-clean) @ isbn-check ---
[INFO] --- maven-resources-plugin:2.6:resources (default-resources) @ isbn-check ---
[INFO] --- maven-compiler-plugin:3.1:compile (default-compile) @ isbn-check ---
[INFO] --- maven-resources-plugin:2.6:testResources (default-testResources) @ isbn-check ---
[INFO] --- maven-compiler-plugin:3.1:testCompile (default-testCompile) @ isbn-check ---
[INFO] --- maven-surefire-plugin:2.12.4:test (default-test) @ isbn-check ---
Tests run: 0, Failures: 0, Errors: 0, Skipped: 0
[INFO] --- maven-jar-plugin:2.4:jar (default-jar) @ isbn-check ---
[INFO] BUILD SUCCESS
ana@vm:~/isbn-check$ mv pom.xml.keep pom.xml
```

Todo plugin é mais antigo que o fixado: clean 2.5, resources 2.6, compiler 3.1, surefire 2.12.4,
jar 2.4. O `grep` guarda as linhas que citam um plugin, a contagem de testes e o veredito, e o
último comando põe o pom de verdade de volta.

E ele diz **`Tests run: 0` ao lado de `BUILD SUCCESS`**. O Surefire 2.12.4 não sabe rodar testes
escritos para a JUnit Platform, então não achou nenhum que soubesse rodar, não rodou nenhum e
informou sucesso, enquanto três testes estavam em `src/test/java`. Nada na tela parecia errado. Esse
é o argumento para fixar todo plugin: um build que falha pode ser consertado por quem o lê, e **um
build que passa sem testar nada** não é encontrado por ninguém.

## O único plugin que o pom esqueceu

O `dependency:tree` rodado na seção sobre dependências imprimiu `maven-dependency-plugin:2.8`. O
plugin de dependências não está ligado a nenhuma fase, então o pom acima nunca o citou, e o Maven
usou a versão da mesma lista embutida: 2.8, enquanto a versão atual do plugin no Central é a
3.11.0. Funcionou desta vez. O próximo objetivo que você pedir a ele pode ser um que a 2.8 não tem,
ou faz de outro jeito, e o build continuaria sem dizer qual versão respondeu. Fixe-o como os
outros. **Substitua o elemento `<build>` do `pom.xml` por este**, que acrescenta um `<plugin>` no
fim:

```xml
  <build>
    <pluginManagement>
      <plugins>
        <plugin>
          <artifactId>maven-clean-plugin</artifactId>
          <version>3.5.0</version>
        </plugin>
        <plugin>
          <artifactId>maven-resources-plugin</artifactId>
          <version>3.5.0</version>
        </plugin>
        <plugin>
          <artifactId>maven-compiler-plugin</artifactId>
          <version>3.15.0</version>
        </plugin>
        <plugin>
          <artifactId>maven-surefire-plugin</artifactId>
          <version>3.5.6</version>
        </plugin>
        <plugin>
          <artifactId>maven-jar-plugin</artifactId>
          <version>3.5.1</version>
        </plugin>
        <plugin>
          <artifactId>maven-install-plugin</artifactId>
          <version>3.1.4</version>
        </plugin>
        <plugin>
          <artifactId>maven-deploy-plugin</artifactId>
          <version>3.1.4</version>
        </plugin>
        <plugin>
          <artifactId>maven-dependency-plugin</artifactId>
          <version>3.11.0</version>
        </plugin>
      </plugins>
    </pluginManagement>
  </build>
```

```
ana@vm:~/isbn-check$ mvn dependency:tree | grep maven-dependency-plugin
[INFO] --- maven-dependency-plugin:3.11.0:tree (default-cli) @ isbn-check ---
```

O `pluginManagement` **fixa uma versão sem rodar nada**: ele diz "se este plugin for usado, use
esta versão", seja o ciclo de vida que o chama, seja você que nomeia um dos objetivos dele. O outro
elemento, uma lista `<plugins>` direto dentro de `<build>`, serve para ligar um objetivo a uma fase
ou configurar um, e a aula 17 o usa.

## Repositórios

Um **repositório** é uma árvore de diretórios com jars e poms organizados pelas coordenadas,
servida por HTTP. O **Maven Central** é o público, que todo Maven conhece sem ninguém dizer, em
`repo.maven.apache.org`. O seu **repositório local** em `~/.m2/repository` tem a mesma organização
e é um cache dele, mais o que o `mvn install` pôs ali:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 264\" role=\"img\" aria-label=\"As coordenadas org.junit.jupiter, junit-jupiter, 6.0.3 viram o caminho org/junit/jupiter/junit-jupiter/6.0.3/junit-jupiter-6.0.3.jar, com os pontos do grupo transformados em diretórios. O mesmo caminho existe no Maven Central e no repositório local em ~/.m2/repository. Um jar que falta localmente é baixado do Central uma vez e guardado; todo build da máquina o lê do repositório local.\"><defs><marker id=\"l1r-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"115\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">coordenadas no pom</text><rect x=\"20\" y=\"30\" width=\"190\" height=\"66\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"34\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">org.junit.jupiter</text><text x=\"34\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">junit-jupiter</text><text x=\"34\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6.0.3</text><text x=\"460\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o caminho em que viram, em qualquer repositório</text><rect x=\"280\" y=\"38\" width=\"400\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"294\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">org/junit/jupiter/junit-jupiter/6.0.3/</text><text x=\"294\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">junit-jupiter-6.0.3.jar</text><line x1=\"212\" y1=\"63\" x2=\"276\" y2=\"63\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l1r-ah)\"></line><rect x=\"20\" y=\"150\" width=\"240\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"140\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">repositório local</text><text x=\"140\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">~/.m2/repository</text><rect x=\"440\" y=\"150\" width=\"240\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"560\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Maven Central</text><text x=\"560\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">repo.maven.apache.org/maven2</text><line x1=\"438\" y1=\"190\" x2=\"264\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l1r-ah)\"></line><text x=\"350\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">só quando falta:</text><text x=\"350\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">baixa uma vez e guarda</text><line x1=\"400\" y1=\"90\" x2=\"160\" y2=\"147\" stroke=\"var(--wire)\" stroke-width=\"1.2\" marker-end=\"url(#l1r-ah)\"></line><line x1=\"560\" y1=\"90\" x2=\"560\" y2=\"147\" stroke=\"var(--wire)\" stroke-width=\"1.2\" marker-end=\"url(#l1r-ah)\"></line><line x1=\"140\" y1=\"206\" x2=\"140\" y2=\"236\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l1r-ah)\"></line><text x=\"140\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">todo build desta máquina lê daqui</text></svg>", "caption": "Coordenadas são um endereço. Os pontos do grupo viram diretórios, e o mesmo caminho leva ao mesmo arquivo no Central e no seu repositório local.", "same": ["Maven Central"]}
```

O Maven procura primeiro no repositório local e só pede ao Central o que falta, uma vez. É por isso
que o segundo build de um projeto não imprime downloads e funciona sem rede.

As transcrições deste curso foram gravadas numa máquina que chegava ao Central por um espelho,
porque o Central respondia aos downloads dela com "429 Too Many Requests". Uma transcrição que
mostra um download cita, por isso, `google-maven-central` e um endereço do Google; na sua máquina a
mesma linha diz `central` e `repo.maven.apache.org`. Os arquivos são os do Central nos dois casos,
com os mesmos checksums. Você não precisa de espelho nem de configuração nenhuma para isso.

## Rodando o programa

O jar que o `package` produziu tem as classes do próprio projeto e mais nada:

```
ana@vm:~/isbn-check$ jar tf target/isbn-check-1.0.0.jar
META-INF/
META-INF/MANIFEST.MF
com/
com/example/
com/example/isbn/
com/example/isbn/IsbnCheck.class
META-INF/maven/
META-INF/maven/com.example/
META-INF/maven/com.example/isbn-check/
META-INF/maven/com.example/isbn-check/pom.xml
META-INF/maven/com.example/isbn-check/pom.properties
```

Uma classe nossa, um manifesto e o pom, que o Maven copia para registro. Nada do Commons
Validator, então o comando óbvio falha assim que o programa toca a biblioteca:

```
ana@vm:~/isbn-check$ java -cp target/isbn-check-1.0.0.jar com.example.isbn.IsbnCheck 978-0-306-40615-7
Exception in thread "main" java.lang.NoClassDefFoundError: org/apache/commons/validator/routines/ISBNValidator
	at com.example.isbn.IsbnCheck.<clinit>(IsbnCheck.java:7)
Caused by: java.lang.ClassNotFoundException: org.apache.commons.validator.routines.ISBNValidator
	at java.base/jdk.internal.loader.BuiltinClassLoader.loadClass(BuiltinClassLoader.java:580)
	at java.base/java.lang.ClassLoader.loadClass(ClassLoader.java:490)
	... 1 more
```

`NoClassDefFoundError` é a JVM procurando uma classe na primeira vez que o código precisa dela e não
a achando em parte nenhuma do classpath. O classpath tem de citar todo jar dos escopos `compile` e
`runtime` do programa, e o plugin de dependências escreve essa lista:

```
ana@vm:~/isbn-check$ mvn -q dependency:build-classpath -DincludeScope=runtime -Dmdep.outputFile=classpath.txt
ana@vm:~/isbn-check$ tr ':' '\n' < classpath.txt; echo
/home/ana/.m2/repository/commons-validator/commons-validator/1.11.0/commons-validator-1.11.0.jar
/home/ana/.m2/repository/commons-beanutils/commons-beanutils/1.11.0/commons-beanutils-1.11.0.jar
/home/ana/.m2/repository/commons-digester/commons-digester/2.1/commons-digester-2.1.jar
/home/ana/.m2/repository/commons-logging/commons-logging/1.4.0/commons-logging-1.4.0.jar
/home/ana/.m2/repository/commons-collections/commons-collections/3.2.2/commons-collections-3.2.2.jar
```

O `includeScope=runtime` guarda os escopos `compile` e `runtime` e descarta o `test`: cinco jars, a
biblioteca do programa e as quatro que ela trouxe, todas no seu repositório local, e é por isso que
isto não precisa de rede. O `outputFile` grava a lista num arquivo, unida por dois-pontos do jeito
que o `-cp` quer; o `tr` põe uma por linha para leitura, e o `echo` termina a última linha, que o
arquivo deixa aberta.

```
ana@vm:~/isbn-check$ java -cp target/isbn-check-1.0.0.jar:$(cat classpath.txt) com.example.isbn.IsbnCheck 978-0-306-40615-7 0-306-40615-2 978-0-306-40615-8
978-0-306-40615-7: valid, ISBN-13 9780306406157
0-306-40615-2: valid, ISBN-13 9780306406157
978-0-306-40615-8: invalid
```

Três argumentos e três vereditos, e o ISBN-10 voltou como o mesmo ISBN-13 do primeiro. Digitar um
classpath não é como um programa Java é distribuído, nem como este curso distribui um: a aula 4
constrói uma aplicação Spring Boot cujo jar leva as dependências dentro dele, e a aula 23 abre esse
jar para ver como.
