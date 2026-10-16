---
title: O buffer, e quantos objetos por dia ele faz
version: 1
---

**Um buffer é escrito quando está cheio ou quando está velho, o que acontecer primeiro.** `SizeInMBs`
é a primeira condição e `IntervalInSeconds` a segunda, e juntas decidem duas coisas que uma equipe só
nota depois: quanto tempo um registro espera até poder ser lido no S3, e quantos objetos o bucket
junta num dia. A AWS documenta as faixas: o tamanho de 1 a 128 MB, 5 por padrão, e o intervalo até 900
segundos, 300 por padrão. Qualquer um dos dois maior quer dizer menos objetos, maiores, que chegam
mais tarde.

O moto não aplica as faixas, e vale ver isso uma vez, porque uma configuração que funciona no
laboratório pode ser recusada pela AWS. O arquivo da seção anterior, editado com `jq` para pedir 500
MB e 5.000 segundos:

```
ana@laptop:~/aws$ jq '.BufferingHints = {"SizeInMBs": 500, "IntervalInSeconds": 5000} | .Prefix = "raw/orders-big/"' orders-to-s3.json > orders-big.json
ana@laptop:~/aws$ aws firehose create-delivery-stream --delivery-stream-name orders-big --extended-s3-destination-configuration file://orders-big.json
{
    "DeliveryStreamARN": "arn:aws:firehose:sa-east-1:123456789012:deliverystream/orders-big"
}
ana@laptop:~/aws$ aws firehose describe-delivery-stream --delivery-stream-name orders-big --query 'DeliveryStreamDescription.Destinations[0].ExtendedS3DestinationDescription.BufferingHints'
{
    "SizeInMBs": 500,
    "IntervalInSeconds": 5000
}
```

**O moto guardou os dois números e respondeu `ACTIVE`.** A AWS valida as dicas quando o stream é
criado e recusa valores fora dessas faixas, então esta requisição teria falhado lá; essa recusa não
foi rodada aqui. E o moto não faz buffer nenhum, como a seção anterior mostrou, então nada nesta lição
mede um buffer. O que vem a seguir é a conta que a documentação da AWS dá, feita à mão.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Quinze minutos de dois delivery streams com as mesmas dicas, 64 MB e 300 segundos. O stream movimentado, 0,23 MB por segundo, enche um buffer de 64 MB em cerca de 278 segundos, então o tamanho o escreve: três objetos cheios nos quinze minutos. O stream quieto, 0,012 MB por segundo, chega só a cerca de 3,5 MB em 300 segundos, então o intervalo o escreve: três objetos em 300, 600 e 900 segundos, cada um quase vazio.\" data-fig=\"l21-buffers\"><text x=\"20.0\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">stream movimentado</text><text x=\"20.0\" y=\"80.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,23 MB por segundo</text><rect x=\"151.0\" y=\"40.0\" width=\"164.8\" height=\"60.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"151.0\" y=\"40.0\" width=\"164.8\" height=\"60.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><line x1=\"315.8\" y1=\"34.0\" x2=\"315.8\" y2=\"104.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></line><rect x=\"317.8\" y=\"40.0\" width=\"164.8\" height=\"60.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"317.8\" y=\"40.0\" width=\"164.8\" height=\"60.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><line x1=\"482.6\" y1=\"34.0\" x2=\"482.6\" y2=\"104.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></line><rect x=\"484.6\" y=\"40.0\" width=\"164.8\" height=\"60.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"484.6\" y=\"40.0\" width=\"164.8\" height=\"60.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><line x1=\"649.4\" y1=\"34.0\" x2=\"649.4\" y2=\"104.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></line><text x=\"233.4\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">64 MB: tamanho atingido</text><text x=\"670.2\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">enchendo</text><text x=\"20.0\" y=\"152.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">stream quieto</text><text x=\"20.0\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,012 MB por segundo</text><rect x=\"151.0\" y=\"130.0\" width=\"178.0\" height=\"60.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"151.0\" y=\"186.7\" width=\"178.0\" height=\"3.3\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><line x1=\"329.0\" y1=\"124.0\" x2=\"329.0\" y2=\"194.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></line><rect x=\"331.0\" y=\"130.0\" width=\"178.0\" height=\"60.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"331.0\" y=\"186.7\" width=\"178.0\" height=\"3.3\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><line x1=\"509.0\" y1=\"124.0\" x2=\"509.0\" y2=\"194.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></line><rect x=\"511.0\" y=\"130.0\" width=\"178.0\" height=\"60.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"511.0\" y=\"186.7\" width=\"178.0\" height=\"3.3\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><line x1=\"689.0\" y1=\"124.0\" x2=\"689.0\" y2=\"194.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></line><text x=\"240.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">3,5 MB: intervalo atingido</text><line x1=\"150.0\" y1=\"205.0\" x2=\"690.0\" y2=\"205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"150.0\" y1=\"201.0\" x2=\"150.0\" y2=\"209.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"150.0\" y=\"222.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0 s</text><line x1=\"330.0\" y1=\"201.0\" x2=\"330.0\" y2=\"209.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"330.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">300 s</text><line x1=\"510.0\" y1=\"201.0\" x2=\"510.0\" y2=\"209.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"510.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">600 s</text><line x1=\"690.0\" y1=\"201.0\" x2=\"690.0\" y2=\"209.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"690.0\" y=\"222.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">900 s</text><text x=\"20.0\" y=\"222.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tempo</text></svg>", "caption": "Um buffer é escrito em 64 MB ou em 300 segundos, o que vier primeiro; um stream quieto é escrito pelo relógio, quase vazio.", "same": ["0 s", "300 s", "600 s", "900 s"]}
```

## A conta de um stream

**Um stream movimentado enche o buffer antes de o intervalo acabar.** Os eventos de pedido da Quitanda
da lição 20 são 20 GB por dia, cerca de 0,23 MB por segundo em média. Com as dicas do
`orders-to-s3.json`, 64 MB e 300 segundos, um buffer enche em 64 / 0,23 ≈ 278 segundos, logo dentro do intervalo. Então é o tamanho que o escreve: cerca de 20.000 MB / 64 MB ≈ 313 objetos por dia, de 64 MB
cada. No pico do jantar, cinco vezes a média, um buffer enche em menos de um minuto; os objetos
continuam do mesmo tamanho e só chegam com mais frequência.

**Um stream quieto é escrito pelo relógio.** O aplicativo dos entregadores da Quitanda manda um stream
de pings de localização de 1 GB por dia, cerca de 0,012 MB por segundo. Com as mesmas dicas, 300
segundos passam muito antes de chegarem 64 MB, então o intervalo escreve todo buffer: 86.400 / 300 =
288 objetos por dia, de cerca de 3,5 MB cada. Subir o intervalo para 900 segundos dá 96 objetos de
cerca de 10,4 MB, ao preço de um ping chegar ao S3 até quinze minutos depois de enviado.

**O número de objetos é um custo pago depois, em toda leitura.** A lição 19 trata de por que um lago
de muitos arquivos pequenos é lento e caro de consultar: todo arquivo é pelo menos uma requisição
`GET` e, no Parquet, um rodapé a ler antes de qualquer dado, então um motor que lê dez mil arquivos
pequenos gasta o tempo abrindo-os. A alavanca é o intervalo, até o atraso que os leitores aguentam, e
depois disso um job de compactação que reescreve os objetos pequenos de um dia em poucos grandes, o
tipo de job Spark que as lições 17 e 24 rodam.

## Um buffer por quê

Um delivery stream tem um buffer por destino, e **com particionamento dinâmico, um buffer por
partição**, que a próxima seção configura. Particionado pelas três lojas da Quitanda, o stream
movimentado acima tem três buffers enchendo a um terço da taxa cada, e cada um é escrito por tamanho
ou por intervalo por conta própria. A AWS fixa o tamanho mínimo em 64 MB quando o particionamento
dinâmico está ligado. E a conta se multiplica: três lojas e um prefixo datado fazem três objetos de
cada vez onde havia um, e uma chave com algumas centenas de valores faz algumas centenas de buffers
pequenos que o intervalo escreve pela metade.
