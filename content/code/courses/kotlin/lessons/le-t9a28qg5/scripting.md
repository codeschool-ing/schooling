---
title: Kotlin as a script
version: 1
---

Not everything needs a build. A file that adds up a week's minutes, run when needed and changed when
needed, is a script, and **a file ending in `.main.kts` is a Kotlin script the `kotlin` command runs
directly**: no `main`, no Gradle, no jar. The input is the `week.txt` lesson 14 wrote into the
planner, one session's minutes per line, copied into a new directory, `~/kt/scripts`:

```
ana@vm:~/kt/scripts$ cp ../planner/week.txt .
ana@vm:~/kt/scripts$ cat week.txt
45
30
60
```

```kotlin
#!/usr/bin/env kotlin
// total.main.kts

import java.io.File

val path = args.firstOrNull() ?: "week.txt"
val minutes = File(path).readLines()
    .filter { it.isNotBlank() }
    .map { it.trim().toInt() }
println("${minutes.size} sessions, ${minutes.sum()} min")
```

The statements run from top to bottom, and `args` holds the command-line arguments. The first line,
`#!/usr/bin/env kotlin`, lets a Linux or macOS shell run the file like any other program once it is
executable:

```
ana@vm:~/kt/scripts$ time kotlin total.main.kts
3 sessions, 135 min

real	0m6.110s
user	0m13.583s
sys	0m0.607s
ana@vm:~/kt/scripts$ chmod +x total.main.kts
ana@vm:~/kt/scripts$ time ./total.main.kts week.txt
3 sessions, 135 min

real	0m2.157s
user	0m3.564s
sys	0m0.291s
```

The first run took about six seconds, most of it compiling the script. **The compiled script is
cached**, in `~/.cache/main.kts.compiled.cache`, so the run after it took two, and an edit to the file
compiles it again.

A script can also name libraries from Maven Central with an annotation at the top,
`@file:DependsOn("group:artifact:version")`, and they are downloaded on its first run. That is what makes
a `.main.kts` file a reasonable replacement for a shell script that has grown past the point where shell
is pleasant: Kotlin's types, its standard library, and any JVM library, in one file.

Gradle's own build files are the best-known Kotlin scripts. `build.gradle.kts` is a script with
Gradle's API in scope, which is why lesson 18's could begin with an `import` like any Kotlin file.
