---
title: A frase de uso, que o iOS mostra por você
version: 1
---

**Um app não abre a câmera, não lê a localização e não vê a biblioteca de fotos até que a pessoa
com o telefone na mão diga sim, e quem faz a pergunta é o iOS, não o app.** O app fornece uma frase
para cada tipo de acesso, a sua **descrição de uso**, e o sistema põe essa frase no alerta que
desenha. A documentação da Apple para o `NSCameraUsageDescription`, lida em 30 de outubro de 2026,
diz que a chave "is required if your app uses APIs that access the device's camera". Sem ela o app
não recebe um alerta recusado: o iOS encerra o app no momento em que ele pede.

A crença a largar é que o alerta é uma tela do próprio app, para redigir e estilizar como quiser. O
app escreve uma string e chama um método. Todo o resto, o título, os dois botões, quando o alerta
aparece e se ele volta a aparecer, pertence ao iOS. **Ele pergunta uma vez.** O guia da Apple sobre
pedir autorização de localização diz isso com todas as letras: depois do primeiro pedido "the system
stores your app's authorization status and doesn't prompt again". Quem toca em *Não Permitir* não é
perguntado uma segunda vez, e a seção 07 trata do que o app faz então.

## O que a frase tem de dizer

A frase diz **o que o app vai fazer com o acesso**, em termos de algo que a pessoa quer. *O Planner
precisa de acesso à câmera* é um fato sobre o app. *O Planner usa a câmera para fotografar as suas
anotações e anexá-las a uma sessão de estudo* é um motivo, e é o que a App Review lê também: a
diretriz 5.1.1 das App Review Guidelines, atualizada pela última vez em 16 de outubro de 2026 e lida
para este curso em 30 de outubro, diz "Ensure your purpose strings clearly and completely describe
your use of the data". A aula 22 lê o resto dessa diretriz.

O planner ganha um recurso novo nesta aula, a foto das anotações anexada a uma sessão, e com ele uma
chave. O resto do arquivo é o da aula 1. Salve-o como `Info.plist` em `~/privacy`:

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
    <key>NSCameraUsageDescription</key>
    <string>Planner uses the camera to photograph your notes and attach them to a study session.</string>
    <key>UILaunchScreen</key>
    <dict/>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
</dict>
</plist>
```

Cada chave de uso é uma string simples no `Info.plist`, e num projeto feito por um Xcode atual você
a digita na aba *Info* do target, como descreve a aula 1, seção 08. **A frase é localizada como
qualquer outro texto que o app mostra**: um telefone em português mostra a frase em português, do
catálogo de strings do app, e uma tradução que falta cai no idioma de desenvolvimento.

| o que o código toca | a chave de que o `Info.plist` precisa |
|---|---|
| a câmera | `NSCameraUsageDescription` |
| a localização enquanto o app está em uso | `NSLocationWhenInUseUsageDescription` |
| a localização a qualquer hora | `NSLocationAlwaysAndWhenInUseUsageDescription`, e a de cima |
| salvar na biblioteca de fotos | `NSPhotoLibraryAddUsageDescription` |
| ler a biblioteca de fotos inteira | `NSPhotoLibraryUsageDescription` |
| rastrear, pelo App Tracking Transparency | `NSUserTrackingUsageDescription` |

As seções 03 a 05 pegam as quatro que o planner poderia querer e dizem de quais ele precisa, e para
três delas a resposta é nenhuma. **A permissão mais barata é a que você nunca pede.**
