---
title: Um projeto feito à mão
version: 1
---

A imagem errada de uma ferramenta de build é um script: uma lista de comandos que alguém escreveu
para compilar e empacotar o próprio código. O Maven é o contrário. **Você descreve o projeto, e o
Maven já sabe os passos.** Onde estão os fontes, do que eles precisam, o que produzir: isso vai num
arquivo só, e os comandos que transformam tudo num jar são do Maven, os mesmos em todo projeto que
segue as convenções dele.

O projeto desta aula é esse arquivo e duas classes. Ele confere ISBNs, os números impressos na
contracapa de um livro, usando uma biblioteca que não está no JDK, para haver algo de que depender.
As aulas 2 e 3 constroem as mesmas duas classes com o Gradle e com o Bazel.

## A estrutura de diretórios

Crie os diretórios primeiro. Os caminhos não são uma sugestão: são onde o Maven procura.

```sh
mkdir -p ~/isbn-check/src/main/java/com/example/isbn ~/isbn-check/src/test/java/com/example/isbn
cd ~/isbn-check
```

`src/main/java` guarda o programa e `src/test/java` guarda os testes, cada um seguido dos
diretórios do pacote. Essa é a **estrutura padrão de diretórios**, e é por causa dela que o pom
abaixo nunca diz onde fica um arquivo-fonte. Um projeto pode mudá-la, e quase nenhum muda, porque
todo desenvolvedor e toda ferramenta esperam por ela.

## O pom

A descrição do projeto é o `pom.xml`, o **Project Object Model**, na raiz do projeto. Crie-o com
isto:

```schooling-example
{"language": "xml", "file": "pom.xml", "parts": [{"code": "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<project xmlns=\"http://maven.apache.org/POM/4.0.0\"\n         xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n         xsi:schemaLocation=\"http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd\">", "note": "O elemento raiz. Os atributos de namespace e de schema não mudam nada no build; eles deixam o editor conferir o arquivo e completá-lo enquanto você digita."}, {"code": "  <modelVersion>4.0.0</modelVersion>\n", "note": "A versão do formato do POM, não do seu projeto. É `4.0.0` em todo pom que o Maven 3 lê."}, {"code": "  <groupId>com.example</groupId>\n  <artifactId>isbn-check</artifactId>\n  <version>1.0.0</version>\n  <packaging>jar</packaging>\n", "note": "As coordenadas: quem publica o projeto, como ele se chama e qual versão é esta. As três juntas o identificam em qualquer lugar, num repositório e na lista de dependências de outro projeto. `packaging` diz o que o build produz, aqui um jar."}, {"code": "  <properties>\n    <maven.compiler.release>25</maven.compiler.release>\n    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>\n  </properties>\n", "note": "Configurações dos plugins, escritas como propriedades. `maven.compiler.release` faz o `javac` gerar classes de Java 25 e conferir cada chamada contra a biblioteca do Java 25. A codificação fixa como os fontes são lidos, para o build não depender do idioma configurado na máquina."}, {"code": "  <dependencies>\n    <dependency>\n      <groupId>commons-validator</groupId>\n      <artifactId>commons-validator</artifactId>\n      <version>1.11.0</version>\n    </dependency>\n    <dependency>\n      <groupId>org.junit.jupiter</groupId>\n      <artifactId>junit-jupiter</artifactId>\n      <version>6.0.3</version>\n      <scope>test</scope>\n    </dependency>\n  </dependencies>\n", "note": "O que o código precisa e o JDK não tem, cada item nomeado pelas suas coordenadas. O Commons Validator é usado pelo programa; o JUnit Jupiter só pelos testes, e é isso que o escopo `test` diz."}, {"code": "  <build>\n    <pluginManagement>\n      <plugins>\n        <plugin>\n          <artifactId>maven-clean-plugin</artifactId>\n          <version>3.5.0</version>\n        </plugin>\n        <plugin>\n          <artifactId>maven-resources-plugin</artifactId>\n          <version>3.5.0</version>\n        </plugin>\n        <plugin>\n          <artifactId>maven-compiler-plugin</artifactId>\n          <version>3.15.0</version>\n        </plugin>\n        <plugin>\n          <artifactId>maven-surefire-plugin</artifactId>\n          <version>3.5.6</version>\n        </plugin>\n        <plugin>\n          <artifactId>maven-jar-plugin</artifactId>\n          <version>3.5.1</version>\n        </plugin>\n        <plugin>\n          <artifactId>maven-install-plugin</artifactId>\n          <version>3.1.4</version>\n        </plugin>\n        <plugin>\n          <artifactId>maven-deploy-plugin</artifactId>\n          <version>3.1.4</version>\n        </plugin>\n      </plugins>\n    </pluginManagement>\n  </build>", "note": "A versão de cada plugin que o build roda, escrita no arquivo. Sem este bloco o Maven 3.8.7 escolhe versões por conta própria, e a seção sobre plugins mostra o preço disso."}, {"code": "</project>"}]}
```

## O código

O programa pergunta ao Apache Commons Validator se cada argumento é um ISBN. O `ISBNValidator`
aceita as formas de 10 e de 13 dígitos, com ou sem hífens, confere o último dígito e devolve o
número como ISBN-13 sem hífens, ou `null` quando não é um ISBN.

`src/main/java/com/example/isbn/IsbnCheck.java`:

```java
package com.example.isbn;

import org.apache.commons.validator.routines.ISBNValidator;

public class IsbnCheck {

    private static final ISBNValidator ISBN = ISBNValidator.getInstance();

    public static String verdict(String text) {
        String isbn13 = ISBN.validate(text);
        return isbn13 == null ? "invalid" : "valid, ISBN-13 " + isbn13;
    }

    public static void main(String[] args) {
        for (String arg : args) {
            System.out.println(arg + ": " + verdict(arg));
        }
    }
}
```

E uma classe de teste, que dá a ele um ISBN-13 válido, um ISBN-10 que vira o mesmo ISBN-13 e um com
o dígito verificador errado:

`src/test/java/com/example/isbn/IsbnCheckTest.java`:

```java
package com.example.isbn;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

class IsbnCheckTest {

    @Test
    void acceptsAnIsbn13WithHyphens() {
        assertEquals("valid, ISBN-13 9780306406157", IsbnCheck.verdict("978-0-306-40615-7"));
    }

    @Test
    void convertsAnIsbn10() {
        assertEquals("valid, ISBN-13 9780306406157", IsbnCheck.verdict("0-306-40615-2"));
    }

    @Test
    void refusesAWrongCheckDigit() {
        assertEquals("invalid", IsbnCheck.verdict("978-0-306-40615-8"));
    }
}
```

## O primeiro build

Três arquivos, cada um no lugar que a estrutura reserva para ele:

```
ana@vm:~/isbn-check$ find . -type f | sort
./pom.xml
./src/main/java/com/example/isbn/IsbnCheck.java
./src/test/java/com/example/isbn/IsbnCheckTest.java
```

O `mvn compile` é o primeiro build, rodado no diretório que contém o `pom.xml`:

```
ana@vm:~/isbn-check$ mvn compile
[INFO] Scanning for projects...
[INFO] 
[INFO] -----------------------< com.example:isbn-check >-----------------------
[INFO] Building isbn-check 1.0.0
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- maven-resources-plugin:3.5.0:resources (default-resources) @ isbn-check ---
[INFO] skip non existing resourceDirectory /home/ana/isbn-check/src/main/resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.15.0:compile (default-compile) @ isbn-check ---
[INFO] Recompiling the module because of changed source code.
[INFO] Compiling 1 source file with javac [debug release 25] to target/classes
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  0.892 s
[INFO] Finished at: 2026-10-22T19:33:31-03:00
[INFO] ------------------------------------------------------------------------
```

O Maven leu o pom, achou um arquivo-fonte onde a estrutura diz que fica o programa e o compilou
para Java 25 (`release 25`) em `target/classes`. Dois plugins rodaram, cada um citado com a sua
versão, e a seção sobre o ciclo de vida lê linhas como essas com calma. O plugin de recursos não
tinha o que fazer, já que este projeto não tem `src/main/resources`, e disse isso.

Nada foi baixado, porque estas transcrições foram gravadas numa máquina com o cache já cheio. No seu
primeiro build a tela se enche de linhas `Downloading from central` antes de tudo isso, uma para
cada jar e pom que o Maven nunca tinha visto, e isso acontece uma vez por versão de cada arquivo. A
seção sobre repositórios diz para onde eles vão.

```
ana@vm:~/isbn-check$ ls target/classes/com/example/isbn
IsbnCheck.class
```

**O `target/` pertence ao Maven**: tudo que um build produz vai para lá, e nada ali é seu para
editar, porque o próximo build sobrescreve.
