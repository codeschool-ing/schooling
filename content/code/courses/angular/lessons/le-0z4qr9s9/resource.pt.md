---
title: resource, um signal que espera por alguma coisa
version: 1
---

**O `resource` transforma algo assíncrono, uma requisição, um arquivo, um timer, em signals: um para o
valor, um para dizer se ainda está carregando, e um para o erro se falhou.** A aula 2 pôs os dados do
planner em `public/courses.json` e prometeu que um signal que espera os leria. É este. Dê os dados ao
resumo da semana e, por enquanto, deixe-o só contar as sessões:

```typescript
// src/app/week-summary/week-summary.ts
import { Component, resource } from '@angular/core';
import { PlannerData } from '../planner';

@Component({
  selector: 'app-week-summary',
  imports: [],
  templateUrl: './week-summary.html',
  styleUrl: './week-summary.css',
})
export class WeekSummary {
  protected readonly data = resource({
    loader: async (): Promise<PlannerData> => (await fetch('/course.json')).json(),
  });
}
```

```html
<!-- src/app/week-summary/week-summary.html -->
@if (data.isLoading()) {
  <p>Loading the week…</p>
} @else if (data.error(); as error) {
  <p>The week could not be loaded: {{ error.message }}</p>
} @else if (data.value(); as value) {
  <p>{{ value.sessions.length }} sessions loaded.</p>
}
```

`PlannerData` é o formato do arquivo inteiro, mais uma interface em `src/app/planner.ts`:

```typescript
// src/app/planner.ts
export interface Course {
  id: string;
  name: string;
}

export interface Session {
  id: number;
  courseId: string;
  date: string;
  minutes: number;
  done: boolean;
}

export interface PlannerData {
  courses: Course[];
  sessions: Session[];
}
```

O `loader` é uma função `async`, e o `resource` a chama assim que o componente existe e guarda o
resultado em signals. O template lê três deles: `isLoading()`, `error()` e `value()`, cada um com
parênteses, cada um um signal como os de antes. O valor é `undefined` até o loader terminar, então o
último ramo dá nome a ele com `as`, do jeito que o `@if` da aula 5 fez, e o lê já sabendo que existe.

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-week-summary --network
[vite] connecting...
[vite] connected.
Angular is running in development mode.
net  GET /course.json  404
[error] Failed to load resource: the server responded with a status of 404 (Not Found)
The week could not be loaded: Unexpected token '<', "<!DOCTYPE "... is not valid JSON
```

O endereço no loader diz `/course.json`, sem o `s`. O `--network` lista as requisições que o código da
página fez, e o servidor de desenvolvimento respondeu essa com `404`, com uma página de erro em HTML.
Depois a mensagem: o `.json()` tentou ler HTML como JSON, lançou um erro, e o `resource` pegou o erro e o
pôs em `error()`. **O template tinha um ramo para isso, então a página diz que algo deu errado em vez de
ficar em branco**, que é o motivo para escrever os três ramos sempre.

A mensagem em si engana, porém: ela culpa o JSON, e o problema de verdade foi o 404. Isso é uma
propriedade do `fetch`: **ele só rejeita quando não há resposta nenhuma**, e um 404 ou um 500 é uma
resposta, então o loader seguiu em frente e leu uma página de erro. Confira o status antes de ler o
corpo:

```typescript
// src/app/week-summary/week-summary.ts
import { Component, resource } from '@angular/core';
import { PlannerData } from '../planner';

@Component({
  selector: 'app-week-summary',
  imports: [],
  templateUrl: './week-summary.html',
  styleUrl: './week-summary.css',
})
export class WeekSummary {
  protected readonly data = resource({
    loader: async (): Promise<PlannerData> => {
      const response = await fetch('/course.json');
      if (!response.ok) throw new Error(`${response.url} answered ${response.status}`);
      return response.json();
    },
  });
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-week-summary
[vite] connecting...
[vite] connected.
Angular is running in development mode.
[error] Failed to load resource: the server responded with a status of 404 (Not Found)
The week could not be loaded: http://localhost:4200/course.json answered 404
```

Agora a página diz o endereço e o status, que é a mensagem que você quer no dia em que um servidor de
verdade estiver fora do ar. Corrija o endereço:

```typescript
// src/app/week-summary/week-summary.ts
import { Component, resource } from '@angular/core';
import { PlannerData } from '../planner';

@Component({
  selector: 'app-week-summary',
  imports: [],
  templateUrl: './week-summary.html',
  styleUrl: './week-summary.css',
})
export class WeekSummary {
  protected readonly data = resource({
    loader: async (): Promise<PlannerData> => {
      const response = await fetch('/courses.json');
      if (!response.ok) throw new Error(`${response.url} answered ${response.status}`);
      return response.json();
    },
  });
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-week-summary --network
[vite] connecting...
[vite] connected.
Angular is running in development mode.
net  GET /courses.json  200
6 sessions loaded.
```

Seis sessões. Note o que continua possível: `Promise<PlannerData>` é uma promessa em que o TypeScript
acreditou. Nada conferiu que a resposta eram os dados de um planner; o tipo é uma afirmação sobre o
servidor, escrita por você. A aula 12 volta a isso com o `HttpClient`.

## O que o resource é, hoje

O `resource` está marcado como **experimental** no Angular 21: a API dele ainda pode mudar entre
versões, e é o próprio framework dizendo isso na documentação. É o caminho para onde o Angular vai com
dados assíncronos em signals, e a aula 12 tem uma versão feita para HTTP. O `fetch` deste loader é o
do próprio navegador, que a aula 16 de `javascript` usou, e ele é trocado na aula 12.

Um resource também pode receber **`params`**, uma função que lê signals: quando eles mudam, o loader
roda de novo com os valores novos, e a requisição anterior é cancelada pelo `abortSignal` que o loader
recebe. O planner precisa disso na aula 17, quando o curso na tela vier do endereço.
