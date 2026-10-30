---
title: Ionic, controles de celular para a web
version: 1
---

**O Ionic é uma biblioteca de componentes com cara e comportamento de celular**: listas com o
espaçamento da plataforma, barras de ferramentas, abas, folhas modais que deslizam para cima, e o visual
do iOS ou do Android escolhido pela plataforma onde o app roda. São web components, então funcionam numa
página simples e dentro de Angular, React e Vue do mesmo jeito, e num app Capacitor são o jeito comum de
fazer a WebView parecer um app e não uma página, que é metade da lista de conferência da aula 6.

Uma página pequena os mostra. É um segundo projeto Vite ao lado do planner, para o planner ficar como
está:

```
ana@dev:~$ npm create vite@9.3.1 planner-ionic -- --template vanilla-ts --no-interactive > /dev/null
ana@dev:~$ cd planner-ionic
ana@dev:~/planner-ionic$ rm -r src public && mkdir src
ana@dev:~/planner-ionic$ npm install -E -D vite@8.3.5 typescript@6.0.3 > /dev/null
ana@dev:~/planner-ionic$ npm install -E @ionic/core@9.0.9

added 7 packages, and audited 24 packages in 3s

found 0 vulnerabilities
ana@dev:~/planner-ionic$ cp ../planner/src/planner.ts ../planner/public/courses.json src/
```

A página, `index.html`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Study planner, with Ionic</title>
  </head>
  <body>
    <div id="app"></div>
    <script type="module" src="/src/main.ts"></script>
  </body>
</html>
```

e o script dela, que desenha os cursos e a semana do planner com os elementos do Ionic, a partir dos
mesmos `planner.ts` e `courses.json`:

```typescript
// src/main.ts: the planner's list of courses, drawn with Ionic's components.
import { defineCustomElements } from "@ionic/core/loader";
import "@ionic/core/css/ionic.bundle.css";
import { mondayOf, weekTotal, type Plan } from "./planner";
import data from "./courses.json";

defineCustomElements();
const plan: Plan = data;
const today = new URLSearchParams(location.search).get("today") ?? new Date().toISOString().slice(0, 10);
const total = weekTotal(plan, mondayOf(today));

document.querySelector("#app")!.innerHTML = `
<ion-app>
  <ion-header><ion-toolbar><ion-title>Study planner</ion-title></ion-toolbar></ion-header>
  <ion-content>
    <ion-list>
      <ion-list-header>This week: ${total.done} of ${total.planned} minutes done</ion-list-header>
      ${plan.courses.map((c) => `<ion-item button detail>${c.name}</ion-item>`).join("")}
    </ion-list>
  </ion-content>
</ion-app>`;
```

```
ana@dev:~/planner-ionic$ npm run build | tail -n 7
dist/assets/ion-textarea.entry-cJZu5Eto.js                 46.89 kB │ gzip:  6.76 kB
dist/assets/ion-select_3.entry-BpSFIhwz.js                 55.20 kB │ gzip: 10.98 kB
dist/assets/ion-item_8.entry-DjDaxm16.js                   57.04 kB │ gzip:  9.10 kB
dist/assets/ion-datetime.entry-Tm1Iz27X.js                 57.53 kB │ gzip: 13.18 kB
dist/assets/index-DQslBGJ4.js                              85.22 kB │ gzip: 26.91 kB

✓ built in 473ms
```

O build é maior que o do planner, porque cada componente do Ionic é um módulo próprio, carregado na
primeira vez que a página o usa. Aberto no Chromium:

```
ana@dev:~/planner$ node look.mjs 'http://localhost:4175/?today=2026-10-21' --wait 1500
- banner: Study planner
- main:
  - list:
    - text: "This week: 75 of 125 minutes done"
    - listitem:
      - button "Spanish A2"
    - listitem:
      - button "Statistics"
    - listitem:
      - button "Guitar"
```

**A mesma semana, 75 de 125, e os mesmos três cursos**, agora como itens de lista do Ionic, cada um um
botão, embaixo de uma barra de ferramentas que a árvore chama de banner. Nada nativo aconteceu aqui: isto
é uma página web com componentes com cara de celular, e o Capacitor a embrulharia exatamente como
embrulhou o planner na aula 2.
