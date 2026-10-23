---
title: O build script
version: 1
---

Um projeto Maven é descrito no `pom.xml`. Um projeto Gradle é descrito em dois arquivos, e **os
dois são programas em Kotlin**, não documentos. Essa é a primeira coisa a saber sobre o Gradle e a
origem da maior parte do que ele tem de bom e de ruim: um arquivo de build pode ter um `if`, um
laço ou uma função, porque é código que o Gradle compila e executa. Os arquivos desta lição não
usam nada disso e se leem quase como um pom sem os sinais de menor e maior.

## As mesmas fontes, um diretório novo

O projeto é o da lição 1, compilado de novo. Crie um diretório ao lado de `~/isbn-check` e copie os
fontes, as duas classes e o teste, exatamente como a lição 1 os escreveu:

```
ana@vm:~$ mkdir ~/isbn-gradle && cp -r ~/isbn-check/src ~/isbn-gradle/
```

O Gradle espera o mesmo layout do Maven, `src/main/java` e `src/test/java`, então nada dentro de
`src` muda. Essa convenção é do Maven, e o Gradle a adotou para que um projeto pudesse passar de
uma ferramenta para a outra sem mover um arquivo.

## settings.gradle.kts

Crie `~/isbn-gradle/settings.gradle.kts` com esta linha:

```kotlin
rootProject.name = "isbn-check"
```

O arquivo de settings marca a raiz de um build e nomeia os projetos que ele contém. Um build grande
lista vários subprojetos aqui, cada um com o próprio build script. Este é um projeto só, e a linha
dá a ele o nome que o pom da lição 1 dava em `artifactId`. Sem ela o projeto levaria o nome do
diretório, `isbn-gradle`, e o jar também.

## build.gradle.kts

Crie `~/isbn-gradle/build.gradle.kts`:

```schooling-example
{"language": "kotlin", "file": "build.gradle.kts", "parts": [{"code": "plugins {\n    application\n}\n", "note": "Um **plugin** traz tarefas e convenções. `application` traz o `java` junto, então o projeto compila, testa e gera um jar, e ganha `run` e um script de execução por cima."}, {"code": "group = \"com.example\"\nversion = \"1.0.0\"\n", "note": "As mesmas coordenadas do `groupId` e da `version` do pom. O nome do artefato não está aqui: vem do `settings.gradle.kts`."}, {"code": "java {\n    toolchain {\n        languageVersion = JavaLanguageVersion.of(25)\n    }\n}\n", "note": "O **toolchain** diz qual Java compila, testa e roda o código. O Gradle procura um JDK 25 na máquina e usa esse, seja qual for o Java que iniciou o próprio Gradle, o que vai além do que `maven.compiler.release` diz."}, {"code": "repositories {\n    mavenCentral()\n}\n", "note": "De onde vêm as dependências. O Maven usa o Central por padrão e o Gradle não usa nada, então este bloco não é opcional."}, {"code": "dependencies {\n    implementation(\"commons-validator:commons-validator:1.11.0\")\n    testImplementation(\"org.junit.jupiter:junit-jupiter:6.0.3\")\n    testRuntimeOnly(\"org.junit.platform:junit-platform-launcher:6.0.3\")\n}\n", "note": "Cada linha é `group:name:version` numa string só, e a palavra antes dela diz onde o jar é necessário. `implementation` é o escopo compile do Maven; `testImplementation` é o escopo test. O launcher só é necessário para RODAR os testes, e o Gradle 9 deixou de fornecê-lo."}, {"code": "application {\n    mainClass = \"com.example.isbn.IsbnCheck\"\n}\n", "note": "A classe com o `main`, para o `run` e para o script de execução."}, {"code": "tasks.test {\n    useJUnitPlatform()\n}", "note": "A tarefa `test` do Gradle não presume JUnit 5 ou posterior. Esta linha manda rodar os testes pela JUnit Platform, que é a base do Jupiter."}]}
```

A terminação `.kts` é o que faz destes arquivos Kotlin. O Gradle também lê `build.gradle`, escrito
em Groovy, que é o que a maioria dos build scripts da internet ainda usa; os dois dizem as mesmas
coisas com pontuação diferente. **A Kotlin DSL é o padrão do Gradle para builds novos**, e a
vantagem dela é que o editor conhece o tipo de tudo o que está ali, então um `implementation`
escrito errado aparece sublinhado antes de o build rodar, e não relatado depois.

Duas linhas não têm equivalente no pom da lição 1. O `repositories` existe porque o Gradle não
presume nada sobre onde ficam as bibliotecas, enquanto o Maven presume o Central. E o launcher do
JUnit precisa ser nomeado porque o Gradle 9 deixou de colocá-lo sozinho no classpath dos testes. A
seção sobre tarefas tira essa linha de propósito, para ver como é a falha.

As **configurações** de dependência carregam o que o `scope` do pom carregava, com cortes mais
finos. `implementation` está no classpath quando o código principal compila e quando roda.
`testImplementation` soma a isso para os testes. `testRuntimeOnly` está presente quando os testes
rodam e ausente quando compilam, o certo para uma biblioteca que nenhuma classe de teste importa.
Há outras, como `compileOnly` para a API de um processador de anotações, e todas são a mesma ideia:
um nome para onde um jar é necessário.

## gradle.properties

Um último arquivo, `~/isbn-gradle/gradle.properties`, guarda configurações do próprio Gradle, e não
do projeto:

```properties
org.gradle.console=plain
```

Num terminal, o Gradle normalmente desenha uma área de progresso que se reescreve enquanto ele
trabalha e quase não deixa nada para trás. **O console plain imprime uma linha por tarefa, com o
resultado da tarefa ao lado**, que é o que esta lição lê em todo build. Apague a linha depois, se
preferir a área de progresso.

Todo comando daqui em diante roda dentro do projeto, então faça `cd ~/isbn-gradle` e veja o que
há ali:

```
ana@vm:~/isbn-gradle$ find . -type f | sort
./build.gradle.kts
./gradle.properties
./settings.gradle.kts
./src/main/java/com/example/isbn/IsbnCheck.java
./src/test/java/com/example/isbn/IsbnCheckTest.java
```

Três arquivos pequenos e os fontes sem mudança. Nada foi compilado ainda. O Gradle em `~/opt`
conseguiria compilar agora, mas a próxima seção primeiro dá ao projeto um Gradle só dele.
