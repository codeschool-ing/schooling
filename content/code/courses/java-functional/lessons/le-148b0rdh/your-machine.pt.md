---
title: Sua máquina, a mesma do curso de java
version: 1
---

**Este curso roda na máquina que o curso `java` montou, e não muda nada nela.** Bastam dois
programas: o **OpenJDK 25**, que compila e roda Java, e o **Maven**, que constrói um projeto que usa
a biblioteca de outra pessoa. Os dois vêm do próprio repositório do Ubuntu 24.04. O curso `java`
instala os dois na seção 02 da aula 1 e explica cada passo; esta seção dá os mesmos passos em
resumo, para quem chega de outro lugar, e depois confere se cada ferramenta responde. O `java-back`,
o curso seguinte, usa os mesmos dois nas mesmas versões, então quem faz os três em ordem não instala
nada duas vezes.

## Três jeitos de ter uma

| caminho | o que você ganha | quanto custa ao seu computador | as transcrições |
|---|---|---|---|
| **instalado** (recomendado) | o JDK e o Maven no Ubuntu que você já usa, ou dentro do WSL no Windows | uns 400 MB de disco | batem com o impresso |
| uma máquina virtual | um Ubuntu Server 24.04 numa janela só dele | alguns gigabytes de disco, e 2 GB de memória enquanto roda | batem com o impresso |
| online | uma máquina Linux numa aba do navegador | nada no seu computador; horas de uma cota mensal | parecidas, não idênticas |

**Instale no computador que você usa.** No **Ubuntu 24.04**, ou em qualquer Linux com os mesmos
pacotes, os dois comandos abaixo são tudo. No **Windows**, todo comando deste curso é digitado num
terminal Linux: abra o PowerShell como administrador, rode `wsl --install -d Ubuntu-24.04`, reinicie,
abra o Ubuntu pelo menu Iniciar e siga os passos de Linux lá dentro. No **Mac**, o
`brew install openjdk@25 maven` do Homebrew dá as mesmas versões; esse caminho não foi executado para
este curso, então um caminho de pasta numa transcrição pode ser diferente do seu.

**Uma máquina virtual** são os mesmos passos dentro de uma máquina só dela: VirtualBox no Windows ou
no Linux, UTM num Mac com chip Apple, e o Ubuntu Server 24.04 LTS como convidado. É a máquina em que
este curso foi gravado, e por isso o prompt de toda transcrição diz `ana@vm`.

**Online**, o GitHub Codespaces e serviços parecidos dão uma máquina Linux com terminal numa aba do
navegador. O GitHub dá às contas pessoais uma cota mensal e cobra o que passar dela, em condições que
ele define e pode mudar, então trate isso como plano B e não como casa. Não foi executado para este
curso. `cat /etc/os-release` diz qual Linux você recebeu antes de começar.

## Os dois pacotes

```sh
sudo apt update
sudo apt install openjdk-25-jdk maven
```

`openjdk-25-jdk` é o **JDK**, o kit para escrever Java: o compilador `javac`, o lançador `java` e
ferramentas como o `javap`, que a seção 04 da aula 1 usa. O pacote `openjdk-25-jre` é só o ambiente
de execução, e uma máquina só com ele roda Java mas não compila. O Ubuntu imprime algumas centenas de
linhas enquanto instala, e nenhuma delas importa para este curso. Isto pergunta o que ele instalou:

```
ana@vm:~$ apt-cache policy openjdk-25-jdk | head -n 5
openjdk-25-jdk:
  Installed: 25.0.4.1+1-1~24.04.4
  Candidate: 25.0.4.1+1-1~24.04.4
  Version table:
 *** 25.0.4.1+1-1~24.04.4 500
```

A linha com `***` é a versão desta máquina. O Ubuntu atualiza o pacote com correções de segurança,
então a sua pode terminar num número maior; qualquer coisa que comece com `25.` se comporta igual ao
longo do curso.

## Conferindo se cada ferramenta responde

Abra um terminal novo e peça a versão a cada uma das três:

```
ana@vm:~$ java -version
openjdk version "25.0.4.1" 2026-08-18
OpenJDK Runtime Environment (build 25.0.4.1+1-1-24.04.4-Ubuntu)
OpenJDK 64-Bit Server VM (build 25.0.4.1+1-1-24.04.4-Ubuntu, mixed mode, sharing)
ana@vm:~$ javac -version
javac 25.0.4.1
ana@vm:~$ mvn -B -v
Apache Maven 3.8.7
Maven home: /usr/share/maven
Java version: 25.0.4.1, vendor: Ubuntu, runtime: /usr/lib/jvm/java-25-openjdk-amd64
Default locale: en, platform encoding: UTF-8
OS name: "linux", version: "6.18.44-fc-v139", arch: "amd64", family: "unix"
```

- **`java -version`** imprime três linhas, e a primeira é a que importa: `25.0.4.1` é a versão 25,
  a versão de suporte longo para a qual este curso e o curso `java` foram escritos;
- **`javac -version`** prova que o compilador está lá, e é isso que separa o JDK do ambiente de
  execução sozinho;
- **`mvn -B -v`** é o Maven. Leia a terceira linha antes da primeira: **o Maven roda no Java que
  encontrar**, e `Java version: 25.0.4.1` diz que ele encontrou o certo. O `-B` pede o modo batch,
  que deixa de fora os códigos de cor que o Maven imprimiria, e todo comando Maven deste curso leva
  esse `-B`.

## Onde fica o trabalho

Tudo o que você escrever neste curso vai em `~/fp`, uma pasta por assunto. Crie a primeira,
`~/fp/lambdas`, e salve este arquivo nela como `Hello.java`:

```java
// Hello.java: the first program of the course, to prove the machine runs one
public class Hello {
    public static void main(String[] args) {
        System.out.println("Hello from Java " + Runtime.version().feature());
    }
}
```

```
ana@vm:~$ mkdir -p ~/fp/lambdas
ana@vm:~$ cd ~/fp/lambdas
ana@vm:~/fp/lambdas$ java Hello.java
Hello from Java 25
ana@vm:~/fp/lambdas$ ls
Hello.java
```

`java Hello.java` compilou o arquivo na memória e o executou, sem deixar um `.class` para trás. Esse
é o **modo de arquivo-fonte** que o curso `java` usou para programas pequenos, e é assim que a maior
parte dos programas deste curso roda: um arquivo, ou alguns na mesma pasta, cada um mostrado inteiro
na seção que o usa. Do Java 22 em diante, um programa rodado assim pode usar os outros arquivos
`.java` ao lado dele, e a aula 6 se apoia nisso. A aula 21 é o único lugar onde se precisa de uma
biblioteca de fora do JDK, e ela monta um projeto Maven ali.
