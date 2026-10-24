---
title: Providers, as quatro receitas
version: 1
---

**Um provider é uma receita que um injetor guarda: quando alguém pedir isto, entregue aquilo.** A
coisa pedida é o **token**; o que volta é decidido pela receita. `providedIn: 'root'` é uma receita
escrita na própria classe, e é a mais comum. As outras vão numa lista `providers`, e a aplicação já
tem uma, no `app.config.ts`:

```typescript
// src/app/app.config.ts
import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import { provideRouter } from '@angular/router';

import { routes } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(routes)
  ]
};
```

`provideRouter(routes)` é uma função que retorna providers, vários deles, para as classes do próprio
router, reunidos sob um nome. A maioria dos recursos do Angular chega a uma aplicação desse jeito, o
`provideHttpClient()` da aula 12 entre eles. A lista é do injetor raiz, então qualquer coisa nela pode
ser pedida em qualquer lugar da aplicação.

## Trocando a classe

Um provider escrito por extenso é um objeto com `provide`, o token, e uma de quatro chaves dizendo
como responder. `useClass` responde com uma instância de outra classe. Um greeter mais alto,
acrescentado abaixo do `Greeter` no bench:

```typescript
// src/app/bench/bench.ts
import { ChangeDetectionStrategy, Component, Injectable, inject } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class Greeter {
  greet(name: string): string {
    return `Hello, ${name}`;
  }
}

@Injectable()
export class LoudGreeter extends Greeter {
  override greet(name: string): string {
    return super.greet(name).toUpperCase() + '!';
  }
}

@Component({
  selector: 'app-bench',
  template: '<p>{{ text }}</p>',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {
  private readonly greeter = inject(Greeter);
  protected readonly text = this.greeter.greet('Ana');
}
```

E a troca, nos providers da aplicação:

```typescript
// src/app/app.config.ts
import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import { provideRouter } from '@angular/router';

import { routes } from './app.routes';
import { Greeter, LoudGreeter } from './bench/bench';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(routes),
    { provide: Greeter, useClass: LoudGreeter },
  ]
};
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Hello, Ana
```

O bench não mudou. Ele ainda pede `Greeter`, e o injetor, seguindo a receita que recebeu, responde
com um `LoudGreeter`. **Um provider numa lista vence o `providedIn`**: a receita da própria classe é
o padrão, usado só quando nada mais específico foi escrito.

## As quatro

| chave | o injetor responde com | uso típico |
|---|---|---|
| `useClass` | uma instância nova dessa classe, feita uma vez | outra implementação do mesmo contrato |
| `useValue` | esse valor, exatamente como escrito | uma constante, um objeto de configuração, uma data fixa num teste |
| `useFactory` | o que a função retornar, chamada uma vez | um valor calculado quando é preciso pela primeira vez; a função pode chamar `inject()` |
| `useExisting` | o que outro token já responde | um apelido, para dois tokens compartilharem uma instância |

Uma classe solta na lista, `providers: [Greeter]`, é a forma curta de
`{ provide: Greeter, useClass: Greeter }`. Toda receita faz sua resposta uma vez por injetor, e
entrega essa mesma resposta a todo mundo que pedir ali. A próxima seção usa `useFactory` e
`useValue` em algo que não é uma classe.
