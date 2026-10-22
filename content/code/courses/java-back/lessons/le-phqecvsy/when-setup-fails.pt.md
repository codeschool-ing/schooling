---
title: Quando a instalação não funciona
version: 1
---

Cada jeito de esta instalação dar errado imprime uma frase que diz qual. Leia a primeira linha do
erro antes de qualquer outra coisa e compare com os títulos daqui.

## `command not found`

É isto que um Ubuntu 24.04 recém-instalado responde quando nenhum dos dois pacotes está instalado.
A transcrição rodou isso num container descartável, uma máquina limpa criada numa linha, que a aula
19 explica; você não precisa digitar:

```
ana@vm:~$ docker run --rm ubuntu:24.04 bash -c 'java -version; mvn -v'
bash: line 1: java: command not found
bash: line 1: mvn: command not found
```

O shell procurou em todos os diretórios do path e não achou programa com esse nome. Ou o
`apt install` da seção anterior não rodou, ou rodou em outra máquina que não aquela em que você está
digitando, ou falhou no meio: suba até as últimas linhas dele e rode de novo.
`javac: command not found` numa máquina em que o `java` funciona é a mesma falha com uma causa mais
estreita: foi instalado um pacote de **runtime** Java no lugar do `openjdk-25-jdk`, e um runtime não
tem compilador.

## Um JDK mais antigo que o 25

Uma máquina que já foi usada para Java pode ter outro JDK, e o Maven pode encontrar esse no lugar
do certo. Dois lugares decidem, e o `mvn -v` informa o resultado: a variável `JAVA_HOME`, se
estiver definida, e senão o `java` a que o seu path leva. Um `JAVA_HOME` esquecido no `~/.bashrc`
por um tutorial antigo é o caso mais comum. Com a linha do `~/.mavenrc` da seção sobre o JDK e o
Maven no lugar, ele falha antes mesmo de o Maven começar:

```
ana@vm:~$ echo $JAVA_HOME
/usr/lib/jvm/java-21-openjdk-amd64
ana@vm:~$ mvn -v
Unrecognized option: --sun-misc-unsafe-memory-access=allow
Error: Could not create the Java Virtual Machine.
Error: A fatal exception has occurred. Program will exit.
```

O `JAVA_HOME` aponta para o JDK 21, então o `mvn` iniciou o Java 21 com a opção do `~/.mavenrc`, e o
JDK 21 não conhece essa opção: **a JVM se recusou a iniciar**, antes que o Maven pudesse imprimir
qualquer coisa. O mesmo JDK sem a linha do `~/.mavenrc` vai mais longe, até dentro de um projeto, e
falha no compilador, que não consegue gerar as classes de Java 25 que o pom pede:

```
ana@vm:~/isbn-check$ mvn -q clean compile
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-compiler-plugin:3.15.0:compile (default-compile) on project isbn-check: Fatal error compiling: error: release version 25 not supported -> [Help 1]
[ERROR] 
[ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch.
[ERROR] Re-run Maven using the -X switch to enable full debug logging.
[ERROR] 
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/MojoExecutionException
```

Duas frases diferentes, uma causa só. A correção é parar de apontar para o JDK antigo. Se a
variável está definida no `~/.bashrc`, apague essa linha e abra um terminal novo; no terminal em
que você está, `unset` a remove, e o Maven volta a usar o `java` do seu path. O `-q` não imprime
nada quando o build funciona, então o `echo` avisa:

```
ana@vm:~/isbn-check$ unset JAVA_HOME; mvn -q compile && echo compiled
compiled
```

Se algo que você usa precisa mesmo do `JAVA_HOME`, aponte-o para
`/usr/lib/jvm/java-25-openjdk-amd64` em vez de removê-lo.

O outro lugar é o `java` do seu path. Quando o `JAVA_HOME` não está definido e o `java -version`
ainda diz 21, as alternativas do Ubuntu apontam o comando `java` para o JDK mais antigo. Isto lista
os JDKs que elas conhecem, com o terminado em `25` na segunda linha aqui:

```
ana@vm:~$ update-java-alternatives -l
java-1.21.0-openjdk-amd64      2111       /usr/lib/jvm/java-1.21.0-openjdk-amd64
java-1.25.0-openjdk-amd64      2511       /usr/lib/jvm/java-1.25.0-openjdk-amd64
```

e isto faz do JDK 25 o que todo `java`, `javac` e `mvn` da máquina usa. Ele pede a sua senha e muda
o padrão para todos os usuários da máquina, e é por isso que as transcrições deste curso o mostram
sem rodá-lo:

```sh
sudo update-java-alternatives -s java-1.25.0-openjdk-amd64
```

Depois disso o `mvn -v` deve citar o runtime 25, como na seção anterior.

## Quatro linhas `WARNING:` antes de todo build

É o aviso de `sun.misc.Unsafe` da seção sobre o JDK e o Maven, e ele quer dizer que a linha do
`~/.mavenrc` está faltando, foi digitada errado ou está num arquivo de outro nome. `cat ~/.mavenrc`
deve imprimir a linha exatamente como ela foi digitada lá. O aviso nunca para um build, e nada mais
daqui depende dele.

## Por baixo de tudo isso: a própria máquina virtual

Se o hipervisor se recusa a iniciar a máquina com uma mensagem sobre `VT-x`, `AMD-V` ou
virtualização desativada, **o processador sabe fazer isso e o firmware do computador está com o
recurso desligado.** É uma configuração no menu da BIOS ou UEFI, que se abre com uma tecla
pressionada enquanto o computador liga, e o site do fabricante diz qual tecla. Se você não puder
mudá-la, o caminho instalado ou o online da primeira seção não precisam de virtualização nenhuma.
