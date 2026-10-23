---
title: Dependencies, their scope, and the ones nobody asked for
version: 1
---

The pom names two dependencies. The build used more than two, and one goal shows all of them:

```
ana@vm:~/isbn-check$ mvn dependency:tree
[INFO] Scanning for projects...
[INFO] 
[INFO] -----------------------< com.example:isbn-check >-----------------------
[INFO] Building isbn-check 1.0.0
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- maven-dependency-plugin:2.8:tree (default-cli) @ isbn-check ---
[INFO] com.example:isbn-check:jar:1.0.0
[INFO] +- commons-validator:commons-validator:jar:1.11.0:compile
[INFO] |  +- commons-beanutils:commons-beanutils:jar:1.11.0:compile
[INFO] |  +- commons-digester:commons-digester:jar:2.1:compile
[INFO] |  +- commons-logging:commons-logging:jar:1.4.0:compile
[INFO] |  \- commons-collections:commons-collections:jar:3.2.2:compile
[INFO] \- org.junit.jupiter:junit-jupiter:jar:6.0.3:test
[INFO]    +- org.junit.jupiter:junit-jupiter-api:jar:6.0.3:test
[INFO]    |  +- org.opentest4j:opentest4j:jar:1.3.0:test
[INFO]    |  +- org.junit.platform:junit-platform-commons:jar:6.0.3:test
[INFO]    |  +- org.apiguardian:apiguardian-api:jar:1.1.2:test
[INFO]    |  \- org.jspecify:jspecify:jar:1.0.0:test
[INFO]    +- org.junit.jupiter:junit-jupiter-params:jar:6.0.3:test
[INFO]    \- org.junit.jupiter:junit-jupiter-engine:jar:6.0.3:test
[INFO]       \- org.junit.platform:junit-platform-engine:jar:6.0.3:test
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  0.720 s
[INFO] Finished at: 2026-10-22T19:33:35-03:00
[INFO] ------------------------------------------------------------------------
```

`dependency:tree` is not a phase of the build; it is one **goal** of the dependency plugin, asked
for by name, and it does nothing but print. Each line is a dependency in the form
`group:artifact:type:version:scope`, and the indentation is who asked for it. The two at the left
margin are the ones in the pom. **Everything indented is a transitive dependency**: Commons
Validator needs Commons BeanUtils, Digester, Logging and Collections to work, so Maven fetched them
too, without the pom naming any of them. That is most of what a build tool is for. The pom says
what the project uses directly, and each library's own pom says what it needs, all the way down.

The `2.8` in the plugin's line deserves a question, and the section on plugins answers it.

## Scope

The last field of every line is the **scope**, which says where a dependency is visible.

| scope | compiles the program | compiles and runs the tests | needed when the program runs |
|---|---|---|---|
| `compile`, the default | yes | yes | yes |
| `test` | no | yes | no |
| `provided` | yes | yes | no: the place it runs supplies it |
| `runtime` | no | yes | yes |

Commons Validator has no `<scope>` in the pom, so it is `compile`: the program imports it, the
tests reach it through the program, and it has to be present when the program runs. JUnit says
`test`, and **a scope is inherited downwards**: every library JUnit pulls in is `test` as well.
Writing `import org.junit...` in `src/main/java` fails to compile, which is the point, because the
program would otherwise ship depending on a test library. The other two do not appear in this
project: `provided` is for an API the place the program runs already has, and `runtime` for an
implementation the code never names, such as a database driver.

## Two paths to one library

A transitive graph has a problem a flat list does not: two libraries can ask for the same third
one at different versions. Here Commons Validator asks for Commons Logging 1.4.0, and BeanUtils,
which Validator also brings, asks for 1.3.5. The tree above showed only the winner. The `verbose`
flag shows the losers too, and `includes` cuts the output to the libraries concerned:

```
ana@vm:~/isbn-check$ mvn dependency:tree -Dverbose -Dincludes=commons-logging,commons-beanutils
[INFO] Scanning for projects...
[INFO] 
[INFO] -----------------------< com.example:isbn-check >-----------------------
[INFO] Building isbn-check 1.0.0
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- maven-dependency-plugin:2.8:tree (default-cli) @ isbn-check ---
[INFO] com.example:isbn-check:jar:1.0.0
[INFO] \- commons-validator:commons-validator:jar:1.11.0:compile
[INFO]    +- commons-beanutils:commons-beanutils:jar:1.11.0:compile
[INFO]    |  \- (commons-logging:commons-logging:jar:1.3.5:compile - omitted for conflict with 1.4.0)
[INFO]    \- commons-logging:commons-logging:jar:1.4.0:compile
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  0.652 s
[INFO] Finished at: 2026-10-22T19:33:37-03:00
[INFO] ------------------------------------------------------------------------
```

Validator declares Commons Logging 1.4.0 itself, two steps from your project. BeanUtils asks for
1.3.5 one step further down, and the line in brackets says that request was **omitted for
conflict**: the build has one Commons Logging on its classpath, and it is 1.4.0.

**Nearest wins** is Maven's rule: of two versions of one library, the one fewer steps from your
project is used, and when they are equally near, the one declared first. It is a rule about
position in the graph and not about which version is newer. Here the nearer one happens to be the
newer one too, which hides the rule; the day an old version wins, it is the rule that explains it.
When the winner is not the version you need, **declare the library yourself**, at the version you
want, and your own declaration is the nearest there is. An `<exclusions>` element
inside a dependency does the opposite job, removing one transitive library a dependency drags in
that your program must not have.

## Where the jars went

Nothing was copied into the project. Every jar Maven fetched sits in one directory in your home,
the **local repository**:

```
ana@vm:~/isbn-check$ ls ~/.m2/repository/commons-validator/commons-validator/1.11.0
_remote.repositories
commons-validator-1.11.0.jar
commons-validator-1.11.0.jar.sha1
commons-validator-1.11.0.pom
commons-validator-1.11.0.pom.sha1
```

Four kinds of file. The jar is the library. The pom is the library's own description, and it is
where Maven read that Validator needs four more. Each `.sha1` is a checksum Maven compared with
what it downloaded, so a jar damaged on the way is noticed. `_remote.repositories` is Maven's note of which repository the files came from. And the path is the coordinates, group,
artifact and version, one directory each: the section on plugins and repositories draws it.
