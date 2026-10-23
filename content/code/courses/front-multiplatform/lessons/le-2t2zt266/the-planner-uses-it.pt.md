---
title: O planner o usa
version: 1
---

**O planner instala o plugin a partir da pasta dele, do jeito que o instalaria do registro.** O `npm
install ../keep-awake` escreve uma dependência `file:`, que liga a pasta em vez de copiá-la, então um
rebuild do plugin chega ao planner sem instalar de novo:

```
ana@dev:~/planner$ npm install -E ../keep-awake

added 1 package, and audited 128 packages in 477ms

3 moderate severity vulnerabilities

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
ana@dev:~/planner$ grep keep-awake package.json
    "capacitor-keep-awake": "file:../keep-awake"
ana@dev:~/planner$ npx cap sync android | grep -A7 "plugins for android"
[info] Found 6 Capacitor plugins for android:
       @capacitor/camera@8.2.6
       @capacitor/filesystem@8.1.5
       @capacitor/geolocation@8.2.4
       @capacitor/local-notifications@8.3.1
       @capacitor/preferences@8.0.1
       capacitor-keep-awake@0.0.1
✔ update android in 62.71ms
```

**O sexto plugin está na lista**, encontrado pelo mesmo `cap sync` que encontrou os cinco oficiais, pela
chave `capacitor` do `package.json` dele. No lado iOS, o sync o escreveu no `Package.swift` do mesmo
jeito. Nada diz ao Capacitor que este é seu.

## Três edições pequenas

No `src/device.ts`, importe o plugin embaixo do import da câmera:

```typescript
import { KeepAwake } from "capacitor-keep-awake";
```

e acrescente uma função no fim do arquivo:

```typescript
export async function keepScreenOn(on: boolean): Promise<string> {
  if (on) await KeepAwake.keepAwake();
  else await KeepAwake.allowSleep();
  return on ? "the screen stays on" : "the screen may sleep again";
}
```

No `src/view.ts`, a lista de ações do aparelho ganha duas palavras, no tipo `Actions`:

```typescript
  device: (what: "export" | "where" | "photo" | "remind" | "awake" | "sleep", session?: string) => void;
```

e a tela do curso dois botões, depois do da foto:

```typescript
  root.append(list, form, button("Photo of my notes", () => act.device("photo")),
    button("Keep the screen on", () => act.device("awake")), button("Let the screen sleep", () => act.device("sleep")), said);
```

No `src/main.ts`, importe `keepScreenOn` ao lado das outras funções do aparelho, acrescente as mesmas
duas palavras à assinatura de `device()`, e uma linha depois da da foto:

```typescript
    if (what === "awake" || what === "sleep") say(await keepScreenOn(what === "awake"));
```

Construa, e experimente no navegador, primeiro como uma página que não recebeu permissão, depois com
ela:

```
ana@dev:~/planner$ npm run build | tail -n 2

✓ built in 223ms
```

```
ana@dev:~/planner$ node look.mjs 'http://localhost:5173/?today=2026-10-21' --click Statistics --click 'Keep the screen on' --wait 300 | tail -n 1
  - status: "awake failed: Wake Lock permission request denied"
ana@dev:~/planner$ node look.mjs 'http://localhost:5173/?today=2026-10-21' --click Statistics --grant screen-wake-lock --click 'Keep the screen on' --wait 300 | tail -n 1
  - status: the screen stays on
ana@dev:~/planner$ node look.mjs 'http://localhost:5173/?today=2026-10-21' --click Statistics --grant screen-wake-lock --click 'Keep the screen on' --click 'Let the screen sleep' --wait 300 | tail -n 1
  - status: the screen may sleep again
```

**A recusa é do navegador, palavra por palavra**, e o planner a informa como informa qualquer falha. O
Chromium sem janela recusa uma trava de tela a menos que ela seja concedida, do jeito que um celular
recusa quando o app não está na tela. Com ela concedida, a trava é tomada e liberada, e a linha de
status diz qual. Num celular, os mesmos dois botões chegam à classe Kotlin ou Swift, e não há pergunta
nenhuma a responder: manter a tela ligada não exige permissão em nenhum dos dois sistemas.

Faça o commit do planner:

```
ana@dev:~/planner$ git add . && git commit -q -m "Keep the screen on during a session" && git log --oneline -1
7a7313d Keep the screen on during a session
```

## Publicar, ou não

O plugin agora funciona para o planner a partir de uma pasta ao lado dele. Para qualquer outra pessoa,
ele seria publicado no npm com `npm publish`, depois de um número de versão de verdade, um README que
diga quais plataformas ele suporta e testes em cada uma. A aula 15 é sobre números de versão. **A maioria
dos plugins escritos para um app nunca precisa ser publicada**, e ficar numa pasta do repositório do
app, ou num monorepo ao lado dele, é um ótimo lugar para um.
