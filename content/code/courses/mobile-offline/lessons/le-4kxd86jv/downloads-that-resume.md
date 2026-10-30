---
title: A download that resumes where it stopped
version: 1
---

**A large file on a phone is downloaded in pieces whether you plan for it or not, so plan for it.**
A train enters a tunnel, the person walks out of Wi-Fi, the system suspends the app: each one stops
a download partway. Starting again from byte zero wastes what already arrived, and on a slow
connection a 30 MB file that restarts at every interruption may never finish at all.

HTTP has had the answer since 1999. The client asks for **a range of bytes**, `Range: bytes=1048576-`
meaning "from this byte to the end", and a server that supports it answers **206 Partial Content**
with only that part. Two more headers make it safe:

| header | what it is for |
|---|---|
| `Accept-Ranges: bytes` | the server says it can answer a `Range` at all |
| `Content-Range: bytes 1048576-3145727/3145728` | which part this is, and the size of the whole |
| `If-Range: "<etag>"` | send the range only if the file is still the one with this tag; otherwise send it whole |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l18-resume\" aria-label=\"A 3 MB file as a bar of bytes. Request 1, without a Range, is answered 200 and stalls after the first megabyte, which is kept in notes.pdf.part. Request 2 asks Range: bytes=1048576- with If-Range and the tag, is answered 206 Partial Content, and appends the remaining two megabytes. Only then is the part file renamed to notes.pdf, and only then is a row recorded.\"><defs><marker id=\"l18-resume-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l18-resume-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l18-resume-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"40\" y=\"90\" width=\"200.0\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"240.0\" y=\"90\" width=\"400.0\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"140.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0 – 1048575</text><text x=\"440.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1048576 – 3145727</text><text x=\"40\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">request 1: no Range</text><text x=\"40\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">200, stalls after 1 MB</text><path d=\"M140.0 62 L140.0 88\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-resume-ah-phosphor)\"></path><text x=\"256.0\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">request 2: Range: bytes=1048576-</text><text x=\"256.0\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">206 Partial Content, the rest</text><path d=\"M440.0 62 L440.0 88\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-resume-ah-amber)\"></path><text x=\"40\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">kept in</text><text x=\"114\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">notes.pdf.part</text><path d=\"M646 110 L680 110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-resume-ah-paper-dim)\"></path><text x=\"636\" y=\"180\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">then renamed</text><text x=\"644\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">notes.pdf</text><text x=\"636\" y=\"200\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">and then the row</text></svg>", "caption": "The first megabyte crosses the network once. The part file has its own name until the last byte is there."}
```

`If-Range` is the one people forget. Without it, a file that changed on the server between the two
requests is resumed onto the end of the old one, and the result is a file made of two versions that
no hash will match.

## A server that stalls, and a client that resumes

The server holds one 3 MB file, filled with the same bytes on every run. It answers ranges, and its
first answer stops after 1 MB and then sends nothing, which is what a connection in a tunnel looks
like from the phone. Save it in `~/planner/files` as `server.ts`:

```typescript
// server.ts: one 3 MB file, served with Range support, on port 8018.
// The first answer stalls after 1 MB, the way a connection does when a train enters a tunnel.
import { createServer } from "node:http";
import { createHash } from "node:crypto";

const file = Buffer.alloc(3 * 1024 * 1024);
for (let i = 0; i < file.length; i++) file[i] = (i * 31 + 7) % 251; // the same bytes on every run
const etag = `"${createHash("sha256").update(file).digest("hex").slice(0, 16)}"`;
let requests = 0;

createServer((req, res) => {
  if (req.url !== "/notes.pdf") return void res.writeHead(404).end();
  requests++;
  const range = /^bytes=(\d+)-$/.exec(req.headers.range ?? "");
  const sameFile = !req.headers["if-range"] || req.headers["if-range"] === etag;
  const start = range && sameFile ? Number(range[1]) : 0;
  const status = start > 0 ? 206 : 200;
  console.log(`request ${requests}: range=${req.headers.range ?? "-"} -> ${status}, from byte ${start}`);
  res.writeHead(status, {
    ETag: etag,
    "Accept-Ranges": "bytes",
    "Content-Length": file.length - start,
    ...(status === 206 ? { "Content-Range": `bytes ${start}-${file.length - 1}/${file.length}` } : {}),
  });
  if (requests === 1) {
    res.write(file.subarray(start, start + 1024 * 1024)); // and then nothing more
  } else {
    res.end(file.subarray(start));
  }
}).listen(8018, "127.0.0.1");
```

The client writes into `notes.pdf.part`, keeps the server's tag beside it, and asks for the rest
when it is run again. It gives the file its real name only when every byte is there. Save it as
`download.ts`:

```typescript
// download.ts: fetch notes.pdf into notes.pdf.part, resume it from where it stopped,
// and only then give it its real name.
import { createWriteStream, existsSync, statSync, renameSync, readFileSync, writeFileSync, rmSync } from "node:fs";
import { request } from "node:http";

const URL = "http://127.0.0.1:8018/notes.pdf";
const PART = "notes.pdf.part";
const have = existsSync(PART) ? statSync(PART).size : 0;
const etag = existsSync(`${PART}.etag`) ? readFileSync(`${PART}.etag`, "utf8") : undefined;
const headers = have > 0 && etag ? { Range: `bytes=${have}-`, "If-Range": etag } : {};

const req = request(URL, { headers }, (res) => {
  const resumed = res.statusCode === 206;
  console.log(`status ${res.statusCode}, ${resumed ? `resuming at byte ${have}` : "from the start"}`);
  writeFileSync(`${PART}.etag`, String(res.headers.etag));
  const out = createWriteStream(PART, { flags: resumed ? "a" : "w" });
  res.pipe(out);
  res.on("close", () => out.end()); // what arrived before the cut is kept
  out.on("close", () => {
    const size = statSync(PART).size;
    const total = resumed ? Number(res.headers["content-range"]!.split("/")[1]) : Number(res.headers["content-length"]);
    if (size === total) {
      renameSync(PART, "notes.pdf");
      rmSync(`${PART}.etag`);
      console.log(`complete: ${size} bytes, renamed to notes.pdf`);
    } else {
      console.log(`kept ${size} of ${total} bytes in ${PART}`);
    }
  });
});
// Nothing for half a second is a dead connection on a phone: stop, and keep what arrived.
let gaveUp = false;
req.setTimeout(500, () => {
  console.log("nothing for 0.5 s: giving up for now");
  gaveUp = true;
  req.destroy();
});
req.on("error", (e) => gaveUp || console.log(`request failed: ${e.message}`));
req.end();
```

Start the server with `node server.ts` in its own terminal, then run the client twice:

```
ana@dev:~/planner/files$ node download.ts
status 200, from the start
nothing for 0.5 s: giving up for now
kept 1048576 of 3145728 bytes in notes.pdf.part
ana@dev:~/planner/files$ ls
attach.ts
attachments
blob.db
download.ts
file.db
notes.pdf.part
notes.pdf.part.etag
save.ts
server.ts
sweep.ts
ana@dev:~/planner/files$ node download.ts
status 206, resuming at byte 1048576
complete: 3145728 bytes, renamed to notes.pdf
ana@dev:~/planner/files$ ls
attach.ts
attachments
blob.db
download.ts
file.db
notes.pdf
save.ts
server.ts
sweep.ts
```

And the server's side:

```
ana@dev:~/planner/files$ node server.ts
request 1: range=- -> 200, from byte 0
request 2: range=bytes=1048576- -> 206, from byte 1048576
```

**The second run asked for byte 1048576 onwards and got a 206**, so the first megabyte crossed the
network once. Three details in the client carry the design:

- **The part file has its own name.** Nothing else in the planner opens `notes.pdf.part`, so a half
  file is never shown as a document, and the sweep in the last section knows to leave it alone.
- **The rename is the moment of completion.** Renaming within one folder is atomic on every phone's
  file system: before it there is no `notes.pdf`, after it there is a whole one.
- **A stall is a timeout of the app's choosing.** A dead connection on a phone does not always
  close; it goes quiet. Half a second suits a capture on one computer. A real app waits longer,
  tens of seconds, and lesson 9's backoff decides when to try again.

The platforms do this for you when they own the download. Android's `DownloadManager` resumes on
its own, and iOS's background `URLSession` hands back resume data from a cancelled task, which
`downloadTask(withResumeData:)` continues. *Both are named from their documentation and were not run
for this course.*
