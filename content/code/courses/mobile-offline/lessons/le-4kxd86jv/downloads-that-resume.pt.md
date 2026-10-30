---
title: Um download que retoma de onde parou
version: 1
---

**Um arquivo grande num celular é baixado em pedaços, você planejando ou não, então planeje.** Um
trem entra num túnel, a pessoa sai do Wi-Fi, o sistema suspende o app: cada um para um download no
meio. Recomeçar do byte zero desperdiça o que já chegou, e numa conexão lenta um arquivo de 30 MB
que recomeça a cada interrupção pode nunca terminar.

O HTTP tem a resposta desde 1999. O cliente pede **uma faixa de bytes**, `Range: bytes=1048576-`
querendo dizer "deste byte até o fim", e um servidor que aceita isso responde **206 Partial
Content** só com essa parte. Mais dois cabeçalhos tornam isso seguro:

| cabeçalho | para que serve |
|---|---|
| `Accept-Ranges: bytes` | o servidor diz que sabe responder a um `Range` |
| `Content-Range: bytes 1048576-3145727/3145728` | que parte é esta, e o tamanho do todo |
| `If-Range: "<etag>"` | mande a faixa só se o arquivo ainda for o desta etiqueta; senão mande inteiro |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l18-resume\" aria-label=\"Um arquivo de 3 MB como uma barra de bytes. A requisição 1, sem Range, recebe um 200 e trava depois do primeiro megabyte, que fica guardado em notes.pdf.part. A requisição 2 pede Range: bytes=1048576- com If-Range e a etiqueta, recebe um 206 Partial Content e acrescenta os dois megabytes restantes. Só então o arquivo parcial é renomeado para notes.pdf, e só então uma linha é gravada.\"><defs><marker id=\"l18-resume-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l18-resume-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l18-resume-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"40\" y=\"90\" width=\"200.0\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"240.0\" y=\"90\" width=\"400.0\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"140.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0 – 1048575</text><text x=\"440.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1048576 – 3145727</text><text x=\"40\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">requisição 1: sem Range</text><text x=\"40\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">200, trava depois de 1 MB</text><path d=\"M140.0 62 L140.0 88\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-resume-ah-phosphor)\"></path><text x=\"256.0\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">requisição 2: Range: bytes=1048576-</text><text x=\"256.0\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">206 Partial Content, o resto</text><path d=\"M440.0 62 L440.0 88\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-resume-ah-amber)\"></path><text x=\"40\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">guardado em</text><text x=\"114\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">notes.pdf.part</text><path d=\"M646 110 L680 110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-resume-ah-paper-dim)\"></path><text x=\"636\" y=\"180\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">depois renomeado</text><text x=\"644\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">notes.pdf</text><text x=\"636\" y=\"200\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">e só então a linha</text></svg>", "caption": "O primeiro megabyte atravessa a rede uma vez só. O arquivo parcial tem nome próprio até o último byte chegar."}
```

O `If-Range` é o que as pessoas esquecem. Sem ele, um arquivo que mudou no servidor entre as duas
requisições é retomado em cima do fim do antigo, e o resultado é um arquivo feito de duas versões
que nenhum hash vai bater.

## Um servidor que trava, e um cliente que retoma

O servidor tem um arquivo de 3 MB, preenchido com os mesmos bytes em toda execução. Ele responde a
faixas, e a primeira resposta para depois de 1 MB e não manda mais nada, que é como uma conexão
num túnel parece vista do celular. Salve na `~/planner/files` como `server.ts`:

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

O cliente grava em `notes.pdf.part`, guarda a etiqueta do servidor ao lado e pede o resto quando é
rodado de novo. Ele só dá ao arquivo o nome de verdade quando todos os bytes estão lá. Salve como
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

Inicie o servidor com `node server.ts` num terminal só dele, depois rode o cliente duas vezes:

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

E o lado do servidor:

```
ana@dev:~/planner/files$ node server.ts
request 1: range=- -> 200, from byte 0
request 2: range=bytes=1048576- -> 206, from byte 1048576
```

**A segunda execução pediu do byte 1048576 em diante e recebeu um 206**, então o primeiro megabyte
atravessou a rede uma vez só. Três detalhes do cliente carregam o desenho:

- **O arquivo parcial tem nome próprio.** Nada mais no planner abre `notes.pdf.part`, então um
  arquivo pela metade nunca é mostrado como documento, e a varredura da última seção sabe que deve
  deixá-lo em paz.
- **A renomeação é o momento da conclusão.** Renomear dentro de uma pasta é atômico no sistema de
  arquivos de todo celular: antes dela não existe `notes.pdf`, depois dela existe um inteiro.
- **Uma trava é um tempo limite que o app escolhe.** Uma conexão morta num celular nem sempre fecha;
  ela fica em silêncio. Meio segundo serve para uma captura num computador só. Um app de verdade
  espera mais, dezenas de segundos, e o recuo da aula 9 decide quando tentar de novo.

As plataformas fazem isso por você quando são donas do download. O `DownloadManager` do Android
retoma sozinho, e a `URLSession` em segundo plano do iOS devolve os dados de retomada de uma tarefa
cancelada, que o `downloadTask(withResumeData:)` continua. *Os dois são citados da documentação
deles e não foram rodados para este curso.*
