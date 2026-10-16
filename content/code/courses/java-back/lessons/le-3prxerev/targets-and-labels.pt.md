---
title: Arquivos BUILD, alvos e rótulos
version: 1
---

O Maven tem um build por projeto, rodado fase a fase. O Bazel tem um **grafo de alvos**, e um
arquivo BUILD é onde os alvos são declarados. Um diretório com um `BUILD.bazel` é um **pacote**, e
um alvo é nomeado por um **rótulo** (*label*): `//`, o caminho do pacote a partir da raiz do
módulo, dois-pontos e o nome do alvo. A biblioteca abaixo é `//src/main/java/com/example/isbn:isbn`.
Todo comando recebe rótulos, e `//...` quer dizer todos os alvos do módulo.

Salve isto como `src/main/java/com/example/isbn/BUILD.bazel`, ao lado do `IsbnCheck.java`:

FENCE_0

E isto como `src/test/java/com/example/isbn/BUILD.bazel`, ao lado do teste:

FENCE_1

Um `java_test` é um programa cujo código de saída é o veredito. O runner de testes do próprio
Bazel só fala JUnit 4, então um teste Jupiter precisa de outra coisa como `main`: o
`use_testrunner = False` desliga o runner do Bazel e o `main_class` nomeia o console launcher do
JUnit, a quem os `args` dizem qual classe rodar. Equipes que escrevem muitos testes Jupiter usam um
conjunto de regras que empacota isso, o `contrib_rules_jvm` e o `java_junit5_test` dele. O `size`
declara o quanto o teste é pesado, e o Bazel dá a ele um tempo-limite à altura.

## Compilar, rodar, testar

FENCE_2

**`linux-sandbox`** é a regra hermética trabalhando: três ações rodaram num sandbox que só tinha
as entradas declaradas delas. Os dois processos `worker` são o compilador, mantido vivo entre um
build e outro, como o servidor. As saídas não ficam num diretório `target/`, e sim em `bazel-bin`,
um dos quatro links simbólicos que o Bazel põe no projeto apontando para o cache dele:

FENCE_3

O `MODULE.bazel.lock` é o **arquivo de lock**: aquilo para que as dependências do módulo foram
resolvidas, até o hash de cada arquivo. Ele vai para o controle de versão ao lado do
`MODULE.bazel`, e os links `bazel-*` não.

FENCE_4

O `bazel run` compila primeiro o que estiver desatualizado, então funciona num checkout limpo
também, e tudo depois de `--` vai para o programa. Agora os testes, com `--test_output=all` para
ver o que o launcher imprimiu, e não só o veredito:

FENCE_5

O segundo `bazel test` não rodou nada. **`(cached) PASSED`** é um resultado de teste tirado do
cache, porque nenhuma entrada do teste mudou desde que ele passou pela última vez: nem a fonte dele,
nem a biblioteca, nem um jar, nem uma flag. Com um cache remoto isso vale entre máquinas, e um job
de CI roda de novo só os testes que um commit pode ter quebrado. O Maven roda todos os testes a
cada `mvn test`.

## O grafo, perguntado diretamente

O Bazel mostra o grafo a partir do qual ele compila. O `cquery` lista aquilo de que um alvo
depende, aqui deixando de fora as dependências implícitas da própria toolchain:

FENCE_6

Todo arquivo também é um alvo: a fonte do teste, a da biblioteca e o `downloaded.jar` de cada
repositório externo. O hash curto entre parênteses nomeia a **configuração**, o conjunto de opções
com que um alvo foi analisado; um arquivo-fonte não tem nenhuma, daí o `null`. O mesmo tipo de
consulta na direção contrária, `rdeps`, lista tudo o que depende de um alvo: até onde uma mudança
nele pode chegar.

## Um load que falta

Apague as duas linhas de `load` do arquivo BUILD da biblioteca e compile de novo:

FENCE_7

A mensagem não diz *load*. Sem o `load`, `java_library` não é a regra do `rules_java`, e aquilo que
o nome quer dizer no Bazel 9 não aceita nenhum desses atributos, então o primeiro erro cita o
`srcs`. Quando um arquivo BUILD que funcionava num Bazel mais antigo falha assim depois de uma
atualização, um `load` do `rules_java` faltando é a primeira coisa a procurar. Ponha as duas linhas
de volta e o módulo compila de novo:

FENCE_8
