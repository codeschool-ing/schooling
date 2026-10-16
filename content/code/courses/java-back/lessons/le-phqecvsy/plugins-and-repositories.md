---
title: Plugins, repositories, and running the result
version: 1
---

Every line of the build in the last section named a plugin **and a version**, and the versions
came from the `<build>` block of the pom. That block looks like ceremony. It is the difference
between a build that means the same thing on every machine and one that depends on which Maven
happens to be installed.

## What Maven picks when the pom does not say

Maven 3.8.7 carries its own list of plugin versions for the lifecycle, chosen when that version of
Maven was made, and uses it for any plugin the pom does not pin. To see that list at work, put the
pom aside, delete its `<build>` element, build, and put the pom back:

@@CAPTURE defaults@@

@@DEFAULTS-PROSE@@

## The one plugin the pom forgot

The `dependency:tree` run in the section on dependencies printed `maven-dependency-plugin:2.8`. The
dependency plugin is not bound to any phase, so the pom above never named it, and Maven used the
version from the same built-in list: 2.8, where the plugin's current version on Central is
3.11.0. It worked this time. The next goal you ask of it may be one 2.8 does not have, or does
differently, and the build would still say nothing about which version answered. Pin it like the
others. **Replace the `<build>`
element of `pom.xml` with this one**, which adds one `<plugin>` at the end:

```xml
  <build>
    <pluginManagement>
      <plugins>
        <plugin>
          <artifactId>maven-clean-plugin</artifactId>
          <version>3.5.0</version>
        </plugin>
        <plugin>
          <artifactId>maven-resources-plugin</artifactId>
          <version>3.5.0</version>
        </plugin>
        <plugin>
          <artifactId>maven-compiler-plugin</artifactId>
          <version>3.15.0</version>
        </plugin>
        <plugin>
          <artifactId>maven-surefire-plugin</artifactId>
          <version>3.5.6</version>
        </plugin>
        <plugin>
          <artifactId>maven-jar-plugin</artifactId>
          <version>3.5.1</version>
        </plugin>
        <plugin>
          <artifactId>maven-install-plugin</artifactId>
          <version>3.1.4</version>
        </plugin>
        <plugin>
          <artifactId>maven-deploy-plugin</artifactId>
          <version>3.1.4</version>
        </plugin>
        <plugin>
          <artifactId>maven-dependency-plugin</artifactId>
          <version>3.11.0</version>
        </plugin>
      </plugins>
    </pluginManagement>
  </build>
```

@@CAPTURE pin@@

`pluginManagement` **pins a version without running anything**: it says "if this plugin is used,
use this version", whether the lifecycle calls it or you name one of its goals. The other
element, a `<plugins>` list directly under `<build>`, is for adding a goal to a phase or
configuring one, and lesson 17 uses it.

## Repositories

A **repository** is a directory tree of jars and poms laid out by coordinates, served over HTTP.
**Maven Central** is the public one every Maven knows without being told, at
`repo.maven.apache.org`. Your **local repository** in `~/.m2/repository` has the same layout and is
a cache of it, plus whatever `mvn install` put there:

@@FIG-REPO@@

Maven looks in the local repository first and asks Central only for what is missing, once. That is
why the second build of a project prints no downloads and works without a network.

The transcripts in this course were recorded on a machine that reached Central through a mirror,
because Central answered its downloads with "429 Too Many Requests". A transcript that
shows a download therefore names `google-maven-central` and a Google address; on your machine the
same line says `central` and `repo.maven.apache.org`. The files are Central's in both cases, with
the same checksums. You need no mirror and no configuration for it.

## Running the program

The jar `package` produced is the project's own classes and nothing else:

@@CAPTURE jar@@

@@RUN-PROSE@@
