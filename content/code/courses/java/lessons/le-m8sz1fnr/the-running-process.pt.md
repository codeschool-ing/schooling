---
title: O programa enquanto roda
version: 1
---

É fácil imaginar `java Greet` como sendo o Greet rodando. **O que roda é a JVM**, um processo comum do
sistema operacional, e o Greet é umas centenas de bytes de bytecode dentro dela. O processo tem um
número, threads, memória e um relógio próprio, e o JDK traz ferramentas que o encontram e lhe fazem
perguntas enquanto ele roda. São essas as ferramentas que você usa quando um serviço Java em produção
se comporta mal, e elas funcionam do mesmo jeito num brinquedo.

## Um programa que fica tempo bastante para ser olhado

O `Greet` termina numa fração de segundo. Este aqui imprime o próprio número de processo e depois
dorme por um minuto, em `~/proc`:

```java
// Wait.java
public class Wait {
    public static void main(String[] args) throws InterruptedException {
        System.out.println("pid " + ProcessHandle.current().pid());
        Thread.sleep(60_000);
        System.out.println("done");
    }
}
```

`ProcessHandle.current().pid()` pergunta à JVM o número que o sistema operacional deu ao processo
dela. `Thread.sleep(60_000)` pausa por 60.000 milissegundos, e o sublinhado só está ali para deixar o
número legível. O `throws InterruptedException` é exigido pelo `sleep`, por motivos que a lição 36
explica.

Compile-o, e inicie-o **em segundo plano**, com `&`, para o terminal ficar livre enquanto ele dorme.
O `> wait.log` manda o que ele imprime para um arquivo, que você lê quando quiser:

```
ana@vm:~/proc$ javac Wait.java
ana@vm:~/proc$ java Wait > wait.log &
ana@vm:~/proc$ cat wait.log
pid 3343
```

O número é diferente a cada execução, e em cada máquina.

## Encontrando e perguntando

O `jps` lista as JVMs que são suas, com os números de processo, e o `-l` acrescenta a classe
principal. Você pode ter outras rodando, um editor por exemplo, então o `grep` guarda a linha do
`Wait`:

```
ana@vm:~/proc$ jps -l | grep -w Wait
3343 Wait
ana@vm:~/proc$ jcmd Wait VM.version
3343:
OpenJDK 64-Bit Server VM version 25.0.4.1+1-1-24.04.4-Ubuntu
JDK 25.0.4.1
ana@vm:~/proc$ jcmd Wait VM.uptime
3343:
5.922 s
```

O `jcmd` manda um comando a uma JVM em execução, que você identifica pelo número do processo ou, como
aqui, pela classe principal. A JVM responde primeiro com o próprio número de processo e depois com o
resultado. O `VM.version` diz em que JDK esse processo está rodando, que num servidor com vários
instalados é a pergunta que importa, e o `VM.uptime` diz que ele está vivo há pouco menos de seis
segundos. `jcmd Wait help` lista todos os comandos que uma JVM aceita.

## Threads que você não criou

O `Wait` tem uma linha de código que faz alguma coisa: ela dorme. Conte as threads do processo mesmo
assim. O `Thread.print` despeja cada thread com o nome entre aspas duplas, e o `grep -c` conta essas
linhas:

```
ana@vm:~/proc$ jcmd Wait Thread.print | grep -c "^\""
18
ana@vm:~/proc$ ps -o pid,rss,args -C java | grep -E "PID|Wait"
  PID   RSS COMMAND
 3343 44080 java Wait
```

**Dezoito threads, e o programa não criou nenhuma.** Uma é a `main`, dormindo dentro do
`Thread.sleep`. As outras são da JVM: o coletor de lixo, que a lição 19 observa, os compiladores JIT
da lição 1, e a thread que acabou de responder ao `jcmd`. A visão do sistema operacional, pelo `ps`,
concorda que este é um processo de verdade: **44.080 kilobytes de memória em uso**, uns 43 MB, para um
programa que guarda uma string. A maior parte é a própria JVM e as classes que ela carregou, que é a
próxima coisa a contar.

## Seiscentas classes por uma linha

O `-Xlog:class+load` faz a JVM registrar cada classe que carrega, uma linha por classe, na hora em que
carrega. Rode o `Greet` com ele, de volta em `~/life`:

```
ana@vm:~/life$ java -Xlog:class+load -cp out Greet Ana | wc -l
605
ana@vm:~/life$ java -Xlog:class+load -cp out Greet Ana | grep -E "Greet|Hello, Ana"
[0.081s][info][class,load] Greet source: file:/home/ana/life/out/
Hello, Ana
ana@vm:~/life$ java -Xlog:class+load -cp out Greet Ana | grep -c "shared objects file"
600
```

605 linhas, e uma delas é `Hello, Ana`, então **a JVM carregou 604 classes para imprimir uma linha**.
Só uma delas é sua: o `Greet`, encontrado aos 0,081 segundo no diretório que o class path indicou. O
resto é a biblioteca: strings, o console, o próprio carregador de classes.

A última contagem explica como isso é rápido. **600 dessas classes vieram do "shared objects file"**,
um arquivo com as classes da biblioteca que o JDK preparou de antemão, já lidas e verificadas, que a
JVM mapeia na memória em vez de carregar uma a uma. É o `sharing` da última linha que o
`java -version` imprimiu na lição 1.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 282\" role=\"img\" aria-label=\"Dentro do processo de java Wait, número 3343, usando 44.080 kilobytes. De um lado as suas 18 threads: main, dormindo em Thread.sleep, e threads da própria JVM, entre elas o coletor de lixo, os compiladores JIT e a que respondeu ao jcmd. Do outro lado as classes na memória: Wait, carregada do diretório pessoal, e centenas de classes da biblioteca, a maioria mapeada do arquivo compartilhado.\"><rect x=\"16\" y=\"16\" width=\"688\" height=\"250\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">process 3343: java Wait</text><text x=\"360\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">44.080 KB de memória, pela conta do ps</text><rect x=\"36\" y=\"72\" width=\"310\" height=\"178\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"191\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">18 threads</text><rect x=\"56\" y=\"108\" width=\"270\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"191\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">main: dormindo em Thread.sleep</text><rect x=\"56\" y=\"144\" width=\"270\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"191\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">coletor de lixo (lição 19)</text><rect x=\"56\" y=\"178\" width=\"270\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"191\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">compiladores JIT (lição 1)</text><rect x=\"56\" y=\"212\" width=\"270\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"191\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a que respondeu ao jcmd</text><rect x=\"374\" y=\"72\" width=\"310\" height=\"178\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"529\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">classes na memória</text><rect x=\"394\" y=\"108\" width=\"270\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"529\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Wait, de ~/proc: sua</text><rect x=\"394\" y=\"144\" width=\"270\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"529\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a biblioteca, centenas de classes,</text><text x=\"529\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a maioria mapeada do arquivo compartilhado</text><text x=\"529\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">strings, o console, o carregador</text></svg>", "caption": "Uma linha sua e um processo cheio de coisas que você não escreveu. A thread que importa para você é a main; todo o resto é a JVM.", "same": ["18 threads"]}
```

Quando o `Wait` chega ao fim do seu minuto, o `main` retorna, a JVM para as próprias threads e o
processo termina com status 0. Nada dele sobra, a não ser o que ele escreveu em `wait.log`.
