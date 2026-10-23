---
title: Três jeitos de ter um JDK
version: 1
---

Da seção 05 desta lição até a última seção da lição 40, este curso pede que você digite comandos e
leia o que volta. Você precisa de um **JDK**, um Java Development Kit: o compilador que transforma o
seu código-fonte em algo executável, o programa `java` que o executa, e umas trinta ferramentas em
volta dos dois. A partir da lição 18 você também precisa do **Maven**, a ferramenta de build que a
maioria dos projetos Java usa. A plataforma não lhe dá máquina nenhuma onde digitar, então o
primeiro trabalho é ter uma sua.

**Há três lugares para pôr um JDK, e o curso recomenda o primeiro**: instalado num Ubuntu 24.04, no
seu próprio computador ou numa máquina virtual rodando nele.

| caminho | o que você ganha | quanto custa ao seu computador | as transcrições do curso |
|---|---|---|---|
| **instalado no Ubuntu 24.04** (recomendado) | OpenJDK 25 e Maven do próprio arquivo do Ubuntu, com `apt` | uns 290 MB de download e pouco menos de 1 GB de disco | rodam como impressas, byte a byte |
| **uma máquina virtual** | o mesmo Ubuntu, numa janela do Windows ou do macOS | o disco de um sistema operacional inteiro, e memória presa enquanto ela roda | rodam como impressas, byte a byte, com o Ubuntu dentro |
| **online** | um ambiente de desenvolvimento numa aba do navegador | nada no seu computador, mas uma conta e uma cota mensal com alguém | quase iguais, com outro build do JDK e outros caminhos |

## Instalado: o caminho recomendado

O JDK com que este curso foi gravado é o **OpenJDK 25**, do pacote `openjdk-25-jdk` do próprio
arquivo do Ubuntu 24.04, e o Maven é o pacote `maven` do mesmo lugar. Uma linha instala os dois. A
Ana, a aluna cujo prompt aparece em cada transcrição, digitou essa linha num Ubuntu 24.04
recém-instalado, que nunca tinha visto Java:

```
ana@vm:~$ java -version; echo $?
bash: line 1: java: command not found
127
ana@vm:~$ sudo apt install -y openjdk-25-jdk maven 2>&1 | grep -E "^(Need to get|After this operation|Setting up openjdk-25|Setting up maven)"
Need to get 290 MB of archives.
After this operation, 964 MB of additional disk space will be used.
Setting up openjdk-25-jre-headless:amd64 (25.0.4.1+1-1~24.04.4) ...
Setting up maven (3.8.7-2) ...
Setting up openjdk-25-jre:amd64 (25.0.4.1+1-1~24.04.4) ...
Setting up openjdk-25-jdk-headless:amd64 (25.0.4.1+1-1~24.04.4) ...
Setting up openjdk-25-jdk:amd64 (25.0.4.1+1-1~24.04.4) ...
```

O `apt` imprime algumas centenas de linhas enquanto trabalha. O `grep` guarda as duas que dizem
quanto custa e as cinco que dizem o que chegou, para você comparar a sua tela com esta. **Na sua
máquina, digite o comando sem o pipe**: `sudo apt install openjdk-25-jdk maven`. Sem o `-y`, o `apt`
para e pergunta antes de baixar qualquer coisa, e é nessa pergunta que os 290 MB aparecem pela
primeira vez.

Depois pergunte a cada ferramenta o que ela é:

```
ana@vm:~$ java -version
openjdk version "25.0.4.1" 2026-08-18
OpenJDK Runtime Environment (build 25.0.4.1+1-1-24.04.4-Ubuntu)
OpenJDK 64-Bit Server VM (build 25.0.4.1+1-1-24.04.4-Ubuntu, mixed mode, sharing)
ana@vm:~$ javac -version
javac 25.0.4.1
ana@vm:~$ mvn -v
Apache Maven 3.8.7
Maven home: /usr/share/maven
Java version: 25.0.4.1, vendor: Ubuntu, runtime: /usr/lib/jvm/java-25-openjdk-amd64
Default locale: en, platform encoding: UTF-8
OS name: "linux", version: "6.18.44-fc-v139", arch: "amd64", family: "unix"
```

**Se as três respondem, o laboratório está montado.** O `java` executa programas, o `javac` os
compila, e o `mvn` é o Maven, que diz qual Java encontrou: o 25, o que acabou de ser instalado. A
seção 04 mostra por que vale a pena ler essa última linha toda vez. A versão do kernel na linha
`OS name` é da máquina em que o curso foi gravado, e a sua vai ser outra; nada no curso depende dela.

Duas coisas decidem as versões, e nenhuma delas é escolha sua depois que você escolhe o caminho. O
arquivo traz a versão do JDK que o Ubuntu empacotou, aqui a 25.0.4.1, e as atualizações de segurança
que chegam pelo `apt upgrade` a fazem avançar dentro da versão 25. O Maven é o 3.8.7, mais antigo que
a série 3.9 que o projeto Maven lança hoje. A lição 18 fixa a versão de cada plugin do Maven que um
projeto usa, e é essa fixação que faz o Maven antigo construir exatamente o que um novo construiria.

## Uma máquina virtual

Se o seu computador roda Windows ou macOS, rode o Ubuntu 24.04 dentro dele e siga ali o caminho
instalado. Cada transcrição então bate com o que você vê, com prompt e tudo.

- **No Windows**, o WSL é o Linux que o próprio Windows consegue rodar. Numa janela do PowerShell
  aberta como administrador, `wsl --install -d Ubuntu-24.04` o instala, e o terminal do Ubuntu que
  ele abre é onde você digita a linha do `apt` acima.
- **No Windows, no macOS ou no Linux**, o Multipass cria máquinas virtuais Ubuntu com um comando.
  Depois de instalá-lo pelo site dele, `multipass launch 24.04 --name java --memory 2G --disk 10G`
  cria uma e `multipass shell java` abre um terminal nela.

Nenhum dos dois comandos foi executado neste laboratório, que já é um Ubuntu virtual e não consegue
iniciar outro. Os números do segundo são uma recomendação, não uma medição. Dois gigabytes de memória
dão espaço para a JVM e o Maven ao mesmo tempo, e dez de disco são o Ubuntu mais os 964 MB acima, com
folga. Uma máquina virtual prende a memória enquanto roda, e um notebook mais velho, com 8 GB, sente
isso; pare-a com `multipass stop java` quando terminar.

## Online

Um ambiente de desenvolvimento na nuvem abre uma máquina Linux numa aba do navegador, com editor e
terminal. Várias empresas oferecem um, e elas mudam os termos com frequência, então este curso não
depende de nenhuma. **Não custa nada ao seu computador e custa a você uma conta**, uma cota mensal de
horas e uma conexão de rede em cada minuto de estudo.

O JDK dele não vai ser o `openjdk-25-jdk` do Ubuntu. Costuma ser um build de outro fornecedor, em
outro diretório, e o `java -version` imprime uma segunda linha diferente. A linguagem e todos os
programas deste curso são os mesmos, porque o Java SE 25 é uma especificação só, e todo JDK que a
implementa executa os mesmos programas. O que muda são os caminhos das seções 03 e 04.

Então: **instale no Ubuntu se puder, use uma máquina virtual quando o seu computador não for Ubuntu,
e deixe o navegador para um computador que não é seu.**
