---
title: Build, depois sync, toda vez
version: 1
---

**Os projetos nativos guardam uma cópia da `dist/`, não um link para ela.** Toda mudança no planner
chega ao celular em dois passos, e eles vêm sempre na mesma ordem: `npm run build` escreve a `dist/`, e
`npx cap sync` a copia para os dois projetos. Deixe de fora o primeiro e você copia um build antigo;
deixe de fora o segundo e os projetos ficam com o anterior.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 150\" role=\"img\" data-fig=\"l02-loop\" aria-label=\"O ciclo que leva uma mudança ao celular. Você edita a src, npm run build escreve a dist, npx cap sync copia a dist para android e ios, e o build nativo faz o app. Pular o build copia uma dist antiga; pular o sync deixa os projetos com a cópia anterior.\"><defs><marker id=\"l02-loop-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"155\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"97.5\" y=\"49.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">editar</text><text x=\"97.5\" y=\"62.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">src/</text><rect x=\"195\" y=\"30\" width=\"155\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"272.5\" y=\"49.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">npm run build</text><text x=\"272.5\" y=\"62.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">escreve a dist/</text><rect x=\"370\" y=\"30\" width=\"155\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"447.5\" y=\"49.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">npx cap sync</text><text x=\"447.5\" y=\"62.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">copia para android/, ios/</text><rect x=\"545\" y=\"30\" width=\"155\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"622.5\" y=\"49.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o build nativo</text><text x=\"622.5\" y=\"62.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Android Studio, Xcode</text><path d=\"M175 56 L195 56\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-loop-ah-paper-dim)\"></path><path d=\"M350 56 L370 56\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-loop-ah-paper-dim)\"></path><path d=\"M525 56 L545 56\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-loop-ah-paper-dim)\"></path><text x=\"272\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" font-style=\"italic\" fill=\"var(--amber)\">pulou: copia uma dist/ antiga</text><text x=\"447\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" font-style=\"italic\" fill=\"var(--amber)\">pulou: os projetos ficam com a cópia anterior</text></svg>", "caption": "Dois passos entre o seu código e o celular, sempre nesta ordem.", "same": ["src/", "npm run build", "npx cap sync", "Android Studio, Xcode"]}
```

## Para onde vai a cópia

```
ana@dev:~/planner$ ls android/app/src/main/assets android/app/src/main/assets/public
android/app/src/main/assets:
capacitor.config.json
capacitor.plugins.json
public

android/app/src/main/assets/public:
assets
cordova.js
cordova_plugins.js
courses.json
index.html
ana@dev:~/planner$ cat android/app/src/main/assets/capacitor.config.json
{
	"appId": "com.example.studyplanner",
	"appName": "Study planner",
	"webDir": "dist"
}
```

A `public/` é a `dist/` como estava no último sync, com dois arquivinhos que o Capacitor acrescenta
para plugins do Cordova. Ao lado dela ficam dois arquivos que o Capacitor escreve para o lado nativo:
**`capacitor.config.json` é o `capacitor.config.ts` transformado em JSON**, porque nem Java nem Swift
leem TypeScript, e `capacitor.plugins.json` lista os plugins com que o app foi sincronizado.

**Nenhum deles está no git.** Os próprios `.gitignore` do Capacitor os deixam de fora, porque são
cópias feitas a partir de coisas que estão no git:

```
ana@dev:~/planner$ git check-ignore -v android/app/src/main/assets/public ios/App/App/public
android/.gitignore:96:app/src/main/assets/public	android/app/src/main/assets/public
ios/.gitignore:4:App/App/public	ios/App/App/public
```

## A cópia que não foi atualizada

Este é o erro que todo mundo comete uma vez. Mude uma palavra em `src/view.ts`, sincronize sem
construir e olhe o que o projeto Android guarda agora:

```
ana@dev:~/planner$ grep -oE "(Back to|All) courses" android/app/src/main/assets/public/assets/*.js
All courses
ana@dev:~/planner$ sed -i 's/All courses/Back to courses/' src/view.ts
ana@dev:~/planner$ npx cap sync android
✔ Copying web assets from dist to android/app/src/main/assets/public in 6.43ms
✔ Creating capacitor.config.json in android/app/src/main/assets in 906.90μs
✔ copy android in 16.14ms
✔ Updating Android plugins in 1.31ms
✔ update android in 23.93ms
[info] Sync finished in 0.05s
ana@dev:~/planner$ grep -oE "(Back to|All) courses" android/app/src/main/assets/public/assets/*.js
All courses
```

**O `cap sync` fez tudo o que disse que fez**, e o projeto Android ainda diz "All courses", porque ele
copiou a `dist/`, e a `dist/` foi construída antes da mudança. Nada avisou, e num celular o app
simplesmente pareceria ter perdido a edição. Construa primeiro:

```
ana@dev:~/planner$ npm run build && npx cap sync android

> planner@0.0.0 build
> tsc && vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 6 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                0.32 kB │ gzip: 0.23 kB
dist/assets/index-BEhkw5vf.js  2.90 kB │ gzip: 1.34 kB

✓ built in 103ms
✔ Copying web assets from dist to android/app/src/main/assets/public in 7.35ms
✔ Creating capacitor.config.json in android/app/src/main/assets in 1.04ms
✔ copy android in 18.31ms
✔ Updating Android plugins in 1.06ms
✔ update android in 18.60ms
[info] Sync finished in 0.045s
ana@dev:~/planner$ grep -oE "(Back to|All) courses" android/app/src/main/assets/public/assets/*.js
Back to courses
```

O `sync` são dois comandos em um: **`cap copy`** põe a `dist/` e a configuração nos projetos, e
**`cap update`** instala o lado nativo de qualquer plugin acrescentado ao `package.json` desde a última
vez. Só o copy basta para uma mudança no seu código web. O sync é o hábito que vale ter, porque ele
também está certo no dia em que você acrescenta um plugin.

Aqui a edição foi desfeita, construída e sincronizada de novo, para o planner continuar como a aula 1
o escreveu. Depois a aula inteira vai para um commit, com os projetos nativos:

```
ana@dev:~/planner$ git add .
ana@dev:~/planner$ git commit -q -m "Capacitor, and the Android and iOS projects"
ana@dev:~/planner$ git log --oneline
5ae7d06 Capacitor, and the Android and iOS projects
f608061 Look at the planner from the terminal
558b1c0 The study planner, as lesson 1 gives it
```
