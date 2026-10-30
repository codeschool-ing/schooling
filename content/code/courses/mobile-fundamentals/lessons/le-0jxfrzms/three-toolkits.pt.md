---
title: Pedir a permissão de lembrete em três toolkits
version: 1
---

**Cada toolkit pede uma permissão com uma chamada, e cada um devolve a resposta depois, porque no meio
a pessoa está olhando um diálogo.** Os três fragmentos abaixo pedem a permissão de notificação do
planner no momento em que a aluna toca em "lembrar", e tratam a resposta. Eles foram adaptados da
documentação do Android sobre pedir permissões, da documentação da Apple sobre
`UNUserNotificationCenter` e da documentação da biblioteca de notificações do Expo, e **não foram
compilados nem executados para este curso**. Leia-os pelo formato: conferir, explicar se preciso,
pedir, e agir conforme a resposta.

## Android: um launcher de resultado de activity

```kotlin
// Compose: ask for POST_NOTIFICATIONS when the student taps "remind me"
val launcher = rememberLauncherForActivityResult(
    ActivityResultContracts.RequestPermission()
) { granted -> if (granted) scheduleReminder(session) else showRemindersOff() }

Button(onClick = {
    when {
        ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS)
            == PackageManager.PERMISSION_GRANTED -> scheduleReminder(session)
        activity.shouldShowRequestPermissionRationale(Manifest.permission.POST_NOTIFICATIONS) ->
            showWhyReminders()   // the app's own screen; its button calls launcher.launch
        else -> launcher.launch(Manifest.permission.POST_NOTIFICATIONS)
    }
}) { Text("Remind me") }
```

**O `when` é o fluxograma da seção anterior, em ordem.** Já concedida: agir. Na janela depois de uma
recusa: mostrar primeiro a explicação do app. Senão: abrir o diálogo do sistema, e deixar o callback
no alto receber a resposta. A documentação do Android observa que o app "não consegue personalizar o
diálogo" em si, e é por isso que a explicação é uma tela do próprio app.

## iOS: uma chamada, com a resposta numa closure

```swift
// SwiftUI: ask for notifications when the student taps "remind me"
Button("Remind me") {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
        if granted {
            scheduleReminder(for: session)
        } else {
            remindersOff = true   // the view then offers a button to Settings
        }
    }
}
// that button opens the app's own page in Settings
openURL(URL(string: UIApplication.openSettingsURLString)!)
```

**Não há ramo de justificativa, porque o iOS não tem segundo diálogo a preservar.** A primeira chamada
mostra o diálogo; toda chamada seguinte devolve na hora a resposta guardada, e é por isso que o mesmo
botão funciona antes e depois de a aluna decidir. Quando a resposta é não, o app mostra o planner sem
lembretes e oferece os Ajustes, pela URL que a documentação da Apple dá para abrir os ajustes do
próprio app.

## React Native: a biblioteca de notificações do Expo

```tsx
// Expo: ask for notifications when the student taps "remind me"
async function remindMe(session: Session) {
  const { status: existing } = await Notifications.getPermissionsAsync();
  let status = existing;
  if (existing !== "granted") {
    status = (await Notifications.requestPermissionsAsync()).status;
  }
  if (status === "granted") {
    await scheduleReminder(session);
  } else {
    setRemindersOff(true);   // the screen then offers Linking.openSettings()
  }
}
```

**Conferir, pedir se não estiver concedida, agir conforme o resultado: os mesmos três passos, em
JavaScript.** Uma chamada da biblioteca cobre as duas plataformas, e cada plataforma continua aplicando
a própria regra por baixo. No Android uma segunda recusa é final e no iOS a primeira é, diga o que
disser o JavaScript. O módulo `PermissionsAndroid` do próprio React Native expõe a justificativa do
Android diretamente, e o `Linking.openSettings()` dele abre a página do app nos Ajustes nas duas
plataformas.

| | Android | iOS | React Native com Expo |
|---|---|---|---|
| conferir | `checkSelfPermission` | a resposta guardada, devolvida pelo pedido | `getPermissionsAsync` |
| explicar antes | `shouldShowRequestPermissionRationale` | antes do único pedido | `PermissionsAndroid`, no Android |
| pedir | `launcher.launch(...)` | `requestAuthorization` | `requestPermissionsAsync` |
| depois do não final | um intent para os detalhes do app | `openSettingsURLString` | `Linking.openSettings()` |

Seja qual for o caminho que você tomar na bifurcação, o curso dele volta a isto: a aula 20 de
`android-apps`, sobre permissões de tempo de execução e o fluxo quando a pessoa diz não duas vezes, a
aula 18 de `ios-apps`, sobre purpose strings e permissões, ou a aula 13 de `react-native`, sobre
permissões ao lado da câmera e dos arquivos.
