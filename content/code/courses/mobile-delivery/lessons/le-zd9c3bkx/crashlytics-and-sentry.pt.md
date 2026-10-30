---
title: Crashlytics e Sentry, e os símbolos de que eles precisam
version: 1
---

**Os dois coletores de crash que a maioria das equipes mobile usa são o Firebase Crashlytics, que é
gratuito e faz parte do Firebase do Google, e o Sentry, que é um serviço pago com plano gratuito e
pode rodar também nos seus próprios servidores.** Os dois fazem o que as quarenta linhas da seção
anterior fizeram, e muito mais: crashes nativos pegos por tratadores de sinal, travamentos,
agrupamento, alertas. Os dois precisam do mesmo passo extra para serem úteis, que é **enviar os
símbolos de todo build de release**. *Nenhum deles foi configurado para este curso; as listagens
foram escritas a partir da documentação de cada produto, outubro de 2026, e não foram geradas.*

## Acrescentando um

| | Crashlytics | Sentry |
|---|---|---|
| Android | os plugins Gradle do Google services e do Crashlytics, e a biblioteca `firebase-crashlytics` | o plugin Gradle do Sentry e `io.sentry:sentry-android` |
| iOS | o pacote `FirebaseCrashlytics`, e uma build phase que envia dSYMs | o pacote `Sentry`, e o `sentry-cli` enviando dSYMs |
| React Native | `@react-native-firebase/crashlytics` | `@sentry/react-native`, com um plugin para o Expo |

Ligar o coletor é uma linha em cada um, e ela vem primeiro, antes do código do próprio app:

```kotlin
// PlannerApp.kt: Sentry starts before anything else in the Application
class PlannerApp : Application() {
    override fun onCreate() {
        super.onCreate()
        SentryAndroid.init(this) { it.dsn = BuildConfig.SENTRY_DSN; it.release = "planner@1.5.0+1050003" }
    }
}
```

```swift
// PlannerApp.swift: the same, in the SwiftUI app's initialiser
import Sentry
@main struct PlannerApp: App {
    init() { SentrySDK.start { $0.dsn = Secrets.sentryDSN; $0.releaseName = "planner@1.5.0+1050003" } }
    var body: some Scene { WindowGroup { WeekView() } }
}
```

```typescript
// index.ts: and in React Native, before the root component is registered
import * as Sentry from "@sentry/react-native";
Sentry.init({ dsn: process.env.EXPO_PUBLIC_SENTRY_DSN, release: "planner@1.5.0+1050003" });
```

O **nome do release** leva a versão e o número de build da lição 9, para que um relatório case com
exatamente um build, e com os símbolos desse build.

## Por que símbolos

Um build de release não é o código que você escreveu. No Android, o **R8** encolhe e renomeia
classes e métodos para economizar espaço, e `WeekViewModel.totalMinutes` vira `a.b`. No iOS, o
binário compilado não tem nome de função nenhum, só endereços. No React Native, o JavaScript é
**minificado** numa linha só. Uma pilha de qualquer um deles é ilegível sem um arquivo produzido por
**aquele build exato**:

| plataforma | o que o build produz | o que ele mapeia |
|---|---|---|
| Android | `mapping.txt`, do R8 | nomes curtos de volta para classes, métodos e linhas |
| iOS | um bundle `.dSYM`, do Xcode | endereços de volta para funções, arquivos e linhas |
| React Native | um **source map**, do Metro ou do Hermes | posições no bundle de volta para os arquivos de código |

**Os símbolos precisam ser enviados a partir do build que foi publicado**, porque um build novo do
mesmo commit produz outro mapeamento. É a regra da lição 7 de novo: um build, guardado, com tudo o
que ele produziu. O Crashlytics e o Sentry fazem isso com um passo no build, e uma equipe só descobre
que esqueceu quando chega o primeiro crash ilegível. A lição 13 torna uma pilha minificada legível à
mão, para você saber para que serve o envio.

## Duas configurações que são decisões de privacidade

- **Se anexar um identificador de usuário.** Os dois produtos deixam o app definir um. Sem ele, os
  crashes são contados por instalação; com ele, viram *Data Linked to You*, lição 5.
- **O que as migalhas registram.** Os dois registram navegação e requisições de rede
  automaticamente, e uma URL com a busca de uma pessoa, ou um e-mail numa query string, entra em todo
  relatório. Os dois têm um gancho, o `beforeSend` no Sentry, para tirar isso.
