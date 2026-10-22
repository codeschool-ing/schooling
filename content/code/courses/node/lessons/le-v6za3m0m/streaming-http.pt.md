---
title: Streams por HTTP
version: 1
---

**Uma requisição é um stream de leitura e uma resposta é um de escrita**, então tudo nesta aula funciona
entre um arquivo e um cliente. Duas rotas mostram as duas direções: mandar um arquivo grande sem
segurá-lo, e receber um upload direto no disco com um limite.

```schooling-example
{"language": "javascript", "file": "transfer.js", "parts": [
 {"code": "import express from \"express\";\nimport { createReadStream, createWriteStream } from \"node:fs\";\nimport { rm, stat } from \"node:fs/promises\";\nimport path from \"node:path\";\nimport { pipeline } from \"node:stream/promises\";\n\nconst app = express();\nconst log = path.join(import.meta.dirname, \"access.log\");\n\napp.get(\"/log\", async (req, res) => {\n  const { size } = await stat(log);\n  res.set({ \"content-type\": \"text/plain; charset=utf-8\", \"content-length\": size });\n  try {\n    await pipeline(createReadStream(log), res);\n  } catch (err) {\n    console.log(`download stopped: ${err.code}`);\n  }\n});", "note": "**Um download.** O `stat` dá o tamanho para o `content-length` antes de um byte ser mandado, e o `pipeline` copia o arquivo para a resposta um pedaço de cada vez, desacelerando para um cliente lento."},
 {"code": "app.put(\"/upload\", async (req, res) => {\n  const target = path.join(import.meta.dirname, \"upload.bin\");\n  let received = 0;\n  const limit = 10 * 1024 * 1024;\n  try {\n    await pipeline(\n      req,\n      async function* (source) {\n        for await (const chunk of source) {\n          received += chunk.length;\n          if (received > limit) throw Object.assign(new Error(\"too large\"), { status: 413 });\n          yield chunk;\n        }\n      },\n      createWriteStream(target),\n    );\n    res.status(201).json({ received });\n  } catch (err) {\n    await rm(target, { force: true });\n    res.status(err.status ?? 500).json({ error: err.message });\n  }\n});\n\napp.listen(3000, \"127.0.0.1\");", "note": "**Um upload, com um limite contado à medida que chega**, como a aula 5 contava um corpo: um transform que passa cada pedaço adiante e faz o pipeline falhar no momento em que o total passa do limite."}
]}
```

O estágio do meio do upload é uma **função geradora assíncrona**, que o `pipeline` aceita como
transform: ela lê pedaços com `for await` e os passa adiante com `yield`. O próprio Express está em
`~/server/links/node_modules`, então esta demonstração fica em `~/server/links/demo`, e lê o log de
acessos copiado para lá. Com ela rodando:

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

O `curl -T -` envia, com PUT, o que chegar pelo pipe. **O download e o upload rodaram cada um com
poucos pedaços na memória**, seja qual for o tamanho. O upload grande demais foi parado no limite, o
arquivo parcial removido, e respondido com 413. O último download foi desacelerado pelo `--limit-rate`
para um mebibyte por segundo, e o servidor simplesmente esperou por ele, a contrapressão da seção sobre
ela; depois o `-m 1` fez o cliente desistir depois de um segundo, e o `pipeline` percebeu, parou de ler
o arquivo, e relatou isso no terminal do servidor:

```
ana@dev:~/server/links$ node demo/transfer.js
download stopped: ERR_STREAM_PREMATURE_CLOSE
^C
```

Uma rota que mandasse o arquivo com `readFile` e `res.send` seguraria 130 megabytes por download e
continuaria lendo o arquivo para um cliente que já tinha ido embora.
