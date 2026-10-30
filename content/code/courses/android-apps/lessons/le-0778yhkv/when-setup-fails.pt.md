---
title: Quando a instalação falha
version: 1
---

**Cada falha abaixo tem uma causa, e a mensagem diz qual** se você ler até o fim. As três primeiras
foram produzidas de propósito, numa cópia nova da máquina do curso `kotlin`, e a quarta é descrita.
São as quatro que esta instalação mais encontra: um terminal que não leu o `~/.bashrc`, uma pasta
no lugar errado, um build que não acha o SDK e um download que não terminou.

## `android: command not found`, logo depois de descompactar

A ferramenta está no disco e o shell não a encontra. Um terminal lê o `~/.bashrc` **quando começa**,
então um que já estava aberto antes das duas linhas de `echo` da seção 03 continua com o `PATH`
antigo:

```
ana@vm:~$ android --version; echo $?
bash: line 1: android: command not found
127
ana@vm:~$ ls ~/Android/Sdk/cmdline-tools/latest/bin/android
/home/ana/Android/Sdk/cmdline-tools/latest/bin/android
```

**127 é o número do próprio shell para "comando inexistente"**, então a mensagem vem do `bash` e não
do Android. O `ls` prova que o arquivo está onde a seção 03 o colocou. Abra um terminal novo, ou
digite `source ~/.bashrc` neste. Se um terminal novo ainda não o encontrar, `tail -2 ~/.bashrc`
mostra as duas linhas, e elas devem estar exatamente como a seção 03 digitou, com aspas simples por
fora.

## `Could not determine SDK root`

O zip descompacta numa pasta chamada `cmdline-tools` com `bin` e `lib` direto dentro dela.
Descompacte-o em `~/Android/Sdk` e pare aí, e as ferramentas ficam um nível acima do que esperam:

```
ana@vm:~$ ls ~/Android/Sdk ~/Android/Sdk/cmdline-tools
/home/ana/Android/Sdk:
cmdline-tools

/home/ana/Android/Sdk/cmdline-tools:
NOTICE.txt
bin
lib
source.properties
ana@vm:~$ ANDROID_HOME=~/Android/Sdk ~/Android/Sdk/cmdline-tools/bin/sdkmanager --list_installed 2>&1 | tail -2
Error: Could not determine SDK root.
Error: Either specify it explicitly with --sdk_root= or move this package into its expected location: <sdk>/cmdline-tools/latest/
```

A segunda linha do erro é a correção, nas palavras do Google: o pacote pertence a
`<sdk>/cmdline-tools/latest/`. As ferramentas descobrem onde está o SDK a partir de onde elas
estão, dois diretórios acima, e a partir do `ANDROID_HOME`; aqui os dois discordam, e elas recusam
em vez de adivinhar. Mova a pasta:

```sh
mkdir -p ~/Android/Sdk/cmdline-tools/latest
mv ~/Android/Sdk/cmdline-tools/{bin,lib,NOTICE.txt,source.properties} ~/Android/Sdk/cmdline-tools/latest/
```

## `SDK location not found`

O SDK está instalado e o build não o encontra. O plugin Android do Gradle procura em dois lugares, e
a mensagem lista os dois:

```
ana@vm:~/planner$ env -u ANDROID_HOME ./gradlew --console=plain assembleDebug 2>&1 | sed -n "/What went wrong/,/^$/p"
* What went wrong:
Could not determine the dependencies of task ':app:compileDebugJavaWithJavac'.
> SDK location not found. Define a valid SDK location with an ANDROID_HOME environment variable or by setting the sdk.dir path in your project's local properties file at '/home/ana/planner/local.properties'.
```

Esta foi produzida rodando o build sem `ANDROID_HOME` no ambiente, que é como fica um terminal
aberto antes da linha `export` da seção 03. O primeiro lugar é a variável; o segundo é um arquivo
chamado `local.properties` no projeto, com uma linha, `sdk.dir=` e o caminho. **Prefira a
variável.** O `local.properties` traz um caminho do seu computador, então nunca deve ir para o
controle de versão, e o Android Studio escreve um para você, e é por isso que todo `.gitignore` de
Android o lista.

## Um download que parou no meio

Uma conexão que cai pode deixar um zip com o nome certo e o tamanho errado. Nada no nome avisa, e o
`unzip` descobre tarde, depois de já ter escrito parte das ferramentas no disco. A conferência é a
que a seção 03 fez: **`sha256sum`, comparado com o valor que o Google publica**, antes de
descompactar. Um arquivo de 173 MB mais curto do que deveria tem outro checksum a partir do primeiro
byte errado, e outro tamanho no `ls -lh`. Apague e baixe de novo; o `curl -fsSLO` escreve por cima do
arquivo antigo.

## O que fazer quando nenhuma destas é a sua mensagem

Leia a mensagem até o fim e procure nela o nome de um programa, de um arquivo ou de uma variável: as
três mensagens acima diziam o seu. Depois confira as três coisas de que esta instalação depende, nesta
ordem, cada uma com um comando: `echo $ANDROID_HOME` deve imprimir `/home/`, o seu nome e
`/Android/Sdk`; `android sdk list` deve mostrar os quatro pacotes da seção 03; `java -version` deve
dizer 21. Se as três respondem e um build ainda falha, a próxima coisa a ler é a seção 06 desta aula,
que é sobre o build.
