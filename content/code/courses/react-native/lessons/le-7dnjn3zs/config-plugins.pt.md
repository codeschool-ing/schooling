---
title: "Config plugins: mudanças nativas escritas como código"
version: 1
---

**Um config plugin é uma função JavaScript que o prebuild roda enquanto escreve os projetos nativos.**
Ela recebe a configuração e um acesso a cada arquivo nativo sendo escrito, o manifesto Android, o
`Info.plist`, os arquivos do Gradle, e os altera. As bibliotecas trazem plugins para a própria
configuração; você escreve um quando o seu app precisa de uma mudança nativa para a qual o `app.json`
não tem campo.

O planner vai precisar de um pequeno fato nas duas plataformas: **em que dia a semana dele começa**. Um
widget ou uma notificação nativa escrita em Kotlin ou Swift poderia lê-lo da configuração do próprio
app. No Android, isso é uma entrada `<meta-data>` no manifesto; no iOS, uma chave no `Info.plist`. Eis
um plugin que escreve as duas. Salve-o no projeto como `plugins/with-week-start.js`:

```schooling-example
{"language": "javascript", "file": "plugins/with-week-start.js", "parts": [{"code": "// plugins/with-week-start.js: write the planner's first day of the week into both native projects.\nconst { withAndroidManifest, withInfoPlist, AndroidConfig } = require(\"expo/config-plugins\");\n", "note": "Os helpers vêm de `expo/config-plugins`, que o pacote `expo` já contém. Um plugin roda no Node.js durante o prebuild, então é CommonJS com `require`, e não o TypeScript do app."}, {"code": "module.exports = function withWeekStart(config, { day = \"monday\" } = {}) {", "note": "Um plugin recebe a configuração e as próprias opções, vindas do par no `app.json`, e devolve a configuração. O valor padrão torna as opções opcionais."}, {"code": "  config = withAndroidManifest(config, (c) => {\n    const app = AndroidConfig.Manifest.getMainApplicationOrThrow(c.modResults);\n    AndroidConfig.Manifest.addMetaDataItemToMainApplication(app, \"planner.WEEK_STARTS\", day);\n    return c;\n  });", "note": "A metade Android. O `withAndroidManifest` entrega o manifesto já interpretado, em `c.modResults`; as duas funções de `AndroidConfig` encontram o elemento `<application>` e acrescentam um `<meta-data>` a ele, substituindo um anterior de mesmo nome."}, {"code": "  return withInfoPlist(config, (c) => {\n    c.modResults.PlannerWeekStarts = day;\n    return c;\n  });\n};", "note": "A metade iOS. O `Info.plist` chega como um objeto comum, então uma chave é uma atribuição. Todo callback devolve o que recebeu, alterado: é assim que o próximo plugin o recebe."}]}
```

## Usando o plugin

Um plugin é citado no `app.json`, numa lista chamada `"plugins"` dentro de `"expo"`. Cada entrada é o
caminho ou o nome de pacote do plugin, ou um par com o nome e as opções dele. Acrescente isto no fim do
objeto `"expo"`:

```json
"plugins": [["./plugins/with-week-start.js", { "day": "monday" }]]
```

Depois gere os projetos de novo e procure o que o plugin escreveu:

```
ana@dev:~/try-expo$ grep -A7 "\"plugins\"" app.json
    "plugins": [
      [
        "./plugins/with-week-start.js",
        {
          "day": "monday"
        }
      ]
    ]
ana@dev:~/try-expo$ npx expo prebuild --clean --no-install > /dev/null 2>&1
ana@dev:~/try-expo$ grep WEEK android/app/src/main/AndroidManifest.xml
    <meta-data android:name="planner.WEEK_STARTS" android:value="monday"/>
ana@dev:~/try-expo$ grep -A1 PlannerWeekStarts ios/tryexpo/Info.plist
    <key>PlannerWeekStarts</key>
    <string>monday</string>
```

**Os dois arquivos nativos trazem o valor, e nenhum foi editado à mão.** Apague as pastas, troque
`"monday"` por `"sunday"`, rode o prebuild, e os dois mudam juntos. Essa é a garantia que o projeto bare
não conseguia dar: as duas plataformas não podem discordar, porque uma função escreve as duas.

## Mods, e por que têm ordem

Cada helper `with…` registra um **mod**, uma mudança num arquivo nativo. O prebuild junta os mods de
todos os plugins e os aplica arquivo por arquivo, na ordem em que os plugins aparecem na lista, então
dois plugins que mexem no manifesto veem as mudanças um do outro em vez de se sobrescreverem. Um plugin
que edita texto com uma expressão regular em vez de usar o arquivo interpretado é do tipo frágil:
funciona até o modelo mudar a linha que ele casava. **Prefira os helpers**, que trabalham sobre o XML e
o plist interpretados, e as funções de `AndroidConfig` e `IOSConfig`, que já sabem onde vai uma entrada
meta-data ou uma permissão.

## Onde as bibliotecas os usam

Você vai ver plugins com mais frequência sem escrever nenhum. `npx expo install expo-camera` acrescenta
a biblioteca de câmera, e o plugin dela acrescenta a permissão de câmera ao manifesto e o texto que o
iOS mostra ao pedi-la. Na aula 13 você define esse texto pelas opções do plugin, e o plugin o coloca no
`Info.plist` e nas strings do Android, onde cada plataforma o espera.

Uma biblioteca com código nativo e sem plugin é o caso a observar. Ela funciona num projeto bare, onde
você cola as linhas de configuração à mão, e num projeto Expo você escreve o plugin que as cola. Isso
raramente passa das vinte linhas acima.
