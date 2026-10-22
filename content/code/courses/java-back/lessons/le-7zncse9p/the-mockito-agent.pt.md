---
title: O aviso, e o Mockito carregado como agente
version: 1
---

Os testes passaram, e no meio deles a JVM que rodou `OrderServiceTest` imprimiu seis linhas que
ninguém pediu. Vale lê-las em ordem, porque contam uma só história por três lados.

**O Mockito falou primeiro.** Desde a versão 5, o jeito padrão de ele criar mocks é o **inline mock
maker**, que reescreve o bytecode da classe que imita enquanto o programa roda. É isso que permite
fazer mock de uma classe final ou de um método de um record, e para isso ele precisa de
`java.lang.instrument`, a interface da JVM para alterar classes já carregadas. Um programa obtém essa
interface sendo um **agente Java**, e o Mockito virou um se anexando à própria JVM no meio da
execução. A mensagem dele diz que isso vai deixar de funcionar e pede que ele seja adicionado "as an
agent to your build".

**Depois falou a JVM.** As quatro linhas `WARNING:` são o lado do JDK no mesmo acontecimento, uma regra
desde o JDK 21: um agente carregado numa JVM já em execução, em vez de nomeado quando ela inicia, é
relatado, e uma versão futura vai recusá-lo, a menos que a JVM tenha iniciado com
`-XX:+EnableDynamicAgentLoading`. O caminho na primeira linha é o jar que fez o anexo, do Byte Buddy, a
biblioteca com que o Mockito gera classes.

A linha sobre compartilhamento é o terceiro lado, e ela volta mais abaixo.

## Nomeando o agente quando a JVM inicia

A correção que a documentação do Mockito indica é iniciar a JVM dos testes com `-javaagent:` e o
caminho do jar do `mockito-core`. O surefire roda os testes numa JVM só deles, um **fork**, e a
configuração `argLine` é a linha de comando que esse fork recebe. Falta o caminho, que é diferente em
cada máquina e muda a cada versão do Mockito:

```
ana@vm:~/bookshop$ ls ~/.m2/repository/org/mockito/mockito-core/5.23.0/
_remote.repositories
mockito-core-5.23.0.jar
mockito-core-5.23.0.jar.sha1
mockito-core-5.23.0.pom
mockito-core-5.23.0.pom.sha1
```

Escrever esse caminho no `pom.xml` amarraria o build a um diretório home e a uma versão. O **goal
`properties` do `maven-dependency-plugin`** faz a busca no lugar disso: para cada dependência, ele
define uma propriedade chamada `groupId:artifactId:type` com o caminho do jar no repositório local, e
roda na fase `initialize`, antes de qualquer compilação. `${org.mockito:mockito-core:jar}` passa então
a ser o caminho acima, qualquer que seja a versão.

Substitua o elemento `<build>` inteiro do `pom.xml` por este. O primeiro e o último plugins são os que
ele já tinha, das aulas 4 e 17; os dois do meio são novos:

```xml
  <build>
    <plugins>
      <plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-dependency-plugin</artifactId>
        <executions>
          <execution>
            <goals>
              <goal>properties</goal>
            </goals>
          </execution>
        </executions>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-surefire-plugin</artifactId>
        <configuration>
          <argLine>-javaagent:${org.mockito:mockito-core:jar}</argLine>
        </configuration>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-javadoc-plugin</artifactId>
        <configuration>
          <show>public</show>
          <doclint>all,-missing</doclint>
        </configuration>
      </plugin>
    </plugins>
  </build>
```

O plugin de dependências não precisa de versão nem de fase, porque o parent da aula 4 fixa a versão e
o goal declara a própria fase. O surefire também não. Rode os testes de novo:

```
ana@vm:~/bookshop$ mvn test 2>&1 | sed -n '/T E S T S/,$p'
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running com.example.bookshop.ordering.OrderTest
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.085 s -- in com.example.bookshop.ordering.OrderTest
[INFO] Running com.example.bookshop.ordering.OrderServiceTest
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
20:29:04.845 [main] INFO com.example.bookshop.ordering.OrderService -- Order 7 placed by ana: 1 line(s), 3500 cents
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.545 s -- in com.example.bookshop.ordering.OrderServiceTest
[INFO] Running com.example.bookshop.catalogue.BookTest
[INFO] Running take
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.009 s -- in take
[INFO] Tests run: 0, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.011 s -- in com.example.bookshop.catalogue.BookTest
[INFO] Running com.example.bookshop.catalogue.IsbnTest
[INFO] Tests run: 10, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.063 s -- in com.example.bookshop.catalogue.IsbnTest
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 17, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  2.915 s
[INFO] Finished at: 2026-10-22T20:29:04-03:00
[INFO] ------------------------------------------------------------------------
```

A mensagem do Mockito e os quatro avisos sumiram, porque nada mais se anexa: o agente estava lá desde a
primeira instrução. **Uma linha fica, e ela é inofensiva.** O agente acrescenta classes ao boot class
path, as classes que a JVM carrega antes de todas as outras, e o class data sharing da JVM, um cache de
classes que ela mantém entre execuções para iniciar mais rápido, passa a cobrir menos delas. Os testes
não percebem nada.

A outra saída, `-XX:+EnableDynamicAgentLoading` no mesmo `argLine`, só esconderia o aviso do JDK. O
Mockito continuaria se anexando no meio da execução, que é exatamente o que o JDK anunciou que vai
deixar de permitir.
