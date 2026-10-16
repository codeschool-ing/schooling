---
title: When the application is wired
version: 1
---

The obvious way to compare web frameworks is by what a route looks like: an annotation in one, a
lambda in another. That is the smallest difference between them. **The difference that decides
most of the rest is when the application is wired**: when something works out which objects
exist, which object each constructor receives, and which URL reaches which method.

Spring Boot does that work **every time the application starts**. Lesson 4 read the conditions
report, where autoconfiguration tested its conditions one by one, and lesson 5 watched the container
build the bookshop's beans; both happen inside `java -jar`, after the JVM is already running. The
container scans `com.example.bookshop` for classes carrying `@Component` and its relatives, reads
their constructors by reflection, checks every autoconfiguration's conditions against the classpath
and the properties, wraps in a proxy the beans that need one, and only then opens port 8080. None of
it is kept between runs, so the next start does all of it again.

That design is a trade, and for the services it was made for it is a good one. A service that starts
once and then runs for weeks pays a few seconds at the start and never notices. In exchange,
everything can be decided late: a library added to the pom configures itself, a property changes a
bean without a rebuild, and security, data access and metrics all plug into one container. Most of
this course is that ecosystem, from lesson 9 to lesson 22.

The cost shows where instances are short-lived or numerous. A function started for each burst of
requests, a service that scales from zero copies when traffic arrives, a few hundred small services
sharing machines where each one's memory is paid for: there, the seconds spent at startup and the
memory the container's metadata holds turn into waiting users and a bill. The four frameworks of this
lesson are four answers to that cost, and the one axis that separates them is where the wiring
happens.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" aria-label=\"Five frameworks on a time line running from writing the code, through compiling and building, to starting the application. Javalin is wired by hand in main, while the code is written. Micronaut is wired at compile time by annotation processors. Quarkus is wired during the build, where its extensions record the result. Spring Boot and Play are wired every time they start, Spring by scanning and reflection, Play by Guice.\"><defs><marker id=\"wh-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"150\" y1=\"24\" x2=\"686\" y2=\"24\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#wh-ah)\"></line><text x=\"212.5\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">you write it</text><rect x=\"150\" y=\"54\" width=\"125\" height=\"236\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"347.5\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">javac compiles</text><rect x=\"285\" y=\"54\" width=\"125\" height=\"236\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"482.5\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the build packages</text><rect x=\"420\" y=\"54\" width=\"125\" height=\"236\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"617.5\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">java -jar starts</text><rect x=\"555\" y=\"54\" width=\"125\" height=\"236\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"140\" y=\"78\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Javalin</text><line x1=\"150\" y1=\"78\" x2=\"680\" y2=\"78\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><rect x=\"156\" y=\"61\" width=\"113\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"212.5\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">by hand,</text><text x=\"212.5\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">in main</text><text x=\"140\" y=\"124\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Micronaut</text><line x1=\"150\" y1=\"124\" x2=\"680\" y2=\"124\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><rect x=\"291\" y=\"107\" width=\"113\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"347.5\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">annotation</text><text x=\"347.5\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">processors</text><text x=\"140\" y=\"170\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Quarkus</text><line x1=\"150\" y1=\"170\" x2=\"680\" y2=\"170\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><rect x=\"426\" y=\"153\" width=\"113\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"482.5\" y=\"163\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">extensions</text><text x=\"482.5\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">record it</text><text x=\"140\" y=\"216\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Spring Boot</text><line x1=\"150\" y1=\"216\" x2=\"680\" y2=\"216\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><rect x=\"561\" y=\"199\" width=\"113\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"617.5\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">scanning and</text><text x=\"617.5\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">reflection</text><text x=\"140\" y=\"262\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Play</text><line x1=\"150\" y1=\"262\" x2=\"680\" y2=\"262\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><rect x=\"561\" y=\"245\" width=\"113\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"617.5\" y=\"255\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Guice, by</text><text x=\"617.5\" y=\"269\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">reflection</text></svg>", "caption": "Where each framework works out which objects exist and how they connect. The further left that happens, the less is left to do on every start."}
```

Read it from the right. **Spring Boot** and **Play** wire the application when it starts, by
reflection. **Quarkus** moves that work into the build, **Micronaut** moves it into the compiler, and
**Javalin** has no container at all: you call `new` yourself, in `main`. Moving left has a price of
its own, which is that more of the application is fixed before it runs. Quarkus, for instance,
divides its configuration into properties read at start and properties fixed at build time, and
changing one of the second kind means building again.

Spring has been moving left as well. Since Spring Boot 3, an optional **ahead-of-time** (AOT) step in
the build can do part of the container's analysis in advance, mainly so the application can become a
native image (the next section says what that is). It is a step a project opts into, with
restrictions on how beans may be declared; a Spring Boot application built the way this course
builds the bookshop still wires itself at start.
