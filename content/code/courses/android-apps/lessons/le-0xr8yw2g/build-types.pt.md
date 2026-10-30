---
title: "Tipos de build: um projeto, um app de debug e um app de release"
version: 1
---

**Todo build Android é uma variante: um tipo de build cruzado com um product flavour.** A aula 1
construiu só `debug`, o tipo de build feito para o desenvolvimento: depurável, assinado com uma chave
que todo mundo tem e otimizado para compilar rápido. Uma versão publicada precisa do contrário em
cada um desses pontos, e o plugin Android do Gradle tem um segundo tipo de build, `release`,
esperando em todo projeto desde a aula 1. Esta aula o configura, acrescenta dois flavours, assina o
resultado com uma chave sua, encolhe o app e o empacota do jeito que o Google Play quer.

Parta do projeto da aula 1. Este é o arquivo de build que a aula inteira usa; as seções seguintes
explicam as partes que ele aponta:

```schooling-example
{"language": "kotlin", "file": "app/build.gradle.kts", "parts": [{"code": "// app/build.gradle.kts\nplugins {\n    alias(libs.plugins.android.application)\n    alias(libs.plugins.kotlin.compose)\n    alias(libs.plugins.roborazzi)\n}\n\nandroid {\n    namespace = \"com.example.planner\"\n    compileSdk = 37\n\n    defaultConfig {\n        applicationId = \"com.example.planner\"\n        minSdk = 26\n        targetSdk = 36\n        versionCode = 1\n        versionName = \"0.1.0\"\n    }\n", "note": "O arquivo da aula 1 até o `defaultConfig`, sem mudanças. `versionCode` é o número que o Google Play compara, e precisa crescer a cada envio; `versionName` é o que as pessoas leem."}, {"code": "    signingConfigs {\n        create(\"upload\") {\n            storeFile = file(System.getProperty(\"user.home\") + \"/keys/planner-upload.jks\")\n            storePassword = providers.environmentVariable(\"PLANNER_UPLOAD_PASSWORD\").orNull\n            keyAlias = \"upload\"\n            keyPassword = providers.environmentVariable(\"PLANNER_UPLOAD_PASSWORD\").orNull\n        }\n    }\n", "note": "**A chave de upload, seção 04.** O caminho fica fora do projeto, então a chave nunca está numa pasta que vai para o controle de versão, e a senha vem do ambiente, então não está em arquivo nenhum."}, {"code": "    buildTypes {\n        debug {\n            applicationIdSuffix = \".debug\"\n            versionNameSuffix = \"-debug\"\n        }\n        release {\n            isMinifyEnabled = true\n            isShrinkResources = true\n            proguardFiles(getDefaultProguardFile(\"proguard-android-optimize.txt\"), \"proguard-rules.pro\")\n            signingConfig = signingConfigs.getByName(\"upload\")\n        }\n    }\n", "note": "**Os dois tipos de build.** `debug` ganha um sufixo para instalar ao lado da versão de release. `release` liga o R8 e o encolhimento de recursos, seção 05, e é assinado com a chave de upload."}, {"code": "    flavorDimensions += \"distribution\"\n    productFlavors {\n        create(\"play\") {\n            dimension = \"distribution\"\n            buildConfigField(\"String\", \"UPDATES_FROM\", \"\\\"Google Play\\\"\")\n        }\n        create(\"direct\") {\n            dimension = \"distribution\"\n            applicationIdSuffix = \".direct\"\n            buildConfigField(\"String\", \"UPDATES_FROM\", \"\\\"the planner's website\\\"\")\n        }\n    }\n", "note": "**Uma dimensão, dois flavours**, seção 03. `direct` é o planner entregue como arquivo no site dele; ganha um application id próprio e um valor próprio de `UPDATES_FROM`."}, {"code": "    buildFeatures {\n        compose = true\n        buildConfig = true\n    }\n\n    testOptions {\n        unitTests.isIncludeAndroidResources = true\n    }\n}\n", "note": "`buildConfig = true` pede ao plugin que gere a classe `BuildConfig` que carrega os campos acima; desde o AGP 8 ela vem desligada por padrão."}, {"code": "dependencies {\n    implementation(libs.core.ktx)\n    implementation(libs.activity.compose)\n    implementation(platform(libs.compose.bom))\n    implementation(libs.compose.ui)\n    implementation(libs.compose.material3)\n    implementation(libs.compose.ui.tooling.preview)\n    debugImplementation(libs.compose.ui.tooling)\n    debugImplementation(libs.compose.ui.test.manifest)\n\n    testImplementation(libs.junit)\n    testImplementation(libs.robolectric)\n    testImplementation(libs.androidx.test.core)\n    testImplementation(platform(libs.compose.bom))\n    testImplementation(libs.compose.ui.test.junit4)\n    testImplementation(libs.roborazzi)\n    testImplementation(libs.roborazzi.compose)\n}", "note": "As dependências são as da aula 1."}]}
```

E o arquivo de regras que o tipo de build `release` cita. O planner ainda não precisa de regra
própria; a seção 05 diz quando um projeto precisa:

```properties
# app/proguard-rules.pro
# The planner keeps no class by reflection yet, so R8 needs no rule of ours.
```

## Dois builds que convivem num celular

```
ana@vm:~/planner$ ./gradlew --console=plain assembleDebug 2>&1 | grep -E '^BUILD'
BUILD SUCCESSFUL in 15s
ana@vm:~/planner$ find app/build/outputs/apk -name "*.apk" | sort
app/build/outputs/apk/direct/debug/app-direct-debug.apk
app/build/outputs/apk/play/debug/app-play-debug.apk
ana@vm:~/planner$ $ANDROID_HOME/build-tools/36.1.0/aapt2 dump badging app/build/outputs/apk/play/debug/app-play-debug.apk | grep -o "name='[^']*' versionCode='[^']*' versionName='[^']*'"
name='com.example.planner.debug' versionCode='1' versionName='0.1.0-debug'
ana@vm:~/planner$ $ANDROID_HOME/build-tools/36.1.0/aapt2 dump badging app/build/outputs/apk/direct/debug/app-direct-debug.apk | grep -o "name='[^']*' versionCode='[^']*' versionName='[^']*'"
name='com.example.planner.direct.debug' versionCode='1' versionName='0.1.0-debug'
```

`assembleDebug` construiu o tipo de build debug **dos dois flavours**, e para um celular cada um é um
app separado: `com.example.planner.debug` e `com.example.planner.direct.debug`. **É para isso que
serve o `applicationIdSuffix`.** O celular de quem desenvolve pode então ter o build de debug ao lado
da versão da loja, cada um com os seus dados, em vez de um substituir o outro a cada instalação.
`versionNameSuffix` põe `-debug` na versão, e assim uma captura de tela da página de configurações diz
de qual build ela veio.

## O que um tipo de build muda

| | `debug` | `release` |
|---|---|---|
| um depurador pode se conectar | sim | não |
| assinado com | a chave de debug compartilhada da aula 1, seção 08 | a sua chave de upload, seção 04 |
| o R8 encolhe e ofusca | não | sim, seção 05 |
| recursos sem uso removidos | não | sim, `isShrinkResources` |
| quanto tempo levou aqui | 15 s, dois APKs | 1 min 16 s, dois APKs e um bundle, seção 04 |

Um tipo de build deve mudar **como** o app é construído e nunca **o que** ele faz. Um recurso que só
funciona em `debug` é um recurso que ninguém testou no build que é publicado.
