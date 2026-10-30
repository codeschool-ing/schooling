---
title: O escopo que uma instância tem de verdade
version: 1
---

**"Um serviço é um singleton" só é verdade sobre onde ele é fornecido.** O `providedIn: 'root'` faz
uma instância para a aplicação, e é o caso de quase todo serviço. Mas a mesma classe listada nos
`providers` de um componente faz uma instância por componente, como o `Tally` fez na aula 10, e nada
na própria classe diz qual. Quem escreve o provider decide o escopo.

O jeito de dar errado é uma linha que alguém acrescenta com boa intenção. Dê ao `CoursePage` o store
nos próprios `providers`, talvez para ter certeza de que ele tem um:

```typescript
// src/app/course-page/course-page.ts
import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { PlannerStore } from '../planner-store';
import { SessionList } from '../session-list/session-list';

@Component({
  selector: 'app-course-page',
  imports: [SessionList],
  providers: [PlannerStore],
  templateUrl: './course-page.html',
  styleUrl: './course-page.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CoursePage {
  readonly courseId = input.required<string>();
  protected readonly store = inject(PlannerStore);
  protected readonly course = computed(() => this.store.courses().find((c) => c.id === this.courseId()));
  protected readonly sessions = computed(() =>
    this.store
      .sessions()
      .filter((s) => s.courseId === this.courseId())
      .sort((a, b) => a.date.localeCompare(b.date)),
  );
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text app-week-summary --network --do 'check 2026-10-24, 50 minutes'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
net  GET /courses.json  200
net  GET /courses.json  200
-- check 2026-10-24, 50 minutes
165 minutes planned, 90 done.

75 minutes to go.

Done this week
```

O defeito da primeira seção desta aula voltou, exatamente: dois pedidos, e 90 minutos feitos depois
da marcação. A pergunta do `CoursePage` parou no próprio injetor, que fez um segundo store, com um
segundo resource e uma segunda cópia. Nada deixou de compilar e nada imprimiu um erro. **Um singleton
por convenção se quebra com uma linha numa lista**, e é por isso que vale procurar `providers:` num
componente antes de acreditar que um serviço é compartilhado.

A linha sai, e o store volta a ser um:

```typescript
// src/app/course-page/course-page.ts
import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { PlannerStore } from '../planner-store';
import { SessionList } from '../session-list/session-list';

@Component({
  selector: 'app-course-page',
  imports: [SessionList],
  templateUrl: './course-page.html',
  styleUrl: './course-page.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CoursePage {
  readonly courseId = input.required<string>();
  protected readonly store = inject(PlannerStore);
  protected readonly course = computed(() => this.store.courses().find((c) => c.id === this.courseId()));
  protected readonly sessions = computed(() =>
    this.store
      .sessions()
      .filter((s) => s.courseId === this.courseId())
      .sort((a, b) => a.date.localeCompare(b.date)),
  );
}
```

## Quando por componente é o certo

Os `providers` de um componente são o lugar certo para estado que pertence a uma instância de um
componente e deve morrer com ela: os campos meio preenchidos de um formulário que aparece várias vezes
numa página, ou os painéis abertos e fechados de uma árvore. Cada cópia deve ser separada, e quando o
componente é destruído o serviço dele vai junto.

| o estado é | forneça-o |
|---|---|
| da aplicação, compartilhado por toda tela | `providedIn: 'root'` |
| de um componente, separado por instância | nos `providers` desse componente |
| de uma área, carregado com uma parte da aplicação | nos `providers` de uma rota, aula 18 |

A terceira linha é outro tipo de injetor, feito para um grupo de rotas que são carregadas juntas. A
aula 18 o mostra, porque ele muda quantas instâncias uma parte da aplicação carregada sob demanda tem
de verdade.

```
ana@dev:~/planner$ git add -A && git commit -q -m "Services: one store for the planner"
```
