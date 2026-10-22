---
title: Which value wins
version: 1
---

So far every port the bookshop started on came from inside the jar: Boot's default, then the dev
profile's file. Settings can also come from outside it, and when two places set the same
property, **Boot does not merge them and does not complain: it takes the value from the stronger
place and ignores the rest**. The order is fixed, and the idea behind it is simple: the closer a
value is to the moment and the machine the application starts on, the stronger it is.

Start the dev profile with a port in the environment as well:

```
ana@vm:~/bookshop$ SPRING_PROFILES_ACTIVE=dev SERVER_PORT=9090 java -jar target/bookshop-0.1.0.jar > /tmp/bookshop.log 2>&1
```

```
ana@vm:~/bookshop$ grep -E 'profile|Tomcat started' /tmp/bookshop.log
2026-10-22T19:11:22.567-03:00  INFO 6947 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : The following 1 profile is active: "dev"
2026-10-22T19:11:24.508-03:00  INFO 6947 --- [bookshop] [           main] o.s.boot.tomcat.TomcatWebServer          : Tomcat started on port 9090 (http) with context path '/'
```

The profile is active and its file says 8081, and Tomcat is on **9090**: the environment variable
outranks every file inside the jar. Now add a command-line argument on top:

```
ana@vm:~/bookshop$ SPRING_PROFILES_ACTIVE=dev SERVER_PORT=9090 java -jar target/bookshop-0.1.0.jar --server.port=9091 > /tmp/bookshop.log 2>&1
```

```
ana@vm:~/bookshop$ grep -E 'profile|Tomcat started' /tmp/bookshop.log
2026-10-22T19:11:27.112-03:00  INFO 7070 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : The following 1 profile is active: "dev"
2026-10-22T19:11:29.112-03:00  INFO 7070 --- [bookshop] [           main] o.s.boot.tomcat.TomcatWebServer          : Tomcat started on port 9091 (http) with context path '/'
```

**9091**: the argument outranks the environment. Stop it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 780 286\" role=\"img\" aria-label=\"Five places a setting can come from, strongest first: a command-line argument gives 9091, an environment variable 9090, the dev profile's file 8081; application.properties sets no port; Boot's default is 8080. A stronger place hides every weaker one.\"><text x=\"36\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">where server.port is set, from strongest to weakest</text><text x=\"560\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">alone, it gives</text><rect x=\"20\" y=\"32\" width=\"500\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"45\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a command-line argument</text><text x=\"36\" y=\"61\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">--server.port=9091</text><rect x=\"540\" y=\"32\" width=\"140\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">9091</text><rect x=\"34\" y=\"82\" width=\"486\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"50\" y=\"95\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">an environment variable</text><text x=\"50\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">SERVER_PORT=9090</text><rect x=\"540\" y=\"82\" width=\"140\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">9090</text><rect x=\"48\" y=\"132\" width=\"472\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"64\" y=\"145\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the active profile's file</text><text x=\"64\" y=\"161\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">application-dev.properties</text><rect x=\"540\" y=\"132\" width=\"140\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">8081</text><rect x=\"62\" y=\"182\" width=\"458\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"78\" y=\"195\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the main properties file</text><text x=\"78\" y=\"211\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">application.properties</text><rect x=\"540\" y=\"182\" width=\"140\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sets no port</text><rect x=\"76\" y=\"232\" width=\"444\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"92\" y=\"245\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Boot's own default</text><text x=\"92\" y=\"261\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\"></text><rect x=\"540\" y=\"232\" width=\"140\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">8080</text><path d=\"M 700 40 L 700 264\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></path><text x=\"712\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">wins</text><text x=\"712\" y=\"264\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">loses</text></svg>", "caption": "The ports the bookshop started on in this lesson, each place on its own. When several set the same property, the highest one wins."}
```

The full list in Spring Boot's documentation has more rungs than this, test properties and files
outside the jar among them, and these four plus the default are the ones a deployment meets
every day. One file outside the jar is worth knowing now: an `application.properties` in the
directory the application is started from is read too, and wins over the copy inside the jar.

Two details make the order work in practice. The same property is reachable under different
spellings, `server.port` in a file, `SERVER_PORT` in the environment, `--server.port` on the
command line, because Boot binds names loosely: case, dots, dashes and underscores are matched
by a rule rather than character by character. That is called **relaxed binding**, and it is
also what turns `SPRING_PROFILES_ACTIVE` into `spring.profiles.active`.

And the order is the reason the jar never needs a secret inside it. A password belongs in the
environment of the machine that runs the jar, where it outranks anything the jar carries, and
lesson 23 hands the bookshop its database password and its token-signing key exactly that way.
