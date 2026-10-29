---
title: A política, escrita diretiva por diretiva
version: 1
---

**Uma Content Security Policy é uma lista de diretivas, cada uma nomeando um tipo de recurso e de onde a
página pode carregá-lo.** O que a lista não permite, o navegador recusa, e diz isso no console. Para uma
página como o planner, que carrega os próprios arquivos e mais nada, a política é curta, e cada `'self'`
nela quer dizer a própria origem da página.

O `vite.config.ts` recebe os cabeçalhos uma vez, como um objeto, e os entrega ao servidor de preview:

```typescript
// vite.config.ts
import { configDefaults, defineConfig } from "vitest/config";

const securityHeaders = {
  "Content-Security-Policy": [
    "default-src 'self'",
    "script-src 'self'",
    "style-src 'self'",
    "img-src 'self'",
    "connect-src 'self'",
    "object-src 'none'",
    "base-uri 'self'",
    "form-action 'self'",
    "frame-ancestors 'none'",
  ].join("; "),
  "X-Content-Type-Options": "nosniff",
  "Referrer-Policy": "strict-origin-when-cross-origin",
  "Permissions-Policy": "camera=(), microphone=(), geolocation=()",
  "Cross-Origin-Opener-Policy": "same-origin",
};

export default defineConfig({
  server: {
    proxy: { "/api": "http://127.0.0.1:3000" },
  },
  preview: {
    headers: securityHeaders,
  },
  test: {
    exclude: [...configDefaults.exclude, "e2e/**"],
  },
});
```

| diretiva ou cabeçalho | o que diz | por que o planner quer |
|---|---|---|
| `default-src 'self'` | o padrão para todo tipo não nomeado | o que for esquecido abaixo continua limitado |
| `script-src 'self'` | scripts só desta origem, **e nenhum script inline** | um `<script>` injetado não roda |
| `style-src 'self'` | folhas de estilo só desta origem, nenhum `<style>` inline | o build tem um arquivo de estilo |
| `img-src 'self'` | imagens só daqui | o `book.svg` é a única |
| `connect-src 'self'` | `fetch` e WebSocket só para cá | um script que rodasse não conseguiria mandar dados para outro lugar |
| `object-src 'none'` | nenhum plugin | nada legítimo precisa deles |
| `base-uri 'self'` | nenhum `<base>` apontando para fora | um `<base>` faria todo endereço relativo virar de outra pessoa |
| `form-action 'self'` | formulários só enviam para cá | um formulário injetado não consegue mandar seus dados embora |
| `frame-ancestors 'none'` | nenhuma outra página pode pôr esta num frame | aula 9, clickjacking |
| `X-Content-Type-Options: nosniff` | acreditar no `Content-Type`, nunca adivinhar | um arquivo servido como texto nunca roda como script |
| `Referrer-Policy` | mandar a outros sites só a origem, nunca o endereço inteiro | endereços podem levar o que outros sites não devem ver |
| `Permissions-Policy` | nada de câmera, microfone ou localização, nesta página ou em algo dentro dela | o planner não usa nenhum |
| `Cross-Origin-Opener-Policy: same-origin` | uma janela que esta página abre, ou que a abriu, não consegue mexer nela | a aba de outro site perde o acesso a esta |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l08-policy\" aria-label=\"Cinco coisas que a página do planner pode tentar rodar ou carregar, cada uma conferida contra a sua Content Security Policy. O próprio script de /assets é permitido pelo script-src 'self'. Um script inline acrescentado à página é recusado pela mesma diretiva. Um script de outra origem é recusado pelo script-src 'self'. Um fetch para outra origem é recusado pelo connect-src 'self'. Outro site pondo a página num frame é recusado pelo frame-ancestors 'none'.\"><defs><marker id=\"l08-policy-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l08-policy-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l08-policy-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"130\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">o que a página tenta</text><text x=\"420\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">a diretiva que decide</text><rect x=\"14\" y=\"34\" width=\"236\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"132.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">o próprio /assets/index-….js</text><path d=\"M250 50 L330 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-policy-ah-paper-dim)\"></path><rect x=\"330\" y=\"34\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"420.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">script-src 'self'</text><path d=\"M510 50 L580 50\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-policy-ah-phosphor)\"></path><rect x=\"580\" y=\"34\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"640.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">roda</text><rect x=\"14\" y=\"76\" width=\"236\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"132.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">um &lt;script&gt; acrescentado à página</text><path d=\"M250 92 L330 92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-policy-ah-paper-dim)\"></path><rect x=\"330\" y=\"76\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"420.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">script-src 'self'</text><path d=\"M510 92 L580 92\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-policy-ah-amber)\"></path><rect x=\"580\" y=\"76\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"640.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">recusado</text><rect x=\"14\" y=\"118\" width=\"236\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"132.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">um script de outra origem</text><path d=\"M250 134 L330 134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-policy-ah-paper-dim)\"></path><rect x=\"330\" y=\"118\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"420.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">script-src 'self'</text><path d=\"M510 134 L580 134\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-policy-ah-amber)\"></path><rect x=\"580\" y=\"118\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"640.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">recusado</text><rect x=\"14\" y=\"160\" width=\"236\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"132.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">fetch() para outra origem</text><path d=\"M250 176 L330 176\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-policy-ah-paper-dim)\"></path><rect x=\"330\" y=\"160\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"420.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">connect-src 'self'</text><path d=\"M510 176 L580 176\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-policy-ah-amber)\"></path><rect x=\"580\" y=\"160\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"640.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">recusado</text><rect x=\"14\" y=\"202\" width=\"236\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"132.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">outro site pondo a página num frame</text><path d=\"M250 218 L330 218\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-policy-ah-paper-dim)\"></path><rect x=\"330\" y=\"202\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"420.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">frame-ancestors 'none'</text><path d=\"M510 218 L580 218\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-policy-ah-amber)\"></path><rect x=\"580\" y=\"202\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"640.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">recusado</text></svg>", "caption": "Cada carregamento passa por uma diretiva. Os arquivos da própria página passam; tudo o que não é da página, inclusive um texto que virou script, é recusado antes de rodar."}
```

**O `script-src 'self'` é a linha que justifica a política.** A aula 9 mostra texto virando marcação; com
esta linha, a marcação que vira um `<script>` é recusada pelo navegador, uma segunda defesa atrás da
primeira.

```
ana@dev:~/planner$ npx playwright test e2e/headers.spec.ts --reporter=list

Running 2 tests using 1 worker

  ✓  1 [chromium] › e2e/headers.spec.ts:6:1 › the built site is served with its security headers (41ms)
  ✓  2 [chromium] › e2e/headers.spec.ts:16:1 › the built site works under its own policy (214ms)

  2 passed (3.7s)
```

Os dois testes passam: os cabeçalhos estão lá, e a página carrega sob eles sem nada no console.

```
ana@dev:~/planner$ curl -s -I http://localhost:4173/
HTTP/1.1 200 OK
Vary: Origin
Content-Type: text/html
Cache-Control: no-cache
Etag: W/"1a1-oQnFYEXs7j/YT1F2ilqAR+fppH0"
Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self'; connect-src 'self'; object-src 'none'; base-uri 'self'; form-action 'self'; frame-ancestors 'none'
X-Content-Type-Options: nosniff
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
Cross-Origin-Opener-Policy: same-origin
Date: Fri, 23 Oct 2026 23:28:57 GMT
Connection: keep-alive
Keep-Alive: timeout=5
```

```
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "Serve the build with a Content Security Policy and four other headers"
```
