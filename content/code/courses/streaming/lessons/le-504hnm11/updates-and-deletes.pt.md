---
title: Updates, deletes e o que o log lembra de uma linha
version: 1
---

**O `before` de um update só é tão completo quanto o WAL do PostgreSQL o faz**, e por padrão o WAL
não guarda a linha antiga. Isso surpreende quem espera que um evento de mudança seja um diff. Venda
um exemplar do `bk-02` no Recife, depois tire o `bk-08` do catálogo da loja de Natal de vez:

```
ubuntu@stream:~/work$ psql pontofinal -c "UPDATE stock SET qty = qty - 1 WHERE shop = 'recife' AND book = 'bk-02'"
UPDATE 1
ubuntu@stream:~/work$ psql pontofinal -c "DELETE FROM stock WHERE shop = 'natal' AND book = 'bk-08'"
DELETE 1
```

O snapshot ocupou os offsets 0 a 39 de `pf.public.stock`, então estes vão do 40 em diante. Leia
três:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic pf.public.stock --partition 0 --offset 40 --max-messages 3 --formatter-property print.key=true
{"shop":"recife","book":"bk-02"}	{"before":null,"after":{"shop":"recife","book":"bk-02","qty":2},"source":{"version":"3.7.0.Final","connector":"postgresql","name":"pf","ts_ms":1792111155764,"snapshot":"false","db":"pontofinal","sequence":"[\"83294528\",\"83294528\"]","ts_us":1792111155764257,"ts_ns":1792111155764257000,"schema":"public","table":"stock","txId":811,"lsn":83294528,"xmin":null,"origin":null,"origin_lsn":null},"transaction":null,"op":"u","ts_ms":1792111156082,"ts_us":1792111156082431,"ts_ns":1792111156082431164}
{"shop":"natal","book":"bk-08"}	{"before":{"shop":"natal","book":"bk-08","qty":0},"after":null,"source":{"version":"3.7.0.Final","connector":"postgresql","name":"pf","ts_ms":1792111155818,"snapshot":"false","db":"pontofinal","sequence":"[\"83294664\",\"83294664\"]","ts_us":1792111155818097,"ts_ns":1792111155818097000,"schema":"public","table":"stock","txId":812,"lsn":83294664,"xmin":null,"origin":null,"origin_lsn":null},"transaction":null,"op":"d","ts_ms":1792111156083,"ts_us":1792111156083916,"ts_ns":1792111156083916457}
{"shop":"natal","book":"bk-08"}	null
Processed a total of 3 messages
```

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

```
ubuntu@stream:~/work$ psql pontofinal -c "ALTER TABLE stock REPLICA IDENTITY FULL"
ALTER TABLE
```

A mesma venda de novo, e agora o `before` é a linha como era. A diferença entre `before` e `after` é
a própria venda — o Recife foi de 2 para 1 — então um consumidor consegue calcular o que mudou sem
guardar uma cópia da tabela:

```
ubuntu@stream:~/work$ psql pontofinal -c "UPDATE stock SET qty = qty - 1 WHERE shop = 'recife' AND book = 'bk-02'"
UPDATE 1
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic pf.public.stock --partition 0 --offset 43 --max-messages 1 | jq -c '{op, before, after}'
Processed a total of 1 messages
{"op":"u","before":{"shop":"recife","book":"bk-02","qty":2},"after":{"shop":"recife","book":"bk-02","qty":1}}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Os offsets 40 a 43 do tópico pf.public.stock, como capturados nesta lição. Offset 40, um update com a replica identity padrão: before é null, after tem o bk-02 do Recife com qty 2. Offset 41, um delete do bk-08 de Natal: before tem a chave e um qty 0 que é preenchimento, after é null. Offset 42, um tombstone: a mesma chave e um valor null. Offset 43, um update depois de REPLICA IDENTITY FULL: before tem qty 2 e after qty 1.\" data-fig=\"l14-before-after\"><text x=\"98\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">offset 40</text><rect x=\"20\" y=\"45\" width=\"156\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"98\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">update, DEFAULT</text><text x=\"98\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">before: null</text><text x=\"98\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">after: qty 2</text><text x=\"98\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a linha antiga é desconhecida</text><text x=\"270\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">offset 41</text><rect x=\"192\" y=\"45\" width=\"156\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">delete, DEFAULT</text><text x=\"270\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">before: qty 0</text><text x=\"270\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">after: null</text><text x=\"270\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">preenchimento, não o 3 real</text><text x=\"442\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">offset 42</text><rect x=\"364\" y=\"45\" width=\"156\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"442\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">tombstone</text><text x=\"442\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">key: natal, bk-08</text><text x=\"442\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">value: null</text><text x=\"442\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">só a chave: para a compactação</text><text x=\"614\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">offset 43</text><rect x=\"536\" y=\"45\" width=\"156\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"614\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">update, FULL</text><text x=\"614\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">before: qty 2</text><text x=\"614\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">after: qty 1</text><text x=\"614\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">a linha antiga inteira</text></svg>", "caption": "O que cada evento diz sobre a linha antes da mudança depende da replica identity da tabela, não do Debezium.", "same": ["offset 40", "offset 41", "offset 42", "offset 43", "update, DEFAULT", "delete, DEFAULT", "tombstone", "update, FULL"]}
```

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
