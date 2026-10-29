---
title: Uma CDN só sua
version: 1
---

**Uma CDN é um cache que muitos visitantes dividem**, em servidores perto deles: um visitante em São Paulo é
respondido de São Paulo, e só o primeiro a pedir um arquivo faz a CDN perguntar à origem, o servidor da
própria aplicação. Cada CDN difere nos detalhes, e todas seguem os cabeçalhos da seção "Os cabeçalhos que
decidem".

O `tools/edge.ts` é uma CDN reduzida à parte que importa para esses cabeçalhos: um servidor na porta 8000 que
repassa cada requisição ao `server.ts`, guarda as respostas que um cache compartilhado pode guardar, pelo
tempo que podem ser guardadas, e responde do estoque quando pode. Ele acrescenta `x-cache: HIT` ou `MISS`,
como a maioria das CDNs faz com algum nome, e o `Age`. Salve-o em `tools/`:

```typescript
// tools/edge.ts: a small CDN in front of server.ts. It keeps the answers the headers allow a
// shared cache to keep, for as long as they allow, and says in x-cache whether an answer came
// from its store and in age how many seconds it has been there.
//
//   node tools/edge.ts        (listens on 8000, asks http://localhost:3000)
import { createServer, request, type IncomingHttpHeaders } from "node:http";

type Kept = { status: number; headers: IncomingHttpHeaders; body: Buffer; at: number; life: number };
const store = new Map<string, Kept>();

// How many seconds a shared cache may keep an answer: s-maxage if there is one, else max-age;
// nothing for private, no-store or no-cache, which this edge does not try to revalidate.
const life = (cacheControl = "") => {
  if (/private|no-store|no-cache/.test(cacheControl)) return 0;
  const m = cacheControl.match(/s-maxage=(\d+)/) ?? cacheControl.match(/max-age=(\d+)/);
  return m ? Number(m[1]) : 0;
};

createServer((req, res) => {
  // The address, and the one header the origin says its answers vary on.
  const key = `${req.method} ${req.url} ${req.headers["accept-encoding"] ?? ""}`;
  const kept = store.get(key);
  const age = kept ? Math.floor((Date.now() - kept.at) / 1000) : 0;
  if (kept && age < kept.life) {
    res.writeHead(kept.status, { ...kept.headers, age: String(age), "x-cache": "HIT" }).end(kept.body);
    return;
  }
  const ask = request(`http://localhost:3000${req.url}`, { method: req.method, headers: req.headers }, (answer) => {
    const chunks: Buffer[] = [];
    answer.on("data", (c) => chunks.push(c));
    answer.on("end", () => {
      const body = Buffer.concat(chunks);
      // These describe one connection, not the answer, so they are not kept or passed on.
      const { connection, "keep-alive": _, "transfer-encoding": __, ...headers } = answer.headers;
      const keep = req.method === "GET" && answer.statusCode === 200 ? life(headers["cache-control"]) : 0;
      if (keep > 0) store.set(key, { status: 200, headers, body, at: Date.now(), life: keep });
      res.writeHead(answer.statusCode!, { ...headers, "x-cache": "MISS" }).end(body);
    });
  });
  req.pipe(ask);
}).listen(8000, () => console.log("edge on http://localhost:8000, in front of :3000"));
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Três caixas em linha: navegadores à esquerda, o edge no meio, o server.ts à direita. Uma requisição de que o edge tem uma cópia fresca é respondida pelo edge, um HIT, e nunca chega ao server.ts. Uma de que ele não tem cópia fresca é repassada, um MISS, e a resposta é guardada se os cabeçalhos deixarem um cache compartilhado guardá-la.\"><rect x=\"30\" y=\"70\" width=\"140\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"100\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">navegadores</text><rect x=\"290\" y=\"70\" width=\"140\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">edge.ts · :8000</text><rect x=\"550\" y=\"70\" width=\"140\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"620\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">server.ts · :3000</text><line x1=\"172\" y1=\"88\" x2=\"288\" y2=\"88\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"288.0,88.0 280.6,91.1 280.6,84.9\" fill=\"var(--phosphor)\"></polygon><text x=\"230\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">requisição</text><line x1=\"288\" y1=\"112\" x2=\"172\" y2=\"112\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"172.0,112.0 179.4,108.9 179.4,115.1\" fill=\"var(--phosphor)\"></polygon><text x=\"230\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">HIT · age</text><line x1=\"432\" y1=\"88\" x2=\"548\" y2=\"88\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><polygon points=\"548.0,88.0 540.6,91.1 540.6,84.9\" fill=\"var(--amber)\"></polygon><text x=\"490\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">MISS</text><line x1=\"548\" y1=\"112\" x2=\"432\" y2=\"112\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><polygon points=\"432.0,112.0 439.4,108.9 439.4,115.1\" fill=\"var(--amber)\"></polygon><text x=\"490\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">resposta + cabeçalhos</text><text x=\"360\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">guardada se o s-maxage ou o max-age deixar,</text><text x=\"360\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nunca se private, no-store ou no-cache</text></svg>", "caption": "Um HIT é uma requisição de que a origem nunca fica sabendo."}
```

Duas simplificações, e as duas são honestas sobre uma CDN de verdade: ele guarda uma cópia por codificação,
onde uma de verdade primeiro normaliza o `Accept-Encoding` em poucos valores; e ele não reconfere, então uma
resposta marcada `no-cache` é repassada em vez de guardada e conferida. Inicie-o num segundo terminal:

```
ana@dev:~/planner$ node tools/edge.ts
edge on http://localhost:8000, in front of :3000
```

e peça a ele duas vezes um script, com dois segundos de intervalo, e duas vezes uma página:

```
ana@dev:~/planner$ A=$(ls dist/assets | grep -m1 '^index.*js'); for i in 1 2; do curl -s -o /dev/null -D - http://localhost:8000/assets/$A | grep -iE '^(x-cache|age)'; sleep 2; done
x-cache: MISS
age: 2
x-cache: HIT
ana@dev:~/planner$ for i in 1 2; do curl -s -o /dev/null -D - http://localhost:8000/courses/git | grep -iE '^(x-cache|age)'; done
x-cache: MISS
x-cache: MISS
```

**O script foi um MISS e depois um HIT, com dois segundos de idade.** A segunda requisição nunca chegou ao
`server.ts`. **A página foi MISS as duas vezes**: `no-cache` é uma ordem para conferir, e este edge não
confere, então pergunta à origem toda vez. Isso é correto para o navegador e um desperdício para uma CDN: uma
página que é a mesma para todo mundo poderia ficar no edge por um tempo, e a próxima seção diz isso com o
`s-maxage`.

O navegador atrás do edge não vê diferença nenhuma, porque o edge repassa os cabeçalhos da origem:

```
ana@dev:~/planner$ node tools/revisit.ts http://localhost:8000/courses/git
/courses/git                   304, kept its copy
/fonts/plex-400.woff2          304, kept its copy
/fonts/plex-700.woff2          304, kept its copy
/assets/index-B_kobX3K.js      from the cache, not asked
/assets/planner-BNdUlffC.js    from the cache, not asked
/covers/git-800.avif           304, kept its copy
```
