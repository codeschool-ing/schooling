---
title: Testando o servidor sem rede
version: 1
---

Iniciar um servidor e digitar comandos curl é uma verificação que precisa ser repetida à mão. **O
`testApplication` do Ktor roda um módulo na memória e dá ao teste um cliente para ele**: sem porta, sem
rede, e com os mesmos tratadores que o servidor de verdade roda.

```kotlin
// src/test/kotlin/ServerTest.kt
package studyplan.server

import io.ktor.client.request.get
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.HttpStatusCode
import io.ktor.http.contentType
import io.ktor.server.testing.testApplication
import kotlin.test.Test
import kotlin.test.assertEquals

class ServerTest {
    @Test
    fun aPostedSessionIsListed() = testApplication {
        application { planner() }
        val created = client.post("/sessions") {
            contentType(ContentType.Application.Json)
            setBody("""{"course":"android-apps","minutes":30}""")
        }
        assertEquals(HttpStatusCode.Created, created.status)
        assertEquals(
            """[{"course":"kotlin","minutes":45},{"course":"android-apps","minutes":30}]""",
            client.get("/sessions").bodyAsText(),
        )
    }

    @Test
    fun zeroMinutesAreRefused() = testApplication {
        application { planner() }
        val response = client.post("/sessions") {
            contentType(ContentType.Application.Json)
            setBody("""{"course":"kotlin","minutes":0}""")
        }
        assertEquals(HttpStatusCode.BadRequest, response.status)
    }
}
```

```
ana@vm:~/kt/server$ ./gradlew -q test && echo tests passed
tests passed
```

**É por isso que o `planner()` é uma função e não o corpo do `main`.** O `main` escolhe um motor e uma
porta; o módulo guarda o comportamento, e o `application { planner() }` o instala num teste sem nenhum
dos dois. Cada teste ganha um módulo novo, então a sessão postada no primeiro não vaza para o segundo.

O JSON é escrito como strings cruas, o `"""…"""` da lição 1, para o teste dizer exatamente o que passa
pelo fio. Esse é o contrato de que um cliente, como o app que o `android-apps` constrói, depende.
