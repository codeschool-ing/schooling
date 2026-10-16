---
title: Os padrões de acesso vêm antes da tabela
version: 1
---

**Num banco relacional você modela os dados e as perguntas vêm depois; no DynamoDB você lista as
perguntas primeiro.** É a inversão a que as pessoas resistem, porque normalizar entidades é uma
habilidade que elas já têm e parece projeto. Aqui não basta. Uma tabela cujas chaves foram escolhidas
antes de alguém escrever como ela seria lida responde bem a uma pergunta, por sorte, e responde às
outras com um scan de todos os itens.

**Um padrão de acesso é uma pergunta, escrita com suas entradas e o tamanho esperado.** Não "pedidos",
mas "os pedidos de um cliente num intervalo de datas, do mais novo para o mais antigo, algumas dezenas
no máximo". As entradas dizem de que a chave tem de ser feita; o tamanho diz se uma leitura basta; a
ordem diz pelo que a chave de ordenação tem de ordenar. O app e o back office da Quitanda precisam de
cinco:

| | a pergunta | recebe | devolve |
|---|---|---|---|
| A1 | o perfil de um cliente | o id do cliente | um item |
| A2 | os pedidos de um cliente num intervalo de datas, com as linhas | o id e duas datas | algumas dezenas de itens |
| A3 | um pedido e suas linhas | o id do cliente, a data e o id do pedido | até dez itens |
| A4 | o pedido mais recente de um cliente | o id do cliente | um pedido |
| A5 | todos os pedidos feitos num dia, de todos os clientes | uma data | centenas de itens |

**Cada padrão vira uma condição de chave, ou vira um problema.** A1 é um `get-item` em
`CUSTOMER#<id>` e `PROFILE`. A2 é uma `query` na mesma chave de partição com a chave de ordenação
entre dois prefixos, o que só funciona se a chave de ordenação começar pela data. A3 é a mesma chave de
partição com a chave de ordenação começando pelo prefixo de um pedido, o que só funciona se as linhas
ficarem logo abaixo do pedido. A4 é o A2 lido ao contrário com limite um, e as próximas seções mostram
que o projeto abaixo o deixa sutilmente errado, que é exatamente o tipo de coisa que escrever os
padrões encontra cedo.

**O A5 é o que esta tabela não consegue responder.** O cliente é a chave de partição, e uma pergunta que
não parte de um cliente não consegue nomear uma partição, então o único jeito de respondê-la com esta
tabela é um scan. Ele fica na lista de propósito. A lição 10 acrescenta o índice que o responde, e põe
preço no que o scan custaria; um padrão que a tabela não atende é uma decisão a tomar por escrito, não
uma surpresa achada em produção.

## O que um padrão não leva em conta

**Um padrão não menciona entidades, tabelas nem joins.** "O pedido e suas linhas" é uma pergunta só,
embora um modelo relacional chame isso de duas tabelas e um join. É isso que permite atendê-la com uma
leitura: as linhas ficam guardadas onde o pedido está, ordenadas ao lado dele, e a query que devolve
um devolve as outras. O preço é pago em outro lugar. Os dados se repetem onde dois padrões precisam
deles em duas formas, e uma pergunta que ninguém listou não tem onde se apoiar.

**Escrever a lista também é como se descobre que o DynamoDB é o armazenamento errado.** Se as
perguntas são improvisadas, mudam toda semana, ou agregam sobre tudo, "a receita por bairro neste
mês", um armazenamento lido por chave está brigando com a carga. Essas pertencem ao data warehouse e ao
lago das lições 14 a 19, muitas vezes alimentados por esta tabela, e a lição 12 mostra o stream que faz
essa alimentação.
