---
title: Encodings
version: 1
---

**An encoding rewrites a column's values into fewer bytes before the codec sees them, using what it
knows about the column.** A codec only knows bytes. Parquet chooses an encoding per column chunk and
records it in the footer. The smallest file of the last section, 1 January:

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

Against the silver layer's footer in section 03, column by column:

| column | silver layer | v2, zstd, micros | encoding now |
|---|---|---|---|
| `event_id` | 257.9 KiB | 0.3 KiB | `DELTA_BINARY_PACKED` |
| `ts` | 532.3 KiB | 4.2 KiB | `DELTA_BINARY_PACKED` |
| `visitor_id` | 156.6 KiB | 105.1 KiB | `RLE_DICTIONARY` |
| `book_id` | 108.4 KiB | 101.2 KiB | `RLE_DICTIONARY` |

**Delta encoding stores the first value and then each difference from the one before**, bit-packed
into as few bits as the largest difference needs. The event ids of a day are consecutive, so every
difference is the same and 65,754 ids fit in 0.3 KiB. The timestamps go up by about a second each,
and 164.3 KiB for 65,754 of them is about 20 bits a row before compression, instead of 96. Delta
binary packing is only for integers, which is why `INT96` timestamps could not use it and why both
changes of the last section were needed together.

**Dictionary encoding stores each distinct value once, and each row as a small number pointing to
it**, with runs of the same number stored as one run: `RLE_DICTIONARY`. It is what made `kind` and
`device` cheap in the silver layer already. It does less for `visitor_id`, with many thousands of different
visitors in a day, and nothing at all for a column with a different value in every row; Parquet then
falls back to `PLAIN`, the values one after another, as it did for `ts` in the silver layer.

**None of this needs the reader's help.** Each encoding is written in the footer, and any Parquet
reader decodes all of them. What the writer chooses is how much it tries: the page format version,
the timestamp type, the codec. Spark's defaults favour compatibility with old readers and fast
writes, and a lake that is written once and read many times does better changing all three.
