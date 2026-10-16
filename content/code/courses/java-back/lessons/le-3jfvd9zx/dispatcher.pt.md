---
title: Um servlet na frente de todo controlador
version: 1
---

É natural imaginar o Tomcat chamando o `BookController`, ou cada controlador escutando os próprios
caminhos. Nenhuma das duas coisas acontece. O Tomcat roda servlets, o padrão Jakarta para um
objeto que recebe uma requisição HTTP e escreve uma resposta, e nesta aplicação ele conhece
exatamente um: o **`DispatcherServlet`** que a autoconfiguração do Spring Boot registrou na aula 4.
Toda requisição vai para ele, e ele decide qual dos seus métodos responde. O padrão tem nome,
**front controller**: uma entrada só, com o roteamento atrás dela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 340\" role=\"img\" aria-label=\"O curl envia GET /books/2 ao Tomcat, que o entrega ao único DispatcherServlet. Dentro dele, quatro passos em ordem: achar o método (RequestMappingHandlerMapping), resolver os argumentos (o texto 2 do caminho vira um long), chamar BookController.get e escrever o BookResponse devolvido como JSON com o Jackson. A resposta, status 200 com corpo em JSON, volta ao curl.\"><defs><marker id=\"l6d-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">curl</text><text x=\"80\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o cliente</text><rect x=\"180\" y=\"40\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"240\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Tomcat</text><text x=\"240\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o servidor</text><line x1=\"140\" y1=\"65\" x2=\"178\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l6d-ah)\"></line><text x=\"159\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">GET /books/2</text><rect x=\"340\" y=\"14\" width=\"345\" height=\"316\" rx=\"5\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"512\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">DispatcherServlet</text><text x=\"512\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">um servlet, toda requisição</text><line x1=\"300\" y1=\"65\" x2=\"338\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l6d-ah)\"></line><rect x=\"360\" y=\"70\" width=\"305\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"374\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">1</text><text x=\"390\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">achar o método</text><text x=\"390\" y=\"101\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">RequestMappingHandlerMapping</text><text x=\"390\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">GET /books/2 é de BookController#get</text><line x1=\"512\" y1=\"124\" x2=\"512\" y2=\"133\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l6d-ah)\"></line><rect x=\"360\" y=\"134\" width=\"305\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"374\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">2</text><text x=\"390\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">resolver os argumentos</text><text x=\"390\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">@PathVariable long id</text><text x=\"390\" y=\"179\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o texto \"2\" do caminho vira o long 2</text><line x1=\"512\" y1=\"188\" x2=\"512\" y2=\"197\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l6d-ah)\"></line><rect x=\"360\" y=\"198\" width=\"305\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"374\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">3</text><text x=\"390\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">chamar o método</text><text x=\"390\" y=\"229\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">BookController#get(long)</text><text x=\"390\" y=\"243\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o seu código: o serviço, um Optional, um status</text><line x1=\"512\" y1=\"252\" x2=\"512\" y2=\"261\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l6d-ah)\"></line><rect x=\"360\" y=\"262\" width=\"305\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"374\" y=\"276\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">4</text><text x=\"390\" y=\"276\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">escrever o valor devolvido</text><text x=\"390\" y=\"293\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">BookResponse</text><text x=\"390\" y=\"307\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o Jackson transforma o record em JSON</text><path d=\"M 360 291 L 80 291 L 80 92\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l6d-ah)\"></path><text x=\"215\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">200, Content-Type: application/json, o corpo em JSON</text></svg>", "caption": "O Tomcat conhece um servlet só. Tudo o que a livraria responde passa por estes quatro passos, e só o terceiro é código seu."}
```

Os quatro passos, na ordem em que rodam:

1. **Achar o método.** Na inicialização, o Spring lê as anotações `@RequestMapping` e `@GetMapping` de
   todo bean controlador e monta uma tabela de um método HTTP e um padrão de caminho para um método
   Java. Cada requisição é procurada nessa tabela. O 405 e o 404 da seção anterior vieram dessa
   busca: um caminho que bate para outro método, e um caminho que não bate com nada.
2. **Resolver os argumentos.** Cada parâmetro é preenchido por um resolvedor escolhido pela anotação
   dele. `@PathVariable` converte um pedaço do caminho; `@RequestBody`, na seção sobre POST, lê o
   corpo com um **conversor de mensagens**. Quando uma conversão falha, o método nunca roda, e foi o
   que aconteceu com `/books/abc`.
3. **Chamar o método.** Este é o único passo que é código seu.
4. **Escrever o valor devolvido.** Um conversor de mensagens transforma o que o método devolveu no
   corpo, escolhido por **negociação de conteúdo**: o que o cliente diz que aceita contra o que os
   conversores sabem escrever. Um `ResponseEntity` acrescenta o status e os cabeçalhos.

## Vendo acontecer

O perfil `dev` que a aula 4 escreveu define `logging.level.org.springframework.web=debug`, que faz o
`DispatcherServlet` narrar o que faz, e muda a porta para 8081. Pare a aplicação e inicie-a com o
perfil:

```sh
java -jar target/bookshop-0.1.0.jar --spring.profiles.active=dev
```

Peça um livro na porta nova:

```
(pending dev-curl)
```

O segundo terminal imprimiu estas linhas entre muitas outras. As linhas de inicialização em volta
delas ficaram de fora aqui:

```
(pending dev-log)
```

Cada linha é um dos passos da figura:

- `4 mappings in 'requestMappingHandlerMapping'` é a tabela do passo 1, montada na inicialização: os
  seus dois métodos e dois que o Spring Boot acrescenta para o próprio caminho `/error`, o que
  escreveu o corpo de `/authors`.
- `Initializing Servlet 'dispatcherServlet'` aparece na primeira requisição e não na inicialização: o
  Spring criou o servlet ao iniciar, e o Tomcat o inicializa na primeira vez que precisa dele.
- `GET "/books/2"` e `Mapped to com.example.bookshop.catalogue.BookController#get(long)` são o passo 1
  trabalhando para esta requisição.
- `Using 'application/json', given [*/*] and supported [...]` é a negociação do passo 4. O curl envia
  `Accept: */*`, que quer dizer que qualquer coisa serve, e os únicos conversores capazes de escrever
  um `BookResponse` produzem JSON.
- A linha `Writing` mostra o record como o `toString` dele o imprime, logo antes de o conversor
  transformá-lo em JSON. `Completed 200 OK` é o fim.

## O que fica em volta dele

O `DispatcherServlet` não é o primeiro código que uma requisição encontra. Na frente dele há uma
cadeia de **filtros** de servlet, que veem toda requisição antes de qualquer controlador: a aula 15
põe o Spring Security ali, e a aula 16 acrescenta um filtro que marca cada requisição com um id. Atrás
dele, quando um método lança uma exceção, o dispatcher pergunta aos seus resolvedores de exceção o que
responder; um deles escreveu o 400 de `/books/abc`, e a aula 7 dá a eles respostas suas.
