---
title: Três preços para o mesmo gigabyte
version: 1
---

Ponha os três tipos lado a lado e o preço de um gigabyte varia num fator de catorze. Estas são as
linhas de armazenamento da tabela, lidas da lista pública de preços da AWS para `sa-east-1` (São
Paulo) e `us-east-1` (Virgínia do Norte), em USD, sem impostos, nas versões de oferta que ela
imprime:

```
ana@laptop:~/cloud$ python3 prices.py storage
AWS public price list, USD, excluding tax
  offer AmazonEC2        version 20260925174521
  offer AWSLambda        version 20260919002359
  offer AmazonS3         version 20260926015512
  offer AWSDataTransfer  version 20260916132208
  offer AmazonEFS        version 20260911124425
  offer AmazonVPC        version 20260917190528
                                        sa-east-1    us-east-1

S3, USD per GB-month (first tier)
  Standard                                0.04050      0.02300
  Standard-Infrequent Access              0.02210      0.01250
  Glacier Instant Retrieval               0.00830      0.00400
  Glacier Flexible Retrieval              0.00765      0.00360

S3 requests, USD per 1,000
  PUT, COPY, POST, LIST                   0.00700      0.00500
  GET and the rest                        0.00056      0.00040

EFS, USD per GB-month
  Standard                                 0.5700       0.3000
```

O preço de bloco é a linha `gp3` da captura da seção sobre blocos, 0.1520 e 0.0800. A linha do S3 é
a primeira faixa, que cobre os primeiros 50 TB guardados num mês. Guardar **500 GB por um mês** em
São Paulo em cada um dos três:

| | linha | 500 GB por um mês, `sa-east-1` | `us-east-1` |
|---|---|---|---|
| bloco | EBS `gp3` | 500 × 0.1520 = 76.00 | 500 × 0.0800 = 40.00 |
| arquivo | EFS Standard | 500 × 0.5700 = 285.00 | 500 × 0.3000 = 150.00 |
| objeto | S3 Standard | 500 × 0.04050 = 20.25 | 500 × 0.02300 = 11.50 |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Quanto custam 500 GB guardados por um mês no preço público de tabela da AWS, em USD, em três tipos de armazenamento. EBS gp3, bloco: 76.00 em sa-east-1 e 40.00 em us-east-1. EFS Standard, arquivo: 285.00 em sa-east-1 e 150.00 em us-east-1. S3 Standard, objeto: 20.25 em sa-east-1 e 11.50 em us-east-1.\"><defs><marker id=\"bars-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">500 GB por um mês, USD, preço público de tabela da AWS</text><text x=\"20\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">EBS gp3</text><text x=\"20\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">bloco</text><rect x=\"170\" y=\"50\" width=\"117.33333333333333\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"295.3333333333333\" y=\"59\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">76.00</text><rect x=\"170\" y=\"72\" width=\"61.754385964912274\" height=\"18\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"239.75438596491227\" y=\"81\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">40.00</text><text x=\"20\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">EFS Standard</text><text x=\"20\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">arquivo</text><rect x=\"170\" y=\"120\" width=\"440.0\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"618.0\" y=\"129\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">285.00</text><rect x=\"170\" y=\"142\" width=\"231.57894736842104\" height=\"18\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"409.57894736842104\" y=\"151\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">150.00</text><text x=\"20\" y=\"202\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">S3 Standard</text><text x=\"20\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">objeto</text><rect x=\"170\" y=\"190\" width=\"31.26315789473684\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"209.26315789473685\" y=\"199\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">20.25</text><rect x=\"170\" y=\"212\" width=\"17.75438596491228\" height=\"18\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"195.75438596491227\" y=\"221\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">11.50</text><rect x=\"170\" y=\"256\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"188\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sa-east-1</text><rect x=\"280\" y=\"256\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"298\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">us-east-1</text></svg>", "caption": "Os mesmos 500 GB, três preços. Armazenamento de arquivos custa catorze vezes o de objetos na mesma região, e cada um custa quase o dobro em São Paulo do que na Virgínia do Norte."}
```

## O que cada preço compra

Cada um é o preço de uma coisa diferente, e a tabela só compara com justiça quando se sabe o que
cada um inclui.

**O preço do volume compra capacidade reservada com desempenho junto.** Quinhentos gigabytes de SSD
são seus, com 3.000 IOPS, usados ou não, numa zona. Ocupe 40 GB e você continua pagando 76.00.

**O preço do arquivo compra um sistema de arquivos que outra pessoa opera em várias zonas, cobrado
pelo que ele guarda.** Isso muda a comparação mais do que o gráfico de barras sugere. Os mesmos 40 GB
no EFS custam 40 × 0.5700 = 22.80, menos que o volume quase vazio. O serviço de arquivos é caro por
gigabyte guardado e barato para pouca coisa, e o volume é o contrário.

**O preço do objeto compra o mínimo e cobra o resto à parte.** Sem sistema de arquivos, sem
montagem, e com um primeiro byte que chega mais devagar que de um volume local. O que 0.04050 compra
é capacidade cobrada pelo que está guardado, mantida em várias zonas. As requisições são cobradas
separadamente: a tabela cobra `PUT, COPY, POST, LIST` a 0.00700 por 1.000 em São Paulo, então um
milhão de uploads custa 7.00, e um milhão de `GET` a 0.00056 por 1.000 custa 0.56. Para dados
servidos ao público, a linha que pesa não é nenhuma dessas, e sim a transferência para a internet,
que a aula 10 põe na conta.

A coluna da direita é a outra lição da tabela. Cada uma das três linhas custa entre 1.76 e 1.9 vezes
mais em São Paulo do que na Virgínia do Norte: 0.04050 / 0.02300 dá 1.76, e 0.1520 / 0.0800 e
0.5700 / 0.3000 dão 1.9. Onde os dados podem morar é uma pergunta com preço, e a aula 9 pesa esse
preço contra a distância até quem os lê.
