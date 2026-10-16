---
title: Uploads that are only data
version: 1
---

An upload is user input with a name, a declared type and a body, and each of the three can be wrong.
The defects are the same as everywhere else in this lesson, with the filesystem as the interpreter:
a name that walks out of its directory, a file served back to browsers that read it as a page, a
body so large it fills the disk. **The defences are four**, and `account.py` has each:

- **the size is checked before the body is read**: `Content-Length` over 200 KB is refused with
  `413`, and the connection is closed without reading what follows;
- **the type is decided by the content, not the name or the header**: the first bytes must be a PNG
  or a JPEG signature, or the answer is `415`;
- **the stored name is made by the server**, 32 random hexadecimal digits and the extension the
  content earned, so nothing the client sent becomes part of a path;
- **the files are never served back** from the service: they land in `data/uploads`, outside any
  directory a route reads from.

Make three files and send each one. The first is a CSV with a `.png` name, the second 300,000 zero
bytes, and the third a real PNG of one pixel, written by a single line of Python so that you have one
without a drawing program:

```
ana@nft:~/boxoffice$ printf 'name,seat\nana,12\n' > notes.png
ana@nft:~/boxoffice$ curl -s -w ' %{http_code}\n' -X POST localhost:8001/avatar -H "Authorization: Bearer $(cat ~/ana.token)" --data-binary @notes.png
{"error": "send a PNG or a JPEG"}
 415
ana@nft:~/boxoffice$ head -c 300000 /dev/zero > big.png
ana@nft:~/boxoffice$ curl -s -w ' %{http_code}\n' -X POST localhost:8001/avatar -H "Authorization: Bearer $(cat ~/ana.token)" --data-binary @big.png
{"error": "send an image of 200 KB or less"}
 413
ana@nft:~/boxoffice$ python3 -c 'import sys, zlib, struct; c = lambda t, d: struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d)); sys.stdout.buffer.write(b"\x89PNG\r\n\x1a\n" + c(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 0, 0, 0, 0)) + c(b"IDAT", zlib.compress(b"\x00\x00")) + c(b"IEND", b""))' > dot.png
ana@nft:~/boxoffice$ curl -s -w ' %{http_code}\n' -X POST localhost:8001/avatar -H "Authorization: Bearer $(cat ~/ana.token)" --data-binary @dot.png
{"ok": true}
 201
ana@nft:~/boxoffice$ ls data/uploads
c52491dd01b3a7f8070893653c59ba56.png
ana@nft:~/boxoffice$ curl -s -w ' %{http_code}\n' localhost:8001/data/uploads/ -H "Authorization: Bearer $(cat ~/ana.token)"
{"error": "not found"}
 404
```

The CSV was refused **although its name ends in `.png`**, the large file was refused by size, and
the real image was stored under a name the client never chose. Asking for the directory gets a
`404`, because `account.py` has no route that reads it. A real service that has to show the images
again serves them from a separate domain or a storage bucket, with `Content-Type` and `nosniff` set,
so a file a browser misread could not run inside the service's own pages.

A content check of the first few bytes is a floor, not a guarantee: a file can start like a PNG and
carry anything after. Services that accept images from strangers re-encode them with an image
library, which keeps the pixels and drops everything else, and run a malware scanner on what they
keep. Both are named here and not built: they need libraries this course does not install.

The service's terminal kept a line for each refusal of this lesson, and none of them holds the file:

```
ana@nft:~/boxoffice$ python3 account.py
account on http://127.0.0.1:8001
2026-10-10 16:47:55,541 WARNING refused POST /account/cancel to account 1: stale form
2026-10-10 16:47:55,703 WARNING refused POST /avatar to account 1: send a PNG or a JPEG
2026-10-10 16:47:55,750 WARNING refused POST /avatar to account 1: send an image of 200 KB or less
```
