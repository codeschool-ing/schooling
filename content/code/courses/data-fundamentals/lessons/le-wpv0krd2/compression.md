---
title: Compression, and the file nobody can split
version: 1
---

**Compression trades processor time for bytes, and a columnar file gives it more to work with,
because the values that sit together are alike.** A compressor finds repeated patterns and writes
them once. Twelve station codes repeated down a column are a pattern; a ride id, a station, a time
and a number in a row are mostly not.

The common codecs make the trade at different points. **Snappy** was designed by Google to be fast
rather than small. **gzip** is older, slower, and squeezes harder. **zstd**, Zstandard, was released
by Facebook in 2016 and is designed to compress about as hard as gzip while being much quicker to
decompress. In Parquet the codec is chosen when the file is written, for the whole file or column by column. It
is applied to each page on its own and recorded in the footer, so the reader knows how to undo it.

## Measuring the trade

This program reads back the uncompressed Parquet file from `five.py`, writes it again with each
codec, and then gzips the CSV for comparison. Save it as `formats/squeeze.py`:

```python
# formats/squeeze.py
import gzip
import os
import shutil
import pyarrow.parquet as pq

table = pq.read_table("five/rides.parquet")
for codec in ["none", "snappy", "gzip", "zstd"]:
    path = f"five/rides.{codec}.parquet"
    pq.write_table(table, path, compression=codec)
    print(f"Parquet, {codec:7} {os.path.getsize(path):>9,} bytes")

with open("five/rides.csv", "rb") as src, gzip.open("five/rides.csv.gz", "wb") as dst:
    shutil.copyfileobj(src, dst)
print(f"CSV, gzip         {os.path.getsize('five/rides.csv.gz'):>9,} bytes")
```

```
ana@lab:~/roda/formats$ python squeeze.py
Parquet, none    1,287,381 bytes
Parquet, snappy    907,079 bytes
Parquet, gzip      638,037 bytes
Parquet, zstd      633,691 bytes
CSV, gzip           570,459 bytes
```

Snappy takes the Parquet file from 1,287,381 bytes to 907,079; gzip and zstd take it to about half,
638,037 and 633,691. And then the last line: **the gzipped CSV, at 570,459 bytes, is smaller than
every one of them.**

## Why the smallest file is not the best one

That last number is real, and it is a good reason not to choose a format by size alone. The
compressed CSV loses on three counts that a size does not show.

**To read one column, it has to be decompressed whole.** gzip turns the file into one continuous
stream. There is no footer saying where `minutes` is, and there are no column chunks to go to; the
only way to the last ride is through every byte before it. Section 08 showed
the Parquet reader going through 3% of its file for the same answer.

**It cannot be split.** A gzip stream has to be decompressed from its first byte, so a file of 50 GB
is read by one worker, start to finish, however many workers there are. A Parquet file compresses
each page separately, inside column chunks inside row groups, and the footer says where each row
group starts: ten workers can take a row group each and never touch the others. Avro is splittable
for a different reason, the sync marker after every block. Some codecs, bzip2 among them, can be
split even on a plain text file; gzip cannot. Lesson 9 is where work is spread over many machines,
and a file that only one of them can read is the first thing that stops it.

**It still has no types.** Decompressed, it is the same CSV, with every guess still to be made.

So a sound default is a columnar format with a fast codec, Snappy or zstd, for anything programs
read again and again, and gzip for a file that is sent somewhere once and read whole, such as an
export a partner downloads.
