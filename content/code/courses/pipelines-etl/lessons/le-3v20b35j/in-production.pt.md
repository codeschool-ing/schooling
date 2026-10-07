---
title: Captura de mudanças em produção
version: 1
---

A versão do laboratório tem todas as peças móveis da captura de mudanças e nada da engenharia. O
que uma montagem de produção acrescenta, peça por peça, vale conhecer antes mesmo de encontrar uma.

**O plugin.** O `pgoutput`, embutido no PostgreSQL, manda as mudanças num formato binário pelo
protocolo de replicação e as filtra por uma **publicação** — `CREATE PUBLICATION wh FOR TABLE
customers, orders` — para o leitor receber só as tabelas que pediu. O `wal2json` é uma alternativa
comum que escreve JSON. O `test_decoding` é para aprender.

**A primeira cópia.** O laboratório copiou os clientes depois de criar o slot e contou com o script
de aplicação ser seguro de repetir. A versão exata cria o slot pelo protocolo de replicação e pede ao
PostgreSQL que **exporte o snapshot** em que ele foi criado: a cópia inicial então lê exatamente o
momento de onde o fluxo parte, e nada é perdido nem aplicado duas vezes.

**O leitor.** O Debezium é o leitor de código aberto mais conhecido: ele se conecta como cliente de
replicação, tira o snapshot inicial, segue o slot e transforma cada mudança numa mensagem — no Kafka,
como uma fonte do Kafka Connect, ou em outros transportes pelo Debezium Server. Cada mensagem traz a
linha antiga, a nova, a operação, a tabela e o LSN, que é a mesma informação que as linhas do
laboratório trazem, em JSON. **Nada disso rodou no laboratório**: nem Kafka, nem Kafka Connect, nem
Debezium. O que está descrito aqui vem da documentação deles, não de uma gravação.

**Onde as mudanças caem.** Quase nunca direto numa tabela do warehouse. As mudanças vão para um log
(o Kafka, ou uma tabela crua de linhas de mudança) e a tabela do warehouse é montada a partir desse
log, para que o histórico de cada linha fique guardado e a cópia possa ser reconstruída. É a camada
crua da lição 2 de novo, uma linha por mudança em vez de uma por extração.

## Uma origem diferente: o outbox

Às vezes a resposta mais limpa é não ler as tabelas da origem. No **padrão outbox** a aplicação
escreve, na mesma transação da sua própria mudança, uma linha que a descreve numa tabela `outbox`:
*o pedido 117013 foi estornado, valor, motivo*. A captura lê só essa tabela. Os eventos são
desenhados por quem os entende, as tabelas internas podem ser reorganizadas à vontade, e o pipeline
deixa de depender de como a loja guarda um pedido.

O preço é que a aplicação precisa fazer isso, o que torna o assunto uma conversa com os
desenvolvedores da origem. **Para um banco que é de outra pessoa e não vai mudar, captura sobre as
tabelas é a ferramenta; para uma aplicação que vocês constroem juntos, o outbox costuma ser o
contrato melhor.**
