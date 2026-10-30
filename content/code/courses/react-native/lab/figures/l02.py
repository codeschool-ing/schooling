"""Lesson 2: the config plugin, annotated, and the prebuild figure."""
from fig import Fig

EXAMPLES = {
 "config-plugins": [{"language": "javascript", "file": "plugins/with-week-start.js", "parts": [
  ('// plugins/with-week-start.js: write the planner\'s first day of the week into both native projects.\nconst { withAndroidManifest, withInfoPlist, AndroidConfig } = require("expo/config-plugins");\n',
   "The helpers come from `expo/config-plugins`, which the `expo` package already contains. A plugin runs in Node.js during prebuild, so it is CommonJS and `require`, not the app's TypeScript.",
   "Os helpers vêm de `expo/config-plugins`, que o pacote `expo` já contém. Um plugin roda no Node.js durante o prebuild, então é CommonJS com `require`, e não o TypeScript do app."),
  ('module.exports = function withWeekStart(config, { day = "monday" } = {}) {',
   "A plugin takes the configuration and its own options, from the pair in `app.json`, and returns the configuration. The default makes the options optional.",
   "Um plugin recebe a configuração e as próprias opções, vindas do par no `app.json`, e devolve a configuração. O valor padrão torna as opções opcionais."),
  ('  config = withAndroidManifest(config, (c) => {\n    const app = AndroidConfig.Manifest.getMainApplicationOrThrow(c.modResults);\n    AndroidConfig.Manifest.addMetaDataItemToMainApplication(app, "planner.WEEK_STARTS", day);\n    return c;\n  });',
   "The Android half. `withAndroidManifest` hands over the manifest already parsed, as `c.modResults`; the two `AndroidConfig` functions find the `<application>` element and add a `<meta-data>` to it, replacing an earlier one of the same name.",
   "A metade Android. O `withAndroidManifest` entrega o manifesto já interpretado, em `c.modResults`; as duas funções de `AndroidConfig` encontram o elemento `<application>` e acrescentam um `<meta-data>` a ele, substituindo um anterior de mesmo nome."),
  ('  return withInfoPlist(config, (c) => {\n    c.modResults.PlannerWeekStarts = day;\n    return c;\n  });\n};',
   "The iOS half. `Info.plist` arrives as a plain object, so a key is an assignment. Every callback returns what it was given, changed: that is how the next plugin receives it.",
   "A metade iOS. O `Info.plist` chega como um objeto comum, então uma chave é uma atribuição. Todo callback devolve o que recebeu, alterado: é assim que o próximo plugin o recebe."),
 ]}],
}

T = {
 "en": dict(aria="Continuous Native Generation. app.json, the installed libraries and your config plugins are committed to git. npx expo prebuild reads them and writes the android and ios folders, which git ignores. Editing a generated folder by hand is lost at the next prebuild --clean.",
   src="committed to git", a=["app.json"], b=["installed libraries", "and their plugins"], c=["your plugins"],
   cmd="npx expo prebuild", out="generated, ignored by git", an=["android/"], io=["ios/"],
   lost="an edit made here by hand is gone after prebuild --clean", cap="The description is source; the native projects are output, written again whenever the description changes."),
 "pt": dict(aria="Continuous Native Generation. O app.json, as bibliotecas instaladas e os seus config plugins vão para o git. O npx expo prebuild os lê e escreve as pastas android e ios, que o git ignora. Uma edição feita à mão numa pasta gerada se perde no próximo prebuild --clean.",
   src="vai para o git", a=["app.json"], b=["bibliotecas instaladas", "e os plugins delas"], c=["os seus plugins"],
   cmd="npx expo prebuild", out="gerado, ignorado pelo git", an=["android/"], io=["ios/"],
   lost="uma edição feita aqui à mão some depois do prebuild --clean", cap="A descrição é fonte; os projetos nativos são saída, escritos de novo sempre que a descrição muda."),
}


def figures(lang):
    t = T[lang]
    f = Fig("l02-cng", 720, 230, t["aria"])
    f.text(110, 22, t["src"], size=10, fill="phosphor", bold=True)
    f.box(30, 36, 160, 34, t["a"], mono=True, size=9.5)
    f.box(30, 80, 160, 44, t["b"], size=9.5)
    f.box(30, 134, 160, 34, t["c"], size=9.5)
    f.box(260, 80, 180, 44, [t["cmd"]], stroke="amber", mono=True, size=9.5)
    for y in (53, 102, 151):
        f.arrow([(190, y), (260, 102)])
    f.text(600, 22, t["out"], size=10, fill="paper-dim", bold=True)
    f.box(520, 50, 160, 40, t["an"], mono=True, size=9.5, dashed=True)
    f.box(520, 114, 160, 40, t["io"], mono=True, size=9.5, dashed=True)
    f.arrow([(440, 95), (520, 70)])
    f.arrow([(440, 110), (520, 134)])
    f.text(560, 196, t["lost"], size=9, fill="amber", italic=True)
    return {"l02-cng": f.json(caption=t["cap"])}
