---
title: Starters, and a parent that holds the versions
version: 1
---

Spring Boot is not something you install. There is no `spring` command in this course and no
server to download: **Boot is a set of libraries named in a pom, plus a parent pom that decides
their versions**, and everything it does happens inside your own `java` process.

Most projects begin at **start.spring.io**, a form on Spring's website that asks for a name, a
Java version and a list of features, and hands back a zip with a pom, a main class and an empty
properties file. It is a fine way to start a real project. This course writes those files by
hand instead, because a generated pom is a file nobody reads, and every line of this one is
about to matter.

The project lives in `~/bookshop`, and lessons 4 to 23 build it up. Make its directories:

```sh
mkdir -p ~/bookshop/src/main/java/com/example/bookshop ~/bookshop/src/main/resources
cd ~/bookshop
```

Then `pom.xml`, at the top of the project:

```schooling-example
{
  "language": "xml",
  "file": "pom.xml",
  "parts": [
    {
      "code": "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<project xmlns=\"http://maven.apache.org/POM/4.0.0\"\n         xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n         xsi:schemaLocation=\"http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd\">\n  <modelVersion>4.0.0</modelVersion>\n",
      "note": "**The same opening as lesson 1's pom.** Nothing in the first lines is Spring's."
    },
    {
      "code": "  <parent>\n    <groupId>org.springframework.boot</groupId>\n    <artifactId>spring-boot-starter-parent</artifactId>\n    <version>4.1.1</version>\n    <relativePath/>\n  </parent>\n",
      "note": "**The parent.** This pom inherits from `spring-boot-starter-parent` 4.1.1, which is how one number here chooses the version of every library below. `<relativePath/>` tells Maven not to look for the parent in a directory above this one, and to fetch it from the repository instead."
    },
    {
      "code": "  <groupId>com.example</groupId>\n  <artifactId>bookshop</artifactId>\n  <version>0.1.0</version>\n",
      "note": "**The coordinates**, as in lesson 1. There is no `<packaging>`, because `jar` is the default."
    },
    {
      "code": "  <properties>\n    <java.version>25</java.version>\n  </properties>\n",
      "note": "**Only the Java version.** The parent already sets the compiler's release from `java.version`, the source encoding and more; its own default is 17, and this line raises it to the JDK this course uses."
    },
    {
      "code": "  <dependencies>\n    <dependency>\n      <groupId>org.springframework.boot</groupId>\n      <artifactId>spring-boot-starter-webmvc</artifactId>\n    </dependency>\n  </dependencies>\n",
      "note": "**One dependency, and no version.** The starter brings the web stack, and the parent supplies the version: the next paragraphs show both halves."
    },
    {
      "code": "  <build>\n    <plugins>\n      <plugin>\n        <groupId>org.springframework.boot</groupId>\n        <artifactId>spring-boot-maven-plugin</artifactId>\n      </plugin>\n    </plugins>\n  </build>\n</project>",
      "note": "**The plugin that makes the jar runnable**, also with no version and no configuration of its own. The parent binds its `repackage` goal to the `package` phase, which is the subject of the next section."
    }
  ]
}
```

## What one starter brings

A **starter** is a dependency whose whole purpose is its own dependencies. You name the feature,
web with Spring MVC here, and the starter names the libraries that feature needs. Ask Maven what
arrived; `-q` keeps Maven's own lines out, and `-DoutputFile` writes the tree to a file without
the `[INFO]` in front of every line:

```
ana@vm:~/bookshop$ mvn -q dependency:tree -DoutputFile=/tmp/tree.txt && cat /tmp/tree.txt
com.example:bookshop:jar:0.1.0
\- org.springframework.boot:spring-boot-starter-webmvc:jar:4.1.1:compile
   +- org.springframework.boot:spring-boot-starter:jar:4.1.1:compile
   |  +- org.springframework.boot:spring-boot-starter-logging:jar:4.1.1:compile
   |  |  +- ch.qos.logback:logback-classic:jar:1.5.38:compile
   |  |  |  +- ch.qos.logback:logback-core:jar:1.5.38:compile
   |  |  |  \- org.slf4j:slf4j-api:jar:2.0.18:compile
   |  |  +- org.apache.logging.log4j:log4j-to-slf4j:jar:2.25.5:compile
   |  |  |  \- org.apache.logging.log4j:log4j-api:jar:2.25.5:compile
   |  |  \- org.slf4j:jul-to-slf4j:jar:2.0.18:compile
   |  +- org.springframework.boot:spring-boot-autoconfigure:jar:4.1.1:compile
   |  +- jakarta.annotation:jakarta.annotation-api:jar:3.0.0:compile
   |  \- org.yaml:snakeyaml:jar:2.6:compile
   +- org.springframework.boot:spring-boot-starter-jackson:jar:4.1.1:compile
   |  \- org.springframework.boot:spring-boot-jackson:jar:4.1.1:compile
   |     \- tools.jackson.core:jackson-databind:jar:3.1.5:compile
   |        +- com.fasterxml.jackson.core:jackson-annotations:jar:2.21:compile
   |        \- tools.jackson.core:jackson-core:jar:3.1.5:compile
   +- org.springframework.boot:spring-boot-starter-tomcat:jar:4.1.1:compile
   |  +- org.springframework.boot:spring-boot-starter-tomcat-runtime:jar:4.1.1:compile
   |  |  +- org.springframework.boot:spring-boot-web-server:jar:4.1.1:compile
   |  |  +- org.apache.tomcat.embed:tomcat-embed-core:jar:11.0.24:compile
   |  |  +- org.apache.tomcat.embed:tomcat-embed-el:jar:11.0.24:compile
   |  |  \- org.apache.tomcat.embed:tomcat-embed-websocket:jar:11.0.24:compile
   |  \- org.springframework.boot:spring-boot-tomcat:jar:4.1.1:compile
   +- org.springframework.boot:spring-boot-http-converter:jar:4.1.1:compile
   |  +- org.springframework.boot:spring-boot:jar:4.1.1:compile
   |  |  +- org.springframework:spring-core:jar:7.0.9:compile
   |  |  |  +- commons-logging:commons-logging:jar:1.3.6:compile
   |  |  |  \- org.jspecify:jspecify:jar:1.0.1:compile
   |  |  \- org.springframework:spring-context:jar:7.0.9:compile
   |  \- org.springframework:spring-web:jar:7.0.9:compile
   |     +- org.springframework:spring-beans:jar:7.0.9:compile
   |     \- io.micrometer:micrometer-observation:jar:1.17.1:compile
   |        \- io.micrometer:micrometer-commons:jar:1.17.1:compile
   \- org.springframework.boot:spring-boot-webmvc:jar:4.1.1:compile
      +- org.springframework.boot:spring-boot-servlet:jar:4.1.1:compile
      \- org.springframework:spring-webmvc:jar:7.0.9:compile
         +- org.springframework:spring-aop:jar:7.0.9:compile
         \- org.springframework:spring-expression:jar:7.0.9:compile
ana@vm:~/bookshop$ grep -c ':compile' /tmp/tree.txt
39
```

One line in the pom, and every line of that tree is on the classpath. Read it from the top:
`spring-boot-starter` is the core every starter shares, and it brings logging (Logback behind
SLF4J, which lesson 16 takes apart) and `spring-boot-autoconfigure`, the subject of the
section after next. Then Jackson 3, which turns objects into JSON, Tomcat 11, embedded,
so the server is a library inside the application rather than something the application is
deployed into, and Spring MVC, which hands each request to your code.

The starter itself contributes no code at all:

```
ana@vm:~/bookshop$ unzip -l ~/.m2/repository/org/springframework/boot/spring-boot-starter-webmvc/4.1.1/spring-boot-starter-webmvc-4.1.1.jar
Archive:  /home/ana/.m2/repository/org/springframework/boot/spring-boot-starter-webmvc/4.1.1/spring-boot-starter-webmvc-4.1.1.jar
  Length      Date    Time    Name
---------  ---------- -----   ----
        0  1980-02-01 00:00   META-INF/
      252  1980-02-01 00:00   META-INF/MANIFEST.MF
    11359  1980-02-01 00:00   META-INF/LICENSE.txt
      210  1980-02-01 00:00   META-INF/NOTICE.txt
---------                     -------
    11821                     4 files
```

A manifest, a licence and a notice. The jar exists because Maven needs an artifact to resolve,
and the value is entirely in the list of dependencies its pom declares.

## Why the pom names no version

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" aria-label=\"The pom names a parent with a version and a starter without one. The parent supplies a list of library versions; the starter supplies the libraries; each library arrives at the version the list gives it.\"><defs><marker id=\"l4f1-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"250\" height=\"170\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"145\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">your pom.xml</text><text x=\"36\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">&lt;parent&gt;</text><text x=\"36\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">spring-boot-starter-parent</text><text x=\"36\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">4.1.1</text><text x=\"36\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">&lt;dependency&gt;</text><text x=\"36\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">spring-boot-starter-webmvc</text><text x=\"36\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no version written</text><rect x=\"380\" y=\"20\" width=\"300\" height=\"112\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"530\" y=\"10\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">which version: the parent</text><text x=\"396\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">spring-framework.version</text><text x=\"664\" y=\"44\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">7.0.9</text><text x=\"396\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">tomcat.version</text><text x=\"664\" y=\"64\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">11.0.24</text><text x=\"396\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">jackson-bom.version</text><text x=\"664\" y=\"84\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">3.1.5</text><text x=\"396\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">logback.version</text><text x=\"664\" y=\"104\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">1.5.38</text><text x=\"530\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">… 195 of these in all</text><rect x=\"380\" y=\"168\" width=\"300\" height=\"112\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"530\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">what: the starter</text><text x=\"396\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">spring-webmvc</text><text x=\"664\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">7.0.9</text><text x=\"396\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">tomcat-embed-core</text><text x=\"664\" y=\"210\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">11.0.24</text><text x=\"396\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">jackson-databind</text><text x=\"664\" y=\"230\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">3.1.5</text><text x=\"396\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">logback-classic</text><text x=\"664\" y=\"250\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">1.5.38</text><text x=\"530\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">… 39 in the tree</text><path d=\"M 270 95 C 320 95, 330 76, 378 76\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l4f1-ah)\"></path><path d=\"M 270 168 C 320 168, 330 224, 378 224\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l4f1-ah)\"></path><path d=\"M 690 110 C 712 140, 712 170, 690 200\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l4f1-ah)\"></path><text x=\"326\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">which version</text><text x=\"326\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what</text></svg>", "caption": "Two lines of the pom, two different jobs: the starter decides what arrives, the parent decides at which version."}
```

The other half is the `<parent>`. `spring-boot-starter-parent` inherits from
`spring-boot-dependencies`, whose `<dependencyManagement>` names a version for every library
Boot knows how to configure, as a property. A dependency that appears there can be declared
without a version, here or in any starter's pom, and gets the one the list says:

```
ana@vm:~/bookshop$ grep -c '\.version>' ~/.m2/repository/org/springframework/boot/spring-boot-dependencies/4.1.1/spring-boot-dependencies-4.1.1.pom
195
ana@vm:~/bookshop$ mvn -q help:evaluate -Dexpression=tomcat.version -DforceStdout; echo
11.0.24
ana@vm:~/bookshop$ mvn -q help:evaluate -Dexpression=jackson-bom.version -DforceStdout; echo
3.1.5
```

195 version properties, for the libraries and for the Maven plugins too, which is why this pom
pins none of the plugins lesson 1 had to. Each was chosen by the Spring team and **tested
together** with the others before Boot 4.1.1 shipped, and that is the real argument for the parent. Without it, choosing a Jackson that works with this
Spring Framework, and a Tomcat that works with both, is a job you do on every upgrade, and get
wrong once.

Two consequences are worth knowing now. **Upgrading Spring Boot is one number**: change `4.1.1` in
the parent and every managed library moves to the versions tested with the new release. And
when one library needs a fix before Boot ships it, a Tomcat security release for example, you
override **the property**, `<tomcat.version>` in your own `<properties>`, so that every Tomcat
jar moves together. Writing a `<version>` on a single dependency instead moves that jar and leaves
its siblings behind. Both are exceptions; the bookshop overrides nothing.
