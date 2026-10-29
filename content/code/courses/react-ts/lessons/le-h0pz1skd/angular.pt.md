---
title: Angular, uma classe e signals
version: 1
---

**O Angular é o framework da aula 1, o que vem com tudo**, e ele tem o próprio comando para criar um
projeto, em vez de um template para o Vite. Duas coisas sobre a versão antes. O Angular 22, o mais novo,
pede o Node.js 22.22.3 ou mais recente, e este curso roda o 22.22.0, então o projeto é feito com o Angular
21, a versão anterior. E o ambiente do laboratório define `NG_CLI_ANALYTICS=false`, para a ferramenta não
parar e perguntar se pode coletar dados de uso; no seu computador ela pergunta uma vez, e qualquer
resposta serve.

```
ana@dev:~$ npx --yes @angular/cli@21.2.28 new sessions-angular --defaults --skip-install --skip-git --ssr=false | tail -n 4
CREATE sessions-angular/src/app/app.html (20144 bytes)
CREATE sessions-angular/src/app/app.config.ts (313 bytes)
CREATE sessions-angular/src/app/app.routes.ts (77 bytes)
CREATE sessions-angular/public/favicon.ico (15086 bytes)
```

O `--defaults` aceita a resposta padrão de toda pergunta, o `--ssr=false` deixa de fora a renderização no
servidor, e o `--skip-git` deixa a pasta sem repositório próprio. O **`--skip-install`** está ali por causa
do que vem a seguir. O `package.json` do projeto pede faixas, como o do `create-vite` pedia, e instalá-las
falha neste computador:

```
ana@dev:~/sessions-angular$ npm install 2>&1 | head -n 1
npm error Cannot read properties of null (reading 'edgesOut')
ana@dev:~/sessions-angular$ npm config set save-exact true --location=project && npm install @angular/common@21.2.25 @angular/compiler@21.2.25 @angular/core@21.2.25 @angular/forms@21.2.25 @angular/platform-browser@21.2.25 @angular/router@21.2.25 rxjs@7.8.2 tslib@2.8.1 @angular/build@21.2.28 @angular/cli@21.2.28 @angular/compiler-cli@21.2.25 jsdom@28.1.0 prettier@3.9.10 typescript@5.9.3 vitest@4.0.18 > /dev/null && grep -A 8 "\"devDependencies\"" package.json && ls src/app
  "devDependencies": {
    "@angular/build": "21.2.28",
    "@angular/cli": "21.2.28",
    "@angular/compiler-cli": "21.2.25",
    "jsdom": "28.1.0",
    "prettier": "3.9.10",
    "typescript": "5.9.3",
    "vitest": "4.0.18"
  }
app.config.ts
app.css
app.html
app.routes.ts
app.spec.ts
app.ts
```

**`Cannot read properties of null (reading 'edgesOut')`** é o npm 10.9.4 falhando enquanto resolve as
dependências peer, e o pacote em que ele falha é o Vitest: o template pede qualquer Vitest 4 a partir do
4.0.8, o npm escolhe o 4.1 mais novo, e é essa versão que ele não consegue resolver. Nomear cada versão,
com o Vitest no 4.0.18, instala sem problema. É a lição da aula 1 de novo, pelo outro lado: uma faixa quer
dizer que a instalação que você recebe depende do dia em que a roda. Repare também no **TypeScript
5.9.3**, não no 6.0 dos outros três projetos: o build do Angular aceita o 5.9 e nada mais novo, então este
é o mais novo que ele pode usar. O `jsdom` e o `vitest` são para o `ng test`, que esta aula não roda.

Um componente Angular é uma **classe com um decorator**. `src/app/sessions.ts`, escrito com ponto e
vírgula, como os próprios arquivos do Angular:

```ts
import { Component, computed, signal } from '@angular/core';

type Session = { id: string; course: string; minutes: number; done: boolean };

@Component({
  selector: 'app-sessions',
  template: `
    <section>
      <h1>This week</h1>
      <p>{{ done() }} of {{ total() }} minutes done</p>
      <ul>
        @for (s of sessions(); track s.id) {
          <li>
            <button [attr.aria-pressed]="s.done" (click)="toggle(s.id)">
              {{ s.course }} · {{ s.minutes }} min
            </button>
          </li>
        }
      </ul>
    </section>
  `,
})
export class Sessions {
  protected readonly sessions = signal<Session[]>([
    { id: 's1', course: 'Statistics', minutes: 40, done: true },
    { id: 's2', course: 'Python', minutes: 35, done: false },
    { id: 's3', course: 'Statistics', minutes: 45, done: false },
  ]);
  protected readonly done = computed(() =>
    this.sessions()
      .filter((s) => s.done)
      .reduce((sum, s) => sum + s.minutes, 0),
  );
  protected readonly total = computed(() =>
    this.sessions().reduce((sum, s) => sum + s.minutes, 0),
  );

  constructor() {
    console.log('Sessions ran');
  }

  protected toggle(id: string) {
    this.sessions.update((all) => all.map((s) => (s.id === id ? { ...s, done: !s.done } : s)));
  }
}
```

- O **`@Component`** diz ao Angular que a classe é um componente: `selector` é a tag que o desenha, e
  `template` é o markup dele. Componentes maiores guardam o template num arquivo `.html` ao lado da
  classe, como o `app.ts` gerado fazia.
- O **`signal`** é um valor reativo, lido chamando-o, `sessions()`, e o **`computed`** é um calculado a
  partir de outros. São a mesma ideia do `ref` do Vue e do `$state` do Svelte, numa terceira grafia.
- **O `toggle` monta um array novo**, como o do React, pelo `update`. Um signal decide se mudou comparando
  o valor antigo com o novo, então uma sessão alterada no lugar passaria despercebida.
- No template, **`@for (…; track s.id)`** repete com uma chave, **`[attr.aria-pressed]`** liga um
  atributo, **`(click)`** escuta um evento, e `{{ }}` põe um valor no texto.
- **O `constructor` roda uma vez**, quando o Angular cria o componente. É ali que o log fica.

O `src/app/app.ts`, que a CLI gerou com um router outlet e uma longa página de boas-vindas, fica reduzido a
desenhar o componente, e os arquivos que ele usava são removidos:

```ts
import { Component } from '@angular/core';
import { Sessions } from './sessions';

@Component({
  selector: 'app-root',
  imports: [Sessions],
  template: '<app-sessions />',
})
export class App {}
```

O build do Angular é o dele, `ng build`, e o servidor é o `ng serve`. Com `--configuration production`, o
`npm start` serve o mesmo código otimizado que o build escreve, na porta 4200:

```
ana@dev:~/sessions-angular$ rm src/app/app.html src/app/app.css src/app/app.spec.ts && npm run build

> sessions-angular@0.0.0 build
> ng build

❯ Building...
✔ Building...
Initial chunk files | Names         |  Raw size | Estimated transfer size
main-GFNTBLOI.js    | main          | 198.63 kB |                54.28 kB
styles-5INURTSO.css | styles        |   0 bytes |                 0 bytes

                    | Initial total | 198.63 kB |                54.28 kB

Application bundle generation complete. [3.796 seconds] - 2026-10-24T02:47:09.086Z

Output location: /home/ana/sessions-angular/dist/sessions-angular

ana@dev:~/sessions-angular$ look http://localhost:4200/ --do 'click button Python · 35 min' --do 'click button Statistics · 45 min'
Sessions ran
-- click button Python · 35 min
-- click button Statistics · 45 min
- heading "This week" [level=1]
- paragraph: 120 of 120 minutes done
- list:
  - listitem:
    - button "Statistics · 40 min" [pressed]
  - listitem:
    - button "Python · 35 min" [pressed]
  - listitem:
    - button "Statistics · 45 min" [pressed]
```

**`Sessions ran` uma vez**, como no Vue e no Svelte. Um clique mudou um signal, o template lia esse
signal, então o Angular conferiu aquele template de novo e mudou o texto e os atributos que estavam
diferentes. Não há `zone.js` nas dependências, que o Angular antigo usava para notar mudanças: desde a
versão 21, um projeto novo o deixa de fora, e fica sabendo que algo mudou pelos signals e pelos eventos
que os templates escutam.
