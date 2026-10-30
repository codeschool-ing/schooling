---
title: A web server in Kotlin with Ktor
version: 1
---

Android is where most people meet Kotlin, and the JVM is where the language started: a large share of
Kotlin code runs on servers, answering HTTP requests, and none of what this course taught changes
there. **Ktor is JetBrains' framework for writing those servers in Kotlin**, built on coroutines from the
ground up, so every request handler is a suspending function, and the lessons of 14 to 17 apply as they
are.

The server lives in a build of its own, `~/kt/server`, started the way lesson 19 started `studyplan`:
a copy of the wrapper, a `settings.gradle.kts` with the repositories, and a catalog. The catalog names
Ktor's pieces and one plugin the JVM build did not need, Kotlin's serialization plugin:

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

`ktor-server-netty` is the server itself, running on Netty, the networking library most JVM servers use
underneath. The two lines after it turn Kotlin objects into JSON and back. `slf4j-simple` is
`runtimeOnly`, from the table in lesson 19: Ktor writes its log through SLF4J, and this is the
smallest thing that prints it.

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

**`planner()` is an extension function on `Application`**, lesson 11's tool, and Ktor calls a server
built this way a module. `routing` maps a method and a path to a suspending block; inside it, `call` is
the request being answered. `start(wait = true)` keeps `main` running until the process is stopped.

Build it as lesson 19 built `app`, and start it:

```
ana@vm:~/kt/server$ ./gradlew -q installDist
ana@vm:~/kt/server$ build/install/server/bin/server
[main] INFO io.ktor.server.Application - Autoreload is disabled because the development mode is off.
[main] INFO io.ktor.server.Application - Application started in 0.537 seconds.
[DefaultDispatcher-worker-1] INFO io.ktor.server.Application - Responding at http://0.0.0.0:8080
```

The three lines are the server's log through `slf4j-simple`, and the last one says it is listening on
port 8080. It keeps the terminal; **open a second terminal for the requests**, in the same directory:

```
ana@vm:~/kt/server$ curl -s -w '\n' localhost:8080/
planner is up
ana@vm:~/kt/server$ curl -s -w '\n' localhost:8080/sessions
[{"course":"kotlin","minutes":45}]
```

The `-s` keeps curl quiet about its own progress, and `-w '\n'` prints a line break after the body,
which the server does not send. The server answered `planner is up` at `/`, and the
list of sessions at `/sessions`, as JSON, without one line of code that writes JSON.
