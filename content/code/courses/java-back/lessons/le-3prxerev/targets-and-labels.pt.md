---
title: Arquivos BUILD, alvos e rótulos
version: 1
---

O Maven tem um build por projeto, rodado fase a fase. O Bazel tem um **grafo de alvos**, e um
arquivo BUILD é onde os alvos são declarados. Um diretório com um `BUILD.bazel` é um **pacote**, e
um alvo é nomeado por um **rótulo** (*label*): `//`, o caminho do pacote a partir da raiz do
módulo, dois-pontos e o nome do alvo. A biblioteca abaixo é `//src/main/java/com/example/isbn:isbn`.
Os comandos de compilar, rodar, testar e consultar recebem rótulos, e `//...` quer dizer todos os alvos do módulo.

Salve isto como `src/main/java/com/example/isbn/BUILD.bazel`, ao lado do `IsbnCheck.java`:

```schooling-example
{"language": "python", "file": "BUILD.bazel", "parts": [{"code": "load(\"@rules_java//java:java_binary.bzl\", \"java_binary\")\nload(\"@rules_java//java:java_library.bzl\", \"java_library\")", "note": "Um arquivo BUILD começa carregando as regras que usa, cada uma do arquivo do `rules_java` que a define. Sem essas linhas nada no arquivo funciona, como o fim desta seção mostra."}, {"code": "\njava_library(\n    name = \"isbn\",\n    srcs = [\"IsbnCheck.java\"],\n    deps = [\"@commons_validator//jar\"],\n    runtime_deps = [\n        \"@commons_beanutils//jar\",\n        \"@commons_collections//jar\",\n        \"@commons_digester//jar\",\n        \"@commons_logging//jar\",\n    ],\n    visibility = [\"//src/test/java/com/example/isbn:__pkg__\"],\n)", "note": "Um **alvo** chamado `isbn`: a classe, compilada num jar. O `deps` é aquilo contra o que o código compila, e o `runtime_deps` só entra no classpath quando algo roda, que são os escopos compile e runtime do Maven ditos por alvo. O `visibility` deixa o pacote do teste depender dele e mais ninguém; num repositório de mil pacotes, é essa linha que mantém as outras equipes longe dos internos de uma equipe."}, {"code": "\njava_binary(\n    name = \"isbn-check\",\n    main_class = \"com.example.isbn.IsbnCheck\",\n    runtime_deps = [\":isbn\"],\n)", "note": "Um segundo alvo, o programa: a biblioteca mais a classe com `main`, e um script de inicialização que põe todos os jars no classpath. `:isbn` é um rótulo relativo a este pacote."}]}
```

E isto como `src/test/java/com/example/isbn/BUILD.bazel`, ao lado do teste:

```py
load("@rules_java//java:java_test.bzl", "java_test")

java_test(
    name = "IsbnCheckTest",
    size = "small",
    srcs = ["IsbnCheckTest.java"],
    deps = [
        "//src/main/java/com/example/isbn:isbn",
        "@junit_console//jar",
    ],
    use_testrunner = False,
    main_class = "org.junit.platform.console.ConsoleLauncher",
    args = [
        "execute",
        "--select-class=com.example.isbn.IsbnCheckTest",
        "--disable-banner",
        "--disable-ansi-colors",
        "--details=summary",
    ],
)
```

Um `java_test` é um programa cujo código de saída é o veredito. O runner de testes do próprio
Bazel só fala JUnit 4, então um teste Jupiter precisa de outra coisa como `main`: o
`use_testrunner = False` desliga o runner do Bazel e o `main_class` nomeia o console launcher do
JUnit, a quem os `args` dizem qual classe rodar. Equipes que escrevem muitos testes Jupiter usam um
conjunto de regras que empacota isso, o `contrib_rules_jvm` e o `java_junit5_test` dele. O `size`
declara o quanto o teste é pesado, e o Bazel dá a ele um tempo-limite à altura.

## Compilar, rodar, testar

```
ana@vm:~/isbn-bazel$ bazel build //src/main/java/com/example/isbn:isbn-check
INFO: Analyzed target //src/main/java/com/example/isbn:isbn-check (0 packages loaded, 0 targets configured).
INFO: Found 1 target...
Target //src/main/java/com/example/isbn:isbn-check up-to-date:
  bazel-bin/src/main/java/com/example/isbn/isbn-check
  bazel-bin/src/main/java/com/example/isbn/isbn-check.jar
INFO: Elapsed time: 11.452s, Critical Path: 5.68s
INFO: 11 processes: 6 internal, 3 linux-sandbox, 2 worker.
INFO: Build completed successfully, 11 total actions
```

**`linux-sandbox`** é a regra hermética trabalhando: três ações rodaram num sandbox que só tinha
as entradas declaradas delas. Os dois processos `worker` são o compilador, mantido vivo entre um
build e outro, como o servidor. As saídas não ficam num diretório `target/`, e sim em `bazel-bin`,
um dos quatro links simbólicos que o Bazel põe no projeto apontando para o cache dele:

```
ana@vm:~/isbn-bazel$ ls -A
.bazelrc
.bazelversion
MODULE.bazel
MODULE.bazel.lock
bazel-bin
bazel-isbn-bazel
bazel-out
bazel-testlogs
src
```

O `MODULE.bazel.lock` é o **arquivo de lock**: aquilo para que as dependências do módulo foram
resolvidas, até o hash de cada arquivo. Ele vai para o controle de versão ao lado do
`MODULE.bazel`, e os links `bazel-*` não.

```
ana@vm:~/isbn-bazel$ bazel run //src/main/java/com/example/isbn:isbn-check -- 978-0-306-40615-7 0-306-40615-2 978-0-306-40615-8
INFO: Analyzed target //src/main/java/com/example/isbn:isbn-check (0 packages loaded, 0 targets configured).
INFO: Found 1 target...
Target //src/main/java/com/example/isbn:isbn-check up-to-date:
  bazel-bin/src/main/java/com/example/isbn/isbn-check
  bazel-bin/src/main/java/com/example/isbn/isbn-check.jar
INFO: Elapsed time: 0.549s, Critical Path: 0.02s
INFO: 1 process: 1 internal.
INFO: Build completed successfully, 1 total action
INFO: Running command line: bazel-bin/src/main/java/com/example/isbn/isbn-check <args omitted>
978-0-306-40615-7: valid, ISBN-13 9780306406157
0-306-40615-2: valid, ISBN-13 9780306406157
978-0-306-40615-8: invalid
```

O `bazel run` compila primeiro o que estiver desatualizado, então funciona num checkout limpo
também, e tudo depois de `--` vai para o programa. Agora os testes, com `--test_output=all` para
ver o que o launcher imprimiu, e não só o veredito:

```
ana@vm:~/isbn-bazel$ bazel test //... --test_output=all
INFO: Analyzed 3 targets (3 packages loaded, 25 targets configured).
INFO: From Testing //src/test/java/com/example/isbn:IsbnCheckTest:
==================== Test output for //src/test/java/com/example/isbn:IsbnCheckTest:

Test run finished after 117 ms
[         4 containers found      ]
[         0 containers skipped    ]
[         4 containers started    ]
[         0 containers aborted    ]
[         4 containers successful ]
[         0 containers failed     ]
[         3 tests found           ]
[         0 tests skipped         ]
[         3 tests started         ]
[         0 tests aborted         ]
[         3 tests successful      ]
[         0 tests failed          ]

================================================================================
INFO: Found 2 targets and 1 test target...
INFO: Elapsed time: 2.121s, Critical Path: 1.53s
INFO: 10 processes: 6 internal, 4 linux-sandbox, 1 worker.
INFO: Build completed successfully, 10 total actions
//src/test/java/com/example/isbn:IsbnCheckTest                           PASSED in 1.0s

Executed 1 out of 1 test: 1 test passes.
ana@vm:~/isbn-bazel$ bazel test //...
INFO: Analyzed 3 targets (0 packages loaded, 0 targets configured).
INFO: Found 2 targets and 1 test target...
INFO: Elapsed time: 0.536s, Critical Path: 0.01s
INFO: 1 process: 1 action cache hit, 1 internal.
INFO: Build completed successfully, 1 total action
//src/test/java/com/example/isbn:IsbnCheckTest                  (cached) PASSED in 1.0s

Executed 0 out of 1 test: 1 test passes.
```

Na tabela do launcher, os três testes são os três métodos do `IsbnCheckTest`, e os quatro
contêineres são a classe e os três engines de teste que o jar do console traz.

O segundo `bazel test` não rodou nada. **`(cached) PASSED`** é um resultado de teste tirado do
cache, porque nenhuma entrada do teste mudou desde que ele passou pela última vez: nem a fonte dele,
nem a biblioteca, nem um jar, nem uma flag. Com um cache remoto isso vale entre máquinas, e um job
de CI roda de novo só os testes que um commit pode ter quebrado. O Maven roda todos os testes a
cada `mvn test`.

## O grafo, perguntado diretamente

O Bazel mostra o grafo a partir do qual ele compila. O `cquery` lista aquilo de que um alvo
depende, aqui deixando de fora as dependências implícitas da própria toolchain:

```
ana@vm:~/isbn-bazel$ bazel cquery --noimplicit_deps 'deps(//src/test/java/com/example/isbn:IsbnCheckTest)'
INFO: Analyzed target //src/test/java/com/example/isbn:IsbnCheckTest (0 packages loaded, 0 targets configured).
INFO: Found 1 target...
//src/test/java/com/example/isbn:IsbnCheckTest (be37ecb)
@junit_console//jar:jar (6258d0d)
//src/test/java/com/example/isbn:IsbnCheckTest.java (null)
//src/main/java/com/example/isbn:isbn (6258d0d)
@bazel_tools//tools/jdk:launcher_flag_alias (6258d0d)
@commons_logging//jar:jar (6258d0d)
@commons_collections//jar:jar (6258d0d)
@junit_console//jar:downloaded.jar (null)
@commons_beanutils//jar:jar (6258d0d)
//src/main/java/com/example/isbn:IsbnCheck.java (null)
@commons_digester//jar:jar (6258d0d)
@commons_validator//jar:jar (6258d0d)
@commons_logging//jar:downloaded.jar (null)
@commons_collections//jar:downloaded.jar (null)
@commons_digester//jar:downloaded.jar (null)
@commons_validator//jar:downloaded.jar (null)
@commons_beanutils//jar:downloaded.jar (null)
INFO: Elapsed time: 0.320s, Critical Path: 0.00s
INFO: 0 processes.
INFO: Build completed successfully, 0 total actions
```

Todo arquivo também é um alvo: a fonte do teste, a da biblioteca e o `downloaded.jar` de cada
repositório externo. O hash curto entre parênteses nomeia a **configuração**, o conjunto de opções
com que um alvo foi analisado; um arquivo-fonte não tem nenhuma, daí o `null`. O mesmo tipo de
consulta na direção contrária, `rdeps`, lista tudo o que depende de um alvo: até onde uma mudança
nele pode chegar.

## Um load que falta

Apague as duas linhas de `load` do arquivo BUILD da biblioteca e compile de novo:

```
ana@vm:~/isbn-bazel$ bazel build //...
ERROR: /home/ana/isbn-bazel/src/main/java/com/example/isbn/BUILD.bazel:2:13: //src/main/java/com/example/isbn:isbn: no such attribute 'srcs' in 'java_library' rule
ERROR: /home/ana/isbn-bazel/src/main/java/com/example/isbn/BUILD.bazel:2:13: //src/main/java/com/example/isbn:isbn: no such attribute 'deps' in 'java_library' rule
ERROR: /home/ana/isbn-bazel/src/main/java/com/example/isbn/BUILD.bazel:2:13: //src/main/java/com/example/isbn:isbn: no such attribute 'runtime_deps' in 'java_library' rule
ERROR: /home/ana/isbn-bazel/src/main/java/com/example/isbn/BUILD.bazel:15:12: //src/main/java/com/example/isbn:isbn-check: no such attribute 'main_class' in 'java_binary' rule
ERROR: /home/ana/isbn-bazel/src/main/java/com/example/isbn/BUILD.bazel:15:12: //src/main/java/com/example/isbn:isbn-check: no such attribute 'runtime_deps' in 'java_binary' rule
ERROR: package contains errors: src/main/java/com/example/isbn
ERROR: package contains errors: src/main/java/com/example/isbn: //src/main/java/com/example/isbn:isbn: no such attribute 'srcs' in 'java_library' rule
WARNING: Target pattern parsing failed.
ERROR: Skipping '//...': Error evaluating '//...': error loading package 'src/main/java/com/example/isbn': Package 'src/main/java/com/example/isbn' contains errors
ERROR: Error evaluating '//...': error loading package 'src/main/java/com/example/isbn': Package 'src/main/java/com/example/isbn' contains errors
INFO: Elapsed time: 0.213s
INFO: 0 processes.
ERROR: Build did NOT complete successfully
```

A mensagem não diz *load*. Sem o `load`, `java_library` não é a regra do `rules_java`, e aquilo que
o nome quer dizer no Bazel 9 não aceita nenhum desses atributos, então o primeiro erro cita o
`srcs`. Quando um arquivo BUILD que funcionava num Bazel mais antigo falha assim depois de uma
atualização, um `load` do `rules_java` faltando é a primeira coisa a procurar. Ponha as duas linhas
de volta e o módulo compila de novo:

```
ana@vm:~/isbn-bazel$ bazel build //... && echo restored
INFO: Analyzed 3 targets (1 packages loaded, 4 targets configured).
INFO: Found 3 targets...
INFO: Elapsed time: 0.582s, Critical Path: 0.00s
INFO: 1 process: 14 action cache hit, 1 internal.
INFO: Build completed successfully, 1 total action
restored
```
