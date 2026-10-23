---
title: Four layers, by how often they change
version: 1
---

The next section puts the bookshop into a container image, and an image is not one file. It is a
**stack of layers**, each holding the files that one step of the build added, and a layer is only
reused from an earlier build when nothing beneath it changed.

Copy the jar into an image as one file and every commit makes a new 66 MiB layer: built, stored, pushed
to a registry and pulled by every server, although almost all of it is the same 112 libraries as last
time. What actually changes from one commit to the next is the bookshop's own classes, a few hundred
kilobytes. Spring Boot's answer is to split the jar by **how often each part changes**, so each part
can be its own layer.

## The jar already knows its layers

The manifest pointed at `BOOT-INF/layers.idx`. The plugin wrote it, and Boot's tools jar reads it.
That jar is the `spring-boot-jarmode-tools` lesson 4 noticed among the libraries, and it runs when the
`jarmode` system property is set:

```
ana@vm:~/bookshop$ java -Djarmode=tools -jar target/bookshop-0.1.0.jar list-layers
dependencies
spring-boot-loader
snapshot-dependencies
application
```

The index says what goes in each, and in what order:

```
ana@vm:~/bookshop$ unzip -p target/bookshop-0.1.0.jar BOOT-INF/layers.idx
- "dependencies":
  - "BOOT-INF/lib/"
- "spring-boot-loader":
  - "org/"
- "snapshot-dependencies":
- "application":
  - "BOOT-INF/classes/"
  - "BOOT-INF/classpath.idx"
  - "BOOT-INF/layers.idx"
  - "META-INF/"
```

- **`dependencies`** is `BOOT-INF/lib`: the libraries, which change when `pom.xml` changes one.
- **`spring-boot-loader`** is everything under `org/`: the launcher, which changes when Spring Boot
  is upgraded.
- **`snapshot-dependencies`** would hold any library whose version ends in `-SNAPSHOT`. A snapshot
  can be rebuilt under the same version number, so it is kept out of the big layer meant to stay put.
  The bookshop depends on none, and the entry is empty.
- **`application`** is the bookshop: `BOOT-INF/classes`, the two indexes, and `META-INF` with the
  manifest. It changes on every commit.

The order is the order of change, rarest first, and it matters because of the rule above: a layer
can be reused only if every layer below it was.

## Splitting it

`extract` writes the four as directories. `--layers` asks for the split, and `--launcher` keeps the
launcher's own layout, so that the four directories merged into one start with `JarLauncher`, as the
jar did:

```
ana@vm:~/bookshop$ java -Djarmode=tools -jar target/bookshop-0.1.0.jar extract --layers --launcher --destination /tmp/extracted
ana@vm:~/bookshop$ du -sh /tmp/extracted/*
308K	/tmp/extracted/application
66M	/tmp/extracted/dependencies
4.0K	/tmp/extracted/snapshot-dependencies
676K	/tmp/extracted/spring-boot-loader
```

Printing nothing is how `extract` says it worked. The sizes say why the split is worth making:
**66 MiB that changes when a library does, against 308 KiB that changes with every commit**. The
`4.0K` is the empty `snapshot-dependencies` directory itself.

```
ana@vm:~/bookshop$ ls /tmp/extracted/application /tmp/extracted/spring-boot-loader/org/springframework/boot/loader
/tmp/extracted/application:
BOOT-INF
META-INF

/tmp/extracted/spring-boot-loader/org/springframework/boot/loader:
jar
jarmode
launch
log
net
nio
ref
zip
```

`application` keeps the jar's paths, `BOOT-INF` and `META-INF`, and `spring-boot-loader` holds the
launcher's packages. Laid on top of each other they rebuild the jar's tree as plain directories, and
that is exactly what the Dockerfile in the next section does, inside the build, so nothing needs to be
extracted on your machine. Remove the directory when you have looked:

```sh
rm -rf /tmp/extracted
```
