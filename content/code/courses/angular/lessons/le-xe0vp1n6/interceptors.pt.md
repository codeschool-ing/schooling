---
title: Interceptors, para o que todo pedido precisa
version: 1
---

**Um interceptor é uma função pela qual todo pedido passa na ida, e toda resposta na volta.** É onde
fica uma coisa que diz respeito a todos os pedidos, para nenhum pedido sozinho ter de lembrar dela:
um cabeçalho que diz quem está pedindo, um token que prova isso, uma linha de log, uma nova
tentativa. O pedido é imutável, então um interceptor que muda um faz uma cópia mudada com `clone` e
a repassa com `next`.

A API do planner registra um cabeçalho, `X-Requested-By`, e até aqui toda linha diz `-`. Um
interceptor que o define em todo pedido:

```schooling-example
{"language": "typescript", "file": "src/app/requested-by.ts", "parts": [
 {"code": "// src/app/requested-by.ts\nimport { HttpInterceptorFn } from '@angular/common/http';\n\nexport const requestedBy: HttpInterceptorFn = (req, next) =>\n  next(req.clone({ setHeaders: { 'X-Requested-By': 'planner' } }));", "note": "Um interceptor é uma função do pedido e do `next`, o resto da cadeia. O que ela retorna é a resposta, então ela pode olhar para isso também."}
]}
```

Interceptors são um recurso do `HttpClient`, então é aqui que entra o `provideHttpClient()`, com o
`withInterceptors` listando-os na ordem em que um pedido os encontra:

```typescript
// src/app/app.config.ts
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import { provideRouter } from '@angular/router';

import { routes } from './app.routes';
import { requestedBy } from './requested-by';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(routes),
    provideHttpClient(withInterceptors([requestedBy])),
  ]
};
```

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text app-week-summary
[vite] connecting...
[vite] connected.
Angular is running in development mode.
165 minutes planned, 90 done.

75 minutes to go.

Done this week
```

A página é a mesma. O terminal da API não:

```
ana@dev:~/planner$ node server/api.mjs
the planner's API is on http://localhost:3000
GET /api/planner -
PATCH /api/sessions/5 -
PATCH /api/sessions/9 -
GET /api/planner -
GET /api/planner -
GET /api/planner -
GET /api/planner -
GET /api/planner -
PATCH /api/sessions/5 -
GET /api/planner -
PATCH /api/sessions/5 -
GET /api/planner planner
```

O último `GET` veio com o cabeçalho, e nem o store nem o resource sabem que ele foi acrescentado. O
resource usa o `HttpClient` por baixo, então passa pela mesma cadeia que um `patch`.

## Para que servem os interceptors

| um interceptor que | é como uma aplicação |
|---|---|
| acrescenta `Authorization: Bearer ...` | manda o token de quem entrou em todo pedido |
| lê o status da resposta | manda alguém para a página de entrar num 401 |
| registra o método, a URL e o tempo gasto | descobre quais pedidos são lentos |
| tenta de novo numa falha de rede | sobrevive a um momento de Wi-Fi ruim |

**Uma proteção vem pronta em vez de escrita.** O `HttpClient` já se defende contra falsificação de
pedidos entre sites, em que a página de outro site faz o seu navegador mandar um pedido à sua API com
os seus cookies: quando o servidor define um cookie `XSRF-TOKEN`, o `HttpClient` o copia para um
cabeçalho `X-XSRF-TOKEN` em todo pedido que muda alguma coisa, e o servidor confere se os dois
batem. Uma página de outro site não consegue ler os seus cookies, então não consegue mandar o
cabeçalho. A API do planner não usa cookies, então ainda não há nada a falsificar; uma API que faz
login com um deve conferir o cabeçalho.
