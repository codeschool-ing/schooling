---
title: Navegação, como arquivos
version: 1
---

**Um app de celular passa de uma tela a outra, e o caminho de volta faz parte da plataforma**: o gesto
de voltar no Android e no iOS, a barra de título com a seta de voltar, a tela deslizando de lado. O
**Expo Router** dá isso a um app React Native com uma regra: **cada arquivo da pasta `app/` é uma tela, e
o caminho dele é o endereço dela**.

| arquivo | endereço | tela |
|---|---|---|
| `app/_layout.tsx` | nenhum | não é uma tela: o que envolve todas as telas, aqui uma pilha |
| `app/index.tsx` | `/` | a lista de cursos |
| `app/course/[id].tsx` | `/course/statistics`, `/course/guitar`, … | um curso; `[id]` é a parte do endereço que varia |

Uma **pilha** é a navegação que todo app de celular tem: uma tela nova vai por cima, voltar a tira. Num
celular, o Expo Router a constrói com a navegação da própria plataforma, então a barra de título, a
animação e o gesto de voltar são do sistema. Num navegador, cada tela é uma página com endereço próprio,
e o botão de voltar do navegador funciona.

Instale-o, com os quatro pacotes de que ele precisa, e deixe o Expo escolher as versões deles para o SDK
58:

```
ana@dev:~/planner-native$ npx expo install expo-router react-native-screens react-native-safe-area-context expo-linking expo-constants
Unable to fetch compatibility data from React Native Directory. Skipping check.
Dependency validation is unreliable in offline-mode
› Installing 5 SDK 58.0.0 compatible native modules using npm
> npm install

added 50 packages, and audited 536 packages in 5s

5 high severity vulnerabilities

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
› Added config plugin: expo-router
```

**As duas primeiras linhas são da máquina de gravação**, não suas: ela não alcançava os servidores do
Expo, então o Expo rodou offline, sem a conferência dele de quais bibliotecas funcionam juntas. Depois o
npm instalou os cinco pacotes nas versões que o SDK 58 lista. A última linha é o Expo editando o
`app.json` por você: um **config plugin** são as instruções de um pacote para os projetos nativos,
aplicadas quando eles são gerados, que a aula 9 encontra de novo. Depois fixe as cinco versões que ele
escolheu, como a aula 7 fez, diga ao projeto que o ponto de entrada agora é o router, não o `index.ts`,
e tire os dois arquivos que a aula 7 tinha no lugar:

```
ana@dev:~/planner-native$ npm install -E expo-router@58.0.26 react-native-screens@4.30.0 react-native-safe-area-context@5.10.1 expo-linking@58.0.14 expo-constants@58.0.13 > /dev/null
ana@dev:~/planner-native$ npm pkg set main=expo-router/entry
ana@dev:~/planner-native$ git rm -q App.tsx index.ts
ana@dev:~/planner-native$ grep -E "\"main\"|expo-router" package.json
  "main": "expo-router/entry",
    "expo-router": "58.0.26",
```

Passar de uma tela a outra é uma chamada, `router.push("/course/statistics")`, e a tela do outro lado lê
a parte variável do endereço com `useLocalSearchParams()`. **O endereço é a única coisa passada entre as
telas**, e é um texto. O plano, de que toda tela precisa, mora acima de todas elas, no layout, que é a
próxima seção.
