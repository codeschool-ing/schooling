---
title: Updates, deletes e o que o log lembra de uma linha
version: 1
---

**O `before` de um update só é tão completo quanto o WAL do PostgreSQL o faz**, e por padrão o WAL
não guarda a linha antiga. Isso surpreende quem espera que um evento de mudança seja um diff. Venda
um exemplar do `bk-02` no Recife, depois tire o `bk-08` do catálogo da loja de Natal de vez:

@@fence@@

O snapshot ocupou os offsets 0 a 39 de `pf.public.stock`, então estes vão do 40 em diante. Leia
três:

@@fence@@

Três mensagens para dois comandos, e cada uma diz uma coisa diferente:

- **O update, offset 40**: `op` `u`, a linha nova no `after`, e o `before` é `null`. O WAL registrou
  a linha nova e nada sobre a antiga, então um leitor sabe que o Recife agora tem 2 exemplares e
  não consegue saber, pelo evento, que tinha 3.
- **O delete, offset 41**: `op` `d`, o `after` é `null`, e o `before` tem a chave e **um `qty` de
  0** — que não é o que a linha guardava. Com a configuração padrão, o WAL guarda só a chave de uma
  linha removida; o Debezium preenche as outras colunas, declaradas `NOT NULL`, com um valor de
  preenchimento. Um leitor que soma `before.qty` para saber o que foi removido obtém um número
  errado e nenhum erro.
- **O offset 42 é um tombstone**: a mesma chave, e um valor `null`. Não é um segundo delete.

## REPLICA IDENTITY

O que o WAL guarda de uma linha antiga é uma propriedade da tabela, a **replica identity** dela. O
`DEFAULT` guarda as colunas da chave primária, e só num update que muda a chave ou num delete. O
`FULL` guarda a linha antiga inteira, toda vez:

@@fence@@

A mesma venda de novo, e agora o `before` é a linha como era. A diferença entre `before` e `after` é
a própria venda — o Recife foi de 2 para 1 — então um consumidor consegue calcular o que mudou sem
guardar uma cópia da tabela:

@@fence@@

**FULL custa WAL**: todo update e todo delete agora gravam também a linha antiga, o que numa tabela
larga e movimentada é uma parte grande do volume de escrita do banco. Ligue-o nas tabelas cujos
consumidores precisam dos valores antigos, não no banco inteiro.

| replica identity | `before` no update | `before` no delete | WAL a mais |
|---|---|---|---|
| `DEFAULT` (chave primária) | `null` | a chave; as outras colunas com valores de preenchimento | nenhum |
| `FULL` | a linha antiga inteira | a linha antiga inteira | a linha antiga, em todo update e delete |
| `NOTHING` | — | — | nenhum; o PostgreSQL recusa o próprio `UPDATE` ou `DELETE` enquanto a tabela estiver numa publicação que os publica |

## Tombstones e compactação

O `null` depois do delete é para o Kafka, não para você. A lição 3 mostrou a **compactação**: num
tópico com `cleanup.policy=compact`, o Kafka acaba guardando só a mensagem mais recente de cada
chave. Uma tabela espelhada num tópico compactado combina bem — o tópico converge para uma mensagem
por linha, a atual — mas um evento de delete ainda é uma mensagem, então a compactação o guardaria
para sempre. **Um tombstone, uma chave com valor `null`, é como um produtor diz à compactação para
descartar a chave por inteiro**, e o Debezium grava um depois de todo delete;
`tombstones.on.delete=false` os desliga para tópicos que nunca são compactados.

Os tópicos desta lição foram criados pelo broker com os padrões dele, então usam
`cleanup.policy=delete`, e o tombstone é só mais uma mensagem. Um consumidor precisa esperar por
ele: um código que faz `json.loads(msg.value())["op"]` para com um `TypeError` no primeiro `None`.
Compactar os tópicos de CDC, e criá-los com as partições que você quer antes de o conector subir, é
o que uma instalação de produção faz, e o Connect pode fazer isso por você com as configurações
`topic.creation.*`. Isso não foi feito neste laboratório.
