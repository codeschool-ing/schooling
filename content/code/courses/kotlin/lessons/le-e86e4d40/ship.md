---
title: Building something to hand over
version: 1
---

`./gradlew run` needs Gradle and the source. A user has neither. **The `application` plugin can lay out
the program as a directory a user runs**: the program's jars, every library it needs, and a start script
that finds Java and puts them all on the classpath.

```
ana@vm:~/kt/studyplan$ ./gradlew -q :app:installDist
ana@vm:~/kt/studyplan$ ls app/build/install/app/bin app/build/install/app/lib
app/build/install/app/bin:
app
app.bat

app/build/install/app/lib:
annotations-13.0.jar
app.jar
core.jar
kotlin-stdlib-2.4.21.jar
ana@vm:~/kt/studyplan$ app/build/install/app/bin/app
2 sessions, 75 of 300 min (25%)
```

`installDist` built both modules and copied the result into `app/build/install/app`. `lib` holds four
jars, the two modules and the two libraries the dependency report would name; `bin/app` is a shell
script, `bin/app.bat` its Windows twin. The program ran with no Gradle involved.

`distZip` and `distTar` package the same directory as one archive, which is what a release attaches.
The person who unpacks it needs a Java runtime of version 21 or newer, the number section 04 put in the
bytecode, and nothing else.

`./gradlew build` is the task CI runs: it compiles every module, runs every test, and assembles the
archives, and it fails if any step does. Lesson 18's tests are part of the build from here on, not an
extra step someone has to remember.
