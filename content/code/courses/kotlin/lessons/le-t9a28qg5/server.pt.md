---
title: Um servidor web em Kotlin com Ktor
version: 1
---

O Android é onde a maioria das pessoas conhece o Kotlin, e a JVM é onde a linguagem começou: boa parte do
código Kotlin roda em servidores, respondendo requisições HTTP, e nada do que este curso ensinou muda
lá. **O Ktor é o framework da JetBrains para escrever esses servidores em Kotlin**, feito sobre corrotinas
desde a base, então todo tratador de requisição é uma função suspensa, e as aulas 14 a 17 valem como
estão.

O servidor mora num build próprio, `~/kt/server`, começado como a aula 19 começou o `studyplan`: uma
cópia do wrapper, um `settings.gradle.kts` com os repositórios, e um catálogo. O catálogo nomeia as peças
do Ktor e um plugin de que o build da JVM não precisava, o plugin de serialização do Kotlin:

```kotlin
// settings.gradle.kts
rootProject.name = "server"

dependencyResolutionManagement {
    repositories {
        mavenCentral()
    }
}
```

```toml
# gradle/libs.versions.toml
[versions]
kotlin = "2.4.21"
ktor = "3.6.1"
coroutines = "1.11.0"

[libraries]
ktor-server-netty = { module = "io.ktor:ktor-server-netty", version.ref = "ktor" }
ktor-server-content-negotiation = { module = "io.ktor:ktor-server-content-negotiation", version.ref = "ktor" }
ktor-serialization-kotlinx-json = { module = "io.ktor:ktor-serialization-kotlinx-json", version.ref = "ktor" }
ktor-server-test-host = { module = "io.ktor:ktor-server-test-host", version.ref = "ktor" }
kotlinx-coroutines-core = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-core", version.ref = "coroutines" }
slf4j-simple = { module = "org.slf4j:slf4j-simple", version = "2.0.17" }

[plugins]
kotlin-jvm = { id = "org.jetbrains.kotlin.jvm", version.ref = "kotlin" }
kotlin-serialization = { id = "org.jetbrains.kotlin.plugin.serialization", version.ref = "kotlin" }
```

```kotlin
// build.gradle.kts
plugins {
    alias(libs.plugins.kotlin.jvm)
    alias(libs.plugins.kotlin.serialization)
    application
}

dependencies {
    implementation(libs.ktor.server.netty)
    implementation(libs.ktor.server.content.negotiation)
    implementation(libs.ktor.serialization.kotlinx.json)
    implementation(libs.kotlinx.coroutines.core)
    runtimeOnly(libs.slf4j.simple)
    testImplementation(kotlin("test"))
    testImplementation(libs.ktor.server.test.host)
}

kotlin {
    jvmToolchain(21)
}

application {
    mainClass = "studyplan.server.ServerKt"
}

tasks.test {
    useJUnitPlatform()
}
```

O `ktor-server-netty` é o servidor em si, rodando sobre o Netty, a biblioteca de rede que a maioria dos
servidores JVM usa por baixo. As duas linhas depois dele transformam objetos Kotlin em JSON e de volta. O
`slf4j-simple` é `runtimeOnly`, da tabela da aula 19: o Ktor escreve o log pelo SLF4J, e este é o menor
componente que o imprime.

```kotlin
// src/main/kotlin/Server.kt
package studyplan.server

import io.ktor.http.HttpStatusCode
import io.ktor.serialization.kotlinx.json.json
import io.ktor.server.application.Application
import io.ktor.server.application.install
import io.ktor.server.engine.embeddedServer
import io.ktor.server.netty.Netty
import io.ktor.server.plugins.contentnegotiation.ContentNegotiation
import io.ktor.server.request.receive
import io.ktor.server.response.respond
import io.ktor.server.response.respondText
import io.ktor.server.routing.get
import io.ktor.server.routing.post
import io.ktor.server.routing.routing
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.serialization.Serializable

@Serializable
data class Session(val course: String, val minutes: Int)

fun Application.planner() {
    val sessions = MutableStateFlow(listOf(Session("kotlin", 45)))
    install(ContentNegotiation) { json() }
    routing {
        get("/") { call.respondText("planner is up") }
        get("/sessions") { call.respond(sessions.value) }
        post("/sessions") {
            val s = call.receive<Session>()
            if (s.minutes <= 0) {
                call.respond(HttpStatusCode.BadRequest, "minutes must be positive")
            } else {
                sessions.update { it + s }
                call.respond(HttpStatusCode.Created, s)
            }
        }
    }
}

fun main() {
    embeddedServer(Netty, port = 8080, module = Application::planner).start(wait = true)
}
```

**O `planner()` é uma função de extensão em `Application`**, a ferramenta da aula 11, e o Ktor chama um
servidor montado assim de módulo. O `routing` liga um método e um caminho a um bloco suspenso; dentro
dele, `call` é a requisição sendo respondida. O `start(wait = true)` mantém o `main` rodando até o
processo ser parado.

Construa-o como a aula 19 construiu o `app`, e inicie-o:

```
ana@vm:~/kt/server$ ./gradlew -q installDist
ana@vm:~/kt/server$ build/install/server/bin/server
[main] INFO io.ktor.server.Application - Autoreload is disabled because the development mode is off.
[main] INFO io.ktor.server.Application - Application started in 0.537 seconds.
[DefaultDispatcher-worker-1] INFO io.ktor.server.Application - Responding at http://0.0.0.0:8080
```

As três linhas são o log do servidor pelo `slf4j-simple`, e a última diz que ele está ouvindo na porta
8080. Ele fica com o terminal; **abra um segundo terminal para as requisições**, no mesmo diretório:

```
ana@vm:~/kt/server$ curl -s -w '\n' localhost:8080/
planner is up
ana@vm:~/kt/server$ curl -s -w '\n' localhost:8080/sessions
[{"course":"kotlin","minutes":45}]
```

O `-s` deixa o curl quieto sobre o próprio progresso, e o `-w '\n'` imprime uma quebra de linha depois do
corpo, que o servidor não manda. O servidor respondeu `planner is up` em `/`, e a lista de sessões em
`/sessions`, como JSON, sem uma linha de código que escreva JSON.
