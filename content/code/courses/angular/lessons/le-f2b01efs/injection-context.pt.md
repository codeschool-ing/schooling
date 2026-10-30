---
title: Onde o inject() pode ser chamado
version: 1
---

**O `inject()` só funciona enquanto o Angular está construindo alguma coisa: num construtor, no
inicializador de um campo, e numa factory.** Essa janela é o **contexto de injeção**. O Angular sabe
a qual injetor perguntar porque é o que está construindo naquele momento; depois que o construtor
retornou, não há injetor atual, e o `inject()` não tem a quem perguntar.

Um método roda depois, quando alguém clica, então um método que chama `inject()` falha:

```typescript
// src/app/bench/bench.ts
import { ChangeDetectionStrategy, Component, Injectable, inject, signal } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class Tally {
  readonly count = signal(0);
}

@Component({
  selector: 'app-bench',
  template: '<button type="button" (click)="report()">Report</button>',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {
  protected report(): void {
    console.log('count', inject(Tally).count());
  }
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'click Report' | grep -v '^    at '
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click Report
[error] ERROR RuntimeError: NG0203: The `_Tally` token injection failed. `inject()` function must be called from an injection context such as a constructor, a factory function, a field initializer, or a function used with `runInInjectionContext`. Find more at https://v21.angular.dev/errors/NG0203
Report
```

O `NG0203` lista os lugares que funcionam. A correção é perguntar enquanto o bench está sendo
construído, num campo, e usar a resposta depois:

```typescript
// src/app/bench/bench.ts
import { ChangeDetectionStrategy, Component, Injectable, inject, signal } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class Tally {
  readonly count = signal(0);
}

@Component({
  selector: 'app-bench',
  template: '<button type="button" (click)="report()">Report</button>',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {
  private readonly tally = inject(Tally);

  protected report(): void {
    console.log('count', this.tally.count());
  }
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'click Report'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click Report
count 0
Report
```

## Uma função que injeta

A regra é sobre **quando** o `inject()` roda, não onde ele está escrito. Uma função comum pode
chamá-lo, desde que ela mesma seja chamada de um campo ou de um construtor:

```typescript
function injectWeek(): WeekRange {
  return weekOf(isoDay(inject(TODAY)));
}

export class Week {
  protected readonly week = injectWeek();
}
```

Uma função assim costuma se chamar `injectAlgumaCoisa`, para quem a chama saber que ela pertence a
um campo ou a um construtor, onde o `inject` funciona. Para o caso raro de um callback que realmente
precisa injetar depois, o `runInInjectionContext(injector, fn)` roda `fn` com um injetor dado como o
atual; use-o só depois de descartar um campo.

## Devolvendo o planner

O bench cumpriu seu papel. Ele sai, e o `App` volta ao que o git tem:

```
ana@dev:~/planner$ rm -r src/app/bench && git checkout -- src/app/app.html src/app/app.ts
```

```
ana@dev:~/planner$ git status --short
 M src/app/week/week.html
 M src/app/week/week.spec.ts
 M src/app/week/week.ts
?? src/app/today.ts
```

```
ana@dev:~/planner$ git add -A && git commit -q -m "Dependency injection: today is a token"
```

O que fica é o token, o `Week` pedindo por ele, o intervalo que ele mostra, e um teste que diz o seu
próprio dia.
