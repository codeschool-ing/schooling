---
title: Ensaie numa cópia
version: 1
---

Um upgrade maior falha de jeitos que um menor não consegue. Uma extensão não tem versão compilada
para a versão nova. Um parâmetro do `postgresql.conf` mudou de nome. O disco tem espaço para uma
cópia dos dados e o método escolhido precisa de duas. A aplicação usa uma função cujo comportamento
mudou. **Cada uma dessas coisas é barata de achar numa cópia e cara de achar no servidor que todo
mundo usa**, por isso um upgrade maior sempre roda pelo menos uma vez em algo que não é produção.

A melhor cópia é uma máquina separada, restaurada do backup da noite anterior, porque isso também
prova que o backup funciona; restaurar um é o assunto das lições 1 a 10 de db-reliability. No seu
servidor há uma cópia mais barata que ensina os mesmos passos: **um segundo cluster ao lado do
`16/main`**, feito só para esta lição. A lição 3 disse que o postgresql-common roda vários clusters
lado a lado, e é para isso que serve. O `16/main` nunca é parado, nunca passa por upgrade e nunca
recebe uma escrita no que vem a seguir. Anote quando ele subiu pela última vez, para que o fim da
lição possa provar isso:

@@1@@

## Um segundo cluster

@@2@@

O `pg_createcluster` rodou o `initdb` para um diretório de dados novo, escreveu uma configuração em
`/etc/postgresql/16/rehearsal` e **escolheu a próxima porta livre, 5433**, porque o `main` ocupa a
5432. Todo comando dirigido ao ensaio daqui em diante leva `-p 5433`; um comando sem isso vai para o
`main`.

@@3@@

O cluster novo está vazio: tem o papel `postgres` e mais nada, nem um papel para você. Copie tudo
num pipe só. O `pg_dumpall` escreve o `main` inteiro como SQL — primeiro os papéis, depois cada
banco — e o `psql` no ensaio executa isso:

@@4@@

O único erro é esperado. O dump começa criando o papel `postgres`, e o cluster novo já tem um, então
esse comando falha e o resto segue. O `>/dev/null` jogou fora a saída comum dos comandos; um erro vai
para a outra saída e teria aparecido do mesmo jeito. O milhão de pedidos chegou.

## Deixe parecido com produção

Um ensaio vale o quanto se parece com a coisa real, e o que mais provavelmente quebra um upgrade
maior é uma **extensão**. Pergunte a cada banco do servidor real com `\dx` e dê à cópia a mesma
lista. Se as extensões que as lições 15 e 18 criaram ainda estão no seu `shop`, a cópia as trouxe
junto, e a recusa da próxima seção vai nomear mais delas do que a gravação. **O `shop` da máquina da
gravação não tem nenhuma**, então ela deu ao ensaio duas que representam os dois tipos que existem.
A `pg_stat_statements` vem com o próprio PostgreSQL, em toda versão. A `pg_repack`, que a lição 15
usou, é um projeto separado, empacotado uma vez para cada versão maior, como `postgresql-16-repack`:

@@5@@

@@6@@

Guarde esses dois números de versão, `1.5.0` e `1.10`. A próxima seção faz o upgrade deste cluster
para o 17, e cada extensão causa um problema diferente lá.
