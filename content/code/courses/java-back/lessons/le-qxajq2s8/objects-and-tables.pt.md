---
title: Objetos, tabelas e o mapeador entre eles
version: 1
---

O repositório da aula 9 fazia dois trabalhos ao mesmo tempo. Escrevia o SQL e copiava cada coluna de
cada linha para um record `Book`. Um **mapeador objeto-relacional**, um ORM, assume o segundo
trabalho inteiro e quase todo o primeiro: você descreve como uma classe corresponde a uma tabela, e o
mapeador escreve os comandos `SELECT`, `INSERT` e `UPDATE` e transforma linhas em objetos e objetos de
volta em linhas.

A imagem errada mais comum é que o mapeador substitui o banco, e que o programa passa a trabalhar com
uma grande coleção de objetos guardada na memória. Não é assim. **Todo objeto que um mapeador entrega
saiu de um `SELECT`, e toda alteração que você faz chega ao banco como um `UPDATE`.** O que muda é quem
escreve esses comandos e quando eles rodam, e a maior parte desta aula trata do quando.

## Dois formatos para um mesmo fato

Objetos e tabelas discordam em três pontos, e um mapeador existe para resolvê-los.

- **Referências contra chaves.** Um objeto livro guarda o seu autor, então `book.getAuthor().getName()`
  é uma chamada de método. Uma linha de `book` guarda um número, `author_id`, e o nome exige uma
  segunda consulta ou um join.
- **Identidade.** Duas consultas JDBC pelo livro 3 devolvem dois records iguais e distintos. Dentro de
  uma unidade de trabalho, um mapeador devolve o mesmo objeto nas duas vezes, porque só existe um
  livro 3.
- **Alteração.** Um record nunca muda; para mudar um preço na aula 9 você escreveria um `UPDATE`. Um
  objeto mapeado tem um campo que muda, e o mapeador percebe e escreve o `UPDATE` sozinho.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 240\" role=\"img\" aria-label=\"À esquerda, um objeto Book cujo campo author aponta para um objeto Author chamado Mary Shelley. À direita, uma linha da tabela book com author_id 3, que corresponde ao id de uma linha da tabela author.\"><defs><marker id=\"map-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"170\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">em Java: objetos</text><text x=\"530\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no PostgreSQL: linhas</text><rect x=\"30\" y=\"45\" width=\"180\" height=\"96\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Book</text><text x=\"45\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">id = 3</text><text x=\"45\" y=\"101\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">title = \"Frankenstein\"</text><text x=\"45\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">author =</text><rect x=\"130\" y=\"165\" width=\"180\" height=\"62\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"220\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Author</text><text x=\"145\" y=\"205\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">name = \"Mary Shelley\"</text><path d=\"M 108 118 C 150 118, 200 130, 210 162\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#map-ah)\"></path><text x=\"262\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma referência</text><rect x=\"390\" y=\"45\" width=\"290\" height=\"66\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"400\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">book</text><text x=\"400\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">id</text><text x=\"400\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3</text><text x=\"440\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">title</text><text x=\"440\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Frankenstein</text><text x=\"580\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">author_id</text><text x=\"580\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3</text><rect x=\"390\" y=\"165\" width=\"290\" height=\"62\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"400\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">author</text><text x=\"400\" y=\"202\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">id</text><text x=\"400\" y=\"217\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3</text><text x=\"440\" y=\"202\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">name</text><text x=\"440\" y=\"217\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Mary Shelley</text><path d=\"M 600 108 C 600 140, 420 130, 412 162\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#map-ah)\"></path><text x=\"625\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um número a procurar</text></svg>", "caption": "Um fato, dois formatos. O objeto guarda o seu autor; a linha guarda um número que precisa ser procurado. O Hibernate traduz entre os dois."}
```

## JPA e Hibernate

O **Jakarta Persistence**, ainda chamado pelo nome antigo, **JPA**, é uma especificação: um conjunto
de anotações (`@Entity`, `@Id`, `@ManyToOne`), a interface `EntityManager` e uma linguagem de
consulta, a JPQL. Ele mora no pacote `jakarta.persistence` e não implementa nada. O **Hibernate** é a
implementação que o Spring Boot usa; o EclipseLink é outra. O código desta aula importa só
`jakarta.persistence`, e o Hibernate faz o trabalho por trás. Você vai ver o nome dele no log e nunca
num import:

```
(capture hibernate-version)
```

## O que ele custa

Um mapeador poupa a cópia, e cobra por isso de três jeitos. Eles são o motivo de a aula 12 olhar
bibliotecas que fazem menos.

- **SQL que você não escreveu.** Uma linha de Java que parece ler um campo pode ser uma consulta. A
  seção sobre o problema N+1 conta essas consultas.
- **Regras sobre tempo.** Um objeto continua ligado ao banco só enquanto uma unidade de trabalho está
  aberta. Leia um campo lazy depois disso e o Hibernate lança uma exceção em vez de consultar; a
  última seção mostra a exceção.
- **Um modelo próprio para aprender.** Entidades, contexto de persistência, flush, proxies: nada disso
  é SQL, e tudo isso decide qual SQL roda. Esta aula ensina a parte que o bookshop usa.
