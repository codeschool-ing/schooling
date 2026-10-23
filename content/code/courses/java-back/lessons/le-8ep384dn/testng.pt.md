---
title: O TestNG, e por que o Spring escolheu o JUnit
version: 1
---

O **TestNG** é o outro framework de testes do mundo Java. Ele surgiu em 2004, quando o JUnit estava
na versão 3, e trouxe ideias que o JUnit levou anos para adotar: anotações no lugar de nomes de
método começando com `test`, testes parametrizados e grupos de testes escolhidos por um arquivo, e
não pelo build. Você o encontra em código corporativo mais antigo, em suítes de Selenium escritas
nos anos 2010 e em projetos cujos testes são cenários longos, e não verificações pequenas.

Quase tudo o que ele faz, o Jupiter hoje também faz. O que continua diferente é uma decisão, e ela é
o contrário da que a seção anterior desenhou: **o TestNG cria UMA instância da classe de teste e roda
todos os métodos nela**, e deixa um teste dizer quais outros testes precisam passar antes.

Esta seção monta um projeto mínimo fora da livraria, para que os dois frameworks nunca dividam um
classpath. Crie `~/testng-look` com quatro arquivos.

## O projeto

`pom.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>com.example</groupId>
  <artifactId>testng-look</artifactId>
  <version>1.0.0</version>

  <properties>
    <maven.compiler.release>25</maven.compiler.release>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
  </properties>

  <dependencies>
    <dependency>
      <groupId>org.testng</groupId>
      <artifactId>testng</artifactId>
      <version>7.12.0</version>
      <scope>test</scope>
    </dependency>
  </dependencies>

  <build>
    <plugins>
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
        <configuration>
          <suiteXmlFiles>
            <suiteXmlFile>testng.xml</suiteXmlFile>
          </suiteXmlFiles>
        </configuration>
      </plugin>
    </plugins>
  </build>
</project>
```

Aqui não há parent do Spring, então nada escolhe as versões dos plugins por você, e as escolhas do
próprio Maven 3.8.7 são antigas (a lição 1 mostrou o quanto isso custa). Os três plugins fixados são
os três que o `mvn test` roda. O surefire é o mesmo plugin que roda os testes JUnit da livraria: ele
olha o classpath de teste, encontra o TestNG no lugar da JUnit Platform e usa o seu provider de
TestNG. A única linha de configuração entrega a ele um arquivo de suíte.

`src/main/java/look/Shelf.java`, a classe testada, conta exemplares por título:

```java
package look;

import java.util.HashMap;
import java.util.Map;

public class Shelf {

    private final Map<String, Integer> copies = new HashMap<>();

    public void add(String title, int count) {
        copies.merge(title, count, Integer::sum);
    }

    public void take(String title) {
        int left = count(title);
        if (left == 0) {
            throw new IllegalStateException("No copies of " + title);
        }
        copies.put(title, left - 1);
    }

    public int count(String title) {
        return copies.getOrDefault(title, 0);
    }
}
```

`src/test/java/look/ShelfTest.java`:

```schooling-example
{
  "language": "java",
  "file": "ShelfTest.java",
  "parts": [
    {
      "code": "package look;\n\nimport static org.testng.Assert.assertEquals;\n\nimport org.testng.annotations.DataProvider;\nimport org.testng.annotations.Test;\n",
      "note": "`assertEquals` vem de `org.testng.Assert`, e **os argumentos estão na ordem contrária à do JUnit: primeiro o obtido, depois o esperado.** Uma linha copiada de um framework para o outro compila, e a mensagem de falha chama de esperado o lado errado."
    },
    {
      "code": "public class ShelfTest {\n\n    private final Shelf shelf = new Shelf();\n",
      "note": "O TestNG cria um único `ShelfTest` para a classe toda, então este `shelf` é compartilhado por todos os métodos que o usam."
    },
    {
      "code": "    @Test\n    public void startsEmpty() {\n        assertEquals(shelf.count(\"Dom Casmurro\"), 0);\n    }\n\n    @Test(dependsOnMethods = \"startsEmpty\")\n    public void addsCopies() {\n        shelf.add(\"Dom Casmurro\", 2);\n        assertEquals(shelf.count(\"Dom Casmurro\"), 2);\n    }\n\n    @Test(dependsOnMethods = \"addsCopies\")\n    public void takesOne() {\n        shelf.take(\"Dom Casmurro\");\n        assertEquals(shelf.count(\"Dom Casmurro\"), 1);\n    }\n",
      "note": "Três testes que são um cenário só, em passos. **`dependsOnMethods` fixa a ordem e acrescenta uma regra: quando o método nomeado falha, este é pulado em vez de rodar.** `takesOne` só faz sentido numa estante que `addsCopies` encheu."
    },
    {
      "code": "    @DataProvider\n    public Object[][] deliveries() {\n        return new Object[][] {\n                {1, 0, 1},\n                {2, 3, 5},\n                {0, 0, 0}\n        };\n    }\n\n    @Test(dataProvider = \"deliveries\")\n    public void addsUpTwoDeliveries(int first, int second, int expected) {\n        Shelf fresh = new Shelf();\n        fresh.add(\"Iracema\", first);\n        fresh.add(\"Iracema\", second);\n        assertEquals(fresh.count(\"Iracema\"), expected);\n    }\n",
      "note": "Um **data provider** é um método que devolve linhas. O teste o nomeia e roda uma vez por linha, como o `@CsvSource`, só que com as linhas montadas em Java. Este teste cria a própria `Shelf`: usar o campo compartilhado faria cada linha depender das anteriores."
    },
    {
      "code": "    @Test(groups = \"stress\")\n    public void holdsAMillionCopies() {\n        Shelf big = new Shelf();\n        for (int i = 0; i < 1_000_000; i++) {\n            big.add(\"Senhora\", 1);\n        }\n        assertEquals(big.count(\"Senhora\"), 1_000_000);\n    }",
      "note": "Um **grupo** é um rótulo. Nada na classe decide se isto roda; quem decide é o arquivo de suíte, abaixo."
    },
    {
      "code": "}"
    }
  ]
}
```

`testng.xml`, na raiz do projeto, ao lado do pom:

```xml
<!DOCTYPE suite SYSTEM "https://testng.org/testng-1.0.dtd">
<suite name="shelf">
  <test name="everything but stress">
    <groups>
      <run>
        <exclude name="stress"/>
      </run>
    </groups>
    <classes>
      <class name="look.ShelfTest"/>
    </classes>
  </test>
</suite>
```

Um arquivo de **suíte** é a forma do próprio TestNG de dizer o que rodar: quais classes, quais
grupos entram ou saem, em que ordem, em paralelo ou não. O JUnit deixa essa escolha para a
ferramenta de build; o TestNG a coloca num arquivo que o time versiona ao lado dos testes.

## Rodando

A primeira rodada baixa o TestNG e o provider de TestNG do surefire. Depois disso:

```
ana@vm:~/testng-look$ mvn test
[INFO] Scanning for projects...
[INFO] 
[INFO] ----------------------< com.example:testng-look >-----------------------
[INFO] Building testng-look 1.0.0
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- maven-resources-plugin:3.5.0:resources (default-resources) @ testng-look ---
[INFO] skip non existing resourceDirectory /home/ana/testng-look/src/main/resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.15.0:compile (default-compile) @ testng-look ---
[INFO] Nothing to compile - all classes are up to date.
[INFO] 
[INFO] --- maven-resources-plugin:3.5.0:testResources (default-testResources) @ testng-look ---
[INFO] skip non existing resourceDirectory /home/ana/testng-look/src/test/resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.15.0:testCompile (default-testCompile) @ testng-look ---
[INFO] Nothing to compile - all classes are up to date.
[INFO] 
[INFO] --- maven-surefire-plugin:3.5.6:test (default-test) @ testng-look ---
[INFO] Using auto detected provider org.apache.maven.surefire.testng.TestNGProvider
[INFO] 
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running TestSuite
SLF4J(W): No SLF4J providers were found.
SLF4J(W): Defaulting to no-operation (NOP) logger implementation
SLF4J(W): See https://www.slf4j.org/codes.html#noProviders for further details.
[INFO] Tests run: 6, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.392 s -- in TestSuite
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 6, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  1.161 s
[INFO] Finished at: 2026-10-22T20:21:07-03:00
[INFO] ------------------------------------------------------------------------
```

Três diferenças em relação às rodadas da livraria, cada uma com um motivo:

- `Using auto detected provider ... TestNGProvider`: o mesmo surefire, outro provider, escolhido
  pelo que está no classpath de teste.
- `Running TestSuite`: com um arquivo de suíte, o surefire relata a suíte inteira como uma classe só,
  chamada `TestSuite`, em vez de uma linha por classe de teste.
- **As três linhas `SLF4J(W)`** vêm do TestNG, que registra seus logs pela fachada SLF4J. A lição 16
  separou fachada e backend, e este projeto tem a fachada sem backend, então o SLF4J avisa que não
  vai registrar nada. São avisos sobre o log do próprio TestNG, não sobre os testes.

`Tests run: 6`: os três passos do cenário e as três linhas do data provider. `holdsAMillionCopies`
não está entre eles, porque a suíte exclui o grupo dele.

## Um teste que depende de outro

Faça `addsCopies` esperar três exemplares em vez de dois, como se o código tivesse um bug que só ele
enxerga:

```
ana@vm:~/testng-look$ sed -i 's/assertEquals(shelf.count("Dom Casmurro"), 2);/assertEquals(shelf.count("Dom Casmurro"), 3);/' src/test/java/look/ShelfTest.java
ana@vm:~/testng-look$ mvn test | grep -E "Tests run:|FAILURE!|expected|BUILD"
SLF4J(W): No SLF4J providers were found.
SLF4J(W): Defaulting to no-operation (NOP) logger implementation
SLF4J(W): See https://www.slf4j.org/codes.html#noProviders for further details.
[ERROR] Tests run: 6, Failures: 1, Errors: 0, Skipped: 1, Time elapsed: 0.368 s <<< FAILURE! -- in TestSuite
[ERROR] look.ShelfTest.addsCopies -- Time elapsed: 0.005 s <<< FAILURE!
java.lang.AssertionError: expected [3] but found [2]
[ERROR]   ShelfTest.addsCopies:20 expected [3] but found [2]
[ERROR] Tests run: 6, Failures: 1, Errors: 0, Skipped: 1
[INFO] BUILD FAILURE
```

Uma falha, e **`Skipped: 1`**. A mensagem, `expected [3] but found [2]`, tem os dois números do
lado certo só porque a chamada os pôs na ordem do TestNG, o obtido primeiro. O arquivo de resultados
do próprio TestNG diz qual teste foi pulado:

```
ana@vm:~/testng-look$ grep -o '<test-method [^>]*status="[A-Z]*"' target/surefire-reports/testng-results.xml | grep -o 'name="[^"]*"\|status="[A-Z]*"' | paste - -
name="startsEmpty"	status="PASS"
name="addsUpTwoDeliveries"	status="PASS"
name="addsUpTwoDeliveries"	status="PASS"
name="addsUpTwoDeliveries"	status="PASS"
name="addsCopies"	status="FAIL"
name="takesOne"	status="SKIP"
```

`takesOne` nunca rodou: `addsCopies`, de quem ele depende, falhou. O relatório é honesto, uma falha
e um teste que não teria nada a dizer, em vez de uma segunda falha que só ecoa a primeira. O custo é
que a classe agora é uma sequência: `takesOne` não pode ser entendido, nem rodado, sem os dois testes antes
dele, e os três dividem a mesma `shelf`. **O JUnit faz a escolha oposta, uma instância nova por
teste, para que nenhum teste dependa de outro por acidente.** Volte a expectativa:

```
ana@vm:~/testng-look$ sed -i 's/assertEquals(shelf.count("Dom Casmurro"), 3);/assertEquals(shelf.count("Dom Casmurro"), 2);/' src/test/java/look/ShelfTest.java
```

## Grupos

O arquivo de suíte exclui `stress`. Troque a exclusão por uma inclusão e só esse grupo roda; desfaça
a troca e os seis voltam a rodar:

```
ana@vm:~/testng-look$ sed -i 's/<exclude name="stress"\/>/<include name="stress"\/>/' testng.xml && grep -n 'stress' testng.xml
3:  <test name="everything but stress">
6:        <include name="stress"/>
ana@vm:~/testng-look$ mvn test | grep -E "Tests run:|BUILD"
SLF4J(W): No SLF4J providers were found.
SLF4J(W): Defaulting to no-operation (NOP) logger implementation
SLF4J(W): See https://www.slf4j.org/codes.html#noProviders for further details.
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.354 s -- in TestSuite
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
ana@vm:~/testng-look$ sed -i 's/<include name="stress"\/>/<exclude name="stress"\/>/' testng.xml && mvn test | grep -E "Tests run:|BUILD"
SLF4J(W): No SLF4J providers were found.
SLF4J(W): Defaulting to no-operation (NOP) logger implementation
SLF4J(W): See https://www.slf4j.org/codes.html#noProviders for further details.
[INFO] Tests run: 6, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.355 s -- in TestSuite
[INFO] Tests run: 6, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

Nada no Java mudou entre as duas rodadas. Quais testes formam "a suíte rápida" ou "a suíte da
madrugada" é decidido num XML ao lado dos testes, e um time pode manter vários arquivos de suíte. O
equivalente no JUnit é `@Tag("stress")` no teste e `-Dgroups=stress` ou `-DexcludedGroups=stress` na
linha de comando do Maven: a mesma escolha, feita pelo build em vez de por um arquivo do framework.

## Por que a livraria usa JUnit

Nada acima está fora do alcance do JUnit. O Jupiter tem `@Tag` para grupos, `@ParameterizedTest`
para data providers e `@TestMethodOrder` com `@Order` para uma sequência fixa. O que ele deixa de
fora de propósito é um teste pulado porque outro falhou: os testes dele são feitos para ser
independentes, e é por isso que ele cria uma instância nova para cada um.

O motivo de projetos Spring usarem JUnit não é uma comparação de recursos. É o que já está no pom. O
`spring-boot-starter-test` traz o JUnit Jupiter e nada do TestNG. **`@SpringBootTest`, e o
`@DataJpaTest` que a lição 19 usa, carregam `@ExtendWith(SpringExtension.class)`**, que é uma
extensão do Jupiter: ponha qualquer um deles numa classe TestNG e ninguém o lê. O Spring ainda
suporta o TestNG, por meio de uma classe base que o seu teste estende,
`AbstractTestNGSpringContextTests`; do que você abre mão é das escolhas do starter e de todo guia
escrito em cima delas. O JUnit mais antigo é que está sendo aposentado pelo Spring: o runner do
JUnit 4, `SpringRunner`, está deprecated desde o Spring Framework 7.0.

Então vale saber ler o TestNG quando você o herda, e vale escolhê-lo para uma suíte de cenários
longos e ordenados que, de outro jeito, repetiriam a preparação em cada teste. Para a livraria, e
para as próximas três lições, é JUnit.
