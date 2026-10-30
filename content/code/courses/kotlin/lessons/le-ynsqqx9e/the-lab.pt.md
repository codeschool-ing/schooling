---
title: Três jeitos de ter Kotlin
version: 1
---

Da seção 04 desta lição até o fim da lição 20, este curso pede que você digite programas, compile e
leia o que volta. Você precisa de três coisas numa máquina: um **JDK**, porque Kotlin no computador
compila para o mesmo bytecode do Java e roda na mesma máquina virtual; o **compilador Kotlin**,
`kotlinc`; e o **Gradle**, a ferramenta de build que todo projeto Android e a maioria dos projetos
Kotlin usam, e que este curso usa a partir da lição 14. A plataforma não dá máquina nenhuma para
você digitar, então o primeiro trabalho é ter uma sua.

**Há três lugares para pôr essas ferramentas, e o curso recomenda o primeiro**: instaladas num
Ubuntu 24.04, no seu próprio computador ou numa máquina virtual rodando nele.

| caminho | o que você recebe | quanto custa ao seu computador | as transcrições do curso |
|---|---|---|---|
| **instalado no Ubuntu 24.04** (recomendado) | OpenJDK 21 do arquivo do Ubuntu, e Kotlin 2.4.21 e Gradle 9.8.2 descompactados na sua pasta pessoal | cerca de 140 MB do Ubuntu e 230 MB dos dois projetos, e uns 600 MB de disco depois de descompactar | rodam como impressas, byte a byte |
| **uma máquina virtual** | o mesmo Ubuntu, dentro de uma janela no Windows ou no macOS | o disco de um sistema operacional inteiro, e memória presa enquanto ela roda | rodam como impressas, byte a byte, depois que o Ubuntu estiver nela |
| **online** | um ambiente de desenvolvimento numa aba do navegador | nada no seu computador, mas uma conta e uma franquia mensal com alguma empresa | parecidas, com outro JDK e outros caminhos |

## O que este curso consegue e não consegue mostrar

**Todo programa deste curso roda num computador, e nenhum precisa de celular.** Kotlin é antes de
tudo uma linguagem, e tudo, de `val` a `StateFlow`, roda na JVM exatamente como vai rodar dentro de
um app Android. Então cada transcrição destas vinte lições foi produzida na máquina descrita abaixo,
e você consegue reproduzir todas.

O que este curso não faz é construir um app Android. Isso exige o Android SDK, o Android Studio e um
emulador, e é o próximo curso deste caminho, `android-apps`, que os instala. A máquina que você
monta aqui é a de onde aquele curso parte.

Mais uma coisa é descrita e não rodada: o build nativo da lição 20, que compila Kotlin para um executável
Linux sem JVM. O compilador dele chega do Maven Central como todo o resto, mas o toolchain de C com que
ele liga o programa é baixado de `download.jetbrains.com`, e a máquina em que estas lições foram gravadas
não alcançava esse endereço. A lição 20 mostra o arquivo de build e diz onde a transcrição dele estaria.

## Instalado: o caminho recomendado

As versões são fixas, e o curso foi gravado exatamente com estas: **OpenJDK 21** do pacote
`openjdk-21-jdk-headless` no arquivo do próprio Ubuntu 24.04, **Kotlin 2.4.21** dos releases do
projeto Kotlin no GitHub e **Gradle 9.8.2** de `services.gradle.org`. O Ubuntu empacota o JDK; não
empacota um Kotlin nem um Gradle atuais, então esses dois chegam como arquivos zip que você mesmo
descompacta. A Ana, a estudante cujo prompt aparece em toda transcrição, começou num Ubuntu 24.04
novo, que nunca tinha visto Java:

```
ana@vm:~$ java -version; echo $?
bash: line 1: java: command not found
127
ana@vm:~$ sudo apt install -y openjdk-21-jdk-headless unzip curl 2>&1 | grep -E "^(Need to get|After this operation|Setting up (openjdk-21|unzip|curl))"
Need to get 137 MB of archives.
After this operation, 321 MB of additional disk space will be used.
Setting up unzip (6.0-28ubuntu4.1) ...
Setting up curl (8.5.0-2ubuntu10.16) ...
Setting up openjdk-21-jre-headless:amd64 (21.0.12.1+1-1~24.04.4) ...
Setting up openjdk-21-jdk-headless:amd64 (21.0.12.1+1-1~24.04.4) ...
```

O `apt` imprime algumas centenas de linhas enquanto trabalha. O `grep` guarda as duas que dizem
quanto custa e as linhas que dizem o que chegou, para você comparar a sua tela com esta. **Na sua
máquina, digite o comando sem o pipe**: `sudo apt install openjdk-21-jdk-headless unzip curl`. Sem o
`-y`, o `apt` para e pergunta antes de baixar qualquer coisa, e essa pergunta é onde o tamanho
aparece para você pela primeira vez.

`-headless` quer dizer o JDK sem as bibliotecas de janelas e gráficos. Nada neste curso desenha uma
janela, e o Android desenha as suas.

Depois, os dois downloads. Crie uma pasta para eles, baixe cada zip e verifique antes de
descompactar:

```
ana@vm:~$ mkdir -p ~/downloads ~/.local/share && cd ~/downloads
ana@vm:~/downloads$ curl -fsSLO https://github.com/JetBrains/kotlin/releases/download/v2.4.21/kotlin-compiler-2.4.21.zip
ana@vm:~/downloads$ curl -fsSLO https://github.com/JetBrains/kotlin/releases/download/v2.4.21/kotlin-compiler-2.4.21.zip.sha256
ana@vm:~/downloads$ echo "$(cat kotlin-compiler-2.4.21.zip.sha256)  kotlin-compiler-2.4.21.zip" | sha256sum -c
kotlin-compiler-2.4.21.zip: OK
ana@vm:~/downloads$ curl -fsSLO https://services.gradle.org/distributions/gradle-9.8.2-bin.zip
ana@vm:~/downloads$ sha256sum gradle-9.8.2-bin.zip
21bd5da2de49b642904077f38c0efdc7778e92b3ed0889392dca61b97e389607  gradle-9.8.2-bin.zip
ana@vm:~/downloads$ ls -lh
total 231M
-rw-r--r-- 1 ana ana 145M Oct 30 03:00 gradle-9.8.2-bin.zip
-rw-r--r-- 1 ana ana  86M Oct 30 03:00 kotlin-compiler-2.4.21.zip
-rw-r--r-- 1 ana ana   64 Oct 30 03:00 kotlin-compiler-2.4.21.zip.sha256
```

O projeto Kotlin publica um checksum SHA-256 ao lado de cada zip. O `sha256sum -c` recalcula o
checksum do arquivo no disco e compara com o publicado, e **`OK` é a única resposta que deixa você
seguir**. Para o Gradle, o `sha256sum` imprime o checksum do que você baixou, e você compara a olho
com o valor que o Gradle publica para a 9.8.2 na página de checksums dos releases,
`gradle.org/release-checksums`. Essa comparação não foi feita quando o curso foi gravado, porque a
máquina de gravação não alcançava o endereço de onde o Gradle serve os arquivos de checksum; o valor
acima é o que a máquina de gravação calculou. A seção 03 mostra como fica um download danificado.

Descompacte os dois em `~/.local/share` e ponha os diretórios `bin` deles no seu `PATH`, para o
shell achar `kotlinc` e `gradle` sem caminho completo:

```
ana@vm:~/downloads$ unzip -q kotlin-compiler-2.4.21.zip -d ~/.local/share
ana@vm:~/downloads$ unzip -q gradle-9.8.2-bin.zip -d ~/.local/share
ana@vm:~/downloads$ echo 'export PATH="$HOME/.local/share/kotlinc/bin:$HOME/.local/share/gradle-9.8.2/bin:$PATH"' >> ~/.bashrc
ana@vm:~/downloads$ source ~/.bashrc
ana@vm:~/downloads$ ls ~/.local/share
gradle-9.8.2
kotlinc
ana@vm:~/downloads$ du -sh ~/.local/share/kotlinc ~/.local/share/gradle-9.8.2 /usr/lib/jvm/java-21-openjdk-amd64
94M	/home/ana/.local/share/kotlinc
165M	/home/ana/.local/share/gradle-9.8.2
286M	/usr/lib/jvm/java-21-openjdk-amd64
```

O `echo` acrescenta uma linha ao `~/.bashrc`, que todo terminal novo lê. O `source` lê esse arquivo
no terminal que você já tem aberto. **Digite a linha exatamente assim, com aspas simples por fora e
aspas duplas por dentro**: as simples mantêm `$HOME` e `$PATH` como texto até um terminal ler o
arquivo.

## Confira que cada ferramenta responde

```
ana@vm:~$ java -version
openjdk version "21.0.12.1" 2026-08-18
OpenJDK Runtime Environment (build 21.0.12.1+1-1-24.04.4-Ubuntu)
OpenJDK 64-Bit Server VM (build 21.0.12.1+1-1-24.04.4-Ubuntu, mixed mode, sharing)
ana@vm:~$ javac -version
javac 21.0.12.1
ana@vm:~$ kotlinc -version
info: kotlinc-jvm 2.4.21 (JRE 21.0.12.1+1-1-24.04.4-Ubuntu)
ana@vm:~$ gradle --version

Welcome to Gradle 9.8.2!

Here are the highlights of this release:
 - Java 27 support
 - Maven mirror settings reuse
 - Linked problem locations in build output

For more details see https://docs.gradle.org/9.8.2/release-notes.html


------------------------------------------------------------
Gradle 9.8.2
------------------------------------------------------------

Build time:    2026-10-19 16:29:26 UTC
Revision:      8de7bcf76e785507ad92f0741ab9235a430c95e6

Kotlin:        2.4.10
Groovy:        4.0.33
Ant:           Apache Ant(TM) version 1.10.17 compiled on April 6 2026
Launcher JVM:  21.0.12.1 (Ubuntu 21.0.12.1+1-1-24.04.4-Ubuntu)
Daemon JVM:    /usr/lib/jvm/java-21-openjdk-amd64 (no Daemon JVM specified, using current Java home)
OS:            Linux 6.18.44-fc-v185 amd64
```

**Se as quatro responderem, o laboratório está montado.** O `java` executa programas e o `javac`
compila Java; o `kotlinc` compila Kotlin e diz qual JVM encontrou, a 21, a que acabou de ser
instalada; o `gradle` dá boas-vindas na primeira execução e depois se descreve, junto com a JVM em
que roda. A linha `OS` mostra o kernel da máquina em que o curso foi gravado, e o seu será outro;
nada no curso depende disso.

Uma linha parece contradição: `Kotlin: 2.4.10`, ao lado de um compilador que acabou de dizer
2.4.21. O Gradle carrega um Kotlin próprio, para ler os scripts de build, que são escritos em
Kotlin. O Kotlin com que os seus programas são compilados da lição 14 em diante é escolhido por cada
projeto, e a lição 19 é exatamente sobre essa diferença. Os zips em `~/downloads`, 231 MB deles,
podem ser apagados quando as duas ferramentas responderem.

## Uma máquina virtual

Se o seu computador roda Windows ou macOS, rode o Ubuntu 24.04 dentro dele e siga o caminho
instalado lá. Toda transcrição então bate com o que você vê, prompt e tudo.

- **No Windows**, o WSL é o Linux que o próprio Windows sabe rodar. Numa janela do PowerShell aberta
  como administrador, `wsl --install -d Ubuntu-24.04` o instala, e o terminal do Ubuntu que ele abre
  é onde você digita tudo o que está acima.
- **No Windows, no macOS ou no Linux**, o Multipass cria máquinas virtuais Ubuntu com um comando.
  Depois de instalá-lo pelo site, `multipass launch 24.04 --name kotlin --memory 4G --disk 15G` cria
  uma e `multipass shell kotlin` abre um terminal nela.

Nenhum dos dois comandos foi executado para este curso, porque a máquina de gravação era ela mesma
um contêiner e não inicia outro. Os números do segundo são uma recomendação, não uma medida: o
Gradle e o compilador Kotlin são duas JVMs que rodam ao mesmo tempo, e quatro gigabytes evitam que
elas usem swap. Uma máquina virtual prende a memória enquanto roda, então pare-a com
`multipass stop kotlin` quando terminar.

## Online

Um ambiente de desenvolvimento na nuvem abre uma máquina Linux numa aba do navegador, com editor e
terminal. Várias empresas oferecem isso e mudam as condições com frequência, então este curso não
depende de nenhuma. **Não custa nada ao seu computador e custa uma conta**, uma franquia mensal de
horas e uma conexão de rede a cada minuto de estudo. O JDK de lá é outro build, em outro diretório,
então os caminhos desta lição serão diferentes; os passos do Kotlin e do Gradle acima funcionam lá
como estão escritos.

Então: **instale no Ubuntu se puder, use uma máquina virtual quando o seu computador não for Ubuntu,
e deixe o navegador para um computador que não é seu.**

## Por que não uma IDE

O IntelliJ IDEA e o Android Studio compilam Kotlin com o mesmo compilador e fazem o build com o mesmo
Gradle. Vale a pena instalá-los, e o `android-apps` instala o Android Studio no primeiro dia. Este
curso digita os comandos, por um motivo: quando um build falha dentro de uma IDE, a mensagem de que
você precisa é a que estes comandos imprimem, e ela é mais fácil de ler depois de vista sozinha.
