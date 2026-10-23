---
title: As metades Android e iOS
version: 1
---

**Cada metade nativa é uma classe, e cada método é uma função que a ponte chama com os argumentos da
chamada JavaScript e um jeito de respondê-la.** Troque a classe de plugin gerada em cada lado.

*Nenhum dos dois arquivos foi compilado para este curso: construir Kotlin para Android exige o SDK do
Android, e Swift para iOS exige o Xcode, e a máquina de gravação não tinha nenhum dos dois (a aula 3 diz
por quê). Eles seguem os guias de plugin do Capacitor para Android e iOS, e as interfaces do Android e da
Apple que eles chamam são as documentadas para manter a tela ligada.*

## Android, em Kotlin

```kotlin
// android/src/main/kotlin/com/example/keepawake/KeepAwakePlugin.kt
package com.example.keepawake

import android.view.WindowManager
import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin

@CapacitorPlugin(name = "KeepAwake")
class KeepAwakePlugin : Plugin() {

    @PluginMethod
    fun keepAwake(call: PluginCall) {
        activity.runOnUiThread {
            activity.window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            call.resolve()
        }
    }

    @PluginMethod
    fun allowSleep(call: PluginCall) {
        activity.runOnUiThread {
            activity.window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            call.resolve()
        }
    }

    @PluginMethod
    fun isSupported(call: PluginCall) {
        call.resolve(JSObject().put("supported", true))
    }
}
```

- **`@CapacitorPlugin(name = "KeepAwake")`** registra a classe sob o nome que o `src/index.ts` usou.
  **`@PluginMethod`** expõe um método ao JavaScript com o próprio nome, então o `keepAwake` daqui
  responde ao `KeepAwake.keepAwake()` de lá.
- **`call`** é a chamada JavaScript: os argumentos saem dela com `call.getString(…)` e afins, e
  `call.resolve(…)` ou `call.reject(…)` resolve a `Promise` que espera do outro lado. Um método que nunca
  chama nenhum dos dois deixa essa `Promise` pendente para sempre, que é o bug clássico de um primeiro
  plugin.
- **`FLAG_KEEP_SCREEN_ON`** é uma flag na janela da activity: enquanto ela está ligada, a tela fica
  ligada, e ela deixa de valer quando a activity sai da tela. Ela não exige permissão nenhuma.
- **`runOnUiThread`**: a ponte chama os métodos do plugin numa thread própria, e o Android só deixa a
  thread principal mudar uma janela.

## iOS, em Swift

```swift
// ios/Sources/KeepAwakePlugin/KeepAwakePlugin.swift
import Foundation
import UIKit
import Capacitor

@objc(KeepAwakePlugin)
public class KeepAwakePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "KeepAwakePlugin"
    public let jsName = "KeepAwake"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "keepAwake", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "allowSleep", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isSupported", returnType: CAPPluginReturnPromise)
    ]

    @objc func keepAwake(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = true
            call.resolve()
        }
    }

    @objc func allowSleep(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = false
            call.resolve()
        }
    }

    @objc func isSupported(_ call: CAPPluginCall) {
        call.resolve(["supported": true])
    }
}
```

- **`jsName`** é o nome de novo, e **`pluginMethods`** lista todo método que o JavaScript pode chamar. No
  iOS, um método que falta nessa lista não é alcançável de jeito nenhum, que é o segundo bug clássico.
- **`isIdleTimerDisabled`** é o interruptor que o iOS dá para a mesma coisa: enquanto ele é `true`, o
  temporizador do sistema que escurece e bloqueia a tela não roda. A documentação da Apple pede que os
  apps o liguem só enquanto é necessário, e é para isso que serve o `allowSleep`.
- **`DispatchQueue.main.async`** é a forma do iOS de `runOnUiThread`: mudanças de interface acontecem na
  thread principal.

**Os dois lados respondem `isSupported` com `true`**, porque os dois sistemas têm o recurso em toda
versão que o Capacitor 8 suporta. O lado web é o único que precisa conferir.
