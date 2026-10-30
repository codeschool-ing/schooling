---
title: Mandando uma página em pedaços
version: 1
---

**Uma resposta HTTP não precisa estar completa antes de ser mandada.** Um servidor pode mandar o
começo de uma página, manter a conexão aberta, e mandar o resto quando o tiver. O navegador lê o HTML
conforme ele chega e desenha o que tem, então a parte que foi rápida aparece enquanto a parte lenta
ainda está sendo feita. Isso é **streaming**, e todo servidor deste curso já conseguia fazê-lo: o
`res.write` manda um pedaço, o `res.end` manda o último.

A ideia comum é que renderizar no servidor quer dizer esperar a consulta mais lenta antes de mandar
qualquer coisa. O `server.ts` da aula 1 faz exatamente isso: lê o plano inteiro, desenha a página
inteira, e só então escreve um byte. Se as sessões viessem de um banco lento, o título, o link e o
formulário, que não precisam de nada disso, esperariam também.

## Uma página em duas partes

O `stream.ts` é um servidor pequeno para uma página, a de um curso, que a manda em duas partes. **As
sessões são lentas de propósito**: o `sessionsOf` espera um segundo antes de lê-las, no papel de uma
consulta lenta. Todo o resto vai na hora. Salve ao lado do `server.ts`:

```schooling-example
{"language": "typescript", "file": "stream.ts", "parts": [
 {"code": "// stream.ts: a course page sent in two parts over one response. Everything that\n// is quick goes at once, with a placeholder; the sessions follow when they are\n// ready, with a few lines of script that put them where the placeholder was.\nimport { createServer } from \"node:http\";\nimport { readFile } from \"node:fs/promises\";\nimport { join } from \"node:path\";\nimport type { Plan } from \"./src/planner.ts\";\n\nconst dist = join(import.meta.dirname, \"dist\");\nconst esc = (s: string) => s.replace(/[&<>\"']/g, (c) => `&#${c.charCodeAt(0)};`);\nconst read = async (): Promise<Plan> => JSON.parse(await readFile(join(dist, \"courses.json\"), \"utf8\"));", "note": "Um servidor próprio, na porta 3005, para o server.ts continuar funcionando ao lado."},
 {"code": "// The sessions are slow on purpose: the second's wait stands for a slow database query.\nasync function sessionsOf(slug: string) {\n  await new Promise((done) => setTimeout(done, 1000));\n  return (await read()).sessions.filter((s) => s.course === slug);\n}", "note": "A parte lenta. Nada mais no arquivo espera por ela."},
 {"code": "createServer(async (req, res) => {\n  const slug = new URL(req.url ?? \"/\", \"http://localhost\").pathname.split(\"/\")[2];\n  const course = (await read()).courses.find((c) => c.slug === slug);\n  if (!course) {\n    // Decided before the first byte, so it can still be a 404.\n    res.writeHead(404, { \"content-type\": \"text/plain\" }).end(\"no such course\\n\");\n    return;\n  }", "note": "Se o curso existe é rápido de descobrir, então é decidido antes de qualquer coisa ser mandada, e um curso desconhecido ainda pode receber um 404."},
 {"code": "  res.writeHead(200, { \"content-type\": \"text/html; charset=utf-8\" });\n  res.write(`<!doctype html>\n<html lang=\"en\"><head><meta charset=\"utf-8\"><title>${esc(course.title)}</title></head>\n<body><main><p><a href=\"/\">All courses</a></p><h1>${esc(course.title)}</h1>\n<ul id=\"sessions\"><li>Loading sessions…</li></ul></main>\n`);", "note": "O primeiro pedaço: o status, os cabeçalhos, e a página até um marcador na lista. O res.write o manda agora e deixa a resposta aberta."},
 {"code": "  const rows = (await sessionsOf(slug)).map((s) => `<li>${s.date} · ${s.minutes} min</li>`).join(\"\");\n  res.end(`<template id=\"later\">${rows}</template>\n<script>document.getElementById(\"sessions\").replaceChildren(document.getElementById(\"later\").content)</script>\n</body></html>\n`);\n}).listen(3005, () => console.log(\"streaming on http://localhost:3005\"));", "note": "O segundo pedaço, um segundo depois: as sessões dentro de um template, que o navegador interpreta e não mostra, e um script que as move para a lista no lugar do marcador."}
]}
```

Ligue-o num terceiro terminal com `node stream.ts`. Para ver os pedaços, o `tools/chunks.ts` pede uma
página com o `fetch` do Node e imprime cada pedaço do corpo conforme ele chega, com o tempo desde a
requisição. Salve em `tools/`:

```typescript
// tools/chunks.ts: ask for a page and print each piece of the response as it
// arrives: how long after the request, how many bytes, and how it begins.
//
//   node tools/chunks.ts URL
const start = performance.now();
const response = await fetch(process.argv[2]);
console.log(`${Math.round(performance.now() - start)} ms  status ${response.status}`);
const decoder = new TextDecoder();
for await (const chunk of response.body!) {
  const text = decoder.decode(chunk, { stream: true }).replace(/\s+/g, " ");
  console.log(`${Math.round(performance.now() - start)} ms  ${chunk.length} bytes  ${text.slice(0, 60)}`);
}
```

```
ana@dev:~/planner$ node tools/chunks.ts http://localhost:3005/courses/git
49 ms  status 200
50 ms  204 bytes  <!doctype html> <html lang="en"><head><meta charset="utf-8">
1049 ms  217 bytes  <template id="later"><li>2026-10-24 · 25 min</li><li>2026-10
ana@dev:~/planner$ node tools/chunks.ts http://localhost:3005/courses/nonsense
49 ms  status 404
50 ms  15 bytes  no such course 
```

**O status e o primeiro pedaço chegaram juntos, e o segundo um segundo depois**, exatamente onde está
a espera. Um curso desconhecido recebeu o seu 404 na hora, porque o servidor procurou o curso antes de
escrever qualquer coisa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"A resposta do stream.ts ao longo do tempo. Aos 50 milissegundos chega o primeiro pedaço: o head, o título e um marcador Loading sessions, que o navegador desenha. Aos 1049 milissegundos chega o segundo pedaço: as sessões num template e um script que as move para a lista.\"><line x1=\"40\" y1=\"150\" x2=\"680\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"680.0,150.0 672.6,153.1 672.6,146.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"680\" y=\"168\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ms</text><rect x=\"65.83333333333334\" y=\"40\" width=\"200\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"165.83333333333334\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">pedaço 1 · 50 ms</text><text x=\"79.83333333333334\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&lt;h1&gt;Git&lt;/h1&gt;</text><text x=\"79.83333333333334\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&lt;li&gt;Loading sessions…</text><rect x=\"431.98333333333335\" y=\"40\" width=\"200\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"531.9833333333333\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">pedaço 2 · 1049 ms</text><text x=\"445.98333333333335\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&lt;template&gt;…&lt;/template&gt;</text><text x=\"445.98333333333335\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&lt;script&gt;…replaceChildren</text><line x1=\"65.83333333333334\" y1=\"132\" x2=\"65.83333333333334\" y2=\"148\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"581.9833333333333\" y1=\"132\" x2=\"581.9833333333333\" y2=\"148\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><text x=\"40\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Uma resposta, uma conexão; o navegador desenha o pedaço 1 um segundo antes de o pedaço 2 existir.</text></svg>", "caption": "A parte rápida não fica refém da lenta."}
```
