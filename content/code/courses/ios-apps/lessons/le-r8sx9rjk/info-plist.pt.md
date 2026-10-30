---
title: Info.plist, a descrição que o app faz de si mesmo
version: 1
---

**Todo app carrega um arquivo que diz ao iOS o que ele é antes de uma linha do seu código rodar.** Ele se chama `Info.plist` e fica no topo do bundle do app. O sistema o lê para saber o identificador do
app, a versão, o nome embaixo do ícone, quais orientações ele aceita, qual iOS ele exige e, a partir
da aula 18, a frase que ele mostra quando pede a câmera.

Uma crença comum é que o `Info.plist` é um arquivo que você edita à mão. Num projeto feito por um
Xcode atual, quase sempre ele nem é um arquivo. A documentação da Apple para as configurações de build
do `Info.plist` descreve o arranjo: a maior parte das chaves são **configurações de build** do target,
mostradas na aba *Info* dele, e o Xcode escreve o arquivo de verdade dentro do app quando compila.
Você só acrescenta um arquivo seu para chaves que nenhuma configuração cobre, e o Xcode junta os dois.
De um jeito ou de outro, o que chega ao telefone é um arquivo só, e é esse arquivo que esta seção lê.

## Como o arquivo é

Uma property list é uma árvore de dicionários, arrays, strings, números, booleanos e datas, guardada
como XML ou numa forma binária. Esta é a do planner, como sairia de um build. Salve-a como
`Info.plist` num diretório próprio, `~/plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- Info.plist -->
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>Planner</string>
    <key>CFBundleExecutable</key>
    <string>Planner</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.planner</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>MinimumOSVersion</key>
    <string>17.0</string>
    <key>UILaunchScreen</key>
    <dict/>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
</dict>
</plist>
```

As chaves que começam com `CF` vêm do Core Foundation e são compartilhadas com o macOS; as que começam
com `UI` e `LS` tratam da interface e da abertura do app. **Duas delas são versões, e não são a mesma
versão.** `CFBundleShortVersionString` é a que as pessoas veem na App Store, `1.0`. `CFBundleVersion`
é o número do build, e todo build enviado para a mesma versão precisa de um maior, que é onde a aula
22 o mostra recusando.

## Lendo o arquivo com um programa

O Foundation lê property lists em toda plataforma onde o Swift roda, então algumas linhas de Swift
leem este arquivo no Linux e conferem as duas regras que a documentação da Apple dá para os campos
que mais dão errado: o bundle identifier só pode ter letras, dígitos, hífens e pontos, e a versão
curta tem até três inteiros separados por pontos. Salve isto como `check.swift` em `~/plist`:

```schooling-example
{"language": "swift", "file": "check.swift", "parts": [{"code": "// check.swift: read an Info.plist and check the fields that most often go wrong\nimport Foundation\n\nlet path = CommandLine.arguments[1]\nlet data = try Data(contentsOf: URL(fileURLWithPath: path))\nlet plist = try PropertyListSerialization.propertyList(from: data, format: nil)\nguard let info = plist as? [String: Any] else { fatalError(\"\\(path) is not a dictionary\") }\n", "note": "O `PropertyListSerialization` lê property lists em XML e em binário do mesmo jeito e devolve `Any`, porque uma property list pode guardar seis tipos de valor. O cast para dicionário é onde um arquivo que não é um `Info.plist` para."}, {"code": "func text(_ key: String) -> String {\n    info[key] as? String ?? \"\"\n}\n\nlet id = text(\"CFBundleIdentifier\")\nlet idOK = !id.isEmpty && id.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == \"-\" || $0 == \".\") }\nprint(\"identifier  \\(id)  \\(idOK ? \"ok\" : \"only A-Z a-z 0-9 - . allowed\")\")\n", "note": "A regra do identificador, letra por letra. O `isASCII` importa: só o `isLetter` aceitaria `é`, e a regra não aceita."}, {"code": "let short = text(\"CFBundleShortVersionString\")\nlet parts = short.split(separator: \".\", omittingEmptySubsequences: false)\nlet shortOK = (1...3).contains(parts.count) && parts.allSatisfy { !$0.isEmpty && $0.allSatisfy(\\.isNumber) }\nprint(\"version     \\(short)  \\(shortOK ? \"ok\" : \"must be up to three integers, like 1.2.3\")\")\nprint(\"build       \\(text(\"CFBundleVersion\"))\")\nprint(\"needs iOS   \\(text(\"MinimumOSVersion\"))\")\n", "note": "O `omittingEmptySubsequences: false` mantém o pedaço vazio de `1..2`, então um ponto dobrado falha em vez de passar como duas partes."}]}
```

`swift check.swift` roda um arquivo sozinho, sem pacote: o toolchain o compila na memória e o roda.
Aqui ele está no arquivo do planner, e depois numa cópia que o `sed` faz com dois erros, um
sublinhado no identificador e uma palavra na versão:

```
ana@vm:~/plist$ swift check.swift Info.plist
identifier  com.example.planner  ok
version     1.0  ok
build       1
needs iOS   17.0
ana@vm:~/plist$ sed -e 's/com.example.planner/com.example.study_planner/' -e 's|<string>1.0</string>|<string>1.0 beta</string>|' Info.plist > Broken.plist
ana@vm:~/plist$ diff Info.plist Broken.plist
13c13
<     <string>com.example.planner</string>
---
>     <string>com.example.study_planner</string>
17c17
<     <string>1.0</string>
---
>     <string>1.0 beta</string>
ana@vm:~/plist$ swift check.swift Broken.plist
identifier  com.example.study_planner  only A-Z a-z 0-9 - . allowed
version     1.0 beta  must be up to three integers, like 1.2.3
build       1
needs iOS   17.0
```

**As ferramentas da Apple seguram as duas regras, e o motivo de vê-las aqui é reconhecer a mensagem
quando ela vier.** Um projeto Xcode novo chamado `study_planner` propõe o identificador com um hífen
no lugar do sublinhado, e o App Store Connect recusa um envio cuja string de versão não esteja nessa
forma, o que a aula 22 mostra. O sublinhado é o erro mais comum, porque parece natural num nome de
duas palavras, `study_planner`, e é um caractere que um identificador Swift aceita e um bundle
identifier não.
