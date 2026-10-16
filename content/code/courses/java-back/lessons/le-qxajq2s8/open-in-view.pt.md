---
title: Open in view, e a exceção que ele esconde
version: 1
---

Um autor lazy só consegue se carregar enquanto o contexto de persistência que o produziu está aberto.
Leia-o depois disso e o Hibernate não roda a consulta discretamente mesmo assim: ele lança uma
**`LazyInitializationException`**. Todo desenvolvedor Hibernate a encontra, e a primeira reação de
costume é fazê-la sumir em vez de lê-la.

## Provocando a exceção

Mais um desvio. Em `BookService`, apague a linha `@Transactional(readOnly = true)` acima de `get`, e
deixe todo o resto como está. Sem transação própria, o `find` roda num contexto de persistência que
dura só aquela chamada, e `BookResponse.from` então lê o autor de um livro que já está desanexado.
Compile, suba e peça um livro:

```
(capture lazy-curl)
```

Um 500, no formato padrão do Spring para uma exceção que ninguém tratou: o handler da aula 7 cobre as
exceções do próprio bookshop e os erros web do Spring, e esta não é nenhuma das duas. O segundo
terminal diz o que foi; estas são as linhas antes de o stack trace começar:

```
(capture lazy-log)
```

Leia como uma frase: o proxy do `Author` número 1 não conseguiu se carregar porque não havia
**session**, o nome que o Hibernate dá ao contexto de persistência. O livro estava bem. O autor dele era
uma promessa que só podia ser cumprida dentro de uma transação, e a transação nunca tinha sido aberta.

## A configuração que a esconde

Agora suba o mesmo build com mais um argumento, `--spring.jpa.open-in-view=true`, e peça de novo:

```
(capture osiv-curl)
```

O mesmo código, e funciona. O segundo terminal mostra os dois comandos, inclusive o do autor:

```
(capture osiv-log)
```

O **open session in view**, OSIV, é uma configuração do Spring que abre um contexto de persistência
quando uma requisição web chega e só o fecha depois que a resposta foi escrita. Todo campo lazy tocado
em qualquer ponto da requisição, no serviço, no controller ou na serialização para JSON, encontra um
contexto aberto e se carrega. O Spring Boot o liga por padrão, e um projeto que nunca define a
propriedade recebe este aviso a cada inicialização:

```
(capture osiv-warning)
```

Ele está desligado neste bookshop por três motivos.

- **Ele esconde onde as consultas acontecem.** O serviço deixa de ser o lugar que decide o que é
  carregado; qualquer código que toque num getter pode rodar uma consulta, inclusive código que só
  queria serializar um objeto.
- **Ele pode segurar uma conexão com o banco pelo resto da requisição**, inclusive o tempo gasto
  escrevendo a resposta para um cliente lento. A aula 14 conta conexões, e elas acabam.
- **Ele só funciona em requisições web.** Um job agendado ou uma tarefa de inicialização não ganha esse
  contexto, então um código que funciona quando um controller o chama lança exceção quando qualquer
  outra coisa chama.

Com ele desligado, a exceção chega cedo e no lugar certo, na primeira vez que o código roda, e a
correção é a que este bookshop já tem: **o serviço decide o que carregar, dentro da transação dele, e
devolve records simples.** Ponha a linha `@Transactional(readOnly = true)` de volta acima de `get`,
para que `BookService.java` volte a ser o arquivo da seção sobre o entity manager.
