---
title: Dois números, para dois leitores
version: 1
---

**Um release mobile leva dois números de versão, e o erro é achar que um deles é cópia do outro.**
Um é um nome para pessoas; o outro é um contador para máquinas. Eles são definidos em lugares
diferentes, conferidos por regras diferentes, e falham de jeitos diferentes.

| | para pessoas | para máquinas |
|---|---|---|
| Android | `versionName`, como `1.5.0` | `versionCode`, um inteiro positivo |
| iOS | `CFBundleShortVersionString`, como `1.5.0` | `CFBundleVersion`, o número do build |
| React Native, com Expo | `version` no `app.json` | `android.versionCode` e `ios.buildNumber` no `app.json` |

**O nome é mostrado e nunca comparado.** A página da loja diz *Versão 1.5.0*, a tela Sobre do app
diz, um e-mail ao suporte cita. O Android nem olha para ele ao decidir sobre uma atualização; ele
pode ser qualquer texto.

**O código é comparado e nunca mostrado.** O Android decide que um pacote é uma atualização, e não
um rebaixamento, só pelo `versionCode`. O número de build da Apple identifica um envio entre os
builds de uma versão, e é o que o TestFlight lista.

## Onde cada um é definido

```kotlin
// build.gradle.kts: both numbers live in the app module's defaultConfig
android {
    defaultConfig {
        versionCode = 1050003
        versionName = "1.5.0"
    }
}
```

```swift
// The Xcode target's build settings set both, and Info.plist reads them:
//   MARKETING_VERSION = 1.5.0          -> CFBundleShortVersionString
//   CURRENT_PROJECT_VERSION = 1050003  -> CFBundleVersion
```

```json
{
  "expo": {
    "version": "1.5.0",
    "android": { "versionCode": 1050003 },
    "ios": { "buildNumber": "1050003" }
  }
}
```

*As três listagens foram escritas a partir da documentação de cada plataforma e não foram geradas
aqui.* O manifesto da lição 1 definia `android:versionCode` e `android:versionName` direto, e o
`aapt2` os compilou no APK: é ali que as duas linhas do Gradle vão parar.
