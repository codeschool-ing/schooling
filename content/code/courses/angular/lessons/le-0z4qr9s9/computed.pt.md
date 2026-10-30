---
title: computed, um valor derivado de outros
version: 1
---

**`computed(() => …)` cria um signal só de leitura cujo valor é calculado a partir de outros signals, e
calculado de novo só quando um deles muda.** É assim que um planner transforma seis sessões em "165
minutos planejados" sem ninguém escrever o total. Duas propriedades fazem dele mais que uma chamada de
função, e um programa que registra cada cálculo mostra as duas:

```typescript
// try/computed.mts
import { computed, signal } from '@angular/core';

const planned = signal(165);
const done = signal(90);
const left = computed(() => {
  console.log('  computing left');
  return planned() - done();
});

console.log('nothing read yet');
console.log('left:', left());
console.log('left again:', left());

done.set(115);
console.log('done changed; nothing read yet');
console.log('left:', left());

planned.set(165);
console.log('planned set to the value it had');
console.log('left:', left());
```

```
ana@dev:~/planner$ node try/computed.mts
nothing read yet
  computing left
left: 75
left again: 75
done changed; nothing read yet
  computing left
left: 50
planned set to the value it had
left: 50
```

**Ele é preguiçoso.** Criar o `left` não calculou nada; a primeira leitura calculou. **Ele memoriza.** A
segunda leitura devolveu o 75 guardado sem calcular de novo. Uma mudança em `done` o marcou como
velho, e o cálculo rodou na leitura seguinte, não no momento da mudança. Definir `planned` com o valor
que ele já tinha não marcou nada: um signal compara o valor novo com o antigo, e um igual não é
mudança.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Dois signals, planned e done, alimentam um computed, left, que um template lê. Quando done é definido, um aviso vai adiante até left, marcando-o como desatualizado, e nada é calculado. Quando o template lê left da próxima vez, left puxa de volta os valores atuais de planned e done e calcula uma vez.\"><rect x=\"30\" y=\"40\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">planned</text><text x=\"105.0\" y=\"73\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">signal(165)</text><rect x=\"30\" y=\"150\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">done</text><text x=\"105.0\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">signal(90)</text><rect x=\"290\" y=\"95\" width=\"170\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"375.0\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">left</text><text x=\"375.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">computed</text><rect x=\"560\" y=\"95\" width=\"130\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">{{ left() }}</text><text x=\"625.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o template</text><line x1=\"180\" y1=\"63\" x2=\"288\" y2=\"108\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"288.0,108.0 280.0,108.0 282.4,102.3\" fill=\"var(--wire)\"></polygon><line x1=\"180\" y1=\"173\" x2=\"288\" y2=\"130\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"288.0,130.0 282.3,135.6 280.0,129.8\" fill=\"var(--amber)\"></polygon><line x1=\"460\" y1=\"118\" x2=\"558\" y2=\"118\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"558.0,118.0 550.6,121.1 550.6,114.9\" fill=\"var(--wire)\"></polygon><text x=\"105\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">1. done.set(115)</text><text x=\"235\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">2. \"left está velho\"</text><path d=\"M558 136 C 520 200, 420 200, 400 145\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><line x1=\"402\" y1=\"150\" x2=\"400\" y2=\"145\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"400.0,145.0 405.6,150.7 399.8,153.0\" fill=\"var(--phosphor)\"></polygon><text x=\"500\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">3. a próxima leitura puxa</text><text x=\"375\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">4. calcula uma vez, depois lembra</text></svg>", "caption": "Uma mudança só marca como velho o que depende dela. O cálculo acontece quando alguém lê.", "same": ["computed", "signal(165)", "signal(90)"]}
```

## As dependências são achadas pela leitura

Nada no `computed` lista `planned` e `done`. O Angular registrou quais signals a função **chamou**
enquanto rodava, e esses viraram as dependências dela. Isso tem uma consequência que vale mais um
programa:

```typescript
// try/branches.mts
import { computed, signal } from '@angular/core';

const showDone = signal(false);
const planned = signal(165);
const done = signal(90);
const label = computed(() => {
  console.log('  computing label');
  return showDone() ? `${done()} done` : `${planned()} planned`;
});

console.log(label());
done.set(100);
console.log('done changed:', label());
showDone.set(true);
console.log('showDone changed:', label());
```

```
ana@dev:~/planner$ node try/branches.mts
  computing label
165 planned
done changed: 165 planned
  computing label
showDone changed: 100 done
```

Enquanto `showDone` era falso, a função nunca chamou `done()`, então `done` não era dependência, e
mudá-lo nem marcou `label` como velho. **Um computed depende do que leu da última vez, não de tudo o que
poderia ler.** Isso é eficiente, e também é por isso que a função precisa ler os seus signals
diretamente: um signal lido dentro de um `setTimeout` ou depois de um `await` num computed não é
rastreado.

Um computed é só de leitura: `left.set(…)` não existe. Se algo deve poder ser definido e também seguir
outros valores, isso é o `linkedSignal`, de que este curso não precisa; os valores derivados do planner
são todos `computed` simples.
