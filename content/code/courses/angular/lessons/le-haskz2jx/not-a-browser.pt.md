---
title: O servidor não é um navegador
version: 1
---

**No servidor não há janela, nem `localStorage`, nem layout, nem foco, e o código que procura por
eles falha lá.** Reinicie o dev server, Ctrl-C e `npx ng serve`, para o terminal dele começar limpo,
e abra a página de um curso:

```
ana@dev:~/planner$ look http://localhost:4200/courses/javascript --today 2026-10-23 --text app-course-sessions
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Angular hydrated 15 component(s) and 108 node(s), 0 component(s) were skipped. Learn more at https://v21.angular.dev/guide/hydration.
Hide sessions that are done
Tue 13 Oct, 45 minutes
Tue 20 Oct, 1 hour
Sat 24 Oct, 50 minutes
```

A página está certa. O terminal não:

```
ana@dev:~/planner$ npx ng serve
❯ Building...
✔ Building...
Browser bundles     
Initial chunk files  | Names            |  Raw size
main.js              | main             |  25.04 kB | 
styles.css           | styles           |   8.81 kB | 
chunk-VL5AOURQ.js    | -                |   6.21 kB | 
polyfills.js         | polyfills        | 172 bytes | 

                     | Initial total    |  40.24 kB

Lazy chunk files     | Names            |  Raw size
chunk-CVOEV7ZX.js    | courses-routes   |  40.42 kB | 


Server bundles      
Initial chunk files  | Names            |  Raw size
main.server.mjs      | main.server      |  26.30 kB | 
chunk-5G2P2OON.mjs   | -                |   6.24 kB | 
server.mjs           | server           |   1.84 kB | 
polyfills.server.mjs | polyfills.server | 363 bytes | 

Lazy chunk files     | Names            |  Raw size
chunk-4PI5SPPZ.mjs   | courses-routes   |  40.46 kB | 

Application bundle generation complete. [3.048 seconds] - 2026-10-23T12:00:03.754Z

Watch mode enabled. Watching for file changes...
NOTE: Raw file sizes do not reflect development server per-request transformations.
  ➜  Local:   http://localhost:4200/
Preferences will last this visit only: ReferenceError: localStorage is not defined
    at map (/home/ana/planner/src/app/preferences.ts:26:9)
    at Object.eval (/home/ana/planner/.angular/cache/21.2.28/planner/vite/deps_ssr/chunk-5IER7EOY.js:4208:5)
    at runEffect (/home/ana/planner/.angular/cache/21.2.28/planner/vite/deps_ssr/chunk-5IER7EOY.js:1033:10)
    at Object.run (/home/ana/planner/.angular/cache/21.2.28/planner/vite/deps_ssr/chunk-5IER7EOY.js:4132:7)
    at ZoneAwareEffectScheduler.flushQueue (/home/ana/planner/.angular/cache/21.2.28/planner/vite/deps_ssr/chunk-5IER7EOY.js:4066:14)
    at ZoneAwareEffectScheduler.flush (/home/ana/planner/.angular/cache/21.2.28/planner/vite/deps_ssr/chunk-5IER7EOY.js:4048:33)
    at _ApplicationRef.synchronizeOnce (/home/ana/planner/.angular/cache/21.2.28/planner/vite/deps_ssr/chunk-HGKWEPPS.js:12413:32)
    at _ApplicationRef.synchronize (/home/ana/planner/.angular/cache/21.2.28/planner/vite/deps_ssr/chunk-HGKWEPPS.js:12401:14)
    at _ApplicationRef.tickImpl (/home/ana/planner/.angular/cache/21.2.28/planner/vite/deps_ssr/chunk-HGKWEPPS.js:12376:12)
    at _ApplicationRef._tick (/home/ana/planner/.angular/cache/21.2.28/planner/vite/deps_ssr/chunk-HGKWEPPS.js:12364:12)
```

O `Preferences`, da aula 22, escreve a preferência no `localStorage` num effect, e effects rodam no
servidor como rodam no navegador. O Node.js não tem `localStorage`, a chamada lança erro, e o `catch`
que a aula 22 escreveu transforma o erro no aviso. Nada quebrou, que é para isso que aquele `catch`
servia. Mas o aviso é falso: nenhuma visita está perdendo nada, e ele é impresso para cada página de
curso que alguém abre. A leitura do começo já é segura, porque o `read()` pega o mesmo erro e responde
com os padrões.

O serviço não deveria tocar no armazenamento no servidor. O Angular diz onde o código está rodando
por um token, o `PLATFORM_ID`, e o `isPlatformBrowser` o lê:

```schooling-example
{"language": "typescript", "file": "src/app/preferences.ts", "parts": [
 {"code": "// src/app/preferences.ts\nimport { Injectable, PLATFORM_ID, computed, effect, inject, signal } from '@angular/core';\nimport { isPlatformBrowser } from '@angular/common';\n\nconst KEY = 'planner.preferences';\n\ninterface Saved {\n  hideDone: boolean;\n}\nfunction read(): Saved {\n  try {\n    const saved = JSON.parse(localStorage.getItem(KEY) ?? '{}');\n    return { hideDone: saved?.hideDone === true };\n  } catch {\n    return { hideDone: false };\n  }\n}\n@Injectable({ providedIn: 'root' })\nexport class Preferences {", "note": "O `PLATFORM_ID` vem de `@angular/core`, o teste dele de `@angular/common`."},
 {"code": "  private readonly inBrowser = isPlatformBrowser(inject(PLATFORM_ID));\n  private readonly state = signal<Saved>(this.inBrowser ? read() : { hideDone: false });\n  readonly hideDone = computed(() => this.state().hideDone);", "note": "Perguntado uma vez, quando o serviço é criado. No servidor as preferências começam com os padrões, sem tentar."},
 {"code": "  constructor() {\n    if (!this.inBrowser) return;\n    effect(() => {\n      const saved = JSON.stringify(this.state());\n      try {\n        localStorage.setItem(KEY, saved);\n      } catch (error) {\n        console.warn('Preferences will last this visit only:', error);\n      }\n    });\n  }", "note": "E o effect que escreve só é criado num navegador. O `catch` fica, para um navegador que bloqueia o armazenamento."},
 {"code": "  setHideDone(hide: boolean): void {\n    this.state.update((saved) => ({ ...saved, hideDone: hide }));\n  }\n}"}
]}
```

A página de curso seguinte é renderizada sem nada no terminal.

## O que o servidor não tem como saber

O servidor agora renderiza toda página de curso com os padrões, porque a preferência mora num
navegador que o servidor nunca viu. Quem esconde as sessões concluídas recebe três sessões no HTML e
uma na tela:

```
ana@dev:~/planner$ look http://localhost:4200/courses/javascript --today 2026-10-23 --text app-course-sessions --do 'check Hide sessions that are done' --do 'go /courses/javascript'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Angular hydrated 15 component(s) and 108 node(s), 0 component(s) were skipped. Learn more at https://v21.angular.dev/guide/hydration.
-- check Hide sessions that are done
-- go /courses/javascript
[vite] connecting...
Angular is running in development mode.
[vite] connected.
Angular hydrated 9 component(s) and 72 node(s), 0 component(s) were skipped. Learn more at https://v21.angular.dev/guide/hydration.
Hide sessions that are done
Sat 24 Oct, 50 minutes
```

```
ana@dev:~/planner$ curl -s http://localhost:4200/courses/javascript | grep -o '[A-Z][a-z][a-z] [0-9]* Oct, [^<]*'
Tue 13 Oct, 45 minutes 
Tue 20 Oct, 1 hour 
Sat 24 Oct, 50 minutes 
```

O navegador lê a preferência enquanto hidrata e desenha a própria lista, e o Angular troca as linhas
do servidor por ela. Por um instante, numa conexão lenta, as sessões concluídas aparecem e somem.
Para uma preferência de arrumação, é um preço justo. Uma preferência que precisa estar certa no
primeiro HTML, um idioma ou um tema escuro, tem de chegar ao servidor com a requisição, e a única
coisa que toda requisição leva são os cookies: essa preferência pertence a um cookie, não ao
`localStorage`.

## O que roda só no navegador

A aula 9 disse que o `afterNextRender` e o `ngAfterViewInit` rodam só no navegador, e é aqui que
isso importa. A diretiva `Autofocus` da aula 20 chama `focus()` dentro do `afterNextRender`, então no
servidor ela não faz nada e não precisa testar onde está. A página do formulário vinda do servidor não
tem foco em lugar nenhum; no navegador, o primeiro campo de data tem:

```
ana@dev:~/planner$ look http://localhost:4200/courses/git/add --no-js --a11y 'app-add-session form' | head -5
- form
  - heading "Add sessions" [level=3]
  - LabelText
    - text: Date 1
  - Date "Date 1"
```

```
ana@dev:~/planner$ look http://localhost:4200/courses/git/add --a11y 'app-add-session form' | head -9
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Angular hydrated 3 component(s) and 56 node(s), 0 component(s) were skipped. Learn more at https://v21.angular.dev/guide/hydration.
- form
  - heading "Add sessions" [level=3]
  - LabelText
    - text: Date 1
  - Date "Date 1" [focused]
```

**Essa é a regra para código que precisa de um navegador: ponha onde o Angular só roda no
navegador.** O `afterNextRender` para o que precisa da página desenhada, um listener de evento para o
que uma pessoa faz, o `isPlatformBrowser` para o resto. No servidor, `window`, `document` e
`localStorage` são todos `undefined`: o Angular monta o HTML numa pequena imitação do DOM, que um
componente alcança pelos próprios elementos ou pelo token `DOCUMENT`, nunca pelas globais. Um
`window` solto fora desses lugares é o jeito comum de uma aplicação quebrar na primeira vez que é
renderizada num servidor.

## Dois relógios

O `TODAY`, desde a aula 10, é `new Date()`, e no servidor isso é o relógio do servidor, no fuso do
servidor. A semana do HTML é a semana do servidor. Quem estuda em São Paulo às 22h de um domingo
ainda está na própria semana; um servidor em UTC já está à 1h de segunda, e manda a semana seguinte. O
navegador calcula o próprio `TODAY`, desenha a própria semana, e a página muda diante dos olhos de
quem estuda. O planner não resolve isso, e vale saber que está ali: tudo que é calculado a partir de
"agora" é calculado duas vezes, em dois relógios.
