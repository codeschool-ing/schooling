---
title: Streams over HTTP
version: 1
---

**A request is a readable stream and a response is a writable one**, so everything in this lesson
works between a file and a client. Two routes show the two directions: sending a large file without
holding it, and receiving an upload straight onto disk with a limit.

```schooling-example
{"language": "javascript", "file": "transfer.js", "parts": [
 {"code": "import express from \"express\";\nimport { createReadStream, createWriteStream } from \"node:fs\";\nimport { rm, stat } from \"node:fs/promises\";\nimport path from \"node:path\";\nimport { pipeline } from \"node:stream/promises\";\n\nconst app = express();\nconst log = path.join(import.meta.dirname, \"access.log\");\n\napp.get(\"/log\", async (req, res) => {\n  const { size } = await stat(log);\n  res.set({ \"content-type\": \"text/plain; charset=utf-8\", \"content-length\": size });\n  try {\n    await pipeline(createReadStream(log), res);\n  } catch (err) {\n    console.log(`download stopped: ${err.code}`);\n  }\n});", "note": "**A download.** `stat` gives the size for `content-length` before a byte is sent, and `pipeline` copies the file to the response a chunk at a time, slowing down for a slow client."},
 {"code": "app.put(\"/upload\", async (req, res) => {\n  const target = path.join(import.meta.dirname, \"upload.bin\");\n  let received = 0;\n  const limit = 10 * 1024 * 1024;\n  try {\n    await pipeline(\n      req,\n      async function* (source) {\n        for await (const chunk of source) {\n          received += chunk.length;\n          if (received > limit) throw Object.assign(new Error(\"too large\"), { status: 413 });\n          yield chunk;\n        }\n      },\n      createWriteStream(target),\n    );\n    res.status(201).json({ received });\n  } catch (err) {\n    await rm(target, { force: true });\n    res.status(err.status ?? 500).json({ error: err.message });\n  }\n});\n\napp.listen(3000, \"127.0.0.1\");", "note": "**An upload, with a limit counted as it arrives**, as lesson 5 counted a body: a transform that passes each chunk on and fails the pipeline the moment the total goes over."}
]}
```

The middle stage of the upload is an **async generator function**, which `pipeline` accepts as a
transform: it reads chunks with `for await` and passes them on with `yield`. Express itself is in
`~/server/links/node_modules`, so this demo lives in `~/server/links/demo`, and reads the access log
copied there. With it running:

```
ana@dev:~/server/links$ curl -s -o /dev/null -w '%{size_download} bytes in %{time_total} s\n' http://127.0.0.1:3000/log
132612041 bytes in 0.183950 s
ana@dev:~/server/links$ head -c 5000000 /dev/zero | curl -s -T - http://127.0.0.1:3000/upload
{"received":5000000}
ana@dev:~/server/links$ head -c 12000000 /dev/zero | curl -s -T - http://127.0.0.1:3000/upload
{"error":"too large"}
ana@dev:~/server/links$ ls demo/upload.bin
ls: cannot access 'demo/upload.bin': No such file or directory
ana@dev:~/server/links$ curl -s -o /dev/null --limit-rate 1M -m 1 http://127.0.0.1:3000/log; echo "curl exit code $?"

curl exit code 28
```

`curl -T -` uploads, with PUT, whatever is piped into it. **The download and the upload each ran with
a few chunks in memory**, whatever their size. The oversized upload was stopped at the limit, its
partial file removed, and answered 413. The last download was slowed by `--limit-rate` to a mebibyte a second, and the server simply waited
for it: the backpressure of the section on it. Then `-m 1` made the client give up after a second,
and `pipeline` noticed, stopped reading the file, and reported it in the server's terminal:

```
ana@dev:~/server/links$ node demo/transfer.js
download stopped: ERR_STREAM_PREMATURE_CLOSE
^C
```

A route that sent the file with `readFile` and `res.send` would hold 130 megabytes per download and
keep reading the file for a client that had already left.
