---
title: Por dentro do projeto iOS
version: 1
---

**O projeto iOS é um projeto Xcode, e num Mac você abre `ios/App/App.xcodeproj` e aperta Run.** Tudo
nele pode ser lido em qualquer computador, e deve ser, porque parte dele você vai mudar seja qual for o
computador onde constrói. No Linux é uma pasta de arquivos de texto:

```
ana@dev:~/planner$ ls ios/App/App
AppDelegate.swift
Assets.xcassets
Base.lproj
Info.plist
SceneDelegate.swift
capacitor.config.json
config.xml
public
ana@dev:~/planner$ grep -A1 -E "CFBundle(DisplayName|Identifier|ShortVersionString|Version)<" ios/App/App/Info.plist
	<key>CFBundleDisplayName</key>
        <string>Study planner</string>
--
	<key>CFBundleIdentifier</key>
	<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
--
	<key>CFBundleShortVersionString</key>
	<string>$(MARKETING_VERSION)</string>
	<key>CFBundleVersion</key>
	<string>$(CURRENT_PROJECT_VERSION)</string>
ana@dev:~/planner$ head -n 12 ios/App/App/AppDelegate.swift
import UIKit
import Capacitor

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
```

**O `Info.plist` é o manifesto do iOS**, uma lista de chaves e valores em XML. `CFBundleDisplayName` é o
nome embaixo do ícone, o `appName` da aula 2. Os outros nem estão escritos ali: são variáveis `$(…)` que
o Xcode preenche a partir das configurações de build do projeto, então o identificador do bundle, que
é o seu `appId`, e os dois números de versão são editados no Xcode, na aba "General" do target, e não
neste arquivo. A aula 15 volta aos dois números de versão, que querem dizer coisas diferentes.

**O `AppDelegate.swift` é o ponto de entrada do app**, com um método para cada momento da vida dele:
iniciado, prestes a ir para o segundo plano, de volta à frente. O modelo do Capacitor os deixa vazios,
e é neles que se liga um plugin que precisa saber desses momentos. O `SceneDelegate.swift` faz o mesmo
para cada janela, e a `Base.lproj` guarda a tela de abertura e o storyboard que contém a WebView.

Toda permissão que um app iOS pede é uma chave no `Info.plist` com uma frase ao lado, o texto do diálogo
que a pessoa vê. **Um app que pede sem essa frase é fechado pelo iOS na hora**, e é por isso que a aula
4 acrescenta uma para cada plugin.

## Rodando, pelos passos da Apple

*Nada disto foi rodado para este curso, que foi gravado no Linux. Vem da documentação do Capacitor para
iOS e da Apple para o Xcode.*

1. Instale o **Xcode** pela Mac App Store, abra uma vez para aceitar a licença e deixe-o instalar os
   componentes e um simulador de iOS.
2. No Mac, na pasta do planner, `npm install`, `npm run build` e `npx cap sync ios`, como em qualquer
   outro computador.
3. `npx cap open ios` abre o projeto no Xcode. Escolha um simulador na barra de cima e aperte Run; o
   planner abre nele.
4. Para rodar no seu próprio iPhone, o Xcode pede um **time**: um Apple ID conectado nas configurações
   "Accounts" do Xcode basta para rodar num celular seu, por um tempo limitado. Publicar exige a
   assinatura paga, e a aula 14 é sobre isso.
