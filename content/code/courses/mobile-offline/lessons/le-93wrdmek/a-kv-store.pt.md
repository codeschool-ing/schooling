---
title: Um armazenamento chave-valor seu
version: 1
---

**Um armazenamento chave-valor é um dicionário que sobrevive ao programa, e a parte difícil é a
linha que o grava.** Ler é trivial: interpretar um arquivo. Gravar precisa sobreviver ao app ser
morto no meio, e a próxima seção mostra o que acontece quando não sobrevive. Esta constrói o
armazenamento que o planner usa pelo resto do curso.

Crie a pasta da aula, `~/planner/prefs`, e salve isto nela como `kv.ts`:

```typescript
// kv.ts: a key-value store in one JSON file, the shape SharedPreferences and UserDefaults have.
import { closeSync, existsSync, fsyncSync, openSync, readFileSync, renameSync, writeSync } from "node:fs";

export type Prefs = Record<string, string | number | boolean>;

// Read the whole file. A missing file is an empty store; a damaged one is an error, not {}.
export function load(path: string): Prefs {
  if (!existsSync(path)) return {};
  return JSON.parse(readFileSync(path, "utf8")) as Prefs;
}

// Write the new contents beside the file, push them to the disk, then rename over the old one.
// A rename replaces the file in one step, so a reader finds the old version or the new one.
export function save(path: string, prefs: Prefs): number {
  const text = JSON.stringify(prefs, null, 2) + "\n";
  const tmp = `${path}.tmp`;
  const fd = openSync(tmp, "w");
  writeSync(fd, text);
  fsyncSync(fd);
  closeSync(fd);
  renameSync(tmp, path);
  return Buffer.byteLength(text);
}
```

Duas decisões nele merecem uma segunda leitura.

**Um arquivo ausente e um arquivo danificado são respostas diferentes.** Um arquivo ausente quer
dizer que o app nunca salvou uma configuração, e um armazenamento vazio é a verdade. Um arquivo que
não se interpreta quer dizer que algo deu errado, e devolver `{}` voltaria as configurações da
pessoa para o padrão em silêncio, sem registro do motivo. Então o `load` deixa o erro do parser
chegar a quem chamou, que decide. O DataStore do Android faz a mesma distinção: um arquivo que ele
não consegue ler levanta `CorruptionException`, e um app que quer recomeçar diz isso com um
`ReplaceFileCorruptionHandler`.

**O `save` nunca grava o arquivo que está substituindo.** Ele grava `settings.json.tmp`, pede ao
sistema operacional que empurre esses bytes para o disco com `fsyncSync`, e só então renomeia o
arquivo temporário por cima do verdadeiro. Sem o `fsync`, o renomear pode chegar ao disco antes do
dado, e uma queda de energia deixa um nome novo num arquivo vazio.

Agora um programa que o usa. Salve isto como `settings.ts`:

```typescript
// settings.ts: the planner's settings, read and written through kv.ts.
import { load, save } from "./kv.ts";

const path = "settings.json";
const [command, key, value] = process.argv.slice(2);
const prefs = load(path);

if (command === "set") {
  prefs[key] = value === "true" ? true : value === "false" ? false : isNaN(Number(value)) ? value : Number(value);
  console.log(`saved ${save(path, prefs)} bytes`);
} else if (command === "get") {
  console.log(key in prefs ? prefs[key] : `(no ${key})`);
} else {
  console.log(prefs);
}
```

O `set` transforma `true`, `false` e qualquer coisa numérica no tipo certo, então `dailyGoal` volta
como o número 45 e não como a string `"45"`:

```
ana@dev:~/planner/prefs$ node settings.ts set theme dark
saved 22 bytes
ana@dev:~/planner/prefs$ node settings.ts set dailyGoal 45
saved 41 bytes
ana@dev:~/planner/prefs$ node settings.ts get theme
dark
ana@dev:~/planner/prefs$ node settings.ts get dailyGoal
45
ana@dev:~/planner/prefs$ node settings.ts
{ theme: 'dark', dailyGoal: 45 }
ana@dev:~/planner/prefs$ cat settings.json
{
  "theme": "dark",
  "dailyGoal": 45
}
```

O arquivo é JSON comum, e isso é uma vantagem: durante o desenvolvimento dá para abri-lo e lê-lo.
Num celular, o equivalente é `shared_prefs/settings.xml` ou a lista de propriedades em
`Library/Preferences/`, que o explorador de dispositivo do Android Studio e o download do
contêiner do Xcode deixam abrir do mesmo jeito.
