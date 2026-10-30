---
title: Containers, blobs and the folders that are not there
version: 1
---

**A container is a named group of blobs inside a storage account, and a blob is a name and the
bytes stored under it.** That is the whole data model of Blob Storage. There are no directories
inside a container and no containers inside a container. The slashes people put in blob names look
like a filesystem, and the portal and every storage explorer draw folders out of them, but underneath
there is one flat list of names per container, sorted. Lesson 3 is about the one switch that changes
that, and this lesson is about the flat namespace every account has by default.

This lesson needs Azurite alone, started empty with `docker compose up -d` in `~/azure`, and the four
lines of "Every time you open a terminal" from lesson 1 typed in the terminal you use. The rest of
the storage lessons, up to lesson 7, start the same way.
Quitanda's shop exports one CSV file a night; make three small ones, for the last three days of
October:

```sh
mkdir -p export
for d in 27 28 29; do
  printf 'order_id,customer_id,total_cents\n%s-1,c-17,4590\n%s-2,c-03,12800\n' "$d" "$d" \
    > export/orders-2026-10-$d.csv
done
```

Then create a container and put the three files in it, each under a name that starts with
`exports/2026/10/`:

```
ana@laptop:~/azure$ az storage container create -n orders-raw
{
  "created": true
}
ana@laptop:~/azure$ az storage blob upload-batch -d orders-raw -s export --destination-path exports/2026/10 --no-progress -o none
ana@laptop:~/azure$ az storage blob list -c orders-raw --query "[].name" -o tsv
exports/2026/10/orders-2026-10-27.csv
exports/2026/10/orders-2026-10-28.csv
exports/2026/10/orders-2026-10-29.csv
```

`upload-batch` sent one request per file, and the name of each blob is the whole string after the
container's name, slashes included. `--no-progress` and `-o none` only keep the transcript short:
without them the command draws a progress bar and prints a line per file.

## Listing is asking for a prefix

```
ana@laptop:~/azure$ az storage blob list -c orders-raw --query "[].name" -o tsv --delimiter /
exports/
ana@laptop:~/azure$ az storage blob list -c orders-raw --query "[].name" -o tsv --delimiter / --prefix exports/2026/
exports/2026/10/
ana@laptop:~/azure$ az storage blob show -c orders-raw -n exports/2026/ 2>&1 | tail -1
ErrorCode:BlobNotFound
ana@laptop:~/azure$ az storage blob exists -c orders-raw -n EXPORTS/2026/10/orders-2026-10-27.csv
{
  "exists": false
}
```

**The second listing shows an `exports/` that nobody created.** Given `--delimiter /`, Blob Storage
groups every name at its first slash and answers with one entry per group, which the library calls a
`BlobPrefix`. Add `--prefix exports/2026/` and it filters first, then groups at the next slash after
the prefix. That is all a folder is: **the answer to a listing question, and it exists only while
some blob's name starts with it.** Delete the three blobs and `exports/` disappears with them, with
nothing to delete on its own.

So asking for the folder as a blob fails, because there is no such blob. And the last command shows
the other half of the same fact: names are compared byte for byte, so `EXPORTS/` is a different
prefix from `exports/`, and nothing lives under it.

Microsoft's documentation states the limits that matter here. A blob name may be up to 1,024
characters long, it is case-sensitive, and a container may hold an unlimited number of blobs. The
name is the only index Blob Storage keeps: a listing walks names in order, so a design that puts the
date early in the name, as `exports/2026/10/` does, lets a program ask for one month without reading
the names of every other month.

## Three types of blob, chosen once

**Every blob has a type, set when it is created and never changed afterwards.** The three files
above are block blobs, which is what every upload is unless it asks for something else. The type
decides which operations the blob accepts:

| type | how it is written | what it is for |
|---|---|---|
| block blob | blocks staged, then committed as a list | files: exports, Parquet, images, backups |
| append blob | blocks added at the end, never changed | logs written a line at a time |
| page blob | 512-byte pages written at any offset | virtual machine disks |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The three blob types side by side. A block blob: blocks B0, B1 and B2 are staged, then one commit names them in order, and only then is the blob readable. An append blob: lines 1 to 3 are written, and the next append can only go after them. A page blob: a grid of 512-byte pages where three are written and the others read as zeros.\" data-fig=\"l02-types\"><defs><marker id=\"l02-types-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--wire)\"/></marker></defs><rect x=\"20\" y=\"20\" width=\"200\" height=\"210\" rx=\"5\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"120\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">block blob</text><text x=\"120\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">staged, then committed</text><rect x=\"260\" y=\"20\" width=\"200\" height=\"210\" rx=\"5\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"360\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">append blob</text><text x=\"360\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">added at the end only</text><rect x=\"500\" y=\"20\" width=\"200\" height=\"210\" rx=\"5\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"600\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">page blob</text><text x=\"600\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">any 512-byte page</text><text x=\"34\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">staged</text><rect x=\"34\" y=\"96\" width=\"46\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"57\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">B0</text><rect x=\"92\" y=\"96\" width=\"46\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"115\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">B1</text><rect x=\"150\" y=\"96\" width=\"46\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"173\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">B2</text><line x1=\"120\" y1=\"128\" x2=\"120\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l02-types-ah)\"/><text x=\"34\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">commit [B0, B1, B2]</text><rect x=\"34\" y=\"174\" width=\"46\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"57\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">B0</text><rect x=\"92\" y=\"174\" width=\"46\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"115\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">B1</text><rect x=\"150\" y=\"174\" width=\"46\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"173\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">B2</text><text x=\"120\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">readable only after the commit</text><rect x=\"290\" y=\"84\" width=\"140\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"360\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">line 1</text><rect x=\"290\" y=\"114\" width=\"140\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"360\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">line 2</text><rect x=\"290\" y=\"144\" width=\"140\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"360\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">line 3</text><rect x=\"290\" y=\"174\" width=\"140\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"/><text x=\"360\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">line 4</text><text x=\"360\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">next append goes here</text><rect x=\"522\" y=\"84\" width=\"36\" height=\"24\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><rect x=\"562\" y=\"84\" width=\"36\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><rect x=\"602\" y=\"84\" width=\"36\" height=\"24\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><rect x=\"642\" y=\"84\" width=\"36\" height=\"24\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><rect x=\"522\" y=\"114\" width=\"36\" height=\"24\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><rect x=\"562\" y=\"114\" width=\"36\" height=\"24\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><rect x=\"602\" y=\"114\" width=\"36\" height=\"24\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><rect x=\"642\" y=\"114\" width=\"36\" height=\"24\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><rect x=\"522\" y=\"144\" width=\"36\" height=\"24\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><rect x=\"562\" y=\"144\" width=\"36\" height=\"24\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><rect x=\"602\" y=\"144\" width=\"36\" height=\"24\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><rect x=\"642\" y=\"144\" width=\"36\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><rect x=\"522\" y=\"174\" width=\"36\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><rect x=\"562\" y=\"174\" width=\"36\" height=\"24\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><rect x=\"602\" y=\"174\" width=\"36\" height=\"24\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><rect x=\"642\" y=\"174\" width=\"36\" height=\"24\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><text x=\"600\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">written pages only; the rest is zeros</text></svg>", "caption": "The type is chosen when the blob is created, and decides which writes it will ever accept."}
```

The next two sections take the types in turn. Almost everything a data platform stores is a block
blob, and it is the only type that takes the hot, cool, cold and archive tiers of lesson 4. The other two are worth knowing
mostly so that an error naming the wrong blob type is recognised when it appears.
