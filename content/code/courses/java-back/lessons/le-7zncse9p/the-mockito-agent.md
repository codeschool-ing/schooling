---
title: The warning, and Mockito loaded as an agent
version: 1
---

The tests passed, and in the middle of them the JVM that ran `OrderServiceTest` printed six lines it
was not asked for. They are worth reading in order, because they tell one story from three sides.

**Mockito spoke first.** Since version 5 its default way of making mocks is the **inline mock
maker**, which rewrites the bytecode of the class it mocks while the program runs. That is what lets
it mock a final class or a method of a record, and it needs `java.lang.instrument`, the JVM's
interface for changing loaded classes. A program gets that interface by being a **Java agent**, and
Mockito made itself one by attaching to its own JVM in the middle of the run. Its message says this
will stop working and asks for it to be added "as an agent to your build".

**The JVM spoke next.** The four `WARNING:` lines are the JDK's side of the same event, a rule since
JDK 21: an agent loaded into a running JVM, instead of named when the JVM starts, is reported, and a
future release will refuse it unless the JVM was started with `-XX:+EnableDynamicAgentLoading`. The
path in the first line is the jar that did the attaching, from Byte Buddy, the library Mockito
generates classes with.

The line about sharing is the third side, and it comes back below.

## Naming the agent when the JVM starts

The fix Mockito's documentation gives is to start the test JVM with `-javaagent:` and the path of
`mockito-core`'s jar. Surefire runs the tests in a JVM of its own, a **fork**, and its `argLine`
setting is the command line that fork gets. What remains is the path, which is different on every
machine and changes with every Mockito version:

```
ana@vm:~/bookshop$ ls ~/.m2/repository/org/mockito/mockito-core/5.23.0/
_remote.repositories
mockito-core-5.23.0.jar
mockito-core-5.23.0.jar.sha1
mockito-core-5.23.0.pom
mockito-core-5.23.0.pom.sha1
```

Writing that path into `pom.xml` would tie the build to one home directory and one version. The
**`properties` goal of `maven-dependency-plugin`** does the lookup instead: for every dependency it
sets a property named `groupId:artifactId:type` to the jar's path in the local repository, and it
runs in the `initialize` phase, before anything is compiled. `${org.mockito:mockito-core:jar}` is then
the path above, whatever the version.

Replace the whole `<build>` element of `pom.xml` with this one. The first and last plugins are the
ones it already had, from lessons 4 and 17; the two in the middle are new:

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

The dependency plugin needs no version and no phase, because the parent from lesson 4 pins the
version and the goal declares its own phase. Neither does surefire. Run the tests again:

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

Mockito's message and the four warnings are gone, because nothing attaches any more: the agent was
there from the first instruction. **One line stays, and it is harmless.** The agent adds classes to
the boot class path, the classes the JVM loads before any other, and the JVM's class data sharing, a
cache of classes it keeps between runs to start faster, then covers fewer of them. The tests do not
see it.

The other way out, `-XX:+EnableDynamicAgentLoading` in the same `argLine`, would only hide the JDK's
warning. Mockito would still attach in the middle of the run, which is exactly what the JDK has
announced it will stop allowing.
