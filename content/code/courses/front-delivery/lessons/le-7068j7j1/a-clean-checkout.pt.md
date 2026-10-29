---
title: Uma cópia limpa, e o arquivo que você esqueceu
version: 1
---

**A única falha que o seu computador nunca consegue mostrar é um arquivo que ele tem e o repositório
não.** Você acrescenta um arquivo, importa, a página funciona, o build funciona, os testes passam, e você
commita tudo menos esse arquivo. No seu computador ele continua lá, então toda conferência que você roda
passa. Em qualquer outra máquina ele não existe.

Esse é o argumento mais forte a favor do CI, e não custa nada ver no seu computador: clone o repositório
numa pasta nova, que é o que uma máquina de CI faz, e rode as conferências lá.

## Um arquivo, esquecido

O planner mostra a duração de uma sessão como `75 min`, que fica melhor como `1 h 15 min`. Uma função
pequena faz isso:

```typescript
// src/format.ts
export function duration(minutes: number): string {
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  return h === 0 ? `${m} min` : m === 0 ? `${h} h` : `${h} h ${m} min`;
}
```

e o `view.ts` a usa, com duas edições. Tudo passa neste computador, e o commit deixa o `format.ts` para
trás, como faz um `git commit` apressado dos arquivos que você editou:

```
ana@dev:~/planner$ sed -i '2i import { duration } from "./format";' src/view.ts
ana@dev:~/planner$ sed -i 's/${s.minutes} min /${duration(s.minutes)} /' src/view.ts
ana@dev:~/planner$ npx tsc && npm test 2>&1 | tail -4
      Tests  5 passed (5)
   Start at  19:52:12
   Duration  229ms (import 37%, transform 27%, worker 18%, tests 18%, environment 1%)

ana@dev:~/planner$ git status --short
 M src/view.ts
?? src/format.ts
ana@dev:~/planner$ git commit -qam "Show durations in hours and minutes"
```

O `git status` imprimiu o aviso bem à vista, `?? src/format.ts`, e é exatamente a linha que as pessoas
param de ler depois da centésima vez.

## As mesmas conferências, numa cópia limpa

Clone o repositório numa pasta própria e rode o pipeline lá, passo a passo, como uma máquina de CI faria:

```
ana@dev:~$ rm -rf ~/ci && git clone -q ~/planner ~/ci && cd ~/ci
ana@dev:~/ci$ npm ci 2>&1 | tail -1
found 0 vulnerabilities
ana@dev:~/ci$ npx tsc
src/view.ts(2,26): error TS2307: Cannot find module './format' or its corresponding type declarations.
```

A instalação funcionou, a partir do lockfile. **A conferência de tipos falhou no import de `./format`**,
porque nesta cópia esse arquivo não existe, e o pipeline pararia aqui com um resultado vermelho no pull
request. Faça o commit do arquivo e rode a cópia limpa de novo:

```
ana@dev:~/planner$ git add src/format.ts
ana@dev:~/planner$ git commit -qm "Add the duration formatter"
ana@dev:~/planner$ cd ~/ci && git pull -q
ana@dev:~/ci$ npx tsc && npm test 2>&1 | tail -4
      Tests  5 passed (5)
   Start at  19:52:18
   Duration  292ms (transform 76%, import 13%, tests 6%, worker 4%)

ana@dev:~/ci$ npx vite build 2>&1 | tail -1
✓ built in 151ms
```

Verde. Esse é o hábito que o CI impõe e o motivo da palavra *limpa*: as únicas conferências que contam são
as rodadas sobre o que foi commitado. Apague `~/ci` quando terminar; é uma cópia e nada mais a usa.
