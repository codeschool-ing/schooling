---
title: O Bazel fixado, e um módulo seu
version: 1
---

Esta seção e a próxima compilam o verificador de ISBN da aula 1 pela terceira vez, agora com o
Bazel. Os dois arquivos Java não mudam; o que muda é tudo em volta deles. Nada daqui em diante é
usado de novo no curso, então, se você só quer as ideias, pode acompanhar a leitura sem digitar.

## Bazelisk, o inicializador

Ninguém instala o Bazel em si. Você instala o **Bazelisk**, um inicializador pequeno que lê a
versão do Bazel que um projeto pede num arquivo chamado `.bazelversion`, baixa essa versão uma vez
em `~/.cache/bazelisk` e a executa. É a mesma ideia do wrapper do Gradle da aula 2: a versão faz
parte do repositório, então todo mundo que o clona compila com o mesmo Bazel. O Bazelisk é um
executável só, das releases dele no GitHub, e a convenção é chamá-lo de `bazel`:

```
TRANSCRIPT_INSTALL
```

O `~/.profile` do Ubuntu põe `~/bin` no seu `PATH` quando o diretório existe, então saia e entre de
novo na sessão, ou rode `source ~/.profile`, e `bazel` vira um comando.

## O projeto

Copie as fontes da aula 1 para um diretório só delas, como a aula 2 fez para o Gradle, e diga com
qual versão do Bazel o projeto compila:

```
TRANSCRIPT_PROJECT
```

Três arquivos ficam na raiz de `~/isbn-bazel`, e mais dois ao lado das fontes, na próxima seção. O
primeiro é o `.bazelversion` de uma linha que o último comando escreveu, e que fixa o Bazel como um
wrapper fixa o Gradle. O segundo é o **`MODULE.bazel`**, e é a presença dele que faz do diretório
um projeto Bazel. O sistema dele se chama **Bzlmod**: o módulo nomeia os conjuntos de regras de que
depende, e o Bazel os busca no **Bazel Central Registry**, que faz o papel que o Maven Central faz
para os jars. Projetos mais antigos declaram as mesmas coisas num arquivo chamado `WORKSPACE`, que
você ainda vai encontrar em repositórios que não migraram.

```schooling-example
{"language": "python", "file": "MODULE.bazel", "parts": [{"code": "module(name = \"isbn_check\", version = \"1.0.0\")\n\nbazel_dep(name = \"rules_java\", version = \"9.9.0\")", "note": "O nome e a versão do próprio módulo, que importam quando outro módulo depende deste, e o único conjunto de regras que ele usa. O `rules_java` define `java_library`, `java_binary` e `java_test`; o Bazel em si não define regra Java nenhuma. A versão é exata: não existem intervalos, e se dois módulos pedem versões diferentes da mesma dependência, o Bzlmod fica com a mais alta."}, {"code": "\nhttp_jar = use_repo_rule(\"@bazel_tools//tools/build_defs/repo:http.bzl\", \"http_jar\")", "note": "O `http_jar` é uma **regra de repositório**: baixa um arquivo e o transforma num repositório externo que os arquivos BUILD conseguem nomear, `@commons_validator` no caso do primeiro abaixo."}, {"code": "\nhttp_jar(\n    name = \"commons_validator\",\n    sha256 = \"b7e1dcdc60d581de82934f4600e25af9ad9366730af1704ddcbf459e4dcc85e5\",\n    urls = [\"https://repo1.maven.org/maven2/commons-validator/commons-validator/1.11.0/commons-validator-1.11.0.jar\"],\n)", "note": "A única biblioteca que o código importa. O `sha256` é a regra hermética aplicada a um download: o Bazel recusa um arquivo cujo hash seja outro, então um jar trocado no servidor, ou um espelho que entrega outra coisa, derruba o build em vez de entrar nele."}, {"code": "\nhttp_jar(\n    name = \"commons_beanutils\",\n    sha256 = \"9e44ba68ec9a3f21286fa2a8bbb003b735c0f69101bb43144b79f4f8aaa74709\",\n    urls = [\"https://repo1.maven.org/maven2/commons-beanutils/commons-beanutils/1.11.0/commons-beanutils-1.11.0.jar\"],\n)\n\nhttp_jar(\n    name = \"commons_digester\",\n    sha256 = \"e0b2b980a84fc6533c5ce291f1917b32c507f62bcad64198fff44368c2196a3d\",\n    urls = [\"https://repo1.maven.org/maven2/commons-digester/commons-digester/2.1/commons-digester-2.1.jar\"],\n)\n\nhttp_jar(\n    name = \"commons_logging\",\n    sha256 = \"d175dbd751dd782a63bde28c7a039520e971f25e84b79c19b8435edc3603e0dc\",\n    urls = [\"https://repo1.maven.org/maven2/commons-logging/commons-logging/1.4.0/commons-logging-1.4.0.jar\"],\n)\n\nhttp_jar(\n    name = \"commons_collections\",\n    sha256 = \"eeeae917917144a68a741d4c0dff66aa5c5c5fd85593ff217bced3fc8ca783b8\",\n    urls = [\"https://repo1.maven.org/maven2/commons-collections/commons-collections/3.2.2/commons-collections-3.2.2.jar\"],\n)", "note": "Os quatro jars de que o próprio commons-validator depende, nas versões que o `mvn dependency:tree` da aula 1 resolveu. O Maven achou todos sozinho a partir de uma `<dependency>`; o `http_jar` só busca o que mandam, então eles aparecem por extenso aqui."}, {"code": "\nhttp_jar(\n    name = \"junit_console\",\n    sha256 = \"3ba0d6150af79214a1411f9ea2fbef864eef68b68c89a17f672c0b89bff9d3a2\",\n    urls = [\"https://repo1.maven.org/maven2/org/junit/platform/junit-platform-console-standalone/6.0.3/junit-platform-console-standalone-6.0.3.jar\"],\n)", "note": "O JUnit do teste: um jar só com a API do Jupiter, o engine dele e um **console launcher** que roda testes a partir de um método `main`. A próxima seção diz por que o teste precisa de um launcher."}]}
```

O terceiro, `.bazelrc`, guarda flags que o Bazel lê em todo comando, para ninguém precisar
digitá-las:

```conf
# Compile for Java 25, as lesson 1's pom does with maven.compiler.release.
common --java_language_version=25
# Print results, not a progress line that redraws itself: what you see is what this lesson shows.
common --noshow_progress
```

Com os três arquivos no lugar, pergunte ao Bazel o que ele é:

```
TRANSCRIPT_VERSION
```

O primeiro comando num diretório novo sobe um **servidor do Bazel**, um processo que fica em segundo
plano e guarda o grafo do build na memória entre um comando e outro, mais ou menos como o daemon do
Gradle. O primeiro comando depois de um `.bazelversion` novo também baixa aquele Bazel, e o primeiro
build baixa o `rules_java`, os seis jars e **dois JDKs do próprio Bazel**: um que roda as
ferramentas dele e um que compila o seu código. É a regra hermética da primeira seção, aplicada ao
próprio compilador. O seu programa continua rodando no JDK 25 que a aula 1 de `java` instalou.
