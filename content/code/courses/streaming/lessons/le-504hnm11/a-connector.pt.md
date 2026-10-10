---
title: Um conector, da tabela ao tópico
version: 1
---

**Um conector do Debezium é configuração, não código.** Você escreve dois arquivos de propriedades —
um para o Kafka Connect, um para o conector — e o Connect faz o resto: conecta no PostgreSQL, copia
o que as tabelas têm agora e depois segue o log. Antes disso, o banco precisa ter algo para
capturar.

## Dois papéis e um banco

Dois usuários de banco, com direitos diferentes. O `ubuntu`, o seu próprio login, é dono das
tabelas; o `cdc` é o usuário com que o Debezium conecta, e ele pode entrar, replicar e ler, e nada
mais. A senha fica num arquivo deste laboratório, o que é aceitável para um laboratório e para nada
além disso:

@@fence@@

Como o usuário do sistema e o papel do banco têm o mesmo nome, `createdb` e `psql` agora funcionam
sem nomear usuário nem digitar senha; a autenticação **peer**, padrão do PostgreSQL, confia no
login. O `cdc` conecta por TCP, com a senha, como o Debezium vai fazer.

Os dados são o catálogo da Ponto Final e quantos exemplares de cada livro cada loja tem: oito
livros, cinco lojas, três exemplares de tudo. Salve isto como `~/work/stock.sql`:

@@fence@@

@@fence@@

Quarenta linhas de estoque e oito livros. **Toda tabela que o Debezium captura precisa de chave
primária**: ela vira a chave de cada mensagem no Kafka, então todas as mudanças de uma linha caem
numa partição, em ordem — a regra da lição 3, aplicada a linhas.

## O worker e o conector

O Kafka Connect roda de dois jeitos. O modo **distribuído** é um cluster de workers que dividem os
conectores e guardam configuração e posições em tópicos do Kafka; é como o Connect roda em produção.
O modo **standalone** é um processo só, que lê a configuração de arquivos e guarda a posição num
arquivo local, que é tudo de que um laboratório precisa. Salve a configuração do worker como
`~/work/connect.properties`:

@@fence@@

Os **conversores** decidem como uma mudança vira bytes. JSON com `schemas.enable=false` grava
objetos JSON simples, que o `jq` consegue ler na próxima seção; com `true`, cada mensagem também
leva uma descrição dos próprios campos, várias vezes maior que os dados. O Avro e o schema registry
da lição 6 são a resposta de produção para o mesmo problema. O `offset.storage.file.filename` é
onde o Connect standalone grava até onde o conector chegou; o slot no PostgreSQL guarda a mesma
posição do lado do banco.

E o conector, como `~/work/stock-connector.properties`:

@@fence@@

O `topic.prefix` dá nome aos tópicos: um por tabela, chamados `pf.public.books` e `pf.public.stock`,
prefixo, depois schema, depois tabela. `publication.autocreate.mode=disabled` faz o conector usar a
publicação que você criou em vez de criar uma para todas as tabelas, e `slot.name` é o slot que ele
vai criar na primeira vez que subir.

## Subindo

No seu **segundo shell**, dentro de `~/work`, suba o Connect com os dois arquivos. Ele escreve o log
no terminal, algumas centenas de linhas nos primeiros segundos, e continua rodando:

@@fence@@

No primeiro shell, pergunte ao próprio Connect. Todo worker tem uma interface REST na porta 8083, e
é assim que você descobre se um conector está rodando sem ler o log:

@@fence@@

`RUNNING` para o conector e para a única task dele. Um conector que não alcança o banco, ou é
recusado por ele, mostra `FAILED` aqui, com a exceção Java num campo `trace`; esse campo é a
primeira coisa a ler quando algo dá errado. Depois veja o que existe agora, dos dois lados:

@@fence@@

@@fence@@

Dois tópicos que ninguém criou à mão, um por tabela: o broker os criou no momento em que o conector
escreveu neles pela primeira vez, porque a criação automática de tópicos vem ligada por padrão. Eles
têm uma partição cada, o padrão deste laboratório; uma instalação de produção os cria antes, ou
deixa o Connect criá-los com as partições que mandarem. E no PostgreSQL há um slot, `active`, o que
quer dizer que alguém o está lendo agora. **A partir deste momento, toda mudança em `books` e
`stock` está a caminho do Kafka**, e a próxima seção lê uma.
