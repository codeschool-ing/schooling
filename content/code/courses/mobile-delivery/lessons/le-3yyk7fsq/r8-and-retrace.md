---
title: R8, and retrace
version: 1
---

**R8 is what every Android release build goes through, and it runs on any Java bytecode, not only an
Android app's.** That makes it possible to watch it work on your computer without the Android build
system: a small program compiled by the JDK, shrunk by R8, run until it crashes, and its trace read
back with **retrace**, the tool that ships inside R8 for that purpose. The program is Java because the
JDK of lesson 1 compiles it with nothing else installed; R8 sees bytecode, and Kotlin compiles to the
same bytecode, so it treats a Kotlin class the same way.

R8 is published on Google's Maven repository as one jar. Download it once:

```sh
curl -fL -o ~/android/r8.jar https://dl.google.com/dl/android/maven2/com/android/tools/r8/8.13.25/r8-8.13.25.jar
```

## The program

Make a folder `~/planner/jvm/src/planner` and save this as `Week.java` in it:

```java
// Week.java: the same bug as week.ts, in the language R8 reads
package planner;

import java.util.List;
import java.util.Map;

public class Week {
    record Session(String course, int minutes) {}

    static int totalFor(Map<String, List<Session>> byCourse, String course) {
        int total = 0;
        for (Session s : byCourse.get(course)) {
            total += s.minutes();
        }
        return total;
    }

    public static void main(String[] args) {
        Map<String, List<Session>> byCourse = Map.of("spanish", List.of(new Session("spanish", 30), new Session("spanish", 45)));
        System.out.println("spanish " + totalFor(byCourse, "spanish"));
        System.out.println("guitar " + totalFor(byCourse, "guitar"));
    }
}
```

R8 needs to be told what must survive under its own name. In an app, Gradle supplies most of that
from the Android plugin; here it is two lines. Save this in `~/planner/jvm` as `rules.pro`:

```
-keep class planner.Week { public static void main(java.lang.String[]); }
-keepattributes SourceFile,LineNumberTable
```

The first keeps the entry point; everything else may be renamed, inlined or removed. The second
keeps line numbers, without which no retrace could say which line, and is the setting every Android
release should have.

## Compile, shrink, crash

```
ana@dev:~/planner/jvm$ javac -d classes src/planner/Week.java && jar --create --file week.jar -C classes .
ana@dev:~/planner/jvm$ java -cp ~/android/r8.jar com.android.tools.r8.R8 --release --classfile --lib /usr/lib/jvm/java-21-openjdk-amd64 --pg-conf rules.pro --pg-map-output mapping.txt --output shrunk.jar week.jar
ana@dev:~/planner/jvm$ ls -l week.jar shrunk.jar; unzip -Z1 shrunk.jar
-rw-r--r-- 1 ana ana 2105 Oct 30 15:55 shrunk.jar
-rw-r--r-- 1 ana ana 2232 Oct 30 15:55 week.jar
META-INF/MANIFEST.MF
planner/Week.class
planner/a.class
ana@dev:~/planner/jvm$ java -cp shrunk.jar planner.Week 2> trace.txt; cat trace.txt
spanish 75
Exception in thread "main" java.lang.NullPointerException: Cannot invoke "java.util.List.iterator()" because the return value of "java.util.Map.get(Object)" is null
	at planner.Week.main(r8-map-id-6bbc4a2bb4d026e05f8d405853da754fac38238bac9da0705077d66fa4cc4b9e:7)
```

**The shrunk jar has a class called `a`**, which was `Week$Session`. And the trace from it is shorter
than the original: **one frame instead of two**, in `main`, at a line 7 that does not exist in
`Week.java`, in a file named after the mapping's identifier. R8 inlined `totalFor` into `main`, so the
method where the bug is has vanished from the trace.

## Reading it back

```
ana@dev:~/planner/jvm$ java -cp ~/android/r8.jar com.android.tools.r8.retrace.Retrace mapping.txt trace.txt
Exception in thread "main" java.lang.NullPointerException: Cannot invoke "java.util.List.iterator()" because the return value of "java.util.Map.get(Object)" is null
	at planner.Week.totalFor(Week.java:12)
	at planner.Week.main(Week.java:21)
ana@dev:~/planner/jvm$ java -cp week.jar planner.Week 2>&1 | tail -n 3
Exception in thread "main" java.lang.NullPointerException: Cannot invoke "java.util.List.iterator()" because the return value of "java.util.Map.get(Object)" is null
	at planner.Week.totalFor(Week.java:12)
	at planner.Week.main(Week.java:21)
```

**Retrace restored the frame that inlining removed**, `totalFor` at line 12, the `for` over a list
that is `null`, called from line 21. The last command runs the jar that was never shrunk, and its
trace is the same two frames: retrace gave back exactly what R8 took away. The mapping file says how: each range of the shrunk method's
lines maps back to the lines of the methods that were folded into it. That is the file the release
must keep and upload, lesson 12; with the wrong build's mapping, the same command would print
confident nonsense.
