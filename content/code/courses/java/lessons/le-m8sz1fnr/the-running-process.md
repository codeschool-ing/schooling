---
title: The program while it runs
version: 1
---

It is easy to picture `java Greet` as Greet running. **What runs is the JVM**, an ordinary process
of the operating system, and Greet is a few hundred bytes of bytecode inside it. The process has a
number, threads, memory and a clock of its own, and the JDK ships tools that find it and ask it
questions while it runs. Those tools are what you reach for when a Java service in production
misbehaves, and they work the same on a toy.

## A program that stays long enough to look at

`Greet` finishes in a fraction of a second. This one prints its own process id and then sleeps for
a minute, in `~/proc`:

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

`ProcessHandle.current().pid()` asks the JVM for the number the operating system gave its process.
`Thread.sleep(60_000)` pauses for 60,000 milliseconds, and the underscore is only there to make the
number readable. The `throws InterruptedException` is required by `sleep`, for reasons lesson 36
explains.

Compile it, and start it **in the background**, with `&`, so the terminal is free while it sleeps.
`> wait.log` sends what it prints into a file, where you can read it whenever you like:

```
ana@vm:~/proc$ javac Wait.java
ana@vm:~/proc$ java Wait > wait.log &
ana@vm:~/proc$ cat wait.log
pid 3343
```

The number is different on every run, and on every machine.

## Finding it, and asking it

`jps` lists the JVMs that belong to you, with their process ids, and `-l` adds the main class. You
may have others running, an editor perhaps, so `grep` keeps the line for `Wait`:

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

`jcmd` sends a command to a running JVM, which you name by process id or, as here, by main class.
The JVM answers with its own process id first and then the result. `VM.version` says which JDK this
process is running on, which on a server with several installed is the question that matters, and
`VM.uptime` says it has been alive for just under six seconds. `jcmd Wait help` lists every
command a JVM accepts.

## Threads you did not start

`Wait` has one line of code that does anything: it sleeps. Count the threads in its process anyway.
`Thread.print` dumps every thread with its name in double quotes, and `grep -c` counts those lines:

```
ana@vm:~/proc$ jcmd Wait Thread.print | grep -c "^\""
18
ana@vm:~/proc$ ps -o pid,rss,args -C java | grep -E "PID|Wait"
  PID   RSS COMMAND
 3343 44080 java Wait
```

**Eighteen threads, and the program started none.** One is `main`, asleep inside `Thread.sleep`.
The others belong to the JVM: the garbage collector, which lesson 19 watches, the JIT compilers
from lesson 1, and the thread that answered `jcmd` just now. The operating system's view, from
`ps`, agrees that this is a real process: **44,080 kilobytes of memory in use**, about 43 MB, for a
program that holds one string. Most of it is the JVM itself and the classes it loaded, which is the
next thing to count.

## Six hundred classes for one line

`-Xlog:class+load` makes the JVM log every class it loads, one line each, as it loads them. Run
`Greet` with it, back in `~/life`:

```
ana@vm:~/life$ java -Xlog:class+load -cp out Greet Ana | wc -l
605
ana@vm:~/life$ java -Xlog:class+load -cp out Greet Ana | grep -E "Greet|Hello, Ana"
[0.081s][info][class,load] Greet source: file:/home/ana/life/out/
Hello, Ana
ana@vm:~/life$ java -Xlog:class+load -cp out Greet Ana | grep -c "shared objects file"
600
```

605 lines, and one of them is `Hello, Ana`, so **the JVM loaded 604 classes to print one line**.
Only one of them is yours: `Greet`, found at 0.081 seconds in the directory the class path named.
The rest are the library: strings, the console, the class loader itself.

The last count explains how that is fast. **600 of those classes came from the "shared objects
file"**, an archive of the library's classes that the JDK prepared in advance, already parsed and
checked, which the JVM maps into memory instead of loading one by one. It is the `sharing` in the
last line `java -version` printed in lesson 1.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 282\" role=\"img\" aria-label=\"Inside the process of java Wait, number 3343, using 44,080 kilobytes. On one side its 18 threads: main, asleep in Thread.sleep, and threads of the JVM itself, among them the garbage collector, the JIT compilers and the one that answered jcmd. On the other side the classes in memory: Wait, loaded from the home directory, and hundreds of library classes, most of them mapped from the shared archive.\"><rect x=\"16\" y=\"16\" width=\"688\" height=\"250\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">process 3343: java Wait</text><text x=\"360\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">44,080 KB of memory, as ps counts it</text><rect x=\"36\" y=\"72\" width=\"310\" height=\"178\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"191\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">18 threads</text><rect x=\"56\" y=\"108\" width=\"270\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"191\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">main: asleep in Thread.sleep</text><rect x=\"56\" y=\"144\" width=\"270\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"191\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">garbage collector (lesson 19)</text><rect x=\"56\" y=\"178\" width=\"270\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"191\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">JIT compilers (lesson 1)</text><rect x=\"56\" y=\"212\" width=\"270\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"191\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the one that answered jcmd</text><rect x=\"374\" y=\"72\" width=\"310\" height=\"178\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"529\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">classes in memory</text><rect x=\"394\" y=\"108\" width=\"270\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"529\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Wait, from ~/proc: yours</text><rect x=\"394\" y=\"144\" width=\"270\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"529\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the library, hundreds of classes,</text><text x=\"529\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">most mapped from the shared archive</text><text x=\"529\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">strings, the console, the loader</text></svg>", "caption": "One line of yours and a process full of things you did not write. The thread that matters to you is main; everything else is the JVM."}
```

When `Wait` reaches the end of its minute, `main` returns, the JVM stops its own threads and the
process exits with status 0. Nothing of it is left except what it wrote to `wait.log`.
