---
title: O manifesto de privacidade, e um verificador para os dois arquivos
version: 1
---

**O `Info.plist` diz por que o app pede; o manifesto de privacidade diz o que o app faz sem pedir.**
O manifesto é um arquivo chamado `PrivacyInfo.xcprivacy`, uma property list como o `Info.plist`, e a
documentação da Apple sobre arquivos de manifesto de privacidade, lida em 30 de outubro de 2026, diz
que ele registra "the types of data collected by your app" e "the required reasons APIs your app or
third-party SDK uses". O Xcode cria um com *File*, *New File*, *App Privacy*. Nada do Xcode foi
executado para esta seção; o verificador no fim dela foi.

## APIs de motivo obrigatório

Algumas APIs comuns podem ser mal usadas para distinguir um aparelho de outro, o que a Apple chama
de **fingerprinting**: o espaço livre em disco, a hora em que o sistema ligou, as datas dos
arquivos, os teclados instalados e o `UserDefaults`. Um app pode usá-las, e tem de dizer por quê,
escolhendo um código de motivo da lista da Apple para cada categoria. A página da Apple *Describing
use of required reason API* diz a consequência: "Starting May 1, 2024, apps that don't describe
their use of required reason API in their privacy manifest file aren't accepted by App Store
Connect."

O planner lembra qual curso estava aberto por último no `UserDefaults`, então declara essa categoria
com **`CA92.1`**, que a lista da Apple descreve como ler e escrever "information that is only
accessible to the app itself". Ele não coleta dados sobre a pessoa e não rastreia ninguém, então as
outras três listas ficam vazias. Salve-o como `PrivacyInfo.xcprivacy` em `~/privacy`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- PrivacyInfo.xcprivacy -->
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

## Um verificador para os dois arquivos

O Foundation lê os dois arquivos no Linux como leu o `Info.plist` na aula 1, então a concordância
entre o que o código usa e o que os dois arquivos dizem pode ser conferida em qualquer lugar. Salve
isto como `check-privacy.swift` em `~/privacy`:

```schooling-example
{"language": "swift", "file": "check-privacy.swift", "parts": [{"code": "// check-privacy.swift: does the app say why, for everything its code uses?\nimport Foundation\n\nfunc plist(_ path: String) -> [String: Any] {\n    let data = try! Data(contentsOf: URL(fileURLWithPath: path))\n    return try! PropertyListSerialization.propertyList(from: data, format: nil) as! [String: Any]\n}\n\nlet info = plist(CommandLine.arguments[1])\nlet manifest = plist(CommandLine.arguments[2])\nlet uses = CommandLine.arguments.dropFirst(3).sorted()\n\n", "note": "Os dois arquivos são property lists, então uma função lê qualquer um. O `try!` e o `as!` param o programa diante de um arquivo que falta ou que não é um dicionário, o que para um verificador rodado à mão é o tipo certo de barulho. O que o código usa vem como palavras depois dos dois caminhos."}, {"code": "let usageKeys = [\n    \"camera\": \"NSCameraUsageDescription\",\n    \"location\": \"NSLocationWhenInUseUsageDescription\",\n    \"photos-add\": \"NSPhotoLibraryAddUsageDescription\",\n    \"tracking\": \"NSUserTrackingUsageDescription\",\n]\nlet reasonAPIs = [\n    \"userdefaults\": \"NSPrivacyAccessedAPICategoryUserDefaults\",\n    \"file-timestamps\": \"NSPrivacyAccessedAPICategoryFileTimestamp\",\n]\n", "note": "Duas tabelas: o que cada tipo de acesso precisa no `Info.plist`, e o que cada API de motivo obrigatório precisa no manifesto. Elas são curtas de propósito; uma lista real está na documentação da Apple, e uma palavra que este verificador não conhece é relatada em vez de aceita."}, {"code": "var problems = 0\nfunc report(_ line: String, ok: Bool) {\n    print(ok ? \"ok       \\(line)\" : \"MISSING  \\(line)\")\n    if !ok { problems += 1 }\n}\n\n", "note": "Toda linha que ele imprime começa com `ok` ou `MISSING`, e todo `MISSING` é contado."}, {"code": "for use in uses {\n    if let key = usageKeys[use] {\n        let text = (info[key] as? String ?? \"\").trimmingCharacters(in: .whitespaces)\n        report(\"\\(use): \\(key) \\(text.isEmpty ? \"is not in Info.plist\" : \"\\\"\\(text)\\\"\")\", ok: !text.isEmpty)\n    } else if let category = reasonAPIs[use] {\n        let entries = manifest[\"NSPrivacyAccessedAPITypes\"] as? [[String: Any]] ?? []\n        let entry = entries.first { $0[\"NSPrivacyAccessedAPIType\"] as? String == category }\n        let reasons = entry?[\"NSPrivacyAccessedAPITypeReasons\"] as? [String] ?? []\n        report(\"\\(use): \\(category) \\(reasons.isEmpty ? \"has no reason\" : reasons.joined(separator: \", \"))\", ok: !reasons.isEmpty)\n    } else {\n        report(\"\\(use): this checker does not know it\", ok: false)\n    }\n}\n\n", "note": "Para uma chave de uso, a string tem de estar lá e não pode ser branca. Para uma API, o manifesto precisa de uma entrada para a categoria dela com pelo menos um motivo. Os códigos de motivo são da Apple, e o verificador não julga se o código dado é o certo; essa parte é sua."}, {"code": "let tracks = manifest[\"NSPrivacyTracking\"] as? Bool ?? false\nreport(\"NSPrivacyTracking is \\(tracks)\", ok: tracks == uses.contains(\"tracking\"))\nprint(problems == 0 ? \"nothing missing\" : \"\\(problems) missing\")\nexit(problems == 0 ? 0 : 1)\n", "note": "A última regra junta os dois arquivos: o `NSPrivacyTracking` do manifesto tem de bater com o código rastrear ou não. O código de saída é 1 quando falta algo, então um script de build poderia parar nele."}]}
```

Rode-o com o planner como está: ele tira fotos com a câmera e guarda o último curso no
`UserDefaults`. Depois no `Info.plist` da aula 1, que é de antes da câmera, salvo aqui como
`Lesson1.plist`; e depois afirmando que o código também rastreia:

```
ana@vm:~/privacy$ swift check-privacy.swift Info.plist PrivacyInfo.xcprivacy camera userdefaults; echo $?
ok       camera: NSCameraUsageDescription "Planner uses the camera to photograph your notes and attach them to a study session."
ok       userdefaults: NSPrivacyAccessedAPICategoryUserDefaults CA92.1
ok       NSPrivacyTracking is false
nothing missing
0
ana@vm:~/privacy$ cp ~/plist/Info.plist Lesson1.plist
ana@vm:~/privacy$ swift check-privacy.swift Lesson1.plist PrivacyInfo.xcprivacy camera userdefaults; echo $?
MISSING  camera: NSCameraUsageDescription is not in Info.plist
ok       userdefaults: NSPrivacyAccessedAPICategoryUserDefaults CA92.1
ok       NSPrivacyTracking is false
1 missing
1
ana@vm:~/privacy$ swift check-privacy.swift Info.plist PrivacyInfo.xcprivacy camera userdefaults tracking; echo $?
ok       camera: NSCameraUsageDescription "Planner uses the camera to photograph your notes and attach them to a study session."
MISSING  tracking: NSUserTrackingUsageDescription is not in Info.plist
ok       userdefaults: NSPrivacyAccessedAPICategoryUserDefaults CA92.1
MISSING  NSPrivacyTracking is false
2 missing
1
```

**A segunda execução é a que teria publicado um travamento.** O arquivo da aula 1 não tinha a chave
da câmera, e nada na compilação do app teria avisado; o primeiro toque no botão da câmera teria. A
terceira execução falha duas vezes por uma mudança só, porque rastrear precisa da frase de uso e de
um manifesto que o admita.
