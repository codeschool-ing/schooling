---
title: A interface, e a metade da web
version: 1
---

**Escreva a interface primeiro, porque ela é o contrato que os outros três cumprem.** É contra ela que o
código do planner é tipado, é ela que a documentação gerada descreve, e é a ela que os lados Kotlin e
Swift têm que responder. Três métodos, cada um devolvendo uma `Promise`, já que toda chamada pela ponte é
assíncrona:

```typescript
// src/definitions.ts: what the plugin promises, the same on every platform.
export interface KeepAwakePlugin {
  /** Keep the screen on, until allowSleep() or until the app leaves the screen. */
  keepAwake(): Promise<void>;
  /** Let the screen turn off again on the system's usual timer. */
  allowSleep(): Promise<void>;
  /** Whether this platform can keep the screen on at all. */
  isSupported(): Promise<{ supported: boolean }>;
}
```

**O `isSupported` está ali porque nem toda plataforma consegue fazer isso**, e o app deve poder
perguntar antes de oferecer um botão que vai falhar. Os comentários não são enfeite: o passo de build do
gerador os transforma no README do plugin, como o fim desta seção mostra.

## A implementação web

No navegador, manter a tela ligada é a Screen Wake Lock API. `navigator.wakeLock.request("screen")`
devolve uma sentinela, um objeto que segura a trava até ela ser liberada:

```typescript
// src/web.ts: the browser's half, on the Screen Wake Lock API.
import { WebPlugin } from '@capacitor/core';

import type { KeepAwakePlugin } from './definitions';

export class KeepAwakeWeb extends WebPlugin implements KeepAwakePlugin {
  private lock: WakeLockSentinel | null = null;

  async keepAwake(): Promise<void> {
    if (!('wakeLock' in navigator)) {
      throw this.unavailable('This browser cannot keep the screen on.');
    }
    this.lock = await navigator.wakeLock.request('screen');
  }

  async allowSleep(): Promise<void> {
    await this.lock?.release();
    this.lock = null;
  }

  async isSupported(): Promise<{ supported: boolean }> {
    return { supported: 'wakeLock' in navigator };
  }
}
```

- **`WebPlugin`** é a classe base do Capacitor para o lado web. `this.unavailable(…)` cria o erro que o
  Capacitor usa para "esta plataforma não consegue", com o código `UNAVAILABLE`, que o planner consegue
  distinguir de uma recusa.
- **O navegador pode recusar.** O `request()` rejeita quando a página não está visível, ou quando o
  navegador não permite, e essa rejeição chega ao planner como um erro, como uma permissão recusada na
  aula 4.
- **A trava termina sozinha quando a página fica escondida**, então sair da aba devolve a tela ao
  sistema. Os lados nativos se comportam do mesmo jeito quando o app sai da tela, e é por isso que o
  comentário da interface diz isso.

Construa. O `npm run build` é o do próprio plugin: limpa a `dist/`, gera a documentação, confere os tipos
e empacota o resultado com o Rollup. O relatório dele vai para `/dev/null` aqui pelo mesmo motivo que o
do gerador, a linha do Rollup aparece, e o `ls` mostra o que ele escreveu:

```
ana@dev:~/keep-awake$ npm run build > /dev/null

dist/esm/index.js → dist/plugin.js, dist/plugin.cjs.js...
created dist/plugin.js, dist/plugin.cjs.js in 58ms
ana@dev:~/keep-awake$ ls dist dist/esm
dist:
docs.json
esm
plugin.cjs.js
plugin.cjs.js.map
plugin.js
plugin.js.map

dist/esm:
definitions.d.ts
definitions.js
definitions.js.map
index.d.ts
index.js
index.js.map
web.d.ts
web.js
web.js.map
```

A documentação que ele gerou, a partir dos comentários do `definitions.ts`:

```
ana@dev:~/keep-awake$ grep -E '^### |^(Keep|Let|Whether) ' README.md
Keep the screen on while a study session runs
### keepAwake()
Keep the screen on, until allowSleep() or until the app leaves the screen.
### allowSleep()
Let the screen turn off again on the system's usual timer.
### isSupported()
Whether this platform can keep the screen on at all.
```

Faça o commit do plugin, para o planner instalar uma versão dele que o git sabe nomear:

```
ana@dev:~/keep-awake$ git add -A
ana@dev:~/keep-awake$ git commit -q -m "Keep the screen on, on three platforms"
ana@dev:~/keep-awake$ git log --oneline
9d831d6 Keep the screen on, on three platforms
4bfe8c8 Initial commit
```
