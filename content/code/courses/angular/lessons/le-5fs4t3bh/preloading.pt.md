---
title: Preloading, lazy sem a espera
version: 1
---

**Um chunk lazy é buscado quando é preciso, então o primeiro clique num curso espera um download.**
Numa rede rápida isso não é nada; num trem é o momento em que a aplicação parece travar. O
**preloading** busca os chunks lazy depois que a aplicação iniciou, enquanto a pessoa lê a primeira
página, então a primeira página fica tão rápida quanto antes e o clique já encontra o código lá.

O `withPreloading(PreloadAllModules)` pré-carrega toda rota lazy:

```typescript
// src/app/app.config.ts
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
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
    provideHttpClient(withInterceptors([requestedBy])),
  ]
};
```

```
ana@dev:~/planner$ look http://localhost:4200/ --scripts --text h2
[vite] connecting...
[vite] connected.
Angular is running in development mode.
scripts: /main.js /chunk-KGABQYFU.js /chunk-5ODBP7SE.js
This week
```

A semana, e nenhum clique: o chunk da área do curso veio mesmo assim, depois que a página foi
desenhada.

O `PreloadAllModules` é a estratégia mais simples, e a certa para uma aplicação deste tamanho. Uma
aplicação com cinquenta áreas lazy pré-carregaria código que a maioria das pessoas nunca usa, no
pacote de dados delas; uma estratégia própria, uma classe com um método, pode pré-carregar só as rotas
marcadas no `data` delas, ou só numa conexão rápida. O padrão, sem `withPreloading`, é não
pré-carregar nada.
