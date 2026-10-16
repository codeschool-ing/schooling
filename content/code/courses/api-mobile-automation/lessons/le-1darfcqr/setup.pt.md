---
title: Preparando um projeto React Native com o Detox
version: 1
---

**O Detox são três coisas para instalar, e só uma delas é um pacote npm.** O pacote vai para o
`package.json` do projeto React Native. O arquivo de configuração diz qual app e qual aparelho. E o
próprio app Android precisa levar a biblioteca do Detox, o que é uma mudança nos arquivos do Gradle.
As duas primeiras rodaram na máquina de gravação e aparecem como rodaram. A terceira não pôde ser
compilada lá, e é descrita a partir do guia de instalação do próprio Detox.

## O projeto

A linha de comando do próprio React Native cria um projeto a partir do modelo dele. Em `~/boxoffice`:

```sh
npx --yes @react-native-community/cli@20.2.0 init TicketsRN --version 0.86.3 --directory tickets-rn --pm npm --skip-git-init
```

`TicketsRN` é o nome do app, que o React Native quer sem hífens. `--directory` o põe em `tickets-rn`,
ao lado do Tickets em Kotlin. `--version` fixa o React Native, pelo motivo que a lição 6 fixa tudo.
`--skip-git-init` deixa de fora um repositório Git próprio, já que o projeto mora dentro do
boxoffice. O comando baixa o modelo e instala os pacotes dele, várias centenas. Ele termina com
instruções para rodar o app no Android. As linhas de progresso dele são desenhadas com símbolos que
esta página não consegue mostrar, então a saída não é reproduzida. Foi isto que ele deixou:

```
ana@laptop:~/boxoffice$ ls tickets-rn
App.tsx    __tests__  babel.config.js  jest.config.js	package-lock.json
Gemfile    android    index.js	       metro.config.js	package.json
README.md  app.json   ios	       node_modules	tsconfig.json
ana@laptop:~/boxoffice$ ls tickets-rn/android/app/src/main/java/com/ticketsrn
MainActivity.kt  MainApplication.kt
```

`App.tsx` é o app, em TypeScript. `android` e `ios` são dois projetos nativos que o embrulham, o de
Android com um `MainActivity.kt` como o do Tickets. `__tests__` e `jest.config.js` são o teste
unitário do próprio modelo. Ele usa o Jest, o executor de testes sobre o qual o Detox também roda.

## O Detox

Dentro do projeto React Native, não do boxoffice, porque o Detox pertence a esse app. Entre em
`tickets-rn` antes, com `cd tickets-rn`. Todo comando daqui em diante roda lá:

```
ana@laptop:~/boxoffice/tickets-rn$ npm install --save-dev --save-exact detox@20.51.4
npm warn deprecated rimraf@2.4.5: Rimraf versions prior to v4 are no longer supported
npm warn deprecated glob@6.0.4: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me
npm warn deprecated glob@8.1.0: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me

added 99 packages, and audited 965 packages in 11s

180 packages are looking for funding
  run `npm fund` for details

60 vulnerabilities (12 moderate, 48 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

```
ana@laptop:~/boxoffice/tickets-rn$ npx detox --version
20.51.4
```

O `npx detox init` escreve os três arquivos com que um projeto Detox começa:

```
ana@laptop:~/boxoffice/tickets-rn$ npx detox init
Created a file at path: .detoxrc.js
Created a file at path: e2e/jest.config.js
Created a file at path: e2e/starter.test.js
```

O `e2e/jest.config.js` diz ao Jest onde estão as specs e que elas rodam pelo Detox. Elas rodam uma de
cada vez, com dois minutos cada, porque uma spec espera um emulador iniciar e um app ser instalado. O
`e2e/starter.test.js` é um exemplo para um app que não é este. Apague-o, já que a seção 05 escreve a
spec de verdade:

```
ana@laptop:~/boxoffice/tickets-rn$ rm e2e/starter.test.js
ana@laptop:~/boxoffice/tickets-rn$ ls e2e
jest.config.js	tickets.test.js
```

## A configuração

O `.detoxrc.js` diz como compilar o app, onde fica o APK compilado e em que aparelho rodá-lo. O
`init` escreve uma para cada combinação: iOS e Android, debug e release, emulador e celular. Fique com
o build de debug do Android no emulador da lição 14 e tire o resto. Substitua o arquivo; salve como
`tickets-rn/.detoxrc.js`:

```js
/** @type {Detox.DetoxConfig} */
module.exports = {
  testRunner: {
    args: {
      '$0': 'jest',
      config: 'e2e/jest.config.js'
    },
    jest: {
      setupTimeout: 120000
    }
  },
  apps: {
    'android.debug': {
      type: 'android.apk',
      binaryPath: 'android/app/build/outputs/apk/debug/app-debug.apk',
      build: 'cd android && ./gradlew assembleDebug assembleAndroidTest -DtestBuildType=debug',
      reversePorts: [
        8081
      ]
    }
  },
  devices: {
    emulator: {
      type: 'android.emulator',
      device: {
        avdName: 'Pixel_8_API_35'
      }
    }
  },
  configurations: {
    'android.emu.debug': {
      device: 'emulator',
      app: 'android.debug'
    }
  }
};
```

| parte | o que diz |
|---|---|
| `testRunner` | rodar as specs com o Jest, usando `e2e/jest.config.js` |
| `apps.android.debug` | o APK a instalar, e o `build`, o comando Gradle que o `npx detox build` roda para gerá-lo e o APK de teste ao lado |
| `reversePorts: [8081]` | `adb reverse` para o Metro, o servidor que manda a um build de debug o JavaScript dele, para o app no emulador alcançá-lo no seu computador |
| `devices.emulator` | o AVD a iniciar, pelo nome: `Pixel_8_API_35`, da lição 14 |
| `configurations` | o par que uma execução pede com `-c android.emu.debug` |

**Um build de debug carrega o JavaScript do Metro no seu computador.** O `npx react-native
start` precisa estar rodando em outro terminal enquanto testes de debug rodam. Um build de release
leva o JavaScript dentro do APK e não precisa do Metro, o que é um dos motivos de pipelines muitas
vezes testarem builds de release.

## O que o app Android precisa, descrito

A biblioteca do Detox para Android vem dentro do pacote npm, e o Gradle a encontra lá:

```
ana@laptop:~/boxoffice/tickets-rn$ ls node_modules/detox/Detox-android
com
```

O guia de instalação do Detox lista as mudanças de que o projeto Android precisa para o app levar essa
biblioteca e poder ser conduzido por ela. Nenhuma delas pôde ser compilada na máquina de gravação,
então elas são nomeadas aqui e não mostradas. Siga o guia da versão que você instalou, porque esses
arquivos são onde o modelo do React Native mais muda entre versões:

1. em `android/build.gradle`, a pasta acima como repositório Maven, para o Gradle achar a
   biblioteca;
2. em `android/app/build.gradle`, dentro de `defaultConfig`, o executor de instrumentação da lição 16
   e o tipo de build contra o qual o Detox testa, e a biblioteca como `androidTestImplementation`;
3. uma pequena classe de teste em `android/app/src/androidTest`, dada no guia, que inicia o Detox
   dentro da instrumentação, o mesmo mecanismo que o Espresso usou na lição 16;
4. uma configuração de segurança de rede que permita HTTP puro para `10.0.2.2` e `localhost`, como a
   que o Tickets tem desde a lição 14. O app fala com o Metro e com o boxoffice em HTTP puro.

Depois, o `npx detox build -c android.emu.debug` roda o comando `build` da configuração, e grava os
dois APKs onde o `binaryPath` diz.
