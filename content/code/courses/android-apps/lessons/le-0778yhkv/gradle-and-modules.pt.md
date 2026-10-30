---
title: O primeiro build, e os três números do SDK
version: 1
---

**`./gradlew assembleDebug` transforma os oito arquivos num app instalável**, e na primeira vez faz
muito mais do que compilar. Baixa o Gradle que o wrapper nomeia, depois o plugin Android do Gradle,
depois cada biblioteca que o módulo pede e cada biblioteca que *essas* pedem, e só então compila.
Isto foi rodado com o cache do Gradle esvaziado antes, então é o build que você vai ver:

```
ana@vm:~/planner$ ./gradlew --console=plain assembleDebug 2>&1 | grep -E "^(Downloading|BUILD|[0-9]+ actionable)"
Downloading https://services.gradle.org/distributions/gradle-9.8.2-bin.zip
BUILD SUCCESSFUL in 2m 50s
36 actionable tasks: 36 executed
ana@vm:~/planner$ ls -lh app/build/outputs/apk/debug/
total 12M
-rw-r--r-- 1 ana ana 12M Oct 30 15:46 app-debug.apk
-rw-r--r-- 1 ana ana 403 Oct 30 15:46 output-metadata.json
```

Quase três minutos, a maior parte baixando. A segunda execução, sem nada mudado, é outro número:

```
ana@vm:~/planner$ ./gradlew --console=plain assembleDebug 2>&1 | grep -E "^(BUILD|[0-9]+ actionable)"
BUILD SUCCESSFUL in 1s
36 actionable tasks: 36 up-to-date
```

**36 tarefas, e nenhuma rodou de novo.** O Gradle registra o que cada tarefa leu e escreveu, e pula
as que não tiveram as entradas alteradas. É por isso que o segundo build é rápido, e por isso que um
build que de repente deixa de ser rápido em geral quer dizer que algo mudou sem você esperar: um
arquivo regenerado, uma versão que andou, um relógio.

## O que o módulo pediu, e o que chegou

O arquivo de build do módulo nomeia oito bibliotecas para o app em si. Pergunte ao Gradle o que o app
recebe de fato em tempo de execução:

```
ana@vm:~/planner$ ./gradlew -q :app:dependencies --configuration debugRuntimeClasspath | grep -E "^[+\\\\]---"
+--- org.jetbrains.kotlin:kotlin-stdlib:2.4.21
+--- androidx.compose.ui:ui-tooling -> 1.12.1
+--- androidx.compose.ui:ui-test-manifest -> 1.12.1
+--- androidx.core:core-ktx:1.19.1 (*)
+--- androidx.activity:activity-compose:1.13.0 (*)
+--- androidx.compose:compose-bom:2026.09.00
+--- androidx.compose.ui:ui -> 1.12.1 (*)
+--- androidx.compose.material3:material3 -> 1.4.0 (*)
\--- androidx.compose.ui:ui-tooling-preview -> 1.12.1 (*)
ana@vm:~/planner$ ./gradlew -q :app:dependencies --configuration debugRuntimeClasspath | grep -oE "[a-z][a-z0-9.-]+:[a-z][a-z0-9.-]+" | sort -u | wc -l
103
```

O primeiro comando imprime o topo da árvore: as oito do arquivo de build, mais a biblioteca padrão
do Kotlin, que o compilador acrescenta sozinho. Uma seta quer dizer que o arquivo de build nomeou uma
versão e o Gradle escolheu outra: `ui -> 1.12.1` é a BOM decidindo, porque o módulo não escreveu
versão nenhuma para `ui`. `(*)` quer dizer que as dependências daquela biblioteca já foram listadas
acima. O segundo comando conta as bibliotecas distintas da árvore inteira, dependências de dependências
incluídas: **uma tela com uma frase, e 103 bibliotecas.** A maioria é pequena e a maioria o R8 remove
de um build de release, que é o assunto da aula 22.

## `compileSdk`, `minSdk` e `targetSdk`

Estes três números são mais confundidos do que qualquer outra coisa num arquivo de build Android,
porque parecem iguais e respondem a três perguntas diferentes.

| | a pergunta que ele responde | este projeto |
|---|---|---|
| **`compileSdk`** | qual API do Android o compilador conhece? | 37, a plataforma que a seção 03 instalou |
| **`minSdk`** | qual é o Android mais antigo que pode instalar o app? | 26, Android 8.0 |
| **`targetSdk`** | contra o comportamento de qual Android o app foi testado? | 36, Android 16 |

**O `compileSdk` não muda nada num celular.** É o conjunto de classes e métodos que o seu código pode
citar, e as bibliotecas opinam nele: a versão de setembro de 2026 do Compose se recusa a compilar
contra qualquer coisa abaixo de 37, e é por isso que este projeto diz 37. Um método que só existe no
37, chamado num celular com 30, quebra; a aula 20 mostra como o código pergunta antes.

**O `minSdk` é uma promessa que você faz à Play Store**: celulares mais antigos que o 26 nem recebem
a oferta do app. Baixá-lo alcança mais celulares e obriga você a testar em aparelhos mais velhos.

**O `targetSdk` é o que muda comportamento.** Cada versão do Android muda regras para os apps que
declaram mirá-la, e deixa os mais antigos em paz: a partir do 33, um app precisa pedir antes de
mostrar uma notificação, que é a aula 19. Subir o `targetSdk` é aderir às regras novas, e o Google
Play exige um recente para apps novos e atualizações; a aula 22 dá a data em que isso foi gravado.

## Módulos, e quando um não basta

Este projeto tem um módulo, `:app`. Um módulo é um diretório com seu próprio arquivo de build, compilado à parte. Um projeto se divide em vários por dois motivos. O primeiro é **para que uma mudança recompile menos**: o Gradle refaz só os módulos que a mudança tocou e os que dependem deles. O segundo é **para que as dependências sejam respeitadas**: um módulo não consegue usar uma classe de outro que ele não declara. Apps grandes têm dezenas. Um planner de estudos feito por uma pessoa não
ganha nada com essa divisão além de mais arquivos de build, então este curso fica com um módulo e a
aula 22 volta à pergunta.
