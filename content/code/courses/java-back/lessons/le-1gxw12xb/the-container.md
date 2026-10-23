---
title: The container and its beans
version: 1
---

In the application, `main` calls `SpringApplication.run`, and Spring builds an **application
context**: the container that creates the objects, connects them and keeps them for as long as the
application runs. An object it manages is a **bean**. Before it creates any, it collects a **bean
definition** for each one: which class, which constructor or method makes it, and under what name.

## Where the definitions come from

Lesson 4 took `@SpringBootApplication` apart into three annotations, and this lesson depends on one
of them, `@ComponentScan`. **Component scanning** reads every class in the package of the class that
carries it, `com.example.bookshop`, and in every package below that one, and makes a definition for
each class marked with a **stereotype** annotation:

| annotation | what it says about the class |
|---|---|
| `@Component` | a bean, with nothing more specific to say |
| `@Service` | a bean that holds the application's rules |
| `@Repository` | a bean that keeps or fetches data; with a persistence library present, Spring also translates that library's exceptions into its own `DataAccessException` family |
| `@Controller`, `@RestController` | a bean that answers web requests, from lesson 6 |
| `@Configuration` | a bean whose `@Bean` methods are definitions of further beans |

Apart from that translation, the first three behave identically. `@Service` and `@Repository` are
`@Component` under a name that tells the next reader what the class is for. Each definition also gets
a **bean name**: the class's simple name with its first letter in lower case, so `bookService` and
`inMemoryBookRepository`.

## Watching it build

The class that creates beans is `DefaultListableBeanFactory`, and at the `debug` level it logs every
bean it creates and every constructor argument it fills. Two arguments on the command line turn that
on and keep the run short. One is the logging level. The other,
`--spring.main.web-application-type=none`, starts the application without its web server: there is no
controller to serve yet, and without a server the application runs its runners and exits instead of
waiting for requests until somebody presses Ctrl+C. Most runs in this lesson use it. The `grep`
keeps the lines about the bookshop's own beans:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.main.web-application-type=none --logging.level.org.springframework.beans.factory.support.DefaultListableBeanFactory=debug | grep -E "'(bookshopApplication|bookService|inMemoryBookRepository|catalogueReport|clock|clockConfig)'|Catalogue opened"
2026-10-22T19:16:15.711-03:00 DEBUG 15953 --- [bookshop] [           main] o.s.b.f.s.DefaultListableBeanFactory     : Creating shared instance of singleton bean 'bookshopApplication'
2026-10-22T19:16:15.712-03:00 DEBUG 15953 --- [bookshop] [           main] o.s.b.f.s.DefaultListableBeanFactory     : Creating shared instance of singleton bean 'bookService'
2026-10-22T19:16:15.714-03:00 DEBUG 15953 --- [bookshop] [           main] o.s.b.f.s.DefaultListableBeanFactory     : Creating shared instance of singleton bean 'inMemoryBookRepository'
2026-10-22T19:16:15.719-03:00 DEBUG 15953 --- [bookshop] [           main] o.s.b.f.s.DefaultListableBeanFactory     : Autowiring by type from bean name 'bookService' via constructor to bean named 'inMemoryBookRepository'
2026-10-22T19:16:15.723-03:00 DEBUG 15953 --- [bookshop] [           main] o.s.b.f.s.DefaultListableBeanFactory     : Creating shared instance of singleton bean 'catalogueReport'
2026-10-22T19:16:15.724-03:00 DEBUG 15953 --- [bookshop] [           main] o.s.b.f.s.DefaultListableBeanFactory     : Creating shared instance of singleton bean 'clock'
2026-10-22T19:16:15.724-03:00 DEBUG 15953 --- [bookshop] [           main] o.s.b.f.s.DefaultListableBeanFactory     : Creating shared instance of singleton bean 'clockConfig'
2026-10-22T19:16:15.726-03:00 DEBUG 15953 --- [bookshop] [           main] o.s.b.f.s.DefaultListableBeanFactory     : Autowiring by type from bean name 'catalogueReport' via constructor to bean named 'bookService'
2026-10-22T19:16:15.726-03:00 DEBUG 15953 --- [bookshop] [           main] o.s.b.f.s.DefaultListableBeanFactory     : Autowiring by type from bean name 'catalogueReport' via constructor to bean named 'clock'
2026-10-22T19:16:15.835-03:00  INFO 15953 --- [bookshop] [           main] c.e.bookshop.catalogue.CatalogueReport   : Catalogue opened on 2026-10-22 with 3 books
```

Read the lines in order, because **the order is the point**. Nobody wrote it down. Spring took up
`bookService`, read its constructor, saw that it needs a `BookRepository`, and created the one bean of
that type, `inMemoryBookRepository`, before it could finish `bookService`. Then `catalogueReport`,
whose constructor wants two things: the `bookService` that already exists, and a `Clock`. The clock is
made by a method of `clockConfig`, so `clockConfig` had to exist before that method could be called.

It is the same order `Wiring.java` followed, derived from the same constructors.
"Autowiring by type" says how each argument was chosen: **by its type**. `BookService` asked for a
`BookRepository` and never named `InMemoryBookRepository`; there was exactly one bean of that type,
and it was the answer.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 290\" role=\"img\" aria-label=\"CatalogueReport points to BookService as its parameter 0 and to Clock as its parameter 1. BookService points to the interface BookRepository as its parameter 0, which is satisfied by the only bean of that type, InMemoryBookRepository. Clock is made by a method of ClockConfig. Numbers 1 to 5 give the order the log created them: bookService, inMemoryBookRepository, catalogueReport, clock, clockConfig.\"><defs><marker id=\"g5-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"g5-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"180\" height=\"58\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">CatalogueReport</text><text x=\"110.0\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">@Component</text><rect x=\"290\" y=\"30\" width=\"180\" height=\"58\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"380.0\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">BookService</text><text x=\"380.0\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">@Service</text><rect x=\"560\" y=\"30\" width=\"180\" height=\"58\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"650.0\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">BookRepository</text><text x=\"650.0\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a type, not a bean</text><rect x=\"560\" y=\"200\" width=\"180\" height=\"58\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"650.0\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">InMemoryBookRepository</text><text x=\"650.0\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">@Repository</text><rect x=\"290\" y=\"200\" width=\"180\" height=\"58\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"380.0\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Clock</text><text x=\"380.0\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">@Bean clock()</text><rect x=\"20\" y=\"200\" width=\"180\" height=\"58\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">ClockConfig</text><text x=\"110.0\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">@Configuration</text><line x1=\"200\" y1=\"59.0\" x2=\"288\" y2=\"59.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#g5-ah)\"></line><text x=\"245.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">parameter 0</text><line x1=\"470\" y1=\"59.0\" x2=\"558\" y2=\"59.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#g5-ah)\"></line><text x=\"515.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">parameter 0</text><line x1=\"650.0\" y1=\"88\" x2=\"650.0\" y2=\"198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#g5-ah)\"></line><text x=\"660.0\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the only bean</text><text x=\"660.0\" y=\"137\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">of this type</text><line x1=\"170\" y1=\"88\" x2=\"320\" y2=\"198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#g5-ah)\"></line><text x=\"198\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">parameter 1</text><line x1=\"290\" y1=\"229.0\" x2=\"202\" y2=\"229.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#g5-ah)\"></line><text x=\"245.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">made by</text><circle cx=\"287\" cy=\"27\" r=\"11\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"287\" y=\"27.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">1</text><circle cx=\"557\" cy=\"197\" r=\"11\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"557\" y=\"197.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">2</text><circle cx=\"17\" cy=\"27\" r=\"11\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"17\" y=\"27.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">3</text><circle cx=\"287\" cy=\"197\" r=\"11\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"287\" y=\"197.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">4</text><circle cx=\"17\" cy=\"197\" r=\"11\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"17\" y=\"197.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">5</text></svg>", "caption": "Each labelled parameter is a constructor argument, resolved by its type, and the clock is made by a method of ClockConfig. The numbers are the order of the \"Creating shared instance\" lines above: a bean that is needed is created before the bean that needs it is finished."}
```

Those six are a small part of what the context holds:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.main.web-application-type=none --logging.level.org.springframework.beans.factory.support.DefaultListableBeanFactory=debug | grep -c 'Creating shared instance'
78
```

Spring created 78 beans in that run, and the bookshop wrote six of them, counting `bookshopApplication` itself. The rest are
Spring Boot's autoconfiguration from lesson 4, made the same way from definitions, and any one of them
can be injected into a bookshop class exactly like the bookshop's own.
