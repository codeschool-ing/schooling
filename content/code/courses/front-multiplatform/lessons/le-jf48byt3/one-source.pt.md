---
title: Uma versão, escrita uma vez
version: 1
---

**A versão mora no `package.json`, e todo o resto é copiado dela.** O `npm version` já sabe mudá-la: o
`npm version minor` transforma `0.1.0` em `0.2.0`, faz o commit da mudança, e marca o commit com a tag `v0.2.0`. O
que ele não sabe é que dois projetos nativos levam uma cópia. Então a cópia é feita por um script que o npm roda no
momento certo.

O Tauri não precisa de script: a `version` dele pode apontar para um arquivo em vez de um número, e
`"../package.json"` faz ele ler a versão dali em todo build. Os celulares precisam de um, e aqui está ele, em
`scripts/version.mjs`:

```javascript
// scripts/version.mjs: copy the version in package.json into the Android and iOS projects.
import fs from "node:fs";

const { version } = JSON.parse(fs.readFileSync("package.json", "utf8"));
const match = /^(\d+)\.(\d+)\.(\d+)$/.exec(version);
if (!match) throw new Error(`not a version this script understands: ${version}`);
const [major, minor, patch] = match.slice(1).map(Number);
if (minor > 99 || patch > 99) throw new Error(`${version}: minor and patch must stay below 100`);
// The number for the system grows with the version: 1.2.3 becomes 10203.
const build = major * 10000 + minor * 100 + patch;

function edit(file, changes) {
  let text = fs.readFileSync(file, "utf8");
  for (const [pattern, replacement] of changes) {
    if (!text.match(pattern)) throw new Error(`${file}: nothing matches ${pattern}`);
    text = text.replace(pattern, replacement);
  }
  fs.writeFileSync(file, text);
}

edit("android/app/build.gradle", [
  [/versionCode \d+/, `versionCode ${build}`],
  [/versionName "[^"]*"/, `versionName "${version}"`],
]);
edit("ios/App/App.xcodeproj/project.pbxproj", [
  [/MARKETING_VERSION = [^;]+;/g, `MARKETING_VERSION = ${version};`],
  [/CURRENT_PROJECT_VERSION = [^;]+;/g, `CURRENT_PROJECT_VERSION = ${build};`],
]);
console.log(`version ${version}, build ${build}`);
```

**O número de build é calculado a partir da versão**, então ele cresce sempre que a versão cresce e ninguém
precisa lembrar dele: `0.2.0` é 200, `1.0.0` é 10000, `1.2.3` é 10203. O preço é a segunda verificação no topo: um
minor ou um patch de 100 colidiria com o próximo major, então o script recusa um em vez de produzir um número que
volta. **Cada edição se recusa a não encontrar nada**, também: um modelo que mudasse a grafia deixaria o número
antigo no lugar, calado.

O `npm version` roda um script chamado `version` depois de mudar o `package.json` e antes do commit, e o que esse
script põe no stage entra no mesmo commit. Então duas linhas fazem a ligação, e antes a árvore vai para um commit,
porque o `npm version` se recusa a rodar com mudanças sem commit:

```
ana@dev:~/planner$ sed -i 's|"version": "0.1.0"|"version": "../package.json"|' src-tauri/tauri.conf.json
ana@dev:~/planner$ npm pkg set scripts.version="node scripts/version.mjs && git add android ios"
ana@dev:~/planner$ git add . && git commit -q -m "One version, in package.json" && git log --oneline -1
b876c9c One version, in package.json
```

Daí um release é um comando só:

```
ana@dev:~/planner$ npm version minor

> version
> node scripts/version.mjs && git add android ios

version 0.2.0, build 200
v0.2.0
ana@dev:~/planner$ grep -n "versionCode\|versionName" android/app/build.gradle
10:        versionCode 200
11:        versionName "0.2.0"
ana@dev:~/planner$ grep -c "MARKETING_VERSION = 0.2.0;" ios/App/App.xcodeproj/project.pbxproj
2
ana@dev:~/planner$ git log --oneline -2 && git tag
7519a04 0.2.0
b876c9c One version, in package.json
v0.2.0
```

**Um comando mudou quatro arquivos e criou uma tag.** `v0.2.0` é o nome a partir do qual o release da aula 16 é
gerado, e o número de build 200 é maior que o 1 do modelo, então uma loja que tivesse visto o antigo aceitaria este.
O app Tauri lê o mesmo `0.2.0` do `package.json` na próxima vez que for gerado.
