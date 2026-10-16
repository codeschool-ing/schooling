---
title: Compressão, medida de quatro jeitos
version: 1
---

**Vendas em JSON comprimem muito bem, porque se repetem.** Toda venda escreve por extenso `"shop"`,
`"book"`, `"qty"`, `"cents"` e `"at"`; cinco nomes de loja e oito códigos de livro cobrem todos os
valores; cada timestamp divide a maior parte dos caracteres com o anterior. Um compressor trabalhando
num lote de centenas de vendas acha essas repetições e as guarda uma vez só.

O Kafka comprime **um lote por vez**, nunca uma mensagem isolada, então o ganho depende de quantas
mensagens dividem um lote, o que é mais um motivo para o batching do produtor (lição 4) importar.
Ele oferece quatro codecs: `gzip`, `snappy`, `lz4` e `zstd`. A compressão pode ser definida em dois
lugares. **No produtor**, `compression.type` (`none` por padrão) faz o cliente comprimir cada lote
antes de mandar, o que economiza a rede além do disco. **No tópico**, a configuração de mesmo nome
faz o broker guardar os lotes no codec que ela indica, recomprimindo o que chegar em outro. O padrão
dela, `producer`, mantém o que o produtor mandou, e a palavra dela para sem compressão é
`uncompressed`, não `none`. A medição aqui usa a configuração do tópico, porque ela não exige mudar
o `tills.py`; a do produtor é a que um pipeline de verdade usa, e ela não foi medida aqui.

## As mesmas vendas, quatro vezes

Quatro tópicos, um por codec:

```
ubuntu@stream:~/work$ for c in uncompressed gzip lz4 zstd; do kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales-$c --partitions 1 --config compression.type=$c; done
Created topic sales-uncompressed.
Created topic sales-gzip.
Created topic sales-lz4.
Created topic sales-zstd.
```

As mesmas cem mil vendas em cada um, com a mesma semente, para que os quatro tópicos tenham mensagens
idênticas:

```
ubuntu@stream:~/work$ for c in uncompressed gzip lz4 zstd; do python tills.py --topic sales-$c --count 100000 --rate 0; done
sent 100000 sales to sales-uncompressed, the last one at 13:39:21
sent 100000 sales to sales-gzip, the last one at 13:39:21
sent 100000 sales to sales-lz4, the last one at 13:39:21
sent 100000 sales to sales-zstd, the last one at 13:39:21
```

E os tamanhos, com os bytes por venda ao lado de cada um, do maior para o menor:

```
ubuntu@stream:~/work$ kafka-log-dirs.sh --bootstrap-server localhost:9092 --describe --topic-list sales-uncompressed,sales-gzip,sales-lz4,sales-zstd | grep '^{' | jq -r '.brokers[0].logDirs[0].partitions[] | "\(.partition)  \(.size)  \(.size / 100000 * 10 | round / 10)"' | sort -k2 -n -r
sales-uncompressed-0  13526579  135.3
sales-lz4-0  3148477  31.5
sales-zstd-0  1687741  16.9
sales-gzip-0  1449945  14.5
```

Sem compressão, o tópico tem os mesmos 135,3 bytes por venda do `bytes` da seção anterior. **O `lz4`
reduz para mais ou menos um quarto, o `zstd` para cerca de um oitavo, e o `gzip`, com 14,5 bytes,
sai o menor dos quatro nestas vendas**, com o `zstd` logo atrás, em 16,9. Essa ordem é um fato sobre
estes dados e estes lotes, não um ranking dos codecs: é o motivo para medir com as suas próprias
mensagens antes de escolher.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Um gráfico de barras de bytes em disco por venda para as mesmas 100 000 vendas guardadas de quatro jeitos: sem compressão 135,3, lz4 31,5, zstd 16,9, gzip 14,5.\" data-fig=\"l17-codecs\"><text x=\"138\" y=\"42\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">sem compressão</text><rect x=\"150\" y=\"30\" width=\"487.08000000000004\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"645.08\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">135,3</text><text x=\"138\" y=\"80\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">lz4</text><rect x=\"150\" y=\"68\" width=\"113.4\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"271.4\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">31,5</text><text x=\"138\" y=\"118\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">zstd</text><rect x=\"150\" y=\"106\" width=\"60.839999999999996\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"218.84\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">16,9</text><text x=\"138\" y=\"156\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">gzip</text><rect x=\"150\" y=\"144\" width=\"52.2\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"210.2\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">14,5</text><text x=\"150\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bytes por venda</text></svg>", "caption": "Bytes em disco por venda, medidos: as mesmas vendas ocupam um oitavo do espaço com zstd, e um pouco menos com gzip."}
```

## O que ela custa

A compressão é paga em tempo de processador: pelo produtor que comprime, e por todo consumidor que
descomprime, uma vez por grupo. Com a configuração do tópico, o broker paga também, porque recomprime
cada lote na entrada. Esse custo não foi medido aqui, e é a metade da troca que a conta de disco
esconde. Os codecs diferem em onde ficam nela:

| codec | onde fica |
|---|---|
| `gzip` | saída pequena, lento para comprimir; o antigo padrão de muitas ferramentas |
| `snappy` | rápido, taxa modesta; comum em pipelines mais antigos |
| `lz4` | muito rápido para comprimir e descomprimir, uma taxa moderada |
| `zstd` | uma taxa perto da do `gzip` a um custo de processador bem menor; tem níveis |

Para um pipeline novo a escolha usual é `zstd` no produtor, ou `lz4` onde o tempo de processador é o
recurso mais escasso; o `gzip` ganhou em tamanho aqui e ainda perde essa escolha em velocidade, que
este laboratório não mediu. **Seja qual for a escolha, ela multiplica tudo o que vem depois**: o
disco em cada réplica, a rede entre brokers e para cada consumidor, e a conta de guardar uma semana
disso.
