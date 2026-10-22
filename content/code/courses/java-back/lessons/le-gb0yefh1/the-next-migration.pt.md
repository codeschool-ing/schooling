---
title: Escrevendo a próxima migração
version: 1
---

As migrações só andam para a frente. Toda mudança no esquema é um arquivo novo com a próxima versão, e um
arquivo que já rodou nunca mais é tocado. A edição gratuita do Flyway não tem desfazer: um erro que
chegou a um banco é corrigido pela migração seguinte, como o preço foi na seção anterior.

Por isso vale saber o que acontece quando uma migração falha no meio. Suponha que a loja comece a
registrar a editora de cada livro. Crie `src/main/resources/db/migration/V3__publisher.sql`:

```sql
CREATE TABLE publisher (
    id   bigserial PRIMARY KEY,
    name text      NOT NULL UNIQUE
);

ALTER TABLE book ADD COLUMN publisher_id bigint NOT NULL REFERENCES publisher (id);
```

Compile e inicie, guardando as linhas de progresso do Flyway e a mensagem do banco:

```
ana@vm:~/bookshop$ mvn -B -q package -DskipTests
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar | grep -m4 -E 'DbMigrate|^Message'
2026-10-22T19:30:23.171-03:00  INFO 17484 --- [bookshop] [           main] o.f.core.internal.command.DbMigrate      : Current version of schema "public": 2
2026-10-22T19:30:23.181-03:00  INFO 17484 --- [bookshop] [           main] o.f.core.internal.command.DbMigrate      : Migrating schema "public" to version "3 - publisher"
2026-10-22T19:30:23.230-03:00 ERROR 17484 --- [bookshop] [           main] o.f.core.internal.command.DbMigrate      : Migration of schema "public" to version "3 - publisher" failed! Changes successfully rolled back.
Message    : ERROR: column "publisher_id" of relation "book" contains null values
```

O segundo comando falhou, e o primeiro foi junto:

```
ana@vm:~/bookshop$ psql postgresql://bookshop:bookshop@localhost/bookshop -c '\dt'
                 List of relations
 Schema |         Name          | Type  |  Owner   
--------+-----------------------+-------+----------
 public | author                | table | bookshop
 public | book                  | table | bookshop
 public | flyway_schema_history | table | bookshop
(3 rows)

ana@vm:~/bookshop$ psql postgresql://bookshop:bookshop@localhost/bookshop -c 'select installed_rank, version, description, success from flyway_schema_history'
 installed_rank | version | description  | success 
----------------+---------+--------------+---------
              1 | 1       | catalogue    | t
              2 | 2       | first titles | t
(2 rows)
```

Nenhuma tabela `publisher`, e nenhuma linha para a versão 3. **O PostgreSQL roda DDL dentro de
transações**, então o Flyway roda cada migração numa, e uma falha em qualquer ponto do arquivo desfaz tudo
o que veio antes no mesmo arquivo. O banco está exatamente como estava na versão 2, e a próxima partida
vai tentar o V3 de novo desde o começo. Nem todo banco consegue isso. O MySQL confirma cada `CREATE` e
`ALTER` no momento em que roda, então a mesma falha lá deixa a tabela para trás e uma linha de falha no
histórico, e alguém tem de limpar as duas coisas à mão antes de qualquer coisa andar.

Agora leia por que falhou, porque essa é a falha pela qual as migrações são conhecidas. Uma coluna
`NOT NULL` sem default não pode ser acrescentada a uma tabela que tem linhas, já que toda linha existente
violaria a regra no instante em que a coluna aparecesse. Num banco vazio, o mesmo arquivo funciona: no
notebook de um colega novo, nos testes da aula 19, que partem do zero, e em toda verificação que nunca
encontra dados reais. **Uma migração que passa num banco vazio provou muito pouco.** Rode migrações novas
contra uma cópia de dados no formato dos de produção antes que a produção faça isso por você.

O caminho é dividir a mudança, e isso tem nome, **expandir e contrair** (*expand and contract*):

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 256\" role=\"img\" aria-label=\"Três versões da esquerda para a direita. A versão 1 expande: uma migração acrescenta uma coluna que aceita nulo, e o código novo a grava enquanto o antigo a ignora. A versão 2 preenche: uma migração dá a cada linha antiga o seu valor. A versão 3 contrai: uma migração torna a coluna obrigatória, quando não sobra nada sem valor.\"><defs><marker id=\"fx-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"120.0\" y=\"20\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" text-anchor=\"middle\" dominant-baseline=\"middle\">versão 1: expandir</text><rect x=\"15\" y=\"36\" width=\"210\" height=\"92\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"52\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\" text-anchor=\"middle\" dominant-baseline=\"middle\">migração</text><text x=\"120.0\" y=\"72\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"middle\" dominant-baseline=\"middle\">cria a tabela e uma</text><text x=\"120.0\" y=\"88\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"middle\" dominant-baseline=\"middle\">coluna que pode ficar vazia</text><text x=\"120.0\" y=\"110\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\" text-anchor=\"middle\" dominant-baseline=\"middle\">publisher_id bigint NULL</text><rect x=\"15\" y=\"140\" width=\"210\" height=\"64\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"156\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\" text-anchor=\"middle\" dominant-baseline=\"middle\">aplicação</text><text x=\"120.0\" y=\"174\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"middle\" dominant-baseline=\"middle\">o código novo grava;</text><text x=\"120.0\" y=\"190\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"middle\" dominant-baseline=\"middle\">o antigo ignora</text><text x=\"350.0\" y=\"20\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" text-anchor=\"middle\" dominant-baseline=\"middle\">versão 2: preencher</text><rect x=\"245\" y=\"36\" width=\"210\" height=\"92\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"52\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\" text-anchor=\"middle\" dominant-baseline=\"middle\">migração</text><text x=\"350.0\" y=\"72\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"middle\" dominant-baseline=\"middle\">dá a cada linha antiga</text><text x=\"350.0\" y=\"88\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"middle\" dominant-baseline=\"middle\">o seu valor</text><text x=\"350.0\" y=\"110\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\" text-anchor=\"middle\" dominant-baseline=\"middle\">UPDATE book SET ...</text><rect x=\"245\" y=\"140\" width=\"210\" height=\"64\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"156\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\" text-anchor=\"middle\" dominant-baseline=\"middle\">aplicação</text><text x=\"350.0\" y=\"174\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"middle\" dominant-baseline=\"middle\">todo o código grava;</text><text x=\"350.0\" y=\"190\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"middle\" dominant-baseline=\"middle\">as linhas antigas alcançam</text><text x=\"580.0\" y=\"20\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" text-anchor=\"middle\" dominant-baseline=\"middle\">versão 3: contrair</text><rect x=\"475\" y=\"36\" width=\"210\" height=\"92\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"580.0\" y=\"52\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\" text-anchor=\"middle\" dominant-baseline=\"middle\">migração</text><text x=\"580.0\" y=\"72\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"middle\" dominant-baseline=\"middle\">torna a coluna</text><text x=\"580.0\" y=\"88\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"middle\" dominant-baseline=\"middle\">obrigatória</text><text x=\"580.0\" y=\"110\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\" text-anchor=\"middle\" dominant-baseline=\"middle\">SET NOT NULL</text><rect x=\"475\" y=\"140\" width=\"210\" height=\"64\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"580.0\" y=\"156\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\" text-anchor=\"middle\" dominant-baseline=\"middle\">aplicação</text><text x=\"580.0\" y=\"174\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"middle\" dominant-baseline=\"middle\">não sobra nada</text><text x=\"580.0\" y=\"190\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"middle\" dominant-baseline=\"middle\">sem valor</text><line x1=\"15\" y1=\"226\" x2=\"685\" y2=\"226\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fx-ah)\"></line><text x=\"350.0\" y=\"244\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\" text-anchor=\"middle\" dominant-baseline=\"middle\">cada passo vai para produção, e é conferido, antes do próximo</text></svg>", "caption": "Expandir e contrair: uma mudança que o banco não aceita de uma vez, dividida em três versões, para que toda versão do código que roda encontre um esquema com que consegue trabalhar.", "same": []}
```

Cada passo é uma migração própria, publicada com a sua própria versão. O motivo das versões separadas é
que uma implantação nunca é instantânea: por um tempo, a versão antiga da aplicação e a nova rodam contra o
mesmo banco, e cada passo deixa um esquema com que as duas conseguem conviver. Renomear tem o mesmo
formato: acrescente a coluna nova, copie para ela, passe o código para ela e apague a coluna antiga numa
versão posterior, quando nada mais a lê.

Este V3 foi uma demonstração. Apague-o, para que a versão 3 fique livre para a de verdade da livraria, que
a aula 14 escreve:

```
ana@vm:~/bookshop$ rm src/main/resources/db/migration/V3__publisher.sql
ana@vm:~/bookshop$ mvn -B -q package -DskipTests
```
