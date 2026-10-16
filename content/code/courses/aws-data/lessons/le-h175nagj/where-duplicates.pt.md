---
title: De onde vêm os duplicados
version: 1
---

**Um duplicado não é um bug do stream; é o que um retry correto produz.** Quatro lugares os fazem nos
pipelines deste curso, e cada um está fazendo a coisa certa quando faz.

## O produtor que tenta de novo

Um produtor manda `PutRecord` e espera a resposta. Se a resposta se perde, porque a conexão caiu ou a
chamada estourou o tempo, o produtor não tem como distinguir um registro que nunca foi escrito de um
que foi escrito e cuja confirmação sumiu. O único movimento seguro é mandar de novo, e se o primeiro
tinha sido escrito, o shard agora o tem duas vezes. Os SDKs da AWS tentam de novo sozinhos, então isso
acontece sem uma linha do código do produtor pedir.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Um produtor e um shard ao longo do tempo. O produtor manda PutRecord de o-301; o shard o escreve como número de sequência 1 e manda uma confirmação, que se perde na volta. O produtor estoura o tempo, não sabe se o registro foi escrito, e o manda de novo; o shard o escreve como número de sequência 2 e esta confirmação chega. O shard agora guarda o-301 duas vezes, sob dois números de sequência.\" data-fig=\"l23-retry\"><text x=\"160.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">produtor</text><text x=\"560.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">shard</text><line x1=\"160.0\" y1=\"30.0\" x2=\"160.0\" y2=\"235.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></line><line x1=\"560.0\" y1=\"30.0\" x2=\"560.0\" y2=\"235.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></line><line x1=\"160.0\" y1=\"50.0\" x2=\"554.0\" y2=\"69.7\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></line><polygon points=\"560.0,70.0 554.2,66.7 553.9,72.7\" fill=\"var(--phosphor)\" stroke=\"none\"></polygon><text x=\"180.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">PutRecord o-301</text><rect x=\"570.0\" y=\"60.0\" width=\"130.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">escrito: seq 1</text><line x1=\"560.0\" y1=\"90.0\" x2=\"380.0\" y2=\"104.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><text x=\"380.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">confirmação perdida</text><rect x=\"10.0\" y=\"120.0\" width=\"140.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"80.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">timeout: escrito ou não?</text><line x1=\"160.0\" y1=\"160.0\" x2=\"554.0\" y2=\"179.7\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></line><polygon points=\"560.0,180.0 554.2,176.7 553.9,182.7\" fill=\"var(--phosphor)\" stroke=\"none\"></polygon><text x=\"180.0\" y=\"152.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">PutRecord o-301</text><text x=\"300.0\" y=\"152.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o mesmo registro, de novo</text><rect x=\"570.0\" y=\"170.0\" width=\"130.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">escrito: seq 2</text><line x1=\"560.0\" y1=\"200.0\" x2=\"166.0\" y2=\"219.7\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></line><polygon points=\"160.0,220.0 166.1,222.7 165.8,216.7\" fill=\"var(--phosphor)\" stroke=\"none\"></polygon><text x=\"190.0\" y=\"228.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">confirmado</text></svg>", "caption": "Uma confirmação perdida e um retry correto: um pagamento, dois registros.", "same": ["shard"]}
```

O moto nunca perde uma resposta, então o laboratório não consegue fazer o timeout acontecer. Consegue
mostrar o resultado, que é o mesmo que mandar um registro duas vezes:

```
ana@laptop:~/aws$ aws kinesis create-stream --stream-name orders --shard-count 1
ana@laptop:~/aws$ aws kinesis put-record --stream-name orders --partition-key c-17 --cli-binary-format raw-in-base64-out --data '{"order_id": "o-301", "cents": 4590}' --query SequenceNumber --output text
1
ana@laptop:~/aws$ aws kinesis put-record --stream-name orders --partition-key c-17 --cli-binary-format raw-in-base64-out --data '{"order_id": "o-301", "cents": 4590}' --query SequenceNumber --output text
2
ana@laptop:~/aws$ IT=$(aws kinesis get-shard-iterator --stream-name orders --shard-id shardId-000000000000 --shard-iterator-type TRIM_HORIZON --query ShardIterator --output text) && aws kinesis get-records --shard-iterator "$IT" --query 'Records[].[SequenceNumber,PartitionKey,Data]' --output text
1	c-17	eyJvcmRlcl9pZCI6ICJvLTMwMSIsICJjZW50cyI6IDQ1OTB9
2	c-17	eyJvcmRlcl9pZCI6ICJvLTMwMSIsICJjZW50cyI6IDQ1OTB9
```

**Dois registros, dois números de sequência, dados idênticos.** O Kinesis não compara registros e não
tem como saber que o segundo é uma cópia: para o stream são dois eventos. Isso decide que tipo de
chave pega este duplicado. Um número de sequência não pega, porque a cópia ganhou um novo; só algo
dentro dos dados, posto lá pelo produtor, pega. Isso é uma **chave de idempotência** (*idempotency
key*), e para um pagamento ela é o id do pedido, porque um pedido é pago uma vez.

## O consumidor que cai

O consumidor da ordem pelo menos uma vez da seção anterior processa um lote e depois faz o checkpoint.
Se morre entre os dois, o reinício lê o lote de novo. Com a Kinesis Client Library isso também
acontece sem queda, quando um worker perde o lease de um shard para outro worker durante um
rebalanceamento: o dono novo começa do último checkpoint, que está atrás do que o dono antigo tinha
feito. Os grupos de consumidores do Kafka fazem o mesmo quando um rebalanceamento move uma partição
antes de os offsets dela serem confirmados. **Esses duplicados mantêm os números de sequência**,
porque são os mesmos registros lidos duas vezes, o que os torna mais fáceis de pegar que os do
produtor.

## O serviço que tenta de novo por você

O Data Firehose repete uma entrega no S3 que não se confirmou, e uma entrega repetida cuja primeira
tentativa na verdade tinha dado certo escreve os mesmos registros no bucket duas vezes; a AWS documenta
isso como a natureza pelo menos uma vez do serviço. A Lambda, lendo um stream do Kinesis por um event
source mapping, repete inteiro um lote cuja invocação falhou, incluindo os registros que a função já
tinha tratado antes de falhar. A Lambda de transformação da lição 21 está na mesma posição. Nada disso
foi rodado aqui, porque o moto não roda Lambda e o Firehose no moto escreve uma vez, na hora.

## Dois que não são duplicados

**Um segundo evento que parece o primeiro não é um duplicado.** Dois pedidos de `c-17` do mesmo valor
no mesmo dia são dois pedidos; uma chave feita de cliente, valor e dia os juntaria e perderia dinheiro
na outra direção. A chave de idempotência tem de identificar o evento, não descrevê-lo, e é por isso
que ela é um id que o produtor atribui uma vez, quando o evento acontece, e nunca deriva depois.

E **um registro fora de ordem também não é um duplicado**. A lição 20 mostrou que um retry pode pôr um
evento mais antigo depois de um mais novo; a deduplicação abaixo remove cópias e não faz nada pela
ordem. Um consumidor que se importa com as duas coisas precisa da chave de idempotência para as cópias
e de uma versão ou um horário nos dados para a ordem, ponto a que a última seção desta lição volta.
