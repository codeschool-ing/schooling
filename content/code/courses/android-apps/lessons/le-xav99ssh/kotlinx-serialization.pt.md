---
title: kotlinx.serialization, do plugin à primeira ida e volta
version: 1
---

**A kotlinx.serialization é duas coisas: um plugin do compilador e uma biblioteca.** O plugin lê
toda classe marcada com `@Serializable` e escreve, dentro da classe compilada, o código que a
transforma em JSON e de volta. A biblioteca traz o `Json`, que comanda esse código. Esqueça o plugin
e a anotação compila para nada, que é o primeiro erro que as pessoas cometem com ela.

O arquivo de build desta aula aplica o plugin e acrescenta tudo o que a aula usa: a biblioteca de
JSON, o Moshi e o plugin do KSP para a seção 06, e o Retrofit e o MockWebServer para a seção 07. O
bloco `testOptions` pede ao Gradle que imprima o que um teste escreve na saída padrão, para que cada
teste abaixo possa mostrar o que decodificou:

```kotlin
// app/build.gradle.kts
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.kotlin.serialization)
    alias(libs.plugins.ksp)
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
    implementation(libs.serialization.json)
    implementation(libs.moshi)
    ksp(libs.moshi.codegen)
    implementation(libs.retrofit)
    implementation(libs.retrofit.kotlinx.serialization)

    testImplementation(libs.junit)
    testImplementation(libs.coroutines.test)
    testImplementation(libs.okhttp.mockwebserver)
}
```

## O DTO

O DTO tem uma propriedade por chave do JSON, e os nomes do servidor onde eles diferem dos do Kotlin:

```kotlin
// app/src/main/java/com/example/planner/data/SessionDto.kt
package com.example.planner.data

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class SessionDto(
    val id: Long,
    @SerialName("course_id") val courseId: String,
    val date: String,
    val minutes: Int,
    val done: Boolean = false,
)
```

`@SerialName("course_id")` resolve o problema inteiro do snake case: a propriedade é `courseId` no
Kotlin e `course_id` no fio, nos dois sentidos. A data fica como `String` por enquanto, e a seção 05
é sobre por que isso não basta.

## Uma ida e volta

```kotlin
// app/src/test/java/com/example/planner/data/SessionJsonTest.kt
package com.example.planner.data

import kotlinx.serialization.json.Json
import org.junit.Test

class SessionJsonTest {
    private val text =
        """{"id": 7, "course_id": "android", "date": "2026-10-27", "minutes": 45, "done": false}"""

    @Test
    fun roundTrip() {
        val session = Json.decodeFromString<SessionDto>(text)
        println(session)
        println(Json.encodeToString(session))
    }
}
```

`decodeFromString<SessionDto>` lê o texto para a classe nomeada entre os sinais de menor e maior;
`encodeToString` o escreve de volta. Rode os testes de unidade do projeto:

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest 2>&1 | grep -E "STANDARD_OUT|PASSED|FAILED|^    |^BUILD"
SessionJsonTest > roundTrip STANDARD_OUT
    SessionDto(id=7, courseId=android, date=2026-10-27, minutes=45, done=false)
    {"id":7,"course_id":"android","date":"2026-10-27","minutes":45}
SessionJsonTest > roundTrip PASSED
BUILD SUCCESSFUL in 8s
```

A primeira linha é o `toString()` do Kotlin para o objeto decodificado, com `courseId` preenchido a
partir de `course_id`. A segunda é o objeto escrito de volta como JSON, e **não é o texto que
entrou**: os espaços sumiram, e o `"done": false` também. A kotlinx.serialization deixa de fora uma
propriedade cujo valor é igual ao padrão, a não ser que `Json { encodeDefaults = true }` peça. Um
servidor que trata um `done` ausente como `false` não vai notar; um que o trata como erro vai, e a
configuração é como você descobre qual dos dois você tem.

**Nada aqui usou reflexão.** O plugin escreveu um serializador dentro do `SessionDto` quando o
compilou. Dá para vê-lo, como uma classe aninhada, na saída compilada:

```
ana@vm:~/planner$ find app/build/intermediates -name "SessionDto*.class" | sed "s|.*/classes/||" | sort
com/example/planner/data/SessionDto$$serializer.class
com/example/planner/data/SessionDto$Companion.class
com/example/planner/data/SessionDto.class
```

`SessionDto$$serializer` é o código gerado que lê e escreve cada campo. A existência dele é toda a
diferença entre "anotada" e "serializável". Tire o plugin do arquivo de build, e a anotação continua
compilando, o teste continua compilando, e a execução é onde você descobre:

```
ana@vm:~/planner$ sed -i "/kotlin.serialization/d" app/build.gradle.kts
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest 2>&1 | grep -E "PASSED|FAILED|Exception|^BUILD"
> Task :app:testDebugUnitTest FAILED
SessionJsonTest > roundTrip FAILED
    kotlinx.serialization.SerializationException at SessionJsonTest.kt:19
BUILD FAILED in 5s
ana@vm:~/planner$ grep -o "message=\"[^\"]*\"" app/build/test-results/testDebugUnitTest/*SessionJsonTest.xml
message="kotlinx.serialization.SerializationException: Serializer for class 'SessionDto' is not found.&#10;Please ensure that class is marked as '@Serializable' and that the serialization compiler plugin is applied.&#10;"
```

O resumo do Gradle diz só a classe da exceção. O relatório XML que ele escreve para cada classe de
teste guarda a mensagem, com `&#10;` onde estavam as quebras de linha, e o segundo comando a lê dali.
**A mensagem diz a causa, e chega em tempo de execução.** Sem o plugin, nada escreveu um
serializador dentro da classe, e o `decodeFromString` procura um quando é chamado. Num app, isso
significa uma queda na primeira tela que carrega dados, e não uma linha vermelha no build. Se você
encontrar essa mensagem, confira o bloco `plugins` do módulo onde a classe mora antes de qualquer
outra coisa. Ponha a linha de volta e o teste passa de novo.
