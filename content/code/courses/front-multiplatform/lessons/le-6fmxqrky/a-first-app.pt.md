---
title: Um primeiro app com Expo
version: 1
---

**O Expo é o jeito que a própria documentação do React Native recomenda para começar um app novo**: um
conjunto de ferramentas e bibliotecas em volta do React Native que roda o app num celular sem construí-lo
antes, o constrói na nuvem quando você precisa de um pacote de verdade, e dá os recursos nativos como
pacotes. A aula 9 é sobre o Expo em si. Esta seção usa o mínimo dele: um projeto novo, e o app num
navegador.

**O projeto é separado do planner**, em `~/planner-native`, porque não tem Vite, nem `index.html`, nem
`src/view.ts`. Crie-o pelo modelo TypeScript do Expo, na versão com que este curso foi gravado, sem
instalar ainda:

```
ana@dev:~$ npx create-expo-app@5.0.0 planner-native --template blank-typescript@sdk-58 --no-install > /dev/null 2>&1
ana@dev:~$ cd planner-native
ana@dev:~/planner-native$ ls
AGENTS.md
App.tsx
LICENSE
app.json
assets
index.ts
package.json
tsconfig.json
```

O `@sdk-58` pede o modelo do SDK 58 do Expo, a versão que este curso usa; sem ele, o `create-expo-app`
pega o modelo mais novo, que acompanha os lançamentos do próprio Expo e não este curso. O relatório dele
foi para `/dev/null` porque desenha um indicador de progresso e emoji que esta página não consegue mostrar;
o `ls` mostra o que ele escreveu. O `App.tsx` é o app, o `index.ts` o registra, e o `app.json` guarda o
nome, os ícones e as configurações de cada plataforma.

Depois instale, com toda versão escrita exata, como na aula 1, mais os três pacotes que deixam o mesmo app
rodar num navegador: `react-dom` e `react-native-web`, que transformam os componentes do React Native em
HTML, e `@expo/metro-runtime`. E o Playwright, na mesma versão que o do planner:

```
ana@dev:~/planner-native$ npm install -E expo@58.0.17 expo-status-bar@58.0.4 react@19.3.0 react-native@0.88.0 react-dom@19.3.0 react-native-web@0.21.4 @expo/metro-runtime@58.0.15

added 481 packages, and audited 482 packages in 15s

5 high severity vulnerabilities

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
ana@dev:~/planner-native$ npm install -E -D typescript@6.0.3 @types/react@19.3.0 playwright@1.63.0

added 4 packages, and audited 486 packages in 2s

5 high severity vulnerabilities

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
ana@dev:~/planner-native$ grep -A12 '"dependencies"' package.json
  "dependencies": {
    "@expo/metro-runtime": "58.0.15",
    "expo": "58.0.17",
    "expo-status-bar": "58.0.4",
    "react": "19.3.0",
    "react-dom": "19.3.0",
    "react-native": "0.88.0",
    "react-native-web": "0.21.4"
  },
  "devDependencies": {
    "@types/react": "19.3.0",
    "playwright": "1.63.0",
    "typescript": "6.0.3"
```

Os cinco avisos de severidade alta estão, no dia em que isto foi gravado, em pacotes de que as próprias
ferramentas do Expo dependem; o `npm audit` os nomeia. Como na aula 2, **não recorra ao `npm audit fix
--force`**, que pode mover o próprio `expo` para outro SDK.

O comando do próprio Expo para acrescentar um pacote, `npx expo install`, escolhe a versão de cada pacote
que combina com o SDK, e a escreve com um `~`. Rodá-lo primeiro e fixar depois com `npm install -E` é o
jeito de ter a versão certa e uma exata.

## Onde rodar

| onde | como | o que mostra |
|---|---|---|
| um navegador | `npx expo start --web`, ou exportar e servir, como abaixo | o app, desenhado com HTML pelo `react-native-web` |
| um celular, com o Expo Go | `npx expo start`, e depois ler com o app Expo Go o QR code que ele imprime | o app, com views nativas de verdade, sem construí-lo |
| um emulador | `npx expo start`, e depois `a` para Android ou `i` para o simulador iOS num Mac | o mesmo, no computador |

**O navegador é o único dos três que este curso conseguiu rodar**, pelos motivos que a aula 3 deu, então
as transcrições mostram o build web. *O Expo Go num celular não foi rodado.* Ele é o mais rápido dos três
de preparar, um app de qualquer uma das lojas e um celular na mesma rede que o computador, e é onde as
views nativas da próxima seção deixam de ser uma descrição.
