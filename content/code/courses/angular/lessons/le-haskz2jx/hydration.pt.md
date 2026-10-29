---
title: Hidratação, e a requisição que o navegador não faz
version: 1
---

**Com o dev server renderizando no servidor, a página tem o texto antes de qualquer script rodar.**
Um `look` com o JavaScript desligado agora lê a semana:

```
ana@dev:~/planner$ look http://localhost:4200/ --no-js --text main
This week

19 October to 25 October 2026

2 hours 45 minutes planned, 1 hour 30 minutes done.

1 hour 15 minutes to go.

Done this week
Courses
HTML and CSS: 30 minutes
JavaScript: 1 hour 50 minutes
Git: 25 minutes
```

Com o JavaScript ligado, o navegador recebe esse HTML, mostra, e então roda a aplicação. O Angular no
navegador não desenha a página uma segunda vez. Ele percorre os elementos que o servidor mandou,
pareia cada um com o componente e o binding que o fizeram, e liga os listeners de eventos. Isso é a
**hidratação**, e em desenvolvimento ela conta o que fez:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --network --text app-week-summary
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Angular hydrated 7 component(s) and 63 node(s), 0 component(s) were skipped. Learn more at https://v21.angular.dev/guide/hydration.
2 hours 45 minutes planned, 1 hour 30 minutes done.

1 hour 15 minutes to go.

Done this week
```

"7 component(s) and 63 node(s)" foram assumidos como estavam, e nenhum precisou ser refeito. O
`provideClientHydration`, que o `ng add` pôs no `app.config.ts`, é o que liga isso. Sem ele, o
navegador jogaria fora o HTML do servidor e desenharia tudo de novo a partir de um `<app-root>`
vazio, e o trabalho do servidor só apareceria como uma piscada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma requisição renderizada no servidor, em duas faixas, o tempo correndo da esquerda para a direita. Na faixa do servidor, o servidor renderiza a página e pede os dados à API. Uma seta leva o HTML e o script ng-state para a faixa do navegador, onde vêm três caixas: o navegador mostra o HTML, roda os scripts e hidrata a página, ligando os listeners. Um colchete sobre as duas primeiras caixas do navegador diz que um clique feito nesse intervalo é gravado e reproduzido. Uma nota sob a última caixa diz que o primeiro GET dos dados é respondido pelo ng-state.\"><text x=\"20\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">servidor</text><text x=\"20\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">navegador</text><line x1=\"100\" y1=\"30\" x2=\"100\" y2=\"220\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><rect x=\"110\" y=\"50\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"200\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">renderiza a página</text><text x=\"200\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">GET /api/planner</text><line x1=\"290\" y1=\"94\" x2=\"318\" y2=\"146\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"318.0,146.0 311.8,141.0 317.2,138.0\" fill=\"var(--amber)\"></polygon><text x=\"312\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">HTML + ng-state</text><rect x=\"320\" y=\"150\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"380\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">mostra o HTML</text><text x=\"380\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">texto, sem listeners</text><rect x=\"455\" y=\"150\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"515\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">roda os scripts</text><text x=\"515\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">main.js</text><rect x=\"590\" y=\"150\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"650\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">hidrata</text><text x=\"650\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">listeners ligados</text><line x1=\"440\" y1=\"172\" x2=\"452\" y2=\"172\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"452.0,172.0 444.6,175.1 444.6,168.9\" fill=\"var(--wire)\"></polygon><line x1=\"575\" y1=\"172\" x2=\"587\" y2=\"172\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"587.0,172.0 579.6,175.1 579.6,168.9\" fill=\"var(--wire)\"></polygon><path d=\"M 320 140 L 320 134 L 575 134 L 575 140\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><text x=\"447\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">um clique agora é gravado e reproduzido depois</text><text x=\"650\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o primeiro GET é respondido</text><text x=\"650\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pelo ng-state</text></svg>", "caption": "O servidor manda uma página pronta e os dados que usou; o navegador mostra na hora e assume a página quando os scripts rodaram."}
```

## Nenhuma segunda requisição

O `--network` não imprimiu requisição nenhuma. Os dados da semana vieram de `/api/planner`, mas o
navegador nunca pediu: o terminal da API tem um `GET` para aquela página, feito pelo servidor.

```
ana@dev:~/planner$ curl -s http://localhost:4200/ | grep -o '<script id="ng-state"[^>]*>.\{70\}'
<script id="ng-state" type="application/json">{"3bb753e941676b4de8a395d1ce503b99d0917105de6c7d9ada19de76449229d7":{"
```

O servidor escreveu cada resposta que o `HttpClient` recebeu enquanto renderizava num elemento script
no pé da página, o `ng-state`, com um hash da requisição como chave. No navegador, o primeiro `GET`
idêntico é respondido dali. Esse é o **transfer cache de HTTP**, e o `provideClientHydration` o liga
com os padrões: só requisições `GET` e `HEAD`, e nenhuma que leve um cabeçalho `Authorization`,
porque a página é HTML que qualquer um pode salvar e ler de novo. Uma requisição que muda algo, um
`PATCH`, sempre vai ao servidor.

## Um clique antes de os scripts chegarem

A outra parte da linha que o `ng add` escreveu é o `withEventReplay()`. Entre o HTML chegar e a
hidratação terminar, a página parece pronta e não está: um link ou um botão ainda não tem listener.
O servidor marca cada elemento que tem um:

```
ana@dev:~/planner$ curl -s http://localhost:4200/ | grep -o 'jsaction="[^"]*"' | sort | uniq -c
      4 jsaction="click:;"
```

Um script pequeno no topo do body grava cada clique num elemento marcado. Quando a hidratação acaba,
o Angular reproduz esses cliques para os listeners de verdade, e quem tocou em "JavaScript" num
celular lento é levado até lá em vez de ignorado.

## O servidor pede `withFetch()`

O terminal do dev server tem duas reclamações, a primeira impressa uma vez e a segunda para cada
página que ele renderizou. (A linha sobre o lockfile é o Vite notando os pacotes que o `ng add`
instalou.)

```
ana@dev:~/planner$ npx ng serve
❯ Building...
✔ Building...
Browser bundles     
Initial chunk files  | Names            |  Raw size
main.js              | main             |  25.02 kB | 
styles.css           | styles           |   8.81 kB | 
chunk-VL5AOURQ.js    | -                |   6.21 kB | 
polyfills.js         | polyfills        | 172 bytes | 

                     | Initial total    |  40.21 kB

Lazy chunk files     | Names            |  Raw size
chunk-CVOEV7ZX.js    | courses-routes   |  40.42 kB | 


Server bundles      
Initial chunk files  | Names            |  Raw size
main.server.mjs      | main.server      |  26.27 kB | 
chunk-5G2P2OON.mjs   | -                |   6.24 kB | 
server.mjs           | server           |   1.84 kB | 
polyfills.server.mjs | polyfills.server | 363 bytes | 

Lazy chunk files     | Names            |  Raw size
chunk-4PI5SPPZ.mjs   | courses-routes   |  40.46 kB | 

Application bundle generation complete. [3.370 seconds] - 2026-10-23T12:00:04.077Z

Watch mode enabled. Watching for file changes...
NOTE: Raw file sizes do not reflect development server per-request transformations.
9:00:04 AM [vite] (client) Re-optimizing dependencies because lockfile has changed
  ➜  Local:   http://localhost:4200/
NG02801: Angular detected that `HttpClient` is not configured to use `fetch` APIs. It's strongly recommended to enable `fetch` for applications that use Server-Side Rendering for better performance and compatibility. To enable `fetch`, add the `withFetch()` to the `provideHttpClient()` call at the root of the application.
XHR support in `@angular/platform-server` is deprecated and will be removed in a future version of Angular. It has known security and performance issues in server environments, such as forwarding `Authorization` headers on cross-origin redirects and susceptibility to denial-of-service (DoS) via redirect loops. Please enable the HttpClient fetch backend instead by using `withFetch()`.
XHR support in `@angular/platform-server` is deprecated and will be removed in a future version of Angular. It has known security and performance issues in server environments, such as forwarding `Authorization` headers on cross-origin redirects and susceptibility to denial-of-service (DoS) via redirect loops. Please enable the HttpClient fetch backend instead by using `withFetch()`.
XHR support in `@angular/platform-server` is deprecated and will be removed in a future version of Angular. It has known security and performance issues in server environments, such as forwarding `Authorization` headers on cross-origin redirects and susceptibility to denial-of-service (DoS) via redirect loops. Please enable the HttpClient fetch backend instead by using `withFetch()`.
XHR support in `@angular/platform-server` is deprecated and will be removed in a future version of Angular. It has known security and performance issues in server environments, such as forwarding `Authorization` headers on cross-origin redirects and susceptibility to denial-of-service (DoS) via redirect loops. Please enable the HttpClient fetch backend instead by using `withFetch()`.
XHR support in `@angular/platform-server` is deprecated and will be removed in a future version of Angular. It has known security and performance issues in server environments, such as forwarding `Authorization` headers on cross-origin redirects and susceptibility to denial-of-service (DoS) via redirect loops. Please enable the HttpClient fetch backend instead by using `withFetch()`.
XHR support in `@angular/platform-server` is deprecated and will be removed in a future version of Angular. It has known security and performance issues in server environments, such as forwarding `Authorization` headers on cross-origin redirects and susceptibility to denial-of-service (DoS) via redirect loops. Please enable the HttpClient fetch backend instead by using `withFetch()`.
```

No servidor, o `HttpClient` ainda manda as requisições do jeito que faz num navegador, pelo
`XMLHttpRequest`, que o Node.js não tem; o Angular preenche a lacuna com uma biblioteca, a `xhr2`, e
a segunda mensagem diz por que essa é uma escolha ruim num servidor. O `withFetch()` faz o
`HttpClient` usar o `fetch` que o Node.js e todo navegador têm. É mais um recurso na chamada de
`provideHttpClient`:

```typescript
// src/app/app.config.ts
import { provideHttpClient, withFetch, withInterceptors } from '@angular/common/http';
import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import { provideClientHydration, withEventReplay } from '@angular/platform-browser';
import {
  PreloadAllModules,
  provideRouter,
  withComponentInputBinding,
  withPreloading,
  withRouterConfig,
} from '@angular/router';

import { routes } from './app.routes';
import { requestedBy } from './requested-by';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(
      routes,
      withComponentInputBinding(),
      withRouterConfig({ paramsInheritanceStrategy: 'always' }),
      withPreloading(PreloadAllModules),
    ),
    provideHttpClient(withFetch(), withInterceptors([requestedBy])),
    provideClientHydration(withEventReplay()),
  ],
};
```

O import que o `ng add` pôs depois dos outros subiu para junto deles, que é onde uma pessoa o teria
escrito. O interceptor da aula 12 continua rodando: interceptors ficam na frente de qualquer backend
que mande a requisição, e o terminal da API continua mostrando `planner` em cada linha. As páginas
seguintes são renderizadas sem reclamação no terminal do dev server.
