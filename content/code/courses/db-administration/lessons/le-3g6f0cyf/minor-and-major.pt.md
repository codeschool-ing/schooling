---
title: Dois tipos de upgrade
version: 1
---

Um número de versão do PostgreSQL tem duas partes, e elas significam dois trabalhos diferentes. Em
`16.15`, **`16` é a versão maior** e **`15` é a versão menor**: o décimo quinto conjunto de correções
publicado para o 16. A lição 3 pediu que você lesse essa string uma vez; esta lição é o porquê.

O erro que vale nomear primeiro é tratar os dois como versões maior e menor da mesma operação. Não
são. Um upgrade menor troca os programas e deixa cada arquivo do cluster como estava. Um upgrade
maior não pode fazer isso, porque os programas novos não entendem os arquivos antigos.

## Uma versão menor

Uma versão menor traz correções de bugs e de segurança, **nunca recursos novos e nunca uma mudança
no formato em disco**. O 16.15 lê exatamente o diretório de dados que o 16.2 escreveu. Então o
upgrade tem três passos: instalar os binários novos, reiniciar o servidor, conferir a versão. O
reinício é a única parada, e dura segundos.

O projeto publica versões menores de todas as versões maiores com suporte num calendário
trimestral, em fevereiro, maio, agosto e novembro, com versões extras quando um problema de
segurança não pode esperar. Elas são **cumulativas**: o 16.15 contém tudo o que há do 16.3 ao 16.14,
então um servidor no 16.2 vai direto para o 16.15 sem passar pelas versões do meio. O Ubuntu empacota
cada uma como uma atualização comum, e foi assim que o seu servidor chegou ao 16.15 na lição 3.

## Uma versão maior

Uma versão maior chega uma vez por ano, no outono do hemisfério norte, e traz os recursos novos. Ela
também muda o **catálogo do sistema** — as tabelas em que o PostgreSQL descreve as suas tabelas,
colunas, tipos e funções — e às vezes o formato de outros arquivos do diretório de dados. **O
PostgreSQL 17 se recusa a subir num diretório de dados que o 16 criou**, e a seção 05 desta lição
mostra a recusa. Alguma coisa tem de levar os dados para o outro lado, e há três maneiras de fazer
isso:

| | como funciona | parada | o caminho de volta |
|---|---|---|---|
| **pg_upgrade** | monta um catálogo novo e reaproveita os arquivos de dados, copiados ou ligados | de segundos a minutos, quase independente do tamanho quando ligados | o cluster antigo, se os arquivos foram copiados; um backup, se foram ligados |
| **dump e restore** | escreve tudo como SQL e carrega na versão nova | cresce com o tamanho dos dados | o cluster antigo, intocado |
| **replicação lógica** | um servidor novo assina o antigo e acompanha as mudanças | o momento da troca, segundos | o servidor antigo, ainda rodando |

Cada versão maior tem suporte do projeto por **cinco anos** depois do lançamento: as correções
continuam chegando como versões menores, e então param. O 16 foi lançado em setembro de 2023 e tem
suporte até novembro de 2028. Um servidor numa versão maior sem suporte não recebe correção de
segurança nenhuma, e esse é o prazo que costuma decidir quando um upgrade maior acontece.

**O Ubuntu não muda a versão maior dentro de uma versão do sistema.** O Ubuntu 24.04 traz o 16 pela
vida inteira, e o `apt upgrade` traz cada versão 16.x nova, mas nunca o 17. Uma versão maior mais nova
vem do repositório do próprio projeto PostgreSQL, de um Ubuntu mais novo ou do botão de upgrade de um
serviço gerenciado, e a seção 05 a instala pelo primeiro desses caminhos.

Antes do PostgreSQL 10 a versão maior tinha dois números: 9.5 e 9.6 eram versões maiores
diferentes, e 9.6.24 era uma versão menor do 9.6. Você ainda vai encontrar servidores assim, e a
mesma regra vale para os dois primeiros números ali.
