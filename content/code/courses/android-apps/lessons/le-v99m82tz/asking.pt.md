---
title: Pedindo de dentro de um composable
version: 1
---

**Um pedido de permissão é um resultado de activity**: o app abre a caixa do sistema e recebe uma
resposta depois, e o Compose embrulha isso no `rememberLauncherForActivityResult`. O launcher é
criado durante a composição, sobrevive à recomposição e chama a sua lambda com `true` ou `false`
quando o estudante responde.

Parta do projeto da aula 1. O arquivo de build é o da aula 1 com um bloco `testLogging` a mais, para
que as linhas impressas pelos testes apareçam como aqui; as APIs de permissão estão no
`androidx.core` e no `androidx.activity`, que o projeto já tem:

```kotlin
// app/build.gradle.kts
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.roborazzi)
}

android {
    namespace = "com.example.planner"
    compileSdk = 37

    defaultConfig {
        applicationId = "com.example.planner"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "0.1.0"
    }

    buildFeatures {
        compose = true
    }

    testOptions {
        unitTests.isIncludeAndroidResources = true
        unitTests.all {
            it.testLogging {
                events("passed", "failed")
                showStandardStreams = true
            }
        }
    }
}

dependencies {
    implementation(libs.core.ktx)
    implementation(libs.activity.compose)
    implementation(platform(libs.compose.bom))
    implementation(libs.compose.ui)
    implementation(libs.compose.material3)
    implementation(libs.compose.ui.tooling.preview)
    debugImplementation(libs.compose.ui.tooling)
    debugImplementation(libs.compose.ui.test.manifest)

    testImplementation(libs.junit)
    testImplementation(libs.robolectric)
    testImplementation(libs.androidx.test.core)
    testImplementation(platform(libs.compose.bom))
    testImplementation(libs.compose.ui.test.junit4)
    testImplementation(libs.roborazzi)
    testImplementation(libs.roborazzi.compose)
}
```

O manifesto declara a permissão, o que a seção 05 da aula 19 mostrou ser necessário antes de ela
poder ser pedida:

```xml
<!-- app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <application
        android:label="@string/app_name"
        android:theme="@android:style/Theme.Material.Light.NoActionBar">
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>

</manifest>
```

E as palavras que o cartão usa, todas desta aula:

```xml
<!-- app/src/main/res/values/strings.xml -->
<resources>
    <string name="app_name">Planner</string>
    <string name="welcome">No courses yet. Add the first one.</string>
    <string name="reminders_ask">Get a reminder on days with a session planned.</string>
    <string name="reminders_ask_button">Turn on reminders</string>
    <string name="reminders_explain">Reminders need permission to show a notification. The planner sends at most one a day, and never anything else.</string>
    <string name="reminders_explain_button">Allow notifications</string>
    <string name="reminders_settings">Notifications are off for the planner. You can turn them on in its settings.</string>
    <string name="reminders_settings_button">Open settings</string>
    <string name="reminders_on">Reminders are on.</string>
</resources>
```

## O composable que pede

```schooling-example
{"language": "kotlin", "file": "app/src/main/java/com/example/planner/ui/RemindersSetting.kt", "parts": [{"code": "// app/src/main/java/com/example/planner/ui/RemindersSetting.kt\npackage com.example.planner.ui\n\nimport android.Manifest\nimport android.content.Context\nimport android.content.Intent\nimport android.content.pm.PackageManager\nimport android.os.Build\nimport android.provider.Settings\nimport androidx.activity.compose.LocalActivity\nimport androidx.activity.compose.rememberLauncherForActivityResult\nimport androidx.activity.result.contract.ActivityResultContracts\nimport androidx.compose.runtime.Composable\nimport androidx.compose.runtime.getValue\nimport androidx.compose.runtime.mutableIntStateOf\nimport androidx.compose.runtime.remember\nimport androidx.compose.runtime.setValue\nimport androidx.compose.ui.platform.LocalContext\nimport androidx.core.app.ActivityCompat\nimport androidx.core.content.ContextCompat\n"}, {"code": "private const val PERMISSION = Manifest.permission.POST_NOTIFICATIONS\n", "note": "O nome da permissão, uma vez. `Manifest.permission` guarda as strings que o Android define."}, {"code": "@Composable\nfun RemindersSetting() {\n    val context = LocalContext.current\n    val activity = LocalActivity.current ?: return\n    val prefs = remember { context.getSharedPreferences(\"permissions\", Context.MODE_PRIVATE) }\n    var answers by remember { mutableIntStateOf(0) }\n", "note": "`LocalActivity` é a activity que hospeda esta composição; o `shouldShowRequestPermissionRationale` precisa dela. O arquivo de preferências guarda uma marca: se o app já pediu alguma vez."}, {"code": "    val launcher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) {\n        prefs.edit().putBoolean(PERMISSION, true).apply()\n        answers++\n    }\n", "note": "**O launcher.** `RequestPermission` é o contrato para uma permissão; a lambda roda quando o estudante responde, com `true` ou `false`. Ela registra que o app pediu e incrementa um contador, para que a oferta abaixo seja calculada de novo."}, {"code": "    val offer = remember(answers) {\n        offerFor(\n            sdk = Build.VERSION.SDK_INT,\n            granted = ContextCompat.checkSelfPermission(context, PERMISSION) ==\n                PackageManager.PERMISSION_GRANTED,\n            showRationale = ActivityCompat.shouldShowRequestPermissionRationale(activity, PERMISSION),\n            askedBefore = prefs.getBoolean(PERMISSION, false),\n        )\n    }\n", "note": "**Cada resposta que o Android pode dar, lida de novo**: a versão do celular, se a permissão está concedida, se o Android aconselha explicar, e a memória do próprio app de ter pedido. A função da seção 04 transforma tudo numa decisão."}, {"code": "    ReminderCard(\n        offer = offer,\n        onAsk = { launcher.launch(PERMISSION) },\n        onOpenSettings = {\n            context.startActivity(\n                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)\n                    .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName),\n            )\n        },\n    )\n}", "note": "O cartão da seção 05 faz o desenho. Pedir é `launch`; configurações é um intent para a página de notificações do app, que o Android tem desde o 8.0, o `minSdk` deste projeto."}]}
```

Duas coisas nessa função não são sobre Compose e importam mais do que o resto. **O app precisa
lembrar que pediu**, porque o Android não conta: a marca no `SharedPreferences` é o que a seção 04
precisa para separar "nunca pedida" de "recusada duas vezes". E **a resposta que o launcher entrega
não é o estado inteiro**: depois de uma recusa, o `shouldShowRequestPermissionRationale` pode ter
mudado, então a função pergunta ao Android de novo em vez de confiar só no booleano.

O contador `answers` é o jeito mais simples de dizer "recalcule depois de cada resposta". Uma tela de
onde o estudante pode sair e voltar também deveria recalcular quando volta ao primeiro plano, porque o
estudante pode ter mudado a permissão nas Configurações nesse meio-tempo; a coleta atenta ao ciclo de
vida da aula 11 é a ferramenta para isso, e a tela do planner num app de verdade a usaria.
