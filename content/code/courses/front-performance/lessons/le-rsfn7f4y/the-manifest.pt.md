---
title: O manifesto
version: 1
---

**O manifesto é um arquivo JSON que descreve o app**, citado em toda página. Salve-o como
`public/manifest.webmanifest`:

```json
{
  "id": "/",
  "name": "Study planner",
  "short_name": "Planner",
  "description": "Plan your study sessions, course by course, week by week.",
  "start_url": "/",
  "scope": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#1d4ed8",
  "icons": [
    { "src": "/icons/icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/icons/icon-512.png", "sizes": "512x512", "type": "image/png" },
    { "src": "/icons/maskable-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
  ]
}
```

| membro | o que decide |
|---|---|
| `id` | a identidade do app: dois manifestos com o mesmo `id` são o mesmo app, mude o que mudar |
| `name`, `short_name` | o nome na lista de aplicativos, e embaixo do ícone onde falta espaço |
| `start_url` | a página em que o app abre |
| `scope` | os endereços que pertencem ao app; um link fora dele abre no navegador |
| `display` | `standalone` é uma janela própria sem a barra do navegador; `browser` é uma aba comum |
| `background_color` | a cor da janela antes da primeira pintura, enquanto a página carrega |
| `theme_color` | a cor da barra de título da janela, e da barra de status no Android |
| `icons` | as imagens com que o sistema desenha o app, que a próxima seção faz |

No `index.html`, duas linhas logo antes do `<title>` citam o manifesto e repetem a cor do tema para os navegadores
que a leem da página:

```html
    <link rel="manifest" href="/manifest.webmanifest" />
    <meta name="theme-color" content="#1d4ed8" />
```

E o `server.ts` aprende mais um tipo, o do próprio manifesto. Na tabela de tipos, troque a última linha de entradas
por:

```typescript
  ".png": "image/png", ".woff2": "font/woff2", ".webmanifest": "application/manifest+json",
```

## Perguntando ao navegador

**O Chromium consegue dizer se uma página é instalável, e se não, por quê**, pelo protocolo das ferramentas de
desenvolvedor: a mesma conferência que ele faz antes de oferecer a instalação. O `tools/installable.ts` pergunta.
Salve-o em `tools/`:

```typescript
// tools/installable.ts: ask Chromium whether a page could be installed as an app, and if
// not, why not: the same check the browser makes before it offers to install one.
//
//   node tools/installable.ts URL
import { chromium } from "playwright";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";

// Two things this check needs that a test browser does not have by default: the full browser,
// not the headless shell Playwright uses, which has no installer to ask; and a profile on disk,
// because nothing can be installed into a private window, which every fresh context is.
const profile = await mkdtemp(join(tmpdir(), "installable-"));
const context = await chromium.launchPersistentContext(profile, { channel: "chromium" });
const page = await context.newPage();
await page.goto(process.argv[2], { waitUntil: "networkidle" });
const cdp = await context.newCDPSession(page);
const manifest = await cdp.send("Page.getAppManifest");
console.log(`manifest: ${manifest.url || "none"}`);
const { installabilityErrors } = await cdp.send("Page.getInstallabilityErrors");
if (installabilityErrors.length === 0) console.log("installable");
for (const e of installabilityErrors) {
  const args = e.errorArguments.map((a) => `${a.name}=${a.value}`).join(", ");
  console.log(`not installable: ${e.errorId}${args ? ` (${args})` : ""}`);
}
// A page that offers its own install button, as the planner does, shows it once Chromium has
// fired beforeinstallprompt, which it does a moment after the page qualifies.
await page.waitForTimeout(3000);
if (await page.$("#install")) console.log(`install button: ${(await page.isVisible("#install")) ? "shown" : "hidden"}`);
await context.close();
await rm(profile, { recursive: true });
```

O comentário dele cita as duas coisas que faltam a um navegador de teste. Faça o build, reinicie o `server.ts` e
pergunte:

```
ana@dev:~/planner$ node tools/installable.ts http://localhost:3000/
manifest: http://localhost:3000/manifest.webmanifest
not installable: no-acceptable-icon (minimum-icon-size-in-pixels=144)
```

**O manifesto é achado, e a resposta é não: não há ícone aceitável.** O manifesto cita três ícones, e nenhum dos
arquivos existe ainda; o Chromium quer pelo menos um de 144 pixels ou mais que ele consiga carregar. A próxima seção
os desenha.
