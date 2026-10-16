---
title: O que você montou, nas palavras deles
version: 1
---

Cada parte do `sync.sh` tem um nome nos produtos. As palavras mudam de fornecedor para fornecedor, e
algumas mudam entre destinos do mesmo fornecedor, então a tabela dá o termo documentado quando há um:

| na aula 7 | Hightouch | Census (Fivetran Activations) | Segment Reverse ETL |
|---|---|---|---|
| `activation.crm_contacts` | um model | um model | um model |
| o CRM | uma destination | uma destination | uma destination |
| `external_id`, casado pelo `PUT` | um record matching field | o identificador pelo qual se casa | o identificador do destino, no mapeamento |
| o que a sincronização faz com uma linha | um sync mode: upsert, update, insert | um sync behavior: Update or Create, Update Only, Create Only, Mirror | registros a mandar: added, updated, added or updated, deleted |
| um contato que saiu do modelo | delete behavior: Do nothing, Clear fields, Delete destination record | o Mirror o apaga | a opção de registros *deleted* |
| `last_sent` e a diferença | guardados pelo produto; com o motor Lightning, num schema do seu warehouse | guardados pelo produto: as sincronizações são incrementais | uma coluna Unique Identifier, usada para detectar linhas novas, alteradas e apagadas |
| `sync_log` | a página de cada execução, com as linhas acrescentadas, alteradas e removidas | o histórico da sincronização | a página de cada sincronização: extraídas, acrescentadas, alteradas, apagadas |

Três coisas nessa tabela merecem uma segunda leitura.

- **A diferença é do produto, não sua.** O `last_sent` era uma tabela que você podia consultar; num
  produto, é estado que o produto guarda. O motor Lightning do Hightouch o guarda no seu warehouse, num
  schema chamado `hightouch_planner` em que ele precisa poder escrever, e a documentação avisa que apagar
  essas tabelas força um full resync. Cada um oferece um jeito de jogá-lo fora — o Segment chama
  de reset, o Hightouch de full resync —, o que faz a próxima execução mandar tudo, exatamente como rodar
  `activation.sql` de novo.
- **O Unique Identifier do Segment é a chave da diferença, não a chave de casamento.** Ele diz ao Segment
  qual linha do modelo é qual entre execuções. Em qual registro do destino uma linha cai é outra escolha,
  no mapeamento. A aula 7 usou um id só para as duas coisas, que é o arranjo a buscar.
- **Upsert é um modo que você escolhe.** Uma sincronização *insert* ou *Create Only* é o `POST` da aula
  7: certa para um destino que só recebe registros novos, como uma lista de eventos, e três registros
  para `lantern-10` em qualquer outro.

O agendamento é a última peça. O `sync.sh` rodava quando você o digitava. A documentação do Hightouch
lista cinco tipos de agendamento: manual, um intervalo, uma expressão cron, e depois de um job do dbt
Cloud ou da Fivetran terminar. Os dois últimos são os preferíveis quando o modelo é feito por um job
desses, pelo motivo da aula 6: uma sincronização que roda antes de o modelo estar atualizado manda os
números de ontem na hora certa.
