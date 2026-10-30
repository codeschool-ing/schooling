---
title: De quais deles você precisa
version: 1
---

**Com signals, um componente novo quase não precisa de hooks.** A pergunta que cada hook respondia tem
agora uma resposta melhor, e os hooks ficam para o código escrito antes dessa resposta existir:

| o trabalho | em código novo | no código que você vai ler |
|---|---|---|
| preparar as coisas | inicializadores de campo e o construtor, com `inject()` | `ngOnInit` |
| ler um input | ler onde for preciso; um `computed` espera por ele | `ngOnInit`, porque o construtor era cedo demais |
| reagir a um input que muda | um `computed`, ou um `effect` para o mundo de fora | `ngOnChanges` e um campo copiado |
| limpar | `inject(DestroyRef).onDestroy(…)` ao lado do que ele limpa | `ngOnDestroy`, longe da preparação |
| mexer no DOM desenhado | `afterNextRender`, `afterEveryRender` | `ngAfterViewInit`, `ngAfterViewChecked` |
| conferir algo a cada conferência | nada: um signal diz quando mudou | `ngDoCheck` |
| usar conteúdo projetado | `contentChild()`, um signal | `ngAfterContentInit` |

O planner, no fim desta aula, não tem hook nenhum, e nada do que ele faz precisa de um. A bancada ensinou
o que veio ensinar; apague-a, e ponha o `App` de volta:

```
ana@dev:~/planner$ rm -r src/app/bench
```

```html
<!-- src/app/app.html -->
<h1>Study planner</h1>
<main>
  <app-week />
  <app-course-page courseId="javascript" />
</main>
<router-outlet />
```

```typescript
// src/app/app.ts
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { CoursePage } from './course-page/course-page';
import { Week } from './week/week';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, Week, CoursePage],
  templateUrl: './app.html',
  styleUrl: './app.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class App {}
```

```
ana@dev:~/planner$ git status --short
```

Nada para commitar: a bancada veio e foi, e o planner está como a aula 8 o deixou.
