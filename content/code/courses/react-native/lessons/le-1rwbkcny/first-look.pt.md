---
title: Um primeiro projeto, e o que vai de fato no app
version: 1
---

**O jeito mais rápido de acreditar nas últimas três seções é construir algo e olhar dentro.** Esta
seção cria um projeto descartável, pede ao Expo para produzir o que iria dentro de um app Android, e
lê o arquivo que ele escreve. A aula 3 começa o projeto de verdade; este vai para o lixo depois.

## As ferramentas respondem

Primeiro, as três ferramentas da seção anterior. Abra um terminal e pergunte a versão de cada uma:

```
ana@dev:~$ node --version
v22.22.0
ana@dev:~$ npm --version
10.9.4
ana@dev:~$ git --version
git version 2.43.0
```

Qualquer `git` dos últimos anos serve. O Node.js e o npm devem estar exatamente nessas versões,
porque toda transcrição deste curso foi gravada com elas; se `node` não for encontrado, a seção
anterior diz de onde ele deveria ter vindo.

## Um projeto a partir do modelo do Expo

O `create-expo-app` escreve um projeto novo a partir de um modelo. O `npx` o baixa e o roda sem
instalá-lo em lugar nenhum de forma permanente. Duas coisas no comando o impedem de se afastar deste
curso: `@5.0.0` fixa a versão da ferramenta, e `@sdk-58` pede o modelo do SDK 58 do Expo, a versão que
este curso usa, em vez do que for mais novo no dia em que você digitar.

```
ana@dev:~$ npx create-expo-app@5.0.0 hello --template blank-typescript@sdk-58 --no-install > /dev/null 2>&1
ana@dev:~$ cd hello
ana@dev:~/hello$ ls
AGENTS.md
App.tsx
LICENSE
app.json
assets
index.ts
package.json
tsconfig.json
ana@dev:~/hello$ npm install

added 460 packages, and audited 461 packages in 31s

8 vulnerabilities (5 low, 3 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

O `--no-install` o impediu de instalar na hora, para que a instalação fosse um passo à parte. **O
`App.tsx` é o app inteiro, por enquanto**, e o resto são as configurações dele; a aula 3 passa por
cada arquivo. O relatório que o `create-expo-app` imprime foi para `/dev/null` porque ele desenha um
indicador animado que esta página não consegue mostrar. O `ls` mostra o que ele escreveu.

## O que um app Android carregaria

`npx expo export` roda o mesmo bundler que um build de verdade roda, chamado **Metro**, e escreve o que
produz em `dist/`. Com `--platform android`, ele produz exatamente o arquivo que um build Android
colocaria dentro do app:

```
ana@dev:~/hello$ npx expo export --platform android > /dev/null 2>&1
ana@dev:~/hello$ find dist -type f
dist/_expo/static/js/android/index-1f4759e666c47e0ac79e3ec24a99b026.hbc
dist/metadata.json
ana@dev:~/hello$ file dist/_expo/static/js/android/*.hbc
dist/_expo/static/js/android/index-1f4759e666c47e0ac79e3ec24a99b026.hbc: Hermes JavaScript bytecode, version 99
ana@dev:~/hello$ grep -c "Open up App.tsx" dist/_expo/static/js/android/*.hbc
1
```

**São dois arquivos, e só um importa aqui.** O `metadata.json` descreve a exportação, e a aula 21 o usa.
O arquivo `.hbc` é o seu app: todo componente, toda linha de React e de React Native, e toda
biblioteca, reunidos num arquivo só e compilados. O `file` o reconhece, e o nome que ele dá é o ponto
desta aula: **Hermes JavaScript bytecode**. Nem código de máquina ARM, nem Kotlin: bytecode para o
motor que o app carrega.

O último comando procurou no bytecode a frase que o `App.tsx` do modelo mostra, e a encontrou uma vez.
As strings sobrevivem à compilação como são; a lógica em volta delas virou instruções para o Hermes.
Foi para isso que o Hermes foi feito: o app carrega um bytecode compilado uma vez, no computador que o
construiu, em vez de interpretar texto JavaScript no celular a cada abertura.

## Jogue fora

```sh
cd ~ && rm -rf hello
```

Nada mais no seu computador mudou: o `npx` guarda os downloads no cache do npm, e o projeto foi a única
coisa escrita fora dele.
