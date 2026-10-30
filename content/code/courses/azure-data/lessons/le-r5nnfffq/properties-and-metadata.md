---
title: Properties, metadata and what the service fills in
version: 1
---

**A blob carries two kinds of description besides its bytes: properties, which the service defines,
and metadata, which you define.** Properties have fixed names and meanings: the type, the size, the
content type, the MD5 of the content, the tier, the ETag, when it last changed. Some are set by the
service and some by whoever uploads. Metadata is a set of name and value pairs that Blob Storage
stores and returns and never interprets. Both come back from one request that reads no content,
which is the cheap way to ask about a blob without downloading it.

## Properties

```
ana@laptop:~/azure$ az storage blob show -c orders-raw -n exports/2026/10/orders-2026-10-27.csv --query "{type:properties.blobType, size:properties.contentLength, contentType:properties.contentSettings.contentType, contentMd5:properties.contentSettings.contentMd5, etag:properties.etag, blobTier:properties.blobTier}"
{
  "blobTier": "Hot",
  "contentMd5": "yqM8kXSyNguuY9wnjUCE8g==",
  "contentType": "text/csv",
  "etag": "\"0x216F28C5453D7E0\"",
  "size": 64,
  "type": "BlockBlob"
}
ana@laptop:~/azure$ openssl dgst -md5 -binary export/orders-2026-10-27.csv | base64
yqM8kXSyNguuY9wnjUCE8g==
```

The command line filled in two of these on its own. **`text/csv` came from the file's extension**,
because `az storage blob upload` guesses a content type when none is given, and a browser or a
query engine that later reads the blob trusts that header. **`contentMd5` is the MD5 of the bytes,
in base64**, and the second command computes it locally with `openssl` to show the two agree. A
program that downloads the blob can compute the same hash and know the bytes arrived intact.

**The ETag is not a hash.** It is an opaque version stamp, `0x` followed by hexadecimal digits, that
changes every time anything about the blob changes. Two blobs with identical content have different
ETags, and the same blob gets a new one when its metadata changes, as the next block shows. Its only
use is the one in the section after this: asking whether a blob is still the version you read.

`blobTier` says `Hot` because the account's default tier applies to a block blob that was not given
one. Lesson 4 is about that property.

## Metadata

```
ana@laptop:~/azure$ az storage blob show -c orders-raw -n exports/2026/10/orders-2026-10-27.csv --query properties.etag -o tsv
"0x216F28C5453D7E0"
ana@laptop:~/azure$ az storage blob metadata update -c orders-raw -n exports/2026/10/orders-2026-10-27.csv --metadata source=shop rows=2 -o none
ana@laptop:~/azure$ az storage blob metadata show -c orders-raw -n exports/2026/10/orders-2026-10-27.csv
{
  "rows": "2",
  "source": "shop"
}
ana@laptop:~/azure$ az storage blob show -c orders-raw -n exports/2026/10/orders-2026-10-27.csv --query properties.etag -o tsv
"0x23C540E60F62F00"
ana@laptop:~/azure$ az storage blob metadata update -c orders-raw -n exports/2026/10/orders-2026-10-27.csv --metadata rows=3 -o none
ana@laptop:~/azure$ az storage blob metadata show -c orders-raw -n exports/2026/10/orders-2026-10-27.csv
{
  "rows": "3"
}
ana@laptop:~/azure$ az storage blob metadata update -c orders-raw -n exports/2026/10/orders-2026-10-27.csv --metadata row-count=3 2>&1 | grep ErrorCode
ErrorCode:InvalidMetadata
```

Four things happened, and the last two surprise people.

1. The first `metadata update` attached two pairs, `source=shop` and `rows=2`, and they came back
   as written.
2. **The ETag changed**, although not a byte of the content did. Any reader holding the old ETag now
   holds a stale one.
3. **The second update replaced the whole set.** It said `rows=3` and nothing else, so `source` is
   gone. There is no operation that changes one pair: a program that wants to add a pair reads the
   metadata, adds to it and writes all of it back.
4. **A name with a hyphen was refused** with `InvalidMetadata`. Metadata names must be valid C#
   identifiers, a rule that comes from how they travel: each pair is an HTTP header,
   `x-ms-meta-rows: 3`, and the rule keeps every name usable from every language's libraries.
   Names are case-insensitive and values are strings.

Microsoft's documentation caps the metadata of one blob at 8 KB, names and values together. That is
plenty for a few labels such as the source system or a row count, and it rules out using metadata
as a small database.

**Metadata cannot be searched.** The only way to find every blob whose `source` is `shop` is to list
the container and read each blob's metadata, one request per blob. Azure has a separate feature for
that question, blob index tags, which the service does index; it is not used in this course, and
nothing here was run against it. For a lake, the usual answer is simpler: put what you will search
by in the name, as `exports/2026/10/` already does for the date, because the name is the one thing a
listing filters on.
