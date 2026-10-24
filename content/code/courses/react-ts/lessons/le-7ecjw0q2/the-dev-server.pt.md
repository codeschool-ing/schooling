---
title: O que o servidor de desenvolvimento faz
version: 1
---

**O servidor de desenvolvimento do Vite não faz build do planejador.** Ele serve cada arquivo quando o
navegador o pede, traduzido no caminho: TypeScript e JSX entram, JavaScript simples sai. Os navegadores
entendem `import` há anos, então o próprio navegador segue os imports, uma requisição por módulo:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --network | grep -E 'GET /(src|node_modules)' | head -n 12
net  GET /src/main.tsx  200
net  GET /node_modules/.vite/deps/react-router_dom.js?v=a137e1be  200
net  GET /node_modules/.vite/deps/react.js?v=a137e1be  200
net  GET /src/courseLoader.ts  200
net  GET /src/index.css  200
net  GET /node_modules/.vite/deps/@tanstack_react-query.js?v=a137e1be  200
net  GET /src/PlannerProvider.tsx  200
net  GET /src/queryClient.ts  200
net  GET /src/ErrorBoundary.tsx  200
net  GET /node_modules/.vite/deps/react-router.js?v=a137e1be  200
net  GET /src/Root.tsx  200
net  GET /src/WeekScreen.tsx  200
ana@dev:~/planner$ ls node_modules/.vite/deps | grep -v '\.map$'
@hookform_resolvers_zod.js
@tanstack_react-query.js
_metadata.json
development-CEpG6Jw9.js
jsx-runtime-cNwuCTLA.js
package.json
react-4hkZzRew.js
react-dom-CRx58tZq.js
react-dom.js
react-dom_client.js
react-hook-form.js
react-router.js
react-router_dom.js
react.js
react_jsx-dev-runtime.js
react_jsx-runtime.js
rolldown-runtime-SbdDWaPq.js
zod.js
```

- **`/src/main.tsx`, `/src/Root.tsx` e o resto são arquivos seus**, cada um buscado quando algo o importa,
  e traduzido quando é buscado. Mudar um significa traduzir um, e por isso uma edição aparece no
  navegador quase na hora, e o servidor inicia numa fração de segundo seja qual for o tamanho do projeto.
- **As dependências são a exceção.** React, React Router e React Query são, cada um, centenas de módulos
  pequenos, e buscá-los um a um seria lento, então o Vite **os empacota antes** em `node_modules/.vite/deps`,
  um arquivo por pacote que o código importa. O `?v=a137e1be` é um hash desse trabalho: muda quando as
  dependências mudam, então o navegador pode guardar esses arquivos pelo tempo que quiser.

A listagem também tem arquivos com nomes com hash, `react-4hkZzRew.js` e companhia: código que vários dos
pacotes empacotados compartilham, guardado uma vez em vez de copiado em cada um.

A aula 1 prometeu uma flag. Por padrão o servidor só responde em `localhost`, esta máquina. O **`--host`**
o faz responder também nos endereços de rede da máquina, para um celular na mesma rede abrir o
planejador, que é o teste mais rápido de um layout numa tela pequena de verdade:

```

> planner@0.0.0 dev
> vite --host


  VITE v8.3.5  ready in 217 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: http://192.0.2.2:5173/  eth0
```

O `--` passa a flag pelo `npm run dev` até o `vite`. A linha `Network` é o endereço a digitar no celular;
o daqui é o da máquina do laboratório. A flag significa o que diz: **qualquer um na mesma rede** pode
abri-lo, então na rede de um café, deixe-a desligada.

```schooling-figure
{"svg": "<svg data-fig=\"dev-and-build\" viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Dois jeitos de o mesmo código chegar a um navegador. Com o servidor de desenvolvimento: cada arquivo de src é traduzido quando o navegador o pede, uma requisição por módulo, e as dependências vêm pré-empacotadas de node_modules/.vite/deps. Com um build: tudo é empacotado antes em poucos arquivos em dist/assets com nomes com hash, mais o index.html e os arquivos de public.\"><text x=\"170\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">npm run dev</text><rect x=\"30\" y=\"36\" width=\"170\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">/src/main.tsx</text><rect x=\"30\" y=\"70\" width=\"170\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">/src/Root.tsx</text><rect x=\"30\" y=\"104\" width=\"170\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">/src/WeekScreen.tsx</text><rect x=\"30\" y=\"138\" width=\"170\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">…</text><rect x=\"30\" y=\"176\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"189.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">.vite/deps/</text><text x=\"115.0\" y=\"202.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">react.js · …</text><text x=\"215\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma requisição</text><text x=\"215\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">por módulo</text><line x1=\"360\" y1=\"20\" x2=\"360\" y2=\"220\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><text x=\"540\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">npm run build</text><rect x=\"400\" y=\"40\" width=\"280\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">dist/index.html</text><rect x=\"400\" y=\"82\" width=\"280\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">assets/index-R8L4SX4s.js</text><rect x=\"400\" y=\"124\" width=\"280\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"139.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">assets/CourseScreen-jvv40fJe.js</text><rect x=\"400\" y=\"166\" width=\"280\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">courses.json · favicon.svg</text><text x=\"540\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">copiados de public/, sem hash</text></svg>", "caption": "O desenvolvimento traduz sob pedido; um build empacota antes."}
```
