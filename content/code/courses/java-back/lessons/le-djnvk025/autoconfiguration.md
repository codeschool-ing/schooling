---
title: Autoconfiguration, and the report that explains it
version: 1
---

Nothing in the bookshop created a Tomcat, a JSON mapper or a `DispatcherServlet`, and all three
exist. The common picture is that Boot "just knows", which leaves you stuck the first time it
guesses wrong. The real mechanism is duller and much more useful: **a list of ordinary
configuration classes, each guarded by conditions, and a report that says which conditions held**.

## Where the list comes from

Boot 4 splits its autoconfiguration into modules, one per technology, and each module's jar
carries a file naming the configuration classes it offers. This is the one inside the Spring MVC
module the starter brought:

```
ana@vm:~/bookshop$ unzip -p ~/.m2/repository/org/springframework/boot/spring-boot-webmvc/4.1.1/spring-boot-webmvc-4.1.1.jar META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports
org.springframework.boot.webmvc.autoconfigure.DispatcherServletAutoConfiguration
org.springframework.boot.webmvc.autoconfigure.WebMvcAutoConfiguration
org.springframework.boot.webmvc.autoconfigure.WebMvcObservationAutoConfiguration
org.springframework.boot.webmvc.autoconfigure.actuate.endpoint.web.WebMvcHealthEndpointExtensionAutoConfiguration
org.springframework.boot.webmvc.autoconfigure.actuate.web.mappings.WebMvcMappingsAutoConfiguration
org.springframework.boot.webmvc.autoconfigure.error.ErrorMvcAutoConfiguration
```

At start-up, `@EnableAutoConfiguration` reads that file **in every jar on the classpath** and
treats each line as a candidate. A candidate is a class like any other configuration class: it
declares beans, Tomcat's factory or Jackson's mapper, exactly as you will in lesson 5. Only jars
that are present can list anything, so the classpath is the first filter. A module the bookshop
does not have, `spring-boot-jdbc` for example, is not refused: its candidates are never read.
The opposite happens too. Three of the six lines above belong with Actuator and its metrics,
which arrive in lesson 22: the module offers them, and their conditions refuse them for now.

The missing module is what catches readers of older material. A guide written for Spring Boot 3 shows
`DataSourceAutoConfiguration` as a negative match in every application without a database. On
Boot 4 it lives in `spring-boot-jdbc`, so the bookshop's report does not mention it at all until
lesson 9 adds a JDBC starter.

## Conditions

Every candidate carries annotations that decide whether it applies. Three kinds do most of the
work, and the bookshop's start-up evaluates all three:

- `@ConditionalOnClass`: apply only if some class is on the classpath. This is how a jar's
  presence becomes a feature, and why adding a dependency is often all the configuration a
  feature needs.
- `@ConditionalOnBooleanProperty` and `@ConditionalOnProperty`: apply only if a property
  has a given value, so a feature can be switched on in `application.properties`.
- `@ConditionalOnMissingBean`: apply only if you have not defined a bean of that type
  yourself. This is the one that makes Boot a set of defaults rather than a set of decisions:
  **declare your own and Boot's backs off**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 352\" role=\"img\" aria-label=\"Every jar on the classpath lists candidate configurations. Each candidate carries conditions: a class must be present, a bean must be missing, a property must be set. Tomcat's configuration and its factory bean are applied; the Gson converters and problem details are skipped.\"><defs><marker id=\"l4f2-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"680\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">every jar on the classpath may list candidates in</text><text x=\"684\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">META-INF/spring/…AutoConfiguration.imports</text><text x=\"36\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">candidate</text><text x=\"300\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">its condition asks</text><text x=\"560\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">outcome</text><rect x=\"20\" y=\"100\" width=\"260\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">TomcatServletWebServer…</text><rect x=\"290\" y=\"100\" width=\"250\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"300\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">is this class on the classpath?</text><text x=\"300\" y=\"131\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">org.apache.catalina.startup.Tomcat</text><rect x=\"560\" y=\"100\" width=\"140\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"630\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">applied</text><path d=\"M 280 122 L 288 122\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l4f2-ah)\"></path><path d=\"M 540 122 L 558 122\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l4f2-ah)\"></path><rect x=\"20\" y=\"156\" width=\"260\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">…#tomcatServletWebServerFactory</text><rect x=\"290\" y=\"156\" width=\"250\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"300\" y=\"171\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">has nobody defined a bean of this type?</text><text x=\"300\" y=\"187\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ServletWebServerFactory</text><rect x=\"560\" y=\"156\" width=\"140\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"630\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">applied</text><path d=\"M 280 178 L 288 178\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l4f2-ah)\"></path><path d=\"M 540 178 L 558 178\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l4f2-ah)\"></path><rect x=\"20\" y=\"212\" width=\"260\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"234\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">GsonHttpMessageConverters…</text><rect x=\"290\" y=\"212\" width=\"250\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"300\" y=\"227\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">is this class on the classpath?</text><text x=\"300\" y=\"243\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">com.google.gson.Gson</text><rect x=\"560\" y=\"212\" width=\"140\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"630\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">skipped</text><path d=\"M 280 234 L 288 234\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l4f2-ah)\"></path><path d=\"M 540 234 L 558 234\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l4f2-ah)\"></path><rect x=\"20\" y=\"268\" width=\"260\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"290\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">…ProblemDetailsErrorHandling…</text><rect x=\"290\" y=\"268\" width=\"250\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"300\" y=\"283\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">is this property set to true?</text><text x=\"300\" y=\"299\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">spring.mvc.problemdetails.enabled</text><rect x=\"560\" y=\"268\" width=\"140\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"630\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">skipped</text><path d=\"M 280 290 L 288 290\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l4f2-ah)\"></path><path d=\"M 540 290 L 558 290\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l4f2-ah)\"></path><text x=\"360\" y=\"336\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">applied: a positive match in the report · skipped: a negative match, with the reason</text></svg>", "caption": "Autoconfiguration is a list of candidates, each with conditions. The report prints the answer to every one."}
```

## The conditions evaluation report

Boot prints every decision when it starts with `--debug`. The report is long, so this time the
second terminal sends the log to a file instead of the screen:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --debug > /tmp/bookshop.log 2>&1
```

And the first terminal searches it, for one candidate that applied and two that did not:

```
ana@vm:~/bookshop$ grep -A2 -E '^   (TomcatServletWebServerAutoConfiguration#tomcatServletWebServerFactory|GsonHttpMessageConvertersConfiguration|WebMvcAutoConfiguration.ProblemDetailsErrorHandlingConfiguration)( matched)?:' /tmp/bookshop.log
   TomcatServletWebServerAutoConfiguration#tomcatServletWebServerFactory matched:
      - @ConditionalOnMissingBean (types: org.springframework.boot.web.server.servlet.ServletWebServerFactory; SearchStrategy: current) did not find any beans (OnBeanCondition)

--
   GsonHttpMessageConvertersConfiguration:
      Did not match:
         - @ConditionalOnClass did not find required class 'com.google.gson.Gson' (OnClassCondition)
--
   WebMvcAutoConfiguration.ProblemDetailsErrorHandlingConfiguration:
      Did not match:
         - @ConditionalOnBooleanProperty (spring.mvc.problemdetails.enabled=true) did not find property 'spring.mvc.problemdetails.enabled' (OnPropertyCondition)
```

Each entry names the candidate and gives the reason, with the condition's class in brackets.
`tomcatServletWebServerFactory` is the bean that builds Tomcat, and it was created because
`@ConditionalOnMissingBean` **did not find** a `ServletWebServerFactory` of yours. The Gson
converters were skipped because `com.google.gson.Gson` is not on the classpath: Jackson is the
bookshop's JSON library, and adding Gson's jar would turn that line positive. And
`ProblemDetailsErrorHandlingConfiguration` was skipped because a property was not set, which is
a switch lesson 7 comes back to.

The report is long because it is complete:

```
ana@vm:~/bookshop$ grep -cE '^   [A-Za-z0-9.#]+ matched:$' /tmp/bookshop.log
52
ana@vm:~/bookshop$ sed -n '/^Negative matches:/,/^Exclusions:/p' /tmp/bookshop.log | grep -cE '^   [A-Za-z0-9.#]+:$'
39
```

The first count is the positive matches and the second the negative ones. You never read it
whole. You search it when something **you expected is missing** — no JSON, no Tomcat, a bean
that is not there — and the entry for that candidate tells you which condition failed, in a
sentence. `debug=true` in `application.properties` prints the same report. Stop the
application before the next section.
