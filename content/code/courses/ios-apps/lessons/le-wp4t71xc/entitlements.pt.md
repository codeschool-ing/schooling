---
title: Entitlements, o que o app reivindica e o que o perfil permite
version: 1
---

**Um entitlement é uma permissão escrita na assinatura do app: notificações push, iCloud, um keychain
compartilhado, Sign in with Apple.** O iOS os lê do app assinado, não do `Info.plist`, e é por isso
que um app não se concede um editando um arquivo depois de assinado. Eles vêm de dois lugares que têm
de concordar. O **app** diz quais quer, num arquivo que o Xcode cria quando você acrescenta uma
capability na aba *Signing & Capabilities* do target, `Planner.entitlements`. O **perfil de
provisionamento** da seção 06 diz quais o App ID pode ter. A assinatura copia os entitlements do app
para dentro dela, e o iOS se recusa a instalar um app que reivindique um que o perfil não permite.

Os dois arquivos desta seção são property lists, então a concordância pode ser conferida em qualquer
lugar. A metade do Xcode não foi executada: ela foi escrita a partir da documentação da Apple sobre
entitlements e sobre capabilities no Xcode, lida em 30 de outubro de 2026.

## Os dois arquivos

O planner tem uma capability, as notificações push da aula 17, e por isso um entitlement. Em
desenvolvimento ele diz `development`, que aponta o app para o serviço de push de teste da Apple.
Salve-o como `Planner.entitlements` em `~/entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- Planner.entitlements -->
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>aps-environment</key>
    <string>development</string>
</dict>
</plist>
```

Um perfil de desenvolvimento carrega o seu próprio dicionário `Entitlements`: aquilo com que o App ID
foi registrado, mais alguns que o Xcode sempre acrescenta, como o `get-task-allow`, que deixa um
depurador se conectar. **Este foi escrito pelo curso como exemplo desse dicionário**, com o team
identifier da aula 1, seção 07; ele não foi copiado de um perfil de verdade, já que nenhum foi feito
para este curso. Salve-o como `allowed.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- allowed.plist -->
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>application-identifier</key>
    <string>ABCDE12345.com.example.planner</string>
    <key>com.apple.developer.team-identifier</key>
    <string>ABCDE12345</string>
    <key>aps-environment</key>
    <string>development</string>
    <key>get-task-allow</key>
    <true/>
</dict>
</plist>
```

## A conferência

Cada chave que o app reivindica tem de estar no perfil com o mesmo valor. Salve isto como
`check-entitlements.swift`:

```schooling-example
{"language": "swift", "file": "check-entitlements.swift", "parts": [{"code": "// check-entitlements.swift: does the profile allow everything the app claims?\nimport Foundation\n\nfunc plist(_ path: String) -> [String: Any] {\n    let data = try! Data(contentsOf: URL(fileURLWithPath: path))\n    return try! PropertyListSerialization.propertyList(from: data, format: nil) as! [String: Any]\n}\n\nlet claimed = plist(CommandLine.arguments[1])\nlet allowed = plist(CommandLine.arguments[2])\n", "note": "O mesmo leitor do verificador da aula 18. O primeiro argumento são os entitlements do app, o segundo o que o perfil permite."}, {"code": "var refused = 0\nfor key in claimed.keys.sorted() {\n    let want = \"\\(claimed[key]!)\"\n    guard let have = allowed[key] else {\n        print(\"refused  \\(key): the profile does not have it\")\n        refused += 1\n        continue\n    }\n    if \"\\(have)\" == want {\n        print(\"ok       \\(key) = \\(want)\")\n    } else {\n        print(\"refused  \\(key): the app wants \\(want), the profile says \\(have)\")\n        refused += 1\n    }\n}\nexit(refused == 0 ? 0 : 1)\n", "note": "Duas formas de falhar: uma chave que o perfil nem tem, e uma chave com outro valor, como `production` contra `development`. Comparar os valores como texto basta para strings e booleanos, que é o que esses arquivos guardam."}]}
```

No planner como está, e depois numa cópia que também reivindica o HealthKit, como alguém faria depois
de copiar uma capability de outro projeto:

```
ana@vm:~/entitlements$ swift check-entitlements.swift Planner.entitlements allowed.plist; echo $?
ok       aps-environment = development
0
ana@vm:~/entitlements$ sed 's|<key>aps-environment</key>|<key>com.apple.developer.healthkit</key><true/><key>aps-environment</key>|' Planner.entitlements > More.entitlements
ana@vm:~/entitlements$ swift check-entitlements.swift More.entitlements allowed.plist; echo $?
ok       aps-environment = development
refused  com.apple.developer.healthkit: the profile does not have it
1
```

**A segunda execução é a mensagem que uma instalação no aparelho teria dado, só que antes.** Num
telefone ela chega como uma instalação que falha reclamando de entitlements; aqui ela cita a chave e
diz que o perfil não a tem. A correção nunca é editar o perfil: acrescente a capability ao App ID na
conta de desenvolvedor, ou deixe o Xcode fazer isso (seção 08), e baixe o perfil novo que volta.
