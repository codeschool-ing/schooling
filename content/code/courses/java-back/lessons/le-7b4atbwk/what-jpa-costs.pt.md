---
title: O que o JPA cobra pelo que oferece
version: 1
---

As aulas 10 e 11 deram ao bookshop um ORM, e ele fez por merecer. `Book` é um objeto, um campo
alterado é gravado de volta sem um `UPDATE` que alguém tenha digitado, e
`findByTitleContainingIgnoreCaseOrderByTitle` é uma consulta que ninguém escreveu. As mesmas duas
aulas mostraram a conta: a listagem mandava um `select` por livro até o `join fetch` e o
`@EntityGraph` resolverem, e ler o autor de um livro depois que a transação fechou lançou uma
`LazyInitializationException`.

Uma imagem comum é que a escolha é entre o JPA e o JDBC puro, o conforto dos objetos ou uma página
de chamadas a `rs.getString`. **O espaço entre os dois está cheio de bibliotecas**, e cada uma
mantém uma parte diferente do que o JPA oferece e larga uma parte diferente do que ele custa. Para
compará-las, ajuda dar nome às partes:

| o JPA oferece | e cobra |
|---|---|
| SQL gerado a partir de entidades e de JPQL | SQL que você não escreveu, lido num log depois de rodar |
| um contexto de persistência que acompanha cada entidade carregada | uma sessão com tempo de vida, e uma exceção quando você passa dele |
| associações preguiçosas, atrás de proxies | uma consulta a mais por associação, a menos que você planeje a busca |
| um só mapeamento para PostgreSQL, MySQL ou Oracle | os recursos próprios do banco alcançados por consultas nativas |

Nada na coluna da direita é defeito. Uma equipe que quer a coluna da esquerda paga a da direita de
bom grado, e a maioria das aplicações Spring é essa equipe. As bibliotecas desta aula existem para
as equipes que olharam uma linha da tabela e concluíram que a troca não servia para elas.

## Todas terminam no JDBC

A aula 9 chamou o JDBC de base sobre a qual todo o resto se apoia, e o título é literal. Seja qual
for a biblioteca por cima, o driver acaba segurando um `PreparedStatement` com os parâmetros
ligados, e **o PostgreSQL nunca fica sabendo qual biblioteca o montou**. O jeito de falar com o
banco é igual para todas. As perguntas úteis são quem escreve o texto SQL, e do que a biblioteca se
lembra entre um comando e o seguinte.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 350\" role=\"img\" aria-label=\"Três colunas de bibliotecas de persistência sobre uma barra chamada JDBC. À esquerda, onde você escreve o SQL como texto: JdbcClient, JDBI e MyBatis. No meio, onde você o escreve como Java: jOOQ. À direita, onde a biblioteca o escreve: Spring Data JPA sobre o Hibernate, e o EBean. Uma seta de cada coluna chega à mesma barra JDBC, e uma seta vai dali até o PostgreSQL.\"><defs><marker id=\"l12-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"125\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">SQL como texto que você escreve</text><text x=\"350\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">SQL como Java que você escreve</text><text x=\"575\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">SQL que a biblioteca escreve</text><rect x=\"20\" y=\"36\" width=\"210\" height=\"174\" rx=\"8\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"245\" y=\"36\" width=\"210\" height=\"174\" rx=\"8\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"460\" y=\"36\" width=\"230\" height=\"174\" rx=\"8\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"30\" y=\"44\" width=\"190\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"125\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">JdbcClient</text><text x=\"125\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Spring, aula 9</text><rect x=\"30\" y=\"100\" width=\"190\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"125\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">JDBI</text><rect x=\"30\" y=\"156\" width=\"190\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"125\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">MyBatis</text><text x=\"125\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">comandos em mappers</text><rect x=\"255\" y=\"100\" width=\"190\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">jOOQ</text><text x=\"350\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">classes geradas do esquema</text><rect x=\"470\" y=\"44\" width=\"100\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"520\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Spring Data JPA</text><rect x=\"470\" y=\"100\" width=\"100\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"520\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Hibernate</text><rect x=\"580\" y=\"100\" width=\"100\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"630\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">EBean</text><line x1=\"520\" y1=\"88\" x2=\"520\" y2=\"98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12-ah)\"></line><rect x=\"30\" y=\"244\" width=\"650\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"355\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">JDBC</text><text x=\"355\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Connection, PreparedStatement, ResultSet</text><line x1=\"125\" y1=\"210\" x2=\"125\" y2=\"242\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12-ah)\"></line><line x1=\"350\" y1=\"210\" x2=\"350\" y2=\"242\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12-ah)\"></line><line x1=\"575\" y1=\"210\" x2=\"575\" y2=\"242\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12-ah)\"></line><text x=\"237\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">toda seta termina nas mesmas chamadas</text><rect x=\"290\" y=\"314\" width=\"130\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"355\" y=\"329\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">PostgreSQL</text><line x1=\"355\" y1=\"294\" x2=\"355\" y2=\"312\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12-ah)\"></line></svg>", "caption": "Toda biblioteca desta aula termina nas mesmas chamadas JDBC, e o banco nunca fica sabendo qual delas montou o comando. O que muda é quem escreve o SQL acima delas.", "same": ["JDBI", "MyBatis", "jOOQ", "Spring Data JPA", "Hibernate", "EBean", "JDBC", "PostgreSQL"]}
```

As três colunas da figura são as três respostas que esta aula encontra:

- O SQL é texto que você escreve. O `JdbcClient` do Spring, da aula 9, o JDBI e o MyBatis ligam os
  seus parâmetros e transformam linhas em objetos, e não se lembram de nada entre uma chamada e
  outra. O SQL é uma string, e o compilador não consegue lê-la.
- O SQL é Java que você escreve. O jOOQ gera uma classe para cada tabela e oferece um builder que se
  lê como SQL, então o compilador confere a consulta contra o esquema.
- O SQL é da biblioteca. O Hibernate, atrás do JPA, e o EBean mapeiam entidades para tabelas e
  escrevem os comandos eles mesmos.

Numa aplicação Spring, mais uma opção fica bem perto de casa. O **Spring Data JDBC** mantém as
interfaces de repositório da aula 11, `CrudRepository`, os métodos de consulta derivada e o `@Query`
(com SQL dentro, em vez de JPQL), e larga o contexto de persistência e o carregamento preguiçoso.
Carregar um objeto carrega tudo o que pertence a ele de uma vez, em vez de aos poucos, e salvar o
grava, sem nada acompanhado no meio do caminho. É a resposta do próprio Spring para "repositórios
sem Hibernate"; as próximas três seções são as respostas de fora do Spring.
