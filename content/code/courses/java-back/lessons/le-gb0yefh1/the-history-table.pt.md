---
title: A tabela de histórico e os seus checksums
version: 1
---

Tudo o que o Flyway sabe sobre este banco está numa tabela que ele criou e em que nada mais escreve.
Peça para vê-la:

```
ana@vm:~/bookshop$ psql postgresql://bookshop:bookshop@localhost/bookshop -c 'select installed_rank, version, description, script, checksum, success from flyway_schema_history'
 installed_rank | version | description  |        script        |  checksum  | success 
----------------+---------+--------------+----------------------+------------+---------
              1 | 1       | catalogue    | V1__catalogue.sql    | 2131081588 | t
              2 | 2       | first titles | V2__first_titles.sql | -765405402 | t
(2 rows)
```

Uma linha por migração aplicada, na ordem em que foram aplicadas. `installed_rank` é essa ordem,
`version` e `description` vêm do nome do arquivo, `script` é o próprio nome, e `success` diz que ela
terminou. A coluna que faz o trabalho é o **`checksum`**, um número que o Flyway calcula a partir do
conteúdo do arquivo quando o aplica, para depois poder dizer se o arquivo que está vendo ainda é o
arquivo que rodou.

A cada partida, o Flyway percorre lado a lado as migrações que encontra no jar e as linhas desta tabela:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 256\" role=\"img\" aria-label=\"Flyway na partida: à esquerda, três arquivos de migração no jar; à direita, duas linhas da flyway_schema_history. V1 e V2 batem com as linhas pelo checksum e são pulados. V3 não tem linha, então é aplicado e uma terceira linha é registrada.\"><defs><marker id=\"fh-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"24\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\" dominant-baseline=\"middle\">no jar: db/migration</text><text x=\"460\" y=\"24\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\" dominant-baseline=\"middle\">no banco</text><rect x=\"20\" y=\"44\" width=\"220\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"34\" y=\"62\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"start\" dominant-baseline=\"middle\">V1__catalogue.sql</text><rect x=\"20\" y=\"100\" width=\"220\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"34\" y=\"118\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"start\" dominant-baseline=\"middle\">V2__first_titles.sql</text><rect x=\"20\" y=\"156\" width=\"220\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"34\" y=\"174\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"start\" dominant-baseline=\"middle\">V3__next_change.sql</text><rect x=\"460\" y=\"44\" width=\"220\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"474\" y=\"62\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"start\" dominant-baseline=\"middle\">1 · 2131081588</text><rect x=\"460\" y=\"100\" width=\"220\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"474\" y=\"118\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"start\" dominant-baseline=\"middle\">2 · -765405402</text><rect x=\"460\" y=\"156\" width=\"220\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"474\" y=\"174\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\" text-anchor=\"start\" dominant-baseline=\"middle\">3 · gravada depois que V3 roda</text><line x1=\"242\" y1=\"62\" x2=\"458\" y2=\"62\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"2 3\"></line><text x=\"350\" y=\"53\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\" text-anchor=\"middle\" dominant-baseline=\"middle\">mesmo checksum: pula</text><line x1=\"242\" y1=\"118\" x2=\"458\" y2=\"118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"2 3\"></line><text x=\"350\" y=\"109\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\" text-anchor=\"middle\" dominant-baseline=\"middle\">mesmo checksum: pula</text><line x1=\"242\" y1=\"174\" x2=\"456\" y2=\"174\" stroke=\"var(--amber)\" stroke-width=\"1.6\" marker-end=\"url(#fh-ah)\"></line><text x=\"350\" y=\"165\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\" text-anchor=\"middle\" dominant-baseline=\"middle\">sem linha: aplica e registra</text><text x=\"350\" y=\"236\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\" text-anchor=\"middle\" dominant-baseline=\"middle\">Uma linha cujo checksum difere do arquivo interrompe a partida antes de aplicar qualquer coisa.</text></svg>", "caption": "O que o Flyway compara a cada partida: cada arquivo com a sua linha. Só um arquivo sem linha roda.", "same": []}
```

Pare a aplicação com Ctrl+C e inicie de novo. Os dois arquivos têm uma linha com o mesmo checksum, então
não há nada a fazer, e o Flyway diz isso:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar | grep -E 'o\.f\.'
2026-10-22T19:30:02.279-03:00  INFO 16715 --- [bookshop] [           main] o.f.core.internal.command.DbValidate     : Successfully validated 2 migrations (execution time 00:00.018s)
2026-10-22T19:30:02.319-03:00  INFO 16715 --- [bookshop] [           main] o.f.core.internal.command.DbMigrate      : Current version of schema "public": 2
2026-10-22T19:30:02.321-03:00  INFO 16715 --- [bookshop] [           main] o.f.core.internal.command.DbMigrate      : Schema "public" is up to date. No migration necessary.
```

## Editando uma migração que já rodou

Agora um erro comum. Alguém percebe que Frankenstein deveria custar 36,00 e não
35,00, abre o `V2__first_titles.sql` e corrige lá, porque é lá que o preço está escrito. Pare a
aplicação e faça o mesmo:

```
ana@vm:~/bookshop$ sed -i 's/3500/3600/' src/main/resources/db/migration/V2__first_titles.sql
ana@vm:~/bookshop$ mvn -B -q package -DskipTests
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar | grep -m1 -A3 'checksum mismatch'
Migration checksum mismatch for migration version 2
-> Applied to database : -765405402
-> Resolved locally    : 1463101623
Either revert the changes to the migration, or run repair to update the schema history.
```

**O Flyway se recusou a iniciar.** O arquivo não bate mais com a linha que o registrou. Este banco rodou o V2 antigo e guarda 3500; um banco criado amanhã rodaria o V2
novo e guardaria 3600. Dois bancos montados a partir do que parece o mesmo conjunto de arquivos
discordariam, e nada jamais diria qual está errado. O checksum é como o Flyway percebe que a história foi
reescrita, e ele para antes de qualquer estrago.

A mensagem oferece duas saídas, e só uma delas é uma correção:

- **Voltar o arquivo.** Uma migração aplicada é o registro do que aconteceu; a correção é uma migração
  nova, a próxima versão, com um `UPDATE` dentro. Todo banco recebe então os mesmos dois passos, na mesma
  ordem.
- **`repair`** reescreve o checksum guardado para bater com o arquivo. Ele não roda nada, então o banco
  fica com 3500 enquanto o arquivo diz 3600. É a ferramenta certa só quando a edição não mudou nada que o
  banco teria feito, como um comentário, ou para limpar a linha que uma migração com falha deixou num
  banco que não consegue desfazer DDL.

**Nunca edite uma migração que já rodou em qualquer lugar além da sua própria máquina.** Na sua máquina,
antes de compartilhar, editar não tem problema: você apaga e recria o seu próprio banco, como a seção
anterior fez, e ninguém mais viu a versão antiga. Quando uma migração está no banco de outra pessoa, ela
é história, e história se corrige acrescentando.

Ponha o preço de volta, para que o arquivo seja o que rodou:

```
ana@vm:~/bookshop$ sed -i 's/3600/3500/' src/main/resources/db/migration/V2__first_titles.sql
ana@vm:~/bookshop$ mvn -B -q package -DskipTests
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar | grep -E 'o\.f\.|Started'
2026-10-22T19:30:15.616-03:00  INFO 17238 --- [bookshop] [           main] o.f.core.internal.command.DbValidate     : Successfully validated 2 migrations (execution time 00:00.027s)
2026-10-22T19:30:15.649-03:00  INFO 17238 --- [bookshop] [           main] o.f.core.internal.command.DbMigrate      : Current version of schema "public": 2
2026-10-22T19:30:15.652-03:00  INFO 17238 --- [bookshop] [           main] o.f.core.internal.command.DbMigrate      : Schema "public" is up to date. No migration necessary.
2026-10-22T19:30:17.657-03:00  INFO 17238 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 4.654 seconds (process running for 5.124)
```

Os checksums voltam a concordar, e a aplicação inicia. A correção em si, se a loja a quisesse, seria a
próxima migração, e a próxima migração é o V3 de verdade da livraria, que a aula 14 escreve.
