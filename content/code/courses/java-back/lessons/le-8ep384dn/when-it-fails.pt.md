---
title: Um teste falhando, lido
version: 1
---

Um teste se paga no dia em que falha, e esse dia não é hora de estar aprendendo a ler a saída. Então
quebre a regra de propósito. O dígito verificador é a distância da soma até o próximo múltiplo de
dez, e a lição 6 explicou o `% 10` de fora em `(10 - sum % 10) % 10`: ele existe para uma soma que já
termina em 0. É também exatamente o tipo de coisa que alguém apaga achando que sobra. Faça isso:

```
ana@vm:~/bookshop$ sed -i 's/int check = (10 - sum % 10) % 10;/int check = 10 - sum % 10;/' src/main/java/com/example/bookshop/catalogue/Isbn.java && grep -n 'int check' src/main/java/com/example/bookshop/catalogue/Isbn.java
18:        int check = 10 - sum % 10;
```

E rode os testes:

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
[INFO] Recompiling the module because of changed source code.
[INFO] Compiling 33 source files with javac [debug parameters release 25] to target/classes
[INFO] 
[INFO] --- maven-resources-plugin:3.5.0:testResources (default-testResources) @ bookshop ---
[INFO] skip non existing resourceDirectory /home/ana/bookshop/src/test/resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.15.0:testCompile (default-testCompile) @ bookshop ---
[INFO] Recompiling the module because of changed dependency.
[INFO] Compiling 1 source file with javac [debug parameters release 25] to target/test-classes
[INFO] 
[INFO] --- maven-surefire-plugin:3.5.6:test (default-test) @ bookshop ---
[INFO] Using auto detected provider org.apache.maven.surefire.junitplatform.JUnitPlatformProvider
[INFO] 
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running com.example.bookshop.catalogue.IsbnTest
[ERROR] Tests run: 10, Failures: 1, Errors: 0, Skipped: 0, Time elapsed: 0.237 s <<< FAILURE! -- in com.example.bookshop.catalogue.IsbnTest
[ERROR] com.example.bookshop.catalogue.IsbnTest.acceptsAValidIsbn13(String)[3] -- Time elapsed: 0.009 s <<< FAILURE!
org.opentest4j.AssertionFailedError: expected: <true> but was: <false>
	at org.junit.jupiter.api.AssertionFailureBuilder.build(AssertionFailureBuilder.java:158)
	at org.junit.jupiter.api.AssertionFailureBuilder.buildAndThrow(AssertionFailureBuilder.java:139)
	at org.junit.jupiter.api.AssertTrue.failNotTrue(AssertTrue.java:69)
	at org.junit.jupiter.api.AssertTrue.assertTrue(AssertTrue.java:41)
	at org.junit.jupiter.api.AssertTrue.assertTrue(AssertTrue.java:35)
	at org.junit.jupiter.api.Assertions.assertTrue(Assertions.java:195)
	at com.example.bookshop.catalogue.IsbnTest.acceptsAValidIsbn13(IsbnTest.java:16)

[INFO] 
[INFO] Results:
[INFO] 
[ERROR] Failures: 
[ERROR]   IsbnTest.acceptsAValidIsbn13:16 expected: <true> but was: <false>
[INFO] 
[ERROR] Tests run: 10, Failures: 1, Errors: 0, Skipped: 0
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  4.494 s
[INFO] Finished at: 2026-10-22T20:20:36-03:00
[INFO] ------------------------------------------------------------------------
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-surefire-plugin:3.5.6:test (default-test) on project bookshop: There are test failures.
[ERROR] 
[ERROR] See /home/ana/bookshop/target/surefire-reports for the individual test results.
[ERROR] See dump files (if any exist) [date].dump, [date]-jvmRun[N].dump and [date].dumpstream.
[ERROR] -> [Help 1]
[ERROR] 
[ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch.
[ERROR] Re-run Maven using the -X switch to enable full debug logging.
[ERROR] 
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/MojoFailureException
```

## Lendo

Comece de novo por baixo, e depois vá ao único lugar que diz o que aconteceu.

- **`BUILD FAILURE`**, e o Maven sai com código diferente de zero. O `mvn package` também teria
  parado aqui, e nenhum jar teria sido gerado.
- **`Tests run: 10, Failures: 1`**: uma das dez invocações falhou, as outras nove passaram.
- **A linha de resumo** sob `Failures:` é a forma curta: classe, método, a linha do teste que falhou
  (`:16`) e a mensagem.
- **O bloco do meio é a forma longa.** A primeira linha dá o nome do teste,
  `IsbnTest.acceptsAValidIsbn13(String)[3]`. A segunda é a exceção e a mensagem dela. Depois vem o
  stack trace, quase todo feito de frames do próprio JUnit; o que importa é o último, a linha do seu
  teste, `IsbnTest.java:16`, que é a chamada a `assertTrue`.

A mensagem é a parte fraca: `expected: <true> but was: <false>`. É verdade e não diz nada sobre
livros. **`assertTrue` só enxerga um boolean**, então é só isso que ele consegue relatar. O que diz
alguma coisa é o índice: `[3]`, o terceiro valor do `@ValueSource`, que é `9786500000030`,
Frankenstein. Os nomes de exibição da seção anterior o teriam impresso por extenso.

Então a regra quebrada recusa um livro de verdade, e o motivo é aritmético. Os produtos ponderados
dos doze primeiros dígitos de Frankenstein somam 70. A regra certa dá `(10 - 0) % 10`, que é 0, e o
ISBN termina em 0. A quebrada dá `10 - 0`, que é 10, e nenhum dígito sozinho vale 10. **Todo ISBN cujo
dígito verificador é 0 passa a ser recusado**, mais ou menos um livro em cada dez, e todos os outros
ISBNs continuam passando.

## O mesmo bug, e um build verde

Agora tire Frankenstein da lista, como se ele nunca tivesse sido escrito:

```
ana@vm:~/bookshop$ sed -i 's/"9786500000023", "9786500000030", /"9786500000023", /' src/test/java/com/example/bookshop/catalogue/IsbnTest.java && grep -n '@ValueSource' src/test/java/com/example/bookshop/catalogue/IsbnTest.java
14:    @ValueSource(strings = {"9786500000016", "9786500000023", "9780306406157"})
ana@vm:~/bookshop$ mvn test | grep -E "Tests run:|BUILD"
[INFO] Tests run: 9, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.178 s -- in com.example.bookshop.catalogue.IsbnTest
[INFO] Tests run: 9, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

**Nove testes, nenhuma falha, `BUILD SUCCESS`, e a regra continua quebrada.** Nenhum dos três ISBNs
que sobraram termina em 0, então nenhum deles enxerga a diferença. Um teste que passa diz que os
casos que alguém anotou se comportam como foi anotado, e nada sobre os que ninguém anotou. É por
isso que a linha de Frankenstein está no `IsbnTest` final: é a única entrada que distingue as duas
regras. Escolher as linhas é o trabalho de verdade de escrever um teste, e a pergunta a fazer a cada
uma é que erro ela pegaria.

Volte os dois arquivos, a regra e o teste, e confira que tudo passa de novo:

```
ana@vm:~/bookshop$ sed -i 's/int check = 10 - sum % 10;/int check = (10 - sum % 10) % 10;/' src/main/java/com/example/bookshop/catalogue/Isbn.java
ana@vm:~/bookshop$ sed -i 's/"9786500000023", /"9786500000023", "9786500000030", /' src/test/java/com/example/bookshop/catalogue/IsbnTest.java && grep -n '@ValueSource' src/test/java/com/example/bookshop/catalogue/IsbnTest.java
14:    @ValueSource(strings = {"9786500000016", "9786500000023", "9786500000030", "9780306406157"})
ana@vm:~/bookshop$ mvn -q test; echo "exit $?"
exit 0
```
