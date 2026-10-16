---
title: Codificações
version: 1
---

**Uma codificação reescreve os valores de uma coluna em menos bytes antes de o codec vê-los, usando o
que sabe sobre a coluna.** Um codec só conhece bytes. O Parquet escolhe uma codificação por column
chunk e a registra no rodapé. O menor arquivo da seção anterior, 1º de janeiro:

```
ana@lab:~/big$ ~/pq-env/bin/python footer.py data/tmp/parquet-v2-zstd-micros/day=2025-01-01
65,754 rows in 1 row group(s), 1,346 bytes of footer, written by parquet-mr version 1.16.0 (build 402c3810c372d29603e181771acebfecc71bef61)
column       on disk  decompressed  codec   encodings
                KiB           KiB
event_id         0.3           2.7  ZSTD    DELTA_BINARY_PACKED
ts               4.2         164.3  ZSTD    DELTA_BINARY_PACKED
visitor_id     105.1         233.4  ZSTD    RLE_DICTIONARY, PLAIN
kind            10.5          16.3  ZSTD    RLE_DICTIONARY, PLAIN
book_id        101.2         109.8  ZSTD    RLE_DICTIONARY, PLAIN
device          10.4          16.4  ZSTD    RLE_DICTIONARY, PLAIN
```

Contra o rodapé da camada silver na seção 03, coluna a coluna:

| coluna | camada silver | v2, zstd, micros | codificação agora |
|---|---|---|---|
| `event_id` | 257,9 KiB | 0,3 KiB | `DELTA_BINARY_PACKED` |
| `ts` | 532,3 KiB | 4,2 KiB | `DELTA_BINARY_PACKED` |
| `visitor_id` | 156,6 KiB | 105,1 KiB | `RLE_DICTIONARY` |
| `book_id` | 108,4 KiB | 101,2 KiB | `RLE_DICTIONARY` |

**A codificação delta guarda o primeiro valor e depois cada diferença para o anterior**, empacotada
em tão poucos bits quanto a maior diferença precisa. Os ids de evento de um dia são consecutivos,
então toda diferença é a mesma e 65.754 ids cabem em 0,3 KiB. Os timestamps sobem cerca de um segundo
cada, e 164,3 KiB para 65.754 deles dá uns 20 bits por linha antes da compressão, em vez de 96. O
delta binary packing é só para inteiros, e é por isso que timestamps `INT96` não podiam usá-lo e por
isso as duas mudanças da seção anterior foram precisas juntas.

**A codificação por dicionário guarda cada valor distinto uma vez, e cada linha como um número
pequeno que aponta para ele**, com trechos do mesmo número guardados como um só trecho: o
`RLE_DICTIONARY`. Foi isso que já deixou `kind` e `device` baratos na camada silver. Ela ajuda menos
o `visitor_id`, com muitos milhares de visitantes diferentes num dia, e nada uma coluna com um valor
diferente em cada linha; o Parquet então volta ao `PLAIN`, os valores um depois do outro, como fez
com o `ts` na camada silver.

**Nada disso precisa da ajuda do leitor.** Cada codificação fica escrita no rodapé, e qualquer leitor
de Parquet decodifica todas. O que quem grava escolhe é o quanto se esforça: a versão do formato de
página, o tipo do timestamp, o codec. Os padrões do Spark favorecem a compatibilidade com leitores
antigos e gravações rápidas, e um lake que é gravado uma vez e lido muitas sai melhor mudando os
três.
