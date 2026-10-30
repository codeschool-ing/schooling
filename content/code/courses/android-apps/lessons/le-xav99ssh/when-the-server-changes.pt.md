---
title: Quando o servidor manda algo que você não esperava
version: 1
---

**O servidor e o app são lançados em dias diferentes.** A equipe do servidor acrescenta um campo
numa terça; o seu app, publicado três semanas antes e instalado em celulares que você não consegue
atualizar, o encontra na quarta. Então a pergunta para uma biblioteca de JSON nunca é só "ela lê o
JSON de hoje". É o que ela faz com o de amanhã: uma chave da qual nunca ouviu falar, uma chave que
falta, um `null` onde deveria haver um número.

Quatro payloads, cada um uma coisa que um servidor de verdade faz, decodificados pelo mesmo
`SessionDto`:

```kotlin
// app/src/test/java/com/example/planner/data/ServerChangesTest.kt
package com.example.planner.data

import kotlinx.serialization.json.Json
import org.junit.Test

class ServerChangesTest {
    private fun attempt(json: Json, label: String, text: String) {
        val outcome = try {
            json.decodeFromString<SessionDto>(text).toString()
        } catch (e: Exception) {
            "${e::class.simpleName}: ${e.message?.lineSequence()?.first()}"
        }
        println("$label -> $outcome")
    }

    private val extraKey =
        """{"id": 7, "course_id": "android", "date": "2026-10-27", "minutes": 45, "room": "B2"}"""
    private val noDone =
        """{"id": 7, "course_id": "android", "date": "2026-10-27", "minutes": 45}"""
    private val noMinutes =
        """{"id": 7, "course_id": "android", "date": "2026-10-27"}"""
    private val nullMinutes =
        """{"id": 7, "course_id": "android", "date": "2026-10-27", "minutes": null}"""

    @Test
    fun strict() {
        attempt(Json, "extra key", extraKey)
        attempt(Json, "no done", noDone)
        attempt(Json, "no minutes", noMinutes)
        attempt(Json, "null minutes", nullMinutes)
    }

    @Test
    fun lenient() {
        val json = Json { ignoreUnknownKeys = true }
        attempt(json, "extra key", extraKey)
        attempt(json, "null minutes", nullMinutes)
    }

    @Test
    fun coerced() {
        val json = Json { coerceInputValues = true }
        attempt(json, "null minutes", nullMinutes)
        attempt(json, "null done", noDone.replace("45}", "45, \"done\": null}"))
    }
}
```

`attempt` decodifica um payload e imprime o objeto ou a classe da exceção e a primeira linha da
mensagem. Rode só esta classe com `--tests`:

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*ServerChangesTest" 2>&1 | grep -E "^    |PASSED|FAILED|^BUILD"
    extra key -> JsonDecodingException: Unexpected JSON token at offset 72: Encountered an unknown key 'room' at path: $
    no done -> SessionDto(id=7, courseId=android, date=2026-10-27, minutes=45, done=false)
    no minutes -> MissingFieldException: Field 'minutes' is required for type with serial name 'com.example.planner.data.SessionDto', but it was missing at path: $
    null minutes -> JsonDecodingException: Unexpected JSON token at offset 67: Unexpected symbol 'n' in numeric literal at path: $.minutes
ServerChangesTest > strict PASSED
    extra key -> SessionDto(id=7, courseId=android, date=2026-10-27, minutes=45, done=false)
    null minutes -> JsonDecodingException: Unexpected JSON token at offset 67: Unexpected symbol 'n' in numeric literal at path: $.minutes
ServerChangesTest > lenient PASSED
    null minutes -> JsonDecodingException: Unexpected JSON token at offset 67: Unexpected symbol 'n' in numeric literal at path: $.minutes
    null done -> SessionDto(id=7, courseId=android, date=2026-10-27, minutes=45, done=false)
ServerChangesTest > coerced PASSED
BUILD SUCCESSFUL in 6s
```

Leia as quatro linhas estritas uma de cada vez, porque cada uma é uma política diferente.

**Uma chave desconhecida é erro por padrão.** O servidor acrescentou `room`, e o `Json` padrão
recusou a sessão inteira. Esse padrão é deliberado do lado da JetBrains, já que uma chave que você
não conhece pode ser uma chave que você escreveu errado, e é o padrão errado para um app num
celular. **Clientes móveis quase sempre ligam `ignoreUnknownKeys = true`**, e o segundo teste mostra
o mesmo payload lido sem problema depois disso. O servidor pode agora acrescentar campos sem quebrar
todas as cópias instaladas do app.

**Uma chave ausente com padrão recebe o padrão.** `done` não veio e virou `false`, porque o DTO diz
`= false`. É o lugar certo para um padrão: no tipo que descreve o fio, onde a próxima pessoa a lê-lo
vê o que o app supõe.

**Uma chave ausente sem padrão é uma `MissingFieldException`.** Não existe um número razoável de
minutos para inventar, então o DTO não tem padrão, e o erro nomeia o campo. É o resultado que você
quer: barulhento, cedo, e nomeando exatamente o que o servidor errou.

**`null` para um tipo não nulo também é erro, e `ignoreUnknownKeys` não muda isso.** O teste
tolerante mostra `null minutes` ainda falhando. A biblioteca tem uma configuração separada para
isso, `coerceInputValues = true`, e o terceiro teste mostra o que ela faz: um `null` em `done`, que
tem padrão, vira `false`, e um `null` em `minutes`, que não tem, continua falhando. É o comportamento
que você quer. Uma sessão sem duração não é uma sessão, e nenhuma configuração deveria inventar uma.

## Configure um `Json`, e compartilhe

Cada configuração acima pertence a uma instância de `Json`, e duas partes de um app que montam a sua
própria vão discordar. Faça uma, com as configurações de que o app precisa, e use-a em todo lugar: na
seção 07 é ela que o conversor do Retrofit recebe.

```kotlin
// app/src/main/java/com/example/planner/data/PlannerJson.kt
package com.example.planner.data

import kotlinx.serialization.json.Json

val plannerJson = Json {
    ignoreUnknownKeys = true
}
```
