---
title: Onde cada forma é guardada
version: 1
---

**Cada forma tem um tipo de armazenamento construído em volta dela, e o tipo decide quais perguntas
saem baratas.** Esta seção dá nome a três, para você reconhecê-los num diagrama de arquitetura. Onde
outro curso vai mais longe, ele é citado quando aparece, e nenhum dos três é ensinado aqui.

## Um banco de dados relacional, para dado estruturado

Um **banco de dados relacional** guarda tabelas com esquemas declarados, e os impõe em toda escrita:
tipos, colunas obrigatórias, unicidade, a regra de que o `bike_id` de uma viagem aponta para uma
bicicleta que existe. PostgreSQL e MySQL são os servidores comuns. O SQLite é a mesma ideia num arquivo
só, e vem dentro do Python, com uma diferença que vale saber: a não ser que a tabela seja declarada
`STRICT`, o SQLite guarda um valor do tipo errado em vez de recusá-lo. Você faz perguntas a ele em SQL,
e o banco descobre como respondê-las. É aqui que o aplicativo da Roda Livre guarda viagens e
pagamentos, e é o assunto de `sql-databases`. O warehouse, o banco feito para análise em vez de para
rodar o aplicativo, é `warehouse-modeling`.

## Um banco de documentos, para dado semiestruturado

Um **banco de documentos** guarda documentos JSON, agrupados em coleções, e não exige que dois
documentos de uma coleção tenham os mesmos campos. O MongoDB é o exemplo mais conhecido. Ele consegue
achar documentos por um campo lá no fundo deles, como toda viagem cujo `bike.battery` está abaixo de
20, sem que ninguém tenha achatado nada antes. O preço é o desta aula: nada impediu um documento com
`"battery": "58%"` de entrar, então toda consulta precisa lidar com ele.

A linha entre os dois não é nítida. O PostgreSQL tem um tipo de coluna, `jsonb`, que guarda um
documento JSON dentro de uma linha de uma tabela comum, então um mesmo banco consegue manter uma tabela
declarada e documentos soltos lado a lado.

## Armazenamento de objetos, para qualquer coisa

O **armazenamento de objetos** guarda arquivos, chamados objetos, sob nomes chamados chaves, e não
olha dentro deles. Uma foto, um e-mail, uma gravação de ligação, um arquivo JSON Lines com os eventos
de um dia, um arquivo Parquet: para o armazenamento, tudo isso são bytes com um nome. O Amazon S3 é o
serviço que popularizou a ideia, e toda nuvem grande tem o seu. Ele é barato por gigabyte, cresce sem
ninguém planejar um disco, e não consegue responder pergunta nenhuma sobre o que há dentro de um
objeto. Isso é trabalho de quem o lê.

Essa combinação é a razão de a zona bruta da seção anterior costumar morar num armazenamento de
objetos, e de um **data lake** ser, na maior parte, armazenamento de objetos com um acordo sobre onde
cada coisa vai. Os serviços de nuvem são `cloud`; os formatos que tornam rápido consultar um arquivo
guardado ali, por guardá-lo em colunas, são a aula 6.

## Uma empresa, os três

| guardado em | na Roda Livre | a forma |
|---|---|---|
| um banco de dados relacional | viagens, pagamentos, clientes, a lista de estações | estruturado |
| um banco de documentos, ou colunas `jsonb` | eventos do aplicativo guardados para o suporte pesquisar | semiestruturado |
| armazenamento de objetos | arquivos brutos de eventos, fotos, e-mails, gravações de ligações | qualquer uma, com metadados ao lado |

A maioria das empresas de algum tamanho tem os três, e o trabalho do engenheiro de dados corre entre
eles: dos objetos e dos documentos para as tabelas, sem perder os originais pelo caminho.
