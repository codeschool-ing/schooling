---
title: Dependencies, their scope, and the ones nobody asked for
version: 1
---

The pom names two dependencies. The build used more than two, and one goal shows all of them:

@@CAPTURE tree@@

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
which Validator also brings, asks for 1.3.5. The tree above showed only the winner. The `verbose` flag
shows the losers too, and `includes` cuts the output to the libraries concerned:

@@CAPTURE verbose@@

Validator declares Commons Logging 1.4.0 itself, two steps from your project. BeanUtils asks for
1.3.5 one step further down, and the line in brackets says that request was **omitted for
conflict**: the build has one Commons Logging on its classpath, and it is 1.4.0.

**Nearest wins** is Maven's rule: of two versions of one library, the one fewer steps from your
project is used, and when they are equally near, the one declared first. It is a rule about
position in the graph and not about which version is newer. Here the nearer one happens to be the
newer one too, which hides the rule; the day an old version wins, it is the rule that explains it. The fix is the same in every case: **declare the library yourself**, at
the version you want, and your own declaration is the nearest there is. An `<exclusions>` element
inside a dependency does the opposite job, removing one transitive library a dependency drags in
that your program must not have.

## Where the jars went

Nothing was copied into the project. Every jar Maven fetched sits in one directory in your home,
the **local repository**:

@@CAPTURE m2@@

Four kinds of file. The jar is the library. The pom is the library's own description, and it is
where Maven read that Validator needs four more. Each `.sha1` is a checksum Maven compared with
what it downloaded, so a jar damaged on the way is noticed. `_remote.repositories`
is Maven's note of which repository the files came from. And the path is the coordinates, group,
artifact and version, one directory each: the section on plugins and repositories draws it.
