---
title: "EBean: um ORM sem a sessão"
version: 1
---

O **EBean** é um ORM da mesma família do Hibernate. Você escreve entidades com as anotações de
mapeamento que a aula 10 pôs em `Book` (`@Entity`, `@Id`, `@ManyToOne`), o EBean escreve o SQL, e
uma associação carrega quando você a toca. Onde ele se separa do Hibernate é no contexto de
persistência. **O EBean não tem `EntityManager` ao qual anexar uma entidade**, então não existe
estado anexado ou desanexado, não existe `merge`, e não existe sessão cujo fim transforma uma
associação preguiçosa numa exceção.

## O estado mora no objeto

O Hibernate guarda o que sabe sobre uma entidade no contexto de persistência: os valores que
carregou, para compará-los no commit e descobrir o que mudou. O EBean guarda esse conhecimento na
própria entidade. Um passo do build chamado **enhancement** (um plugin do Maven, ou um agente Java
na partida) reescreve as classes de entidade compiladas, de modo que cada objeto registra quais
propriedades foram carregadas e quais mudaram desde então.

Três comportamentos decorrem disso, e cada um responde a uma linha da tabela da primeira seção:

- Salvar é uma chamada que você faz, `DB.save(book)`, e o `UPDATE` que ela envia cita só as colunas
  que mudaram. O Hibernate, por padrão, grava todas as colunas da entidade.
- Uma associação preguiçosa tocada depois que a transação terminou é carregada nesse momento, num
  comando próprio, onde o bookshop da aula 10 lançava `LazyInitializationException`.
- Nada precisa ser fechado, limpo ou mesclado, porque nada segura os objetos além do seu código.

Carregar ao tocar ainda é uma consulta por toque, porém, e o problema N+1 da aula 10 continua à
disposição. O EBean o ameniza carregando associações preguiçosas em lotes em vez de uma de cada vez,
e você planeja a busca, exatamente como o `join fetch` fazia, quando os lotes não bastam.

## Query beans

A segunda ideia do EBean é o **query bean**. Um processador de anotações lê cada entidade na
compilação e gera uma classe para consultá-la, `QBook` para `Book`, com um campo por propriedade. A
consulta que a aula 11 escreveu com `@Query`, os livros de um autor em ordem de título, fica assim
no EBean. É um esboço do formato e **não foi rodado para este curso**:

```java
List<Book> books = new QBook()
        .author.name.eq("Machado de Assis")
        .orderBy().title.asc()
        .findList();
```

`author.name` é uma cadeia de campos de uma classe gerada, então uma propriedade escrita errado é um
erro de compilação. Uma string JPQL dentro de `@Query` só é conferida pelo Spring Data quando a
aplicação sobe, e a seção sobre o JDBI, nesta aula, mostra uma string SQL comum sendo conferida mais
tarde ainda.

## O que ele cobra

O preço é o enhancement, e uma equipe o paga em lugares que ela percebe. O build precisa do plugin,
e todo outro jeito de rodar o código precisa das classes modificadas também, inclusive um teste
iniciado pela IDE. Uma entidade que escapou desse passo falha em tempo de execução em vez de no
build. A comunidade é bem menor que a do Hibernate, o que significa menos respostas para procurar e
menos colegas que já viram o seu erro antes. E o Spring Boot não tem autoconfiguração para ele,
então ligar o EBean ao bookshop seria trabalho seu.

Você o encontra principalmente em dois lugares. Um é o **Play Framework** da aula 8, cujo lado Java
oferece o EBean pelo módulo `play-ebean` há muitos anos. O outro é uma base de código cujos autores
queriam um ORM e não queriam a sessão.
