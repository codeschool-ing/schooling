---
title: O que é uma atualização
version: 1
---

**Um app React Native são dois programas**: a casca nativa, Kotlin e Swift e o código nativo de cada
biblioteca, compilada no build que a loja entregou; e o bundle JavaScript, que a casca carrega e roda. A
loja precisa entregar o primeiro. **O segundo é um arquivo**, e um arquivo pode ser trocado a partir de um
servidor sem uma loja no meio. Isso é uma atualização over-the-air.

O `expo-updates` é a biblioteca que faz isso: na abertura, ele pergunta a um servidor de atualizações se há
um bundle mais novo para este build, o baixa, e o roda, na abertura seguinte ou na hora, conforme
configurado. Instale-o:

```
ana@dev:~/planner$ npx expo install expo-updates
Unable to fetch compatibility data from React Native Directory. Skipping check.
Dependency validation is unreliable in offline-mode
› Installing 1 SDK 58.0.0 compatible native module using npm
> npm install

added 4 packages, and audited 1133 packages in 7s

15 vulnerabilities (12 low, 3 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

**O que ele baixa é exatamente o que o `npx expo export` escreve.** Exporte o planner para Android e olhe a
descrição da exportação, o `metadata.json`:

```
ana@dev:~/planner$ npx expo export --platform android > /dev/null 2>&1
ana@dev:~/planner$ node -p "const m = require(\"./dist/metadata.json\").fileMetadata.android; [m.bundle, m.assets.length + \" assets\"].join(\"\\n\")"
_expo/static/js/android/index-b2458e330c5f77ad4ff827060629eb78.hbc
18 assets
ana@dev:~/planner$ du -sh dist
4.2M	dist
```

**Uma atualização é um bundle do Hermes e as imagens que ele usa**, alguns megabytes ao todo, com nomes
tirados do hash do conteúdo, para um celular baixar só os arquivos que ainda não tem. Publicar uma
atualização é enviar esses arquivos com uma descrição de para quais builds eles servem; essa descrição é o
assunto da seção depois da próxima.

Repare no que não está lá: nada de Kotlin, nada de Swift, nenhum `AndroidManifest.xml`, nenhum
`Info.plist`, nenhuma permissão, nenhum ícone. **Nada nativo consegue chegar por aqui**, porque o lado nativo
é compilado no build, e o build é o que a loja assinou e entregou.
