---
title: O que escrever hoje, e como o código antigo chega aqui
version: 1
---

**Para código novo a resposta é curta: estado em signals, OnPush em todo componente, e nada de
zone.js.** Cada um dos três torna o seguinte seguro. Os signals marcam exatamente o que mudou, o OnPush
deixa o Angular pular todo o resto, e sem o zone.js nada percorre a árvore porque um mouse se mexeu.

## OnPush no planner

Todo componente que o planner tem já lê o estado que muda a partir de signals, então marcá-los como
OnPush não muda nada na página e deixa o Angular pular cada um quando nada do que ele lê mudou. A
bancada cumpriu o papel; apague-a, e restaure o `App` com o OnPush acrescentado:

```
ana@dev:~/planner$ rm -r src/app/bench
```

```html
<!-- src/app/app.html -->
<h1>Study planner</h1>
<main>
  <app-week />
</main>
<router-outlet />
```

```typescript
// src/app/app.ts
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { Week } from './week/week';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, Week],
  templateUrl: './app.html',
  styleUrl: './app.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class App {}
```

O `Week` e o `WeekSummary` ganham a mesma linha, e as classes deles ficam como a aula 6 as deixou:

```typescript
// src/app/week/week.ts
import { ChangeDetectionStrategy, Component, computed, resource } from '@angular/core';
import { isoDay, loadPlanner, totals, weekOf } from '../planner';
import { WeekSummary } from '../week-summary/week-summary';

@Component({
  selector: 'app-week',
  imports: [WeekSummary],
  templateUrl: './week.html',
  styleUrl: './week.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Week {
  protected readonly data = resource({ loader: loadPlanner });
  private readonly week = weekOf(isoDay(new Date()));
  protected readonly rows = computed(() => {
    const data = this.data.value();
    if (!data) return [];
    return data.courses.map((course) => ({
      course,
      minutes: totals(data.sessions.filter((s) => s.courseId === course.id), this.week).planned,
    }));
  });
}
```

```typescript
// src/app/week-summary/week-summary.ts
import { ChangeDetectionStrategy, Component, computed, resource } from '@angular/core';
import { isoDay, loadPlanner, totals, weekOf } from '../planner';

@Component({
  selector: 'app-week-summary',
  imports: [],
  templateUrl: './week-summary.html',
  styleUrl: './week-summary.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WeekSummary {
  protected readonly data = resource({ loader: loadPlanner });
  private readonly week = weekOf(isoDay(new Date()));
  protected readonly totals = computed(() => totals(this.data.value()?.sessions ?? [], this.week));
}
```

E para que todo componente gerado daqui em diante já comece assim, diga à CLI uma vez:

```
ana@dev:~/planner$ npx ng config projects.planner.schematics.@schematics/angular:component.changeDetection OnPush
```

O `ng config` escreve no `angular.json`, nos `schematics` do projeto, o padrão de uma opção do
`ng generate component`. O próximo componente que a aula 8 gerar já vem com OnPush no decorator.

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text main
[vite] connecting...
[vite] connected.
Angular is running in development mode.
This week

165 minutes planned, 90 done.

75 minutes to go.

Done this week
Courses
HTML and CSS: 30 minutes
JavaScript: 110 minutes
Git: 25 minutes
```

A mesma semana com que a aula 6 terminou. Testes, e um commit:

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep Tests
      Tests  4 passed (4)
```

```
ana@dev:~/planner$ git add -A && git commit -q -m "Change detection: OnPush everywhere, no zone.js"
```

## Uma aplicação antiga, levada para zoneless

A aplicação que você vai encontrar no trabalho tem zone.js, poucos signals e uma mistura de componentes
OnPush e padrão. A mudança é feita nesta ordem, cada passo publicável sozinho:

1. **Tornar os componentes OnPush, um por vez**, e consertar o que fica velho: um campo definido de
   forma assíncrona vira um signal, ou ganha um `markForCheck()` por enquanto. Esse é o passo lento, e
   ele vale a pena mesmo que os seguintes nunca aconteçam.
2. **Trocar o `provideZoneChangeDetection` pelo `provideZonelessChangeDetection()`**, que no Angular 21
   também é o que deixar os dois de fora significa, e tirar o `zone.js` do `main.ts` ou dos
   `polyfills` no `angular.json`, e do `package.json`.
3. **Rodar todos os testes e olhar todas as telas.** O que ainda ficar velho dependia do zone.js e
   escapou no passo 1.

A documentação do Angular chama o zoneless de estável desde a versão 20.2, e projetos novos são
zoneless por padrão desde a 21. O código com zone.js no mundo vai durar mais que este curso; saber lê-lo
é a habilidade, e saber de qual linha das seções anteriores ele depende é como você o conserta.
