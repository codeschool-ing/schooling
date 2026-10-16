---
title: O contêiner e os seus beans
version: 1
---

Na aplicação, o `main` chama `SpringApplication.run`, e o Spring monta um **contexto de aplicação**
(application context): o contêiner que cria os objetos, os liga entre si e os mantém enquanto a
aplicação roda. Um objeto que ele administra é um **bean**. Antes de criar qualquer um, ele junta uma
**definição de bean** para cada um: qual classe, qual construtor ou método o produz, e com que nome.

## De onde vêm as definições

A lição 4 desmontou `@SpringBootApplication` em três anotações, e esta lição depende de uma delas,
`@ComponentScan`. A **varredura de componentes** lê todas as classes do pacote da classe que a carrega,
`com.example.bookshop`, e de todos os pacotes abaixo dele, e cria uma definição para cada classe
marcada com uma anotação de **estereótipo**:

| anotação | o que ela diz da classe |
|---|---|
| `@Component` | um bean, sem nada mais específico a dizer |
| `@Service` | um bean que guarda as regras da aplicação |
| `@Repository` | um bean que guarda ou busca dados; com uma biblioteca de persistência presente, o Spring também traduz as exceções dessa biblioteca para a sua própria família `DataAccessException` |
| `@Controller`, `@RestController` | um bean que responde a requisições web, a partir da lição 6 |
| `@Configuration` | um bean cujos métodos `@Bean` são definições de outros beans |

Fora essa tradução, as três primeiras se comportam igual. `@Service` e `@Repository` são `@Component`
com um nome que diz ao próximo leitor para que a classe serve. Cada definição ganha também um **nome
de bean**: o nome simples da classe com a primeira letra minúscula, então `bookService` e
`inMemoryBookRepository`.

## Vendo a montagem

A classe que cria os beans é `DefaultListableBeanFactory`, e no nível `debug` ela registra cada bean
que cria e cada argumento de construtor que preenche. Dois argumentos na linha de comando ligam isso e
deixam a execução curta. Um é o nível de log. O outro,
`--spring.main.web-application-type=none`, inicia a aplicação sem o servidor web: ainda não há
controlador para servir, e sem servidor a aplicação roda os seus runners e termina, em vez de esperar
requisições até alguém apertar Ctrl+C. A maioria das execuções desta lição usa esse argumento. O
`grep` fica com as linhas sobre os beans da própria livraria:

```
!!! MISSING BLOCK beans
```

Leia as linhas na ordem, porque **a ordem é o que importa**. Ninguém a escreveu. O Spring pegou
`bookService`, leu o seu construtor, viu que ele precisa de um `BookRepository` e criou o único bean
desse tipo, `inMemoryBookRepository`, antes de conseguir terminar `bookService`. Depois veio
`catalogueReport`, cujo construtor quer duas coisas: o `bookService` que já existe e um `Clock`. O
relógio é feito por um método de `clockConfig`, então `clockConfig` precisou existir antes que esse
método pudesse ser chamado.

É a mesma ordem que `Wiring.java` seguiu, tirada dos mesmos construtores. "Autowiring by type" diz
como cada argumento foi escolhido: **pelo tipo**. `BookService` pediu um `BookRepository` e nunca citou
`InMemoryBookRepository`; havia exatamente um bean desse tipo, e ele foi a resposta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 290\" role=\"img\" aria-label=\"CatalogueReport aponta para BookService como parâmetro 0 e para Clock como parâmetro 1. BookService aponta para a interface BookRepository como parâmetro 0, satisfeita pelo único bean desse tipo, InMemoryBookRepository. Clock é feito por um método de ClockConfig. Os números de 1 a 5 dão a ordem em que o log os criou: bookService, inMemoryBookRepository, catalogueReport, clock, clockConfig.\"><defs><marker id=\"g5-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"g5-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"180\" height=\"58\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">CatalogueReport</text><text x=\"110.0\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">@Component</text><rect x=\"290\" y=\"30\" width=\"180\" height=\"58\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"380.0\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">BookService</text><text x=\"380.0\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">@Service</text><rect x=\"560\" y=\"30\" width=\"180\" height=\"58\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"650.0\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">BookRepository</text><text x=\"650.0\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um tipo, não um bean</text><rect x=\"560\" y=\"200\" width=\"180\" height=\"58\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"650.0\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">InMemoryBookRepository</text><text x=\"650.0\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">@Repository</text><rect x=\"290\" y=\"200\" width=\"180\" height=\"58\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"380.0\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Clock</text><text x=\"380.0\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">@Bean clock()</text><rect x=\"20\" y=\"200\" width=\"180\" height=\"58\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">ClockConfig</text><text x=\"110.0\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">@Configuration</text><line x1=\"200\" y1=\"59.0\" x2=\"288\" y2=\"59.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#g5-ah)\"></line><text x=\"245.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">parâmetro 0</text><line x1=\"470\" y1=\"59.0\" x2=\"558\" y2=\"59.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#g5-ah)\"></line><text x=\"515.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">parâmetro 0</text><line x1=\"650.0\" y1=\"88\" x2=\"650.0\" y2=\"198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#g5-ah)\"></line><text x=\"660.0\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o único bean</text><text x=\"660.0\" y=\"137\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">deste tipo</text><line x1=\"170\" y1=\"88\" x2=\"320\" y2=\"198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#g5-ah)\"></line><text x=\"198\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">parâmetro 1</text><line x1=\"290\" y1=\"229.0\" x2=\"202\" y2=\"229.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#g5-ah)\"></line><text x=\"245.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">feito por um método de</text><circle cx=\"292\" cy=\"32\" r=\"11\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"292\" y=\"32.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">1</text><circle cx=\"562\" cy=\"202\" r=\"11\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"562\" y=\"202.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">2</text><circle cx=\"22\" cy=\"32\" r=\"11\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"22\" y=\"32.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">3</text><circle cx=\"292\" cy=\"202\" r=\"11\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"292\" y=\"202.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">4</text><circle cx=\"22\" cy=\"202\" r=\"11\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"22\" y=\"202.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">5</text></svg>", "caption": "Cada seta é um parâmetro de construtor, resolvido pelo tipo. Os números são a ordem das linhas \"Creating shared instance\" acima: um bean necessário é criado antes que o bean que precisa dele termine."}
```

Esses seis são uma pequena parte do que o contexto guarda:

```
!!! MISSING BLOCK count
```

A livraria escreveu seis desses beans, contando o próprio `bookshopApplication`. O resto é a
autoconfiguração do Spring Boot da lição 4, feita do mesmo jeito a partir de definições, e qualquer um
deles pode ser injetado numa classe da livraria exatamente como os da própria livraria.
