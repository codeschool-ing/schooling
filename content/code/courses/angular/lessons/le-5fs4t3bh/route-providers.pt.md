---
title: Providers numa rota, e quanto tempo vivem
version: 1
---

**Uma rota pode ter `providers`, e eles vão para um injetor próprio da rota, que todo componente
abaixo dela pergunta antes da raiz.** A aula 11 deixou esta linha da tabela dela para aqui, dizendo
que ela muda quantas instâncias uma parte da aplicação carregada sob demanda tem de verdade. O jeito
honesto de descobrir é contar. Um probe que numera cada instância feita, e diz quando uma é destruída:

```typescript
// src/app/area-probe.ts
import { DestroyRef, Injectable, inject } from '@angular/core';

let made = 0;

@Injectable()
export class AreaProbe {
  readonly number = ++made;

  constructor() {
    console.log(`probe ${this.number} made`);
    inject(DestroyRef).onDestroy(() => console.log(`probe ${this.number} destroyed`));
  }
}
```

Fornecido na rota da área do curso:

```typescript
// src/app/courses.routes.ts
import { Routes } from '@angular/router';
import { AddSession } from './add-session/add-session';
import { AreaProbe } from './area-probe';
import { CoursePage } from './course-page/course-page';
import { CourseSessions } from './course-sessions/course-sessions';
import { unsavedWork } from './unsaved-work';

export const courseRoutes: Routes = [
  {
    path: '',
    component: CoursePage,
    providers: [AreaProbe],
    children: [
      { path: '', component: CourseSessions },
      { path: 'add', component: AddSession, canDeactivate: [unsavedWork] },
    ],
  },
];
```

E pedido pela página do curso, que diz qual probe recebeu:

```typescript
// src/app/course-page/course-page.ts
import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { AreaProbe } from '../area-probe';
import { PlannerStore } from '../planner-store';

@Component({
  selector: 'app-course-page',
  imports: [RouterLink, RouterLinkActive, RouterOutlet],
  templateUrl: './course-page.html',
  styleUrl: './course-page.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CoursePage {
  readonly courseId = input.required<string>();
  protected readonly store = inject(PlannerStore);
  private readonly probe = inject(AreaProbe);
  protected readonly course = computed(() => this.store.courses().find((c) => c.id === this.courseId()));

  constructor() {
    console.log(`a course page, given probe ${this.probe.number}`);
  }
}
```

Da semana para o Git, de volta para a semana, e para o JavaScript:

```
ana@dev:~/planner$ look http://localhost:4200/ --text h2 --do 'click Git' --do 'click This week' --do 'click JavaScript'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click Git
probe 1 made
a course page, given probe 1
-- click This week
-- click JavaScript
a course page, given probe 1
JavaScript
```

**Um probe, feito na primeira vez que se entrou na área, e nunca destruído.** Sair para a semana não
o encerrou, e a página do JavaScript recebeu o mesmo do Git. O injetor de uma rota é feito quando a
rota é usada pela primeira vez e mantido enquanto a aplicação roda, então um serviço fornecido numa
rota é um singleton daquela área, compartilhado por todo curso, nem um por curso nem um por visita.

| fornecido | uma instância por | feita | termina |
|---|---|---|---|
| `providedIn: 'root'` | aplicação | na primeira vez que é pedida | nunca |
| os `providers` de uma rota | essa rota, em toda visita e todo parâmetro | na primeira vez que a rota é usada | nunca |
| os `providers` de um componente | instância do componente | com o componente | com o componente |

Então os providers de uma rota servem para o que pertence a uma área mas sobrevive a uma visita, um
cache de algo que só aquela área usa, por exemplo, mantido fora da raiz para o bundle principal não o
carregar. Estado que deve começar do zero a cada visita fica nos `providers` do componente.

O probe respondeu a pergunta, e sai:

```
ana@dev:~/planner$ rm src/app/area-probe.ts && git checkout -- src/app/course-page/course-page.ts
```

```typescript
// src/app/courses.routes.ts
import { Routes } from '@angular/router';
import { AddSession } from './add-session/add-session';
import { CoursePage } from './course-page/course-page';
import { CourseSessions } from './course-sessions/course-sessions';
import { unsavedWork } from './unsaved-work';

export const courseRoutes: Routes = [
  {
    path: '',
    component: CoursePage,
    children: [
      { path: '', component: CourseSessions },
      { path: 'add', component: AddSession, canDeactivate: [unsavedWork] },
    ],
  },
];
```
