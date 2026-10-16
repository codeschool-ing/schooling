---
title: Um jar que roda, e o build que roda no Java errado
version: 1
---

Um jar é um arquivo zip de arquivos de classe com um pequeno arquivo de texto dentro, o
**manifesto**, que diz coisas sobre o resto. O `java -jar` executa um jar, e para isso lê uma linha
do manifesto. O jar que a seção 04 construiu não tem essa linha:

```
ana@vm:~/library$ java -jar target/library-1.0-SNAPSHOT.jar
no main manifest attribute, in target/library-1.0-SNAPSHOT.jar
```

**`no main manifest attribute`** (nenhum atributo principal no manifesto): a JVM abriu o jar, leu o
manifesto e não encontrou `Main-Class`, então não tinha classe por onde começar. Nada diz ao Maven
qual das classes de um projeto tem o `main` a executar; uma biblioteca não tem nenhum e um programa
grande pode ter vários. O plugin de jar escreve a linha quando lhe dizem, na configuração dele. Este é
o `pom.xml` inteiro de novo, com um acréscimo no fim, um elemento `<plugins>` depois do
`pluginManagement`:

```xml
<!-- pom.xml -->
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>com.example</groupId>
  <artifactId>library</artifactId>
  <version>1.0-SNAPSHOT</version>

  <properties>
    <maven.compiler.release>25</maven.compiler.release>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
  </properties>

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
          <version>3.2.0</version>
        </plugin>
      </plugins>
    </pluginManagement>
    <plugins>
      <plugin>
        <artifactId>maven-jar-plugin</artifactId>
        <configuration>
          <archive>
            <manifest>
              <mainClass>com.example.library.App</mainClass>
            </manifest>
          </archive>
        </configuration>
      </plugin>
    </plugins>
  </build>
</project>
```

A primeira linha, `<!-- pom.xml -->`, é um comentário XML que diz qual arquivo é este, e o Maven o
ignora. O novo `<plugin>` não traz `<version>`: vale a do `pluginManagement`. **O `pluginManagement`
decide a versão de um plugin, e o `plugins` decide o que ele faz**, e é por isso que o curso mantém os
dois separados. O `-q`, quiet (silencioso), não imprime nada além de avisos e erros, que é como fica
um build que funciona quando você já confia nele:

```
ana@vm:~/library$ mvn -q package
WARNING: A terminally deprecated method in sun.misc.Unsafe has been called
WARNING: sun.misc.Unsafe::objectFieldOffset has been called by com.google.common.util.concurrent.AbstractFuture$UnsafeAtomicHelper (file:/usr/share/maven/lib/guava.jar)
WARNING: Please consider reporting this to the maintainers of class com.google.common.util.concurrent.AbstractFuture$UnsafeAtomicHelper
WARNING: sun.misc.Unsafe::objectFieldOffset will be removed in a future release
ana@vm:~/library$ java -jar target/library-1.0-SNAPSHOT.jar
The library has Effective Java
ana@vm:~/library$ jar tf target/library-1.0-SNAPSHOT.jar
META-INF/
META-INF/MANIFEST.MF
com/
com/example/
com/example/library/
META-INF/maven/
META-INF/maven/com.example/
META-INF/maven/com.example/library/
com/example/library/Book.class
com/example/library/App.class
META-INF/maven/com.example/library/pom.xml
META-INF/maven/com.example/library/pom.properties
ana@vm:~/library$ jar xf target/library-1.0-SNAPSHOT.jar META-INF/MANIFEST.MF && cat META-INF/MANIFEST.MF
Manifest-Version: 1.0
Created-By: Maven JAR Plugin 3.5.1
Java-Version: 25
Build-Jdk-Spec: 25
Main-Class: com.example.library.App
```

**`Main-Class: com.example.library.App`**, o nome completo, e agora o `java -jar` o inicia. A
listagem mostra o que mais há num jar do Maven: os diretórios do pacote com as duas classes, e uma
cópia do `pom.xml` sob `META-INF/maven`, para que um jar encontrado sozinho ainda diga de onde veio. O
`java -jar` ignora o `-cp`: tudo o que o programa precisa tem de estar no jar ou nomeado no
manifesto, o que importa no dia em que um projeto usa uma biblioteca, no `java-back`.

## O build no Java errado

A seção 04 da lição 1 deixou uma promessa: com o `JAVA_HOME` apontando para o `default-java` do
Ubuntu, que é o Java 21 que veio com o Maven, o primeiro projeto que pede o 25 falha. Aqui está:

```
ana@vm:~/library$ JAVA_HOME=/usr/lib/jvm/default-java mvn -q clean package
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-compiler-plugin:3.15.0:compile (default-compile) on project library: Fatal error compiling: error: release version 25 not supported -> [Help 1]
[ERROR] 
[ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch.
[ERROR] Re-run Maven using the -X switch to enable full debug logging.
[ERROR] 
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/MojoExecutionException
ana@vm:~/library$ mvn -q clean package && echo built
WARNING: A terminally deprecated method in sun.misc.Unsafe has been called
WARNING: sun.misc.Unsafe::objectFieldOffset has been called by com.google.common.util.concurrent.AbstractFuture$UnsafeAtomicHelper (file:/usr/share/maven/lib/guava.jar)
WARNING: Please consider reporting this to the maintainers of class com.google.common.util.concurrent.AbstractFuture$UnsafeAtomicHelper
WARNING: sun.misc.Unsafe::objectFieldOffset will be removed in a future release
built
```

**`release version 25 not supported`** (versão 25 não suportada), de dentro do plugin do compilador:
o Maven rodou no Java 21, e o `javac` do Java 21 não consegue produzir arquivos de classe da versão
69. A mensagem nunca diz que o Maven estava no Java errado. Você tem de saber que a versão da mensagem
é a do `pom.xml`, e que o JDK que a recusa é aquele que o Maven encontrou. Repare também no que falta:
no Java 21 os quatro avisos de `Unsafe` da seção 04 não aparecem, porque só o Java 24 em diante os
imprime.

O segundo comando, com o `JAVA_HOME` sem valor, construiu sem problema. **Quando um build diz que uma
versão não é suportada, rode `mvn -v` e leia a linha `Java version`** antes de qualquer outra coisa.
