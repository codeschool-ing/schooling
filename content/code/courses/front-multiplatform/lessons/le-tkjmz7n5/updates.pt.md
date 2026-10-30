---
title: Atualizações remotas
version: 1
---

**Um app Expo pode baixar um bundle JavaScript novo e usá-lo na próxima vez que abrir**, sem uma versão
nova na loja. Isso funciona porque a maior parte de um app é JavaScript e recursos, que o app carrega ao
iniciar, e só a parte nativa precisa ser a mesma. O **`expo-updates`** é a biblioteca que faz isso: ao
abrir, ela pergunta a um servidor de atualizações se existe um bundle mais novo para este app, o baixa e
o roda na abertura seguinte.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l09-updates\" aria-label=\"Como uma atualização remota chega a um app instalado. O build da loja contém o código nativo e o bundle 1, com a runtime version 1.0.0. O servidor de atualizações guarda o bundle 2, também para a runtime 1.0.0, e o bundle 3, construído para a runtime 1.1.0. Ao abrir, o app pergunta ao servidor, baixa o bundle 2 e o roda na abertura seguinte. O bundle 3 não é aceito, porque a runtime version é outra: ele precisa de código nativo que o app instalado não tem, e só chega às pessoas com um build novo da loja.\"><defs><marker id=\"l09-updates-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l09-updates-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l09-updates-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"200\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"91.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o build da loja:</text><text x=\"120.0\" y=\"104.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">código nativo + bundle 1</text><text x=\"120\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">runtime 1.0.0</text><rect x=\"440\" y=\"20\" width=\"260\" height=\"180\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"570\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">o servidor de atualizações</text><rect x=\"470\" y=\"52\" width=\"200\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"68.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">bundle 2</text><text x=\"570.0\" y=\"81.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">runtime 1.0.0</text><rect x=\"470\" y=\"136\" width=\"200\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"152.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">bundle 3</text><text x=\"570.0\" y=\"165.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">runtime 1.1.0</text><path d=\"M220 88 L470 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-updates-ah-paper-dim)\"></path><text x=\"330\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">ao abrir: algo novo para a 1.0.0?</text><path d=\"M470 82 L222 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-updates-ah-phosphor)\"></path><text x=\"330\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--phosphor)\">aceito, roda na abertura seguinte</text><path d=\"M470 159 L222 118\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l09-updates-ah-amber)\"></path><text x=\"330\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--amber)\">recusado: precisa de código nativo que falta</text></svg>", "caption": "Uma atualização muda o JavaScript e os recursos. A runtime version é a promessa de que o código nativo por baixo é o mesmo."}
```

Instale-a, e fixe:

```
ana@dev:~/planner-native$ npx expo install expo-updates > /dev/null
Dependency validation is unreliable in offline-mode
ana@dev:~/planner-native$ npm install -E expo-updates@58.0.18 > /dev/null
ana@dev:~/planner-native$ grep expo-updates package.json
    "expo-updates": "58.0.18",
```

## O que é uma atualização

Não há mistério nela. **Uma atualização é o que o `npx expo export` escreve para uma plataforma**: o
bundle, compilado em bytecode do Hermes, e os recursos que ele usa. Exporte o planner para o Android:

```
ana@dev:~/planner-native$ npx expo export --platform android > /dev/null
ana@dev:~/planner-native$ ls dist dist/_expo/static/js/android
dist:
_expo
assets
metadata.json

dist/_expo/static/js/android:
entry-e597ee604262eb10534a99c0f050340d.hbc
ana@dev:~/planner-native$ file dist/_expo/static/js/android/*.hbc
dist/_expo/static/js/android/entry-e597ee604262eb10534a99c0f050340d.hbc: Hermes JavaScript bytecode, version 99
ana@dev:~/planner-native$ node -p "const m = require('./dist/metadata.json').fileMetadata.android; m.assets.length + ' assets, and ' + m.bundle"
26 assets, and _expo/static/js/android/entry-e597ee604262eb10534a99c0f050340d.hbc
```

**Um arquivo de bytecode do Hermes e as imagens que ele usa**, nomeadas pelo conteúdo, e um
`metadata.json` que as lista, que é o que um servidor de atualizações serve e o app baixa. No serviço do
próprio Expo, o `eas update` roda essa exportação e envia o resultado; uma equipe também pode rodar um
servidor próprio que fale o mesmo protocolo. *O `eas update` não foi rodado para este curso, pelo mesmo
motivo do EAS Build.*

## A runtime version

**Uma atualização só é segura para um app cujo código nativo é aquele contra o qual ela foi construída.**
Um bundle que chama um módulo nativo que o app instalado não tem para o app no momento em que chega a essa
chamada. Então todo build e toda atualização carregam uma **runtime version**, e o app só aceita uma
atualização cuja runtime version é igual à dele. A política mais simples a amarra à versão do app:

```
ana@dev:~/planner-native$ grep -E "\"version\"|runtimeVersion" app.json
    "version": "1.0.0",
    "runtimeVersion": { "policy": "appVersion" },
```

Com `"policy": "appVersion"`, toda atualização construída enquanto a `version` é `1.0.0` só chega a builds
da `1.0.0`. **Mudou código nativo, tem que mudar a versão**, e mandar um build para a loja; mudanças só de
JavaScript saem como atualizações para a versão já instalada. O Expo também tem uma política
`fingerprint`, que calcula a runtime version a partir do próprio código nativo, e aí esquecer de subi-la
deixa de ser possível.

Faça o commit da aula:

```
ana@dev:~/planner-native$ git add . && git commit -q -m "An identity, generated native projects and updates" && git log --oneline -1
fc85f21 An identity, generated native projects and updates
```
