---
title: Angular SSR
version: 1
---

**O Angular declara as suas rotas numa lista, e as versões recentes declaram uma segunda lista ao
lado dela, que diz como o servidor renderiza cada uma.** O `app.routes.ts` liga um endereço a um
componente, como faz num app sem servidor nenhum. O `app.routes.server.ts` liga um endereço a um
*modo de renderização*: renderizado a cada requisição, pré-renderizado no build, ou deixado para o
navegador. O CLI escreveu as duas, com o servidor, quando recebeu `--ssr`.

Os dados são buscados com o `HttpClient` do Angular, do mesmo `courses.json` que o planner serve em
`public/`. Salve isto como `src/app/plan.ts`. **No servidor a requisição vai ao próprio servidor,
por HTTP**, e a resposta viaja ao navegador dentro da página, então o navegador não pede de novo:

```typescript
// src/app/plan.ts: the planner's data, fetched once per page, on the server and in the browser.
import { HttpClient } from "@angular/common/http";
import { inject, Injectable } from "@angular/core";
import { toSignal } from "@angular/core/rxjs-interop";

export interface Plan {
  courses: { slug: string; title: string }[];
  sessions: { id: number; course: string; date: string; minutes: number; done: boolean }[];
}

@Injectable({ providedIn: "root" })
export class PlanService {
  readonly plan = toSignal(inject(HttpClient).get<Plan>("/courses.json"));
}
```

A página inicial, `src/app/home.ts`:

```typescript
// src/app/home.ts: the address /.
import { Component, inject } from "@angular/core";
import { RouterLink } from "@angular/router";
import { PlanService } from "./plan";

@Component({
  selector: "app-home",
  imports: [RouterLink],
  template: `
    <h1>Study planner</h1>
    @if (plan(); as p) {
      <ul>
        @for (c of p.courses; track c.slug) {
          <li><a [routerLink]="['/courses', c.slug]">{{ c.title }}</a> · {{ count(c.slug) }} sessions</li>
        }
      </ul>
    }
  `,
})
export class Home {
  protected readonly plan = inject(PlanService).plan;
  protected count(slug: string) {
    return this.plan()!.sessions.filter((s) => s.course === slug).length;
  }
}
```

Um curso, `src/app/course.ts`. `slug` é um **input** que o roteador preenche a partir do endereço, e
o `withComponentInputBinding()` lá embaixo é o que liga isso:

```typescript
// src/app/course.ts: the address /courses/<slug>.
import { Component, computed, inject, input } from "@angular/core";
import { RouterLink } from "@angular/router";
import { PlanService } from "./plan";

@Component({
  selector: "app-course",
  imports: [RouterLink],
  template: `
    <p><a routerLink="/">All courses</a></p>
    @if (course(); as c) {
      <h1>{{ c.title }}</h1>
      <ul>
        @for (s of sessions(); track s.id) {
          <li>{{ s.date }} · {{ s.minutes }} min{{ s.done ? " · done" : "" }}</li>
        }
      </ul>
    }
  `,
})
export class Course {
  readonly slug = input.required<string>();
  private readonly plan = inject(PlanService).plan;
  protected readonly course = computed(() => this.plan()?.courses.find((c) => c.slug === this.slug()));
  protected readonly sessions = computed(() => this.plan()?.sessions.filter((s) => s.course === this.slug()) ?? []);
}
```

O componente em volta de toda rota substitui `src/app/app.ts`; apague o `app.html` e o `app.css` do
CLI, que eram da sua página de boas-vindas:

```typescript
// src/app/app.ts: the page around every route.
import { Component } from "@angular/core";
import { RouterOutlet } from "@angular/router";

@Component({
  selector: "app-root",
  imports: [RouterOutlet],
  template: `<main><router-outlet /></main>`,
})
export class App {}
```

As duas listas. Primeiro as rotas, `src/app/app.routes.ts`:

```typescript
// src/app/app.routes.ts: which component answers which address.
import { Routes } from "@angular/router";
import { Course } from "./course";
import { Home } from "./home";

export const routes: Routes = [
  { path: "", component: Home, title: "Study planner" },
  { path: "courses/:slug", component: Course, title: "Study planner" },
];
```

Depois como o servidor as renderiza, `src/app/app.routes.server.ts`. A versão do CLI
pré-renderizava toda rota; esta renderiza toda rota a cada requisição, como os outros três
projetos fazem:

```typescript
// src/app/app.routes.server.ts: how the server renders each address.
import { RenderMode, ServerRoute } from "@angular/ssr";

export const serverRoutes: ServerRoute[] = [
  { path: "**", renderMode: RenderMode.Server },
];
```

E a configuração, `src/app/app.config.ts`, que acrescenta o `HttpClient` e o input binding ao que o
CLI escreveu. `provideClientHydration(withEventReplay())` já estava lá: é a linha que faz o navegador
hidratar o HTML do servidor em vez de desenhá-lo de novo, e ela registra os cliques que acontecem
antes de a hidratação terminar, para repeti-los depois. A aula 4 é exatamente sobre essa janela.

```typescript
// src/app/app.config.ts
import { ApplicationConfig, provideBrowserGlobalErrorListeners } from "@angular/core";
import { provideHttpClient, withFetch } from "@angular/common/http";
import { provideClientHydration, withEventReplay } from "@angular/platform-browser";
import { provideRouter, withComponentInputBinding } from "@angular/router";
import { routes } from "./app.routes";

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(routes, withComponentInputBinding()),
    provideHttpClient(withFetch()),
    provideClientHydration(withEventReplay()),
  ],
};
```

## O host que ele recusa

Faça o build:

```
ana@dev:~/meta/angular$ npm run build 2>&1 | grep -E 'Initial total|Prerendered'
                     | Initial total    | 270.04 kB |                74.41 kB
Prerendered 0 static routes.
```

`Prerendered 0 static routes`, porque agora toda rota é `RenderMode.Server`. Ligue o servidor que o
CLI escreveu no segundo terminal, e no primeiro peça um curso a ele e veja o que voltou dentro do
`<app-root>`:

```
ana@dev:~/meta/angular$ curl -s http://localhost:3004/courses/git | grep app-root
  <app-root></app-root>
```

O segundo terminal, depois dessa requisição:

```
ana@dev:~/meta/angular$ PORT=3004 node dist/angular/server/server.mjs
Node Express server listening on http://localhost:3004
ERROR: Bad Request ("http://localhost:3004/courses/git").
Header "host" with value "localhost:3004" is not allowed.
Falling back to client side rendering. This will become a 400 Bad Request in a future major version.

For more information, see https://angular.dev/best-practices/security#preventing-server-side-request-forgery-ssrf
```

**A página voltou com um `<app-root>` vazio: o servidor se recusou a renderizá-la, e mandou no lugar
a página renderizada no cliente.** O log diz por quê. Como o servidor busca o `courses.json` de si
mesmo, uma requisição cujo cabeçalho `Host` nomeasse outra máquina o faria buscar dessa máquina, com
o acesso de rede do próprio servidor. Isso se chama *server-side request forgery*, falsificação de
requisição do lado do servidor, e o Angular agora se recusa a renderizar para qualquer host de que
não foi avisado. Hoje ele cai para o navegador e imprime isto; a mensagem diz que uma versão futura
vai responder com um 400.

A correção é nomear o host. Pare o servidor com `Ctrl-C`; o `ng config` escreve o nome no
`angular.json`, e o build precisa rodar de novo para valer:

```
ana@dev:~/meta/angular$ npx ng config projects.angular.architect.build.options.security.allowedHosts '["localhost"]'
ana@dev:~/meta/angular$ grep -A3 '"security"' angular.json
            "security": {
              "allowedHosts": [
                "localhost"
              ]
ana@dev:~/meta/angular$ npm run build 2>&1 | grep -E 'Initial total|Prerendered'
                     | Initial total    | 270.04 kB |                74.41 kB
Prerendered 0 static routes.
```

Numa hospedagem de verdade essa lista guarda os nomes de domínio do próprio site. Ligue-o no segundo
terminal:

```sh
PORT=3004 node dist/angular/server/server.mjs
```
