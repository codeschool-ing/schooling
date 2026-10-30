---
title: Três jeitos de ter o SDK do Android
version: 1
---

**Este curso parte da máquina que o curso `kotlin` montou**, e acrescenta uma coisa a ela: o
**SDK do Android**, as bibliotecas e ferramentas que transformam Kotlin em algo que um celular
instala. A aula 1 de `kotlin` preparou um Ubuntu 24.04 com OpenJDK 21, Kotlin 2.4.21 e Gradle 9.8.2,
e todo comando deste curso conta com eles. Confira se cada um responde antes de seguir:

```
ana@vm:~$ java -version 2>&1 | head -1; kotlinc -version; gradle --version | grep ^Gradle
openjdk version "21.0.12.1" 2026-08-18
info: kotlinc-jvm 2.4.21 (JRE 21.0.12.1+1-1-24.04.4-Ubuntu)
Gradle 9.8.2
```

Se algum deles imprimir `command not found` ou outra versão, volte à aula 1 de `kotlin`, seções 02
e 03, e monte aquela máquina primeiro. Tudo o que vem abaixo é colocado em cima dela.

## Três caminhos, e o que este curso recomenda

| caminho | o que você ganha | quanto custa ao seu computador | as transcrições do curso |
|---|---|---|---|
| **as ferramentas de linha de comando no Ubuntu 24.04** (recomendado) | o SDK em `~/Android/Sdk`, comandado de um terminal | cerca de 520 MB para o SDK e 160 MB para a Android CLI, mais o cache do Gradle, que passa de 2 GB até a aula 22 | executadas como impressas, byte a byte |
| **o Android Studio**, no Linux, no Windows ou no macOS | o mesmo SDK, mais um editor, prévias na janela e o gerenciador de emuladores | o Google lista memória e disco na página de download; é o maior dos três | os comandos do Gradle funcionam como impressos; a janela não aparece neste curso |
| **online**, um ambiente de desenvolvimento na nuvem | uma máquina Linux numa aba do navegador | nada no seu computador, mas uma conta e uma cota mensal com alguém | parecidas, sem emulador e com caminhos diferentes |

**O curso recomenda as ferramentas de linha de comando**, no mesmo Ubuntu que o curso `kotlin`
montou, e grava tudo desse jeito. É o menor download, funciona igual dentro de uma máquina virtual, e
cada passo é um comando que dá para ler. O Android Studio instala exatamente o mesmo SDK no mesmo
diretório, `~/Android/Sdk` no Linux, e roda o mesmo build do Gradle; se você prefere um editor que
mostra os composables enquanto você digita, instale-o também, ou no lugar. O instalador e a janela
dele não foram executados para este curso.

**Uma máquina virtual** serve para tudo, menos para o emulador, que também é uma máquina virtual e
precisa do `/dev/kvm` da seção 02. Dentro do VirtualBox ou do UTM ele em geral não chega, então um
celular pelo USB é o jeito de ver o app rodando.

**Online**, o GitHub Codespaces e serviços parecidos dão uma máquina Linux numa aba do navegador. O
build e todos os testes deste curso rodam ali; não há emulador nem porta USB. Cada serviço dá às
contas pessoais uma cota mensal e cobra além dela, em termos que ele define e pode mudar. Não foi
executado para este curso.

## As ferramentas de linha de comando

O Google publica as ferramentas de linha de comando do SDK num zip para Linux. O nome do arquivo
carrega um número de build, e este curso fixa o que foi usado na gravação: **versão 23.0, build
16111833**.

```
ana@vm:~$ mkdir -p ~/Android/Sdk/cmdline-tools && cd ~/downloads
ana@vm:~/downloads$ curl -fsSLO https://dl.google.com/android/repository/commandlinetools-linux-16111833_latest.zip
ana@vm:~/downloads$ sha256sum commandlinetools-linux-16111833_latest.zip
0877a1d048fe4a24efe2eff536ca4223f7adeb58648bb81909d33c446918cfa8  commandlinetools-linux-16111833_latest.zip
ana@vm:~/downloads$ ls -lh commandlinetools-linux-16111833_latest.zip
-rw-r--r-- 1 ana ana 173M Oct 30 15:41 commandlinetools-linux-16111833_latest.zip
ana@vm:~/downloads$ unzip -q commandlinetools-linux-16111833_latest.zip -d ~/Android/Sdk/cmdline-tools
ana@vm:~/downloads$ mv ~/Android/Sdk/cmdline-tools/cmdline-tools ~/Android/Sdk/cmdline-tools/latest
ana@vm:~/downloads$ ls ~/Android/Sdk/cmdline-tools/latest/bin
android
apkanalyzer
avdmanager
d8
lint
profgen
r8
resourceshrinker
retrace
screenshot2
sdkmanager
```

O `sha256sum` imprime o checksum do que chegou. O Google imprime o SHA-256 de cada download na
página de download do Android Studio, em *Command line tools only*; **compare os dois a olho antes
de descompactar qualquer coisa**. Essa comparação não foi feita na gravação do curso, porque a
página é um formulário de navegador que a máquina de gravação não conseguiu abrir; o valor acima é o
que ela calculou. A seção 04 mostra o que um download danificado faz.

**Renomear não é opcional.** O zip descompacta numa pasta chamada `cmdline-tools`, e as ferramentas
dentro dela esperam morar em `<sdk>/cmdline-tools/latest`. Pule o `mv` e elas não conseguem
descobrir onde está o SDK; a seção 04 mostra essa mensagem também.

Duas linhas no `~/.bashrc` dizem a todo terminal novo onde está o SDK. **`ANDROID_HOME` é a variável
que o plugin Android do Gradle lê**, e a linha do `PATH` faz as ferramentas de
`cmdline-tools/latest/bin` e, depois de instalado, o `adb` de `platform-tools` responderem pelo nome:

```
ana@vm:~$ echo 'export ANDROID_HOME="$HOME/Android/Sdk"' >> ~/.bashrc
ana@vm:~$ echo 'export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"' >> ~/.bashrc
ana@vm:~$ source ~/.bashrc
ana@vm:~$ echo $ANDROID_HOME
/home/ana/Android/Sdk
```

## A Android CLI, e o que ela pergunta da primeira vez

A primeira ferramenta a rodar é `android`, a **Android CLI**. Na versão 23.0 das ferramentas de linha de comando ela é a substituta do `sdkmanager`, como o fim desta seção mostra. O zip traz só um pequeno lançador: na primeira execução, ele baixa a versão mais recente de si mesmo e mostra duas coisas para ler.

```
ana@vm:~$ android --version
Downloading Android CLI...
Unpacking embedded installation...

Terms of Service and License Agreement for the Android Software Development Kit

https://developer.android.com/studio/terms

Google collects usage data for the Android CLI, such as commands, sub-commands, and flags used. This data does not include custom parameters or identifiable information. This information helps improve the tool and is collected in accordance with Google's Privacy Policy.

https://policies.google.com/privacy

Disable Android CLI metrics collection by using the --no-metrics flag.

Tip: For the best experience using Android CLI with agents, we strongly recommend running android init to install the necessary skills and resources.
1.1.16717390
Oct 30, 2026 3:41:51 PM java.util.prefs.FileSystemPreferences setupUserRoot
INFO: Created user preferences directory.
ana@vm:~$ ls ~/.android/cli
analytics
bundles
last_update_check
tos_displayed
```

Leia os dois links antes de seguir. O primeiro é a licença do SDK, que você aceita ao usá-lo. O
segundo diz que o Google coleta dados de uso da CLI, e como desligar isso: acrescente
`--no-metrics` a um comando. A linha `java.util.prefs` no fim vem da JVM, não da CLI, e aparece uma
vez.

**A CLI é a única coisa nesta máquina que não dá para fixar.** O lançador sempre baixa a versão mais
recente, e este curso foi gravado com a 1.1.16717390, a que ele encontrou em 30 de outubro de 2026.
Se a sua imprimir um número maior, os comandos abaixo devem continuar funcionando; se algum não
funcionar, o `--help` dele diz o que o substituiu.

Agora o SDK em si. Três pacotes: a **plataforma** do Android 37, que é a API contra a qual o
compilador confere o seu código; as **build tools**, que empacotam e assinam um app; e as **platform
tools**, que trazem o `adb`, o programa que conversa com um celular.

```
ana@vm:~$ android sdk install platforms/android-37.0 build-tools/36.1.0 platform-tools
...om/android/repository/platform-37.0_r02.zip [##########] 100% (  64.2 MB/  64.2 MB) ETA: ----- 
...roid/repository/build-tools_r36.1_linux.zip [##########] 100% (  61.2 MB/  61.2 MB) ETA: ----- 
...repository/platform-tools_r37.0.1-linux.zip [##########] 100% (   8.6 MB/   8.6 MB) ETA: ----- 
Unzipping platforms/android-37.0... [#####################] 100% ( 119.2 MB/ 119.2 MB) ETA: ----- 
Unzipping build-tools/36.1.0... [#########################] 100% ( 149.2 MB/ 149.2 MB) ETA: ----- 
Unzipping platform-tools... [#############################] 100% (  21.2 MB/  21.2 MB) ETA: ----- 
ana@vm:~$ android sdk list
Installed packages:
  build-tools/36.1.0             36.1.0                      Android SDK Build-Tools 36.1           
  cmdline-tools/latest           unknown   ->        23.0.0  Android SDK Command-line Tools (latest)
  platform-tools                 37.0.1                      Android SDK Platform-Tools             
  platforms/android-37.0         2.0.0                       Android SDK Platform 37.0              
```

`android sdk list` mostra o que está instalado, e `android sdk list --all` mostra tudo o que o
repositório oferece. O `cmdline-tools` aparece com versão instalada `unknown` porque foi
descompactado à mão, e não instalado pela CLI; funciona do mesmo jeito. Eis quanto tudo custa:

```
ana@vm:~$ du -sh ~/Android/Sdk/* ~/.android/cli
150M	/home/ana/Android/Sdk/build-tools
174M	/home/ana/Android/Sdk/cmdline-tools
8.0K	/home/ana/Android/Sdk/licenses
22M	/home/ana/Android/Sdk/platform-tools
165M	/home/ana/Android/Sdk/platforms
160M	/home/ana/.android/cli
ana@vm:~$ adb version | head -2
Android Debug Bridge version 1.0.41
Version 37.0.1-15733141
```

Cerca de 520 MB no SDK e 160 MB para a CLI em `~/.android/cli`. O `adb` responde, e não vai ter com
quem conversar até um celular ou um emulador ser conectado.

## O emulador, se o seu computador consegue rodar um

**Não executado.** A máquina de gravação não tinha `/dev/kvm`, então estes comandos não foram
digitados para este curso. A documentação do Google para a Android CLI instala um emulador e uma imagem de sistema como pacotes do SDK, iguais aos três acima: o pacote `emulator` e uma imagem em `system-images/`. Depois cria e inicia um aparelho virtual com `android emulator`; `android emulator --help` lista os comandos. Com o Android Studio, o Device Manager faz o mesmo numa janela.

## `sdkmanager`, que você vai ver em todo lugar

A maioria dos tutoriais escritos antes de 2026 diz `sdkmanager`, e o zip ainda o traz. Agora ele
imprime um aviso e passa o trabalho para a CLI:

```
ana@vm:~$ sdkmanager --list_installed 2>&1 | head -2
WARNING: The SDK Manager CLI tool (sdkmanager) is deprecated. Android CLI will be used instead.
The 'android' binary can also be found in the cmdline-tools directory, and 'android sdk' is the replacement for 'sdkmanager'.
```

**Os nomes de pacote dele usam ponto e vírgula onde a CLI usa barra**: `"platforms;android-37.0"`
contra `platforms/android-37.0`. Quando um tutorial mostrar a forma antiga, a tradução é esse único
caractere.
