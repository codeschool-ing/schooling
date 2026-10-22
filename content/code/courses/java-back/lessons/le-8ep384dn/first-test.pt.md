---
title: Um primeiro teste, e como ler o que o Maven diz
version: 1
---

A primeira classe a testar é `Isbn`, da lição 6: um método estático, uma string entra, um boolean
sai, e nada mais da livraria envolvido. O projeto da lição 1 tinha uma classe de teste do mesmo
formato, que estava ali para o `mvn package` ter o que rodar. Esta lição lê uma.

Crie `src/test/java/com/example/bookshop/catalogue/IsbnTest.java`. Esta é uma primeira versão, e a
próxima seção a substitui:

```java
package com.example.bookshop.catalogue;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class IsbnTest {

    @Test
    void acceptsAValidIsbn13() {
        assertTrue(Isbn.isValid("9786500000016"));
    }

    @Test
    void refusesAWrongCheckDigit() {
        assertFalse(Isbn.isValid("9786500000017"));
    }

    @Test
    void refusesNull() {
        assertFalse(Isbn.isValid(null));
    }
}
```

Cinco coisas sobre o formato dela, e cada uma importa:

- **Ela fica em `src/test/java`, no mesmo pacote de `Isbn`.** O Maven a compila separado e nunca a
  coloca no jar. Estar no mesmo pacote quer dizer que um teste poderia alcançar um método de
  visibilidade de pacote, embora este só precise do público.
- **Nem a classe nem os métodos são `public`.** O Jupiter os encontra por reflexão e não precisa
  disso. O JUnit 4 precisava, e é por isso que código antigo está cheio de
  `public void testSomething()`.
- **`@Test` marca um método de teste**: sem parâmetros, devolve `void` e passa a menos que algo que
  ele chama lance uma exceção.
- **Uma asserção é um método que lança uma exceção quando sua condição é falsa.** `assertTrue` e
  `assertFalse` vêm de `org.junit.jupiter.api.Assertions`, importados de forma estática para que o
  teste se leia como uma frase. Uma asserção que falha lança `AssertionFailedError`, e é por essa
  exceção que o JUnit sabe que o teste falhou.
- **O nome do método diz o que está sendo afirmado.** É o que o Maven imprime quando o teste falha,
  então `refusesAWrongCheckDigit` conta o que quebrou antes de você abrir um arquivo. `test1` não
  conta nada.

## Rodando

```
ana@vm:~/bookshop$ mvn test
[INFO] Scanning for projects...
[INFO] 
[INFO] ------------------------< com.example:bookshop >------------------------
[INFO] Building bookshop 0.1.0
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- maven-resources-plugin:3.5.0:resources (default-resources) @ bookshop ---
[INFO] Copying 4 resources from src/main/resources to target/classes
[INFO] Copying 3 resources from src/main/resources to target/classes
[INFO] 
[INFO] --- maven-compiler-plugin:3.15.0:compile (default-compile) @ bookshop ---
[INFO] Nothing to compile - all classes are up to date.
[INFO] 
[INFO] --- maven-resources-plugin:3.5.0:testResources (default-testResources) @ bookshop ---
[INFO] skip non existing resourceDirectory /home/ana/bookshop/src/test/resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.15.0:testCompile (default-testCompile) @ bookshop ---
[INFO] Recompiling the module because of changed source code.
[INFO] Compiling 1 source file with javac [debug parameters release 25] to target/test-classes
[INFO] 
[INFO] --- maven-surefire-plugin:3.5.6:test (default-test) @ bookshop ---
[INFO] Using auto detected provider org.apache.maven.surefire.junitplatform.JUnitPlatformProvider
[INFO] 
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running com.example.bookshop.catalogue.IsbnTest
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.081 s -- in com.example.bookshop.catalogue.IsbnTest
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  3.431 s
[INFO] Finished at: 2026-10-22T20:20:11-03:00
[INFO] ------------------------------------------------------------------------
```

Leia de baixo para cima, do jeito que você vai ler toda rodada daqui em diante:

- `BUILD SUCCESS` ou `BUILD FAILURE` é o veredito, e é também o código de saída: 0 ou não. É isso
  que um script, ou mais tarde um servidor de CI, olha.
- `Results:` soma todas as classes: `Tests run: 3, Failures: 0, Errors: 0, Skipped: 0`. Uma
  **falha** (failure) é uma asserção que não se confirmou; um **erro** (error) é qualquer outra
  exceção escapando do teste, como um `NullPointerException` no código testado. As duas derrubam o
  build, e a diferença diz onde olhar: depois de uma falha o código respondeu errado, depois de um
  erro ele nem chegou a responder.
- Acima disso, uma linha `Running` e uma linha `Tests run` por classe de teste, com o tempo dela.
- `Using auto detected provider ... JUnitPlatformProvider` é o surefire dizendo que achou a JUnit
  Platform no classpath de teste, obra do starter.

O surefire também escreve um relatório por classe em `target/surefire-reports`, em texto e em XML:

```
ana@vm:~/bookshop$ ls target/surefire-reports
TEST-com.example.bookshop.catalogue.IsbnTest.xml
com.example.bookshop.catalogue.IsbnTest.txt
ana@vm:~/bookshop$ cat target/surefire-reports/com.example.bookshop.catalogue.IsbnTest.txt
-------------------------------------------------------------------------------
Test set: com.example.bookshop.catalogue.IsbnTest
-------------------------------------------------------------------------------
Tests run: 3, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.081 s -- in com.example.bookshop.catalogue.IsbnTest
```

Os arquivos XML são o que um servidor de CI lê para montar a lista de testes; o curso
`testing-cicd` monta um.

Duas formas de rodar menos. `-q` deixa só avisos e erros, então uma rodada que passa não imprime
nada e só o código de saída diz que ela passou; `-Dtest` escolhe uma classe, ou um método com `#`:

```
ana@vm:~/bookshop$ mvn -q test; echo "exit $?"
exit 0
ana@vm:~/bookshop$ mvn test -Dtest='IsbnTest#refusesNull' | grep 'Tests run'
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.060 s -- in com.example.bookshop.catalogue.IsbnTest
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0
```

Mais uma consequência do ciclo de vida que a lição 1 desenhou: `package` vem depois de `test`. De
agora em diante o `mvn package` roda estes testes antes, e um teste falhando quer dizer nenhum jar.
`-DskipTests` pula os testes, e existe para o caso em que outra coisa acabou de rodá-los.

## Um desvio: um teste que nunca roda

O surefire não roda toda classe de `src/test/java`. Ele roda as que têm nome compatível com os seus
**padrões de inclusão**, que por padrão são `Test*`, `*Test`, `*Tests` e `*TestCase`. Renomeie a
classe para algo que se lê igualmente bem, `IsbnChecks`:

```
ana@vm:~/bookshop$ mv src/test/java/com/example/bookshop/catalogue/IsbnTest.java src/test/java/com/example/bookshop/catalogue/IsbnChecks.java && sed -i 's/class IsbnTest/class IsbnChecks/' src/test/java/com/example/bookshop/catalogue/IsbnChecks.java
ana@vm:~/bookshop$ mvn test | tail -n 12
[INFO] 
[INFO] --- maven-compiler-plugin:3.15.0:testCompile (default-testCompile) @ bookshop ---
[INFO] Recompiling the module because of changed source code.
[INFO] Compiling 1 source file with javac [debug parameters release 25] to target/test-classes
[INFO] 
[INFO] --- maven-surefire-plugin:3.5.6:test (default-test) @ bookshop ---
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  1.672 s
[INFO] Finished at: 2026-10-22T20:20:20-03:00
[INFO] ------------------------------------------------------------------------
```

A classe compilou (`Compiling 1 source file`), o surefire rodou e o cabeçalho `T E S T S` nunca
apareceu. **O build diz `BUILD SUCCESS`, e três testes não verificaram nada.** É o mesmo formato da
restrição da lição 6 que nunca era aplicada: nada falha, então nada parece errado. A lição 19 usa
esses mesmos padrões de propósito, chamando os testes de integração de `*IT` para que o surefire os
deixe para outro plugin. Volte o nome da classe:

```
ana@vm:~/bookshop$ mv src/test/java/com/example/bookshop/catalogue/IsbnChecks.java src/test/java/com/example/bookshop/catalogue/IsbnTest.java && sed -i 's/class IsbnChecks/class IsbnTest/' src/test/java/com/example/bookshop/catalogue/IsbnTest.java
```
