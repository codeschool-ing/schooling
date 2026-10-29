---
title: Zoneless, o jeito do planner desde a aula 2
version: 1
---

**Sem o zone.js, nada avisa o Angular de que "algo assíncrono aconteceu", então o Angular só percorre a
árvore quando algo em que ele confia diz que um valor mudou.** É assim que o planner roda desde a aula
2: o `ng new --zoneless` não escreveu zone.js, e o Angular 21 é zoneless a não ser que alguém diga o
contrário. Tire o zone.js do planner de novo. O `git status` lista os quatro arquivos que a seção
anterior mudou, o `git checkout` os põe de volta como estavam no último commit, e o `npm ci` faz o
`node_modules` bater com o lockfile de novo:

```
ana@dev:~/planner$ git status --short
 M package-lock.json
 M package.json
 M src/app/app.config.ts
 M src/main.ts
ana@dev:~/planner$ git checkout -- .
ana@dev:~/planner$ npm ci

added 474 packages, and audited 475 packages in 8s

2 moderate severity vulnerabilities

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

A mesma bancada, os mesmos timers:

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --wait 1000
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Bench

default, plain field: 0

OnPush, plain field: 0

OnPush, signal: 1
```

**Agora o componente padrão também manteve o 0.** O timer dele era o `setTimeout` do próprio navegador,
ninguém estava ouvindo, e o campo mudou numa classe que nenhuma passada visitou. O signal continuou
funcionando: defini-lo marcou o componente dele e agendou uma passada, e a página mostrou 1.

O que agenda uma passada numa aplicação zoneless:

- **um signal lido por um template muda**, e é por isso que a aula 6 levou os dados do planner para
  signals antes de esta aula explicar o porquê;
- **um evento ligado num template dispara**, então todo `(click)` da aula 4 continua redesenhando
  como antes;
- **o `markForCheck()` é chamado**, por você ou por algo que você usa, como o pipe `async` da aula 13;
- **um `resource` termina de carregar**, já que o valor dele é um signal.

**A falha é silenciosa.** Um campo atribuído num timer, no `then` de uma promise ou num callback de uma
biblioteca mostra o valor antigo até algo disparar uma passada, e então pula. Numa aplicação com
zone.js o mesmo código funcionava, e é exatamente isso que faz de levar uma aplicação antiga para
zoneless a parte que exige cuidado: o código que dependia do zone.js não falha, ele fica velho.

Aqui está o campo comum feito do jeito certo, como o código do planner é escrito:

```typescript
protected readonly count = signal(0);
constructor() {
  setTimeout(() => this.count.set(1), 300);
}
```

e o template dele lê `{{ count() }}`. Essa é a migração inteira da maioria dos componentes: estado que
muda de forma assíncrona vai para um signal.
