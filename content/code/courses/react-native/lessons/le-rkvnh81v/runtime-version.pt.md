---
title: A runtime version, e o fingerprint
version: 1
---

**Todo build tem uma runtime version, e uma atualização é publicada para uma.** Um celular só baixa
atualizações cuja runtime version é a dele, então um bundle que precisa de uma biblioteca nativa só chega aos
builds que a contêm. A pergunta é como escolher a runtime version para ela mudar exatamente quando o lado
nativo muda:

- **`appVersion`** usa o `version` do `app.json`. Simples, e depende de as pessoas aumentarem a versão
  sempre que acontece uma mudança nativa, que é o tipo de coisa que as pessoas esquecem.
- **`fingerprint`** calcula um hash de tudo o que é nativo: as bibliotecas com código nativo e as versões
  delas, as configurações nativas do `app.json`, módulos locais como o da aula 17, as entradas das pastas
  geradas. Ele muda quando o lado nativo muda, e só então.

O planner usa o fingerprint. No `app.json`, dentro de `"expo"`, acrescente:

```json
"runtimeVersion": { "policy": "fingerprint" }
```

O `@expo/fingerprint`, que o Expo já instalou, calcula o mesmo hash pela linha de comando. Para ver as
mudanças dele, salve este pequeno leitor das comparações como `changed.mjs`:

```javascript
// changed.mjs: read fingerprint:diff's answer and print one line per native source that changed.
//
//   npx @expo/fingerprint fingerprint:diff A.json B.json | node changed.mjs
import { text } from "node:stream/consumers";

for (const d of JSON.parse(await text(process.stdin))) {
  const s = d.afterSource ?? d.addedSource ?? d.beforeSource ?? d.removedSource ?? d.source;
  console.log(d.op.padEnd(8), s.type.padEnd(9), s.filePath ?? s.id ?? s.name);
}
```

Depois calcule o fingerprint, mude a redação da nota no pé da aba *Courses* no `src/PlanScreen.tsx` para *the
planner counts its weeks from Monday*, e calcule de novo:

```
ana@dev:~/planner$ grep -A2 runtimeVersion app.json
    "runtimeVersion": {
      "policy": "fingerprint"
    }
ana@dev:~/planner$ npx @expo/fingerprint fingerprint:generate > before.json
ana@dev:~/planner$ node -p "require(\"./before.json\").hash"
32541c36c38a038d87ab6d075d07d1f70462e18d
ana@dev:~/planner$ grep -n "counts its weeks" src/PlanScreen.tsx
45:        Your phone's calendar starts the week on {DAYS[WeekStart.firstWeekday()]}; the planner counts its weeks from Monday.
ana@dev:~/planner$ npx @expo/fingerprint fingerprint:generate > after-js.json
ana@dev:~/planner$ node -p "require(\"./after-js.json\").hash"
32541c36c38a038d87ab6d075d07d1f70462e18d
```

**O mesmo hash: texto é JavaScript, então um build feito antes da mudança pode recebê-la como
atualização.** Agora uma biblioteca com código nativo, a `expo-haptics`, que faz o celular vibrar, e o hash
de novo:

```
ana@dev:~/planner$ npx expo install expo-haptics > /dev/null 2>&1
ana@dev:~/planner$ npx @expo/fingerprint fingerprint:generate > after-native.json
ana@dev:~/planner$ node -p "require(\"./after-native.json\").hash"
067bc58992dd2a05bec9c345c035fdb767a3f369
ana@dev:~/planner$ npx @expo/fingerprint fingerprint:diff before.json after-native.json | node changed.mjs
changed  contents  expoAutolinkingConfig:android
changed  contents  expoAutolinkingConfig:ios
added    package   node_modules/expo-haptics/package.json
ana@dev:~/planner$ npm uninstall expo-haptics > /dev/null 2>&1
ana@dev:~/planner$ npx @expo/fingerprint fingerprint:generate | node -p "JSON.parse(require(\"fs\").readFileSync(0)).hash"
32541c36c38a038d87ab6d075d07d1f70462e18d
```

**Um hash diferente, e a comparação diz por quê**: a lista de módulos nativos que o autolinking vai ligar
mudou nas duas plataformas, e um pacote com código nativo foi acrescentado. Uma atualização feita depois
dessa mudança levaria a nova runtime version, e nenhum build feito antes dela a baixaria. Depois a
`expo-haptics` sai de novo, o planner nunca a usou, e **o hash volta a ser o primeiro**: o fingerprint descreve
o que o lado nativo *é*, não o que aconteceu com ele.

```
ana@dev:~/planner$ npx jest weekStart --forceExit 2>&1 | grep -E "Tests:"
Tests:       1 passed, 1 total
```
