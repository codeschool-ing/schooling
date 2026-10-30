---
title: O que chega pelo fio, e o tipo em que ele vira
version: 1
---

**Um servidor manda texto, e o app precisa de objetos.** Em algum ponto entre os bytes que o
Retrofit recebeu na aula 13 e o `StudySession` que uma tela desenha, uma string como a de baixo
precisa virar um valor Kotlin, campo por campo, com cada campo conferido. Esse passo é a
**desserialização**, o inverso é a **serialização**, e esta aula é sobre fazer os dois sem escrever
o parsing você mesmo.

Esta é uma sessão de estudo como o servidor do planner a manda:

```json
{"id": 7, "course_id": "android", "date": "2026-10-27", "minutes": 45, "done": false}
```

Três coisas nela não batem com o modelo que o app usa. O servidor escreve `course_id` em snake case
onde o Kotlin escreve `courseId`; a data é uma string, onde o app quer um `LocalDate` que dá para
comparar e somar dias; e nada garante que o servidor de amanhã não vá acrescentar uma sexta chave.
Cada uma dessas é uma seção desta aula.

## Dois tipos, de propósito

O modelo é o que todas as aulas deste curso usam:

```kotlin
// app/src/main/java/com/example/planner/data/Model.kt
package com.example.planner.data

import java.time.LocalDate

data class Course(val id: String, val name: String)

data class StudySession(
    val id: Long,
    val courseId: String,
    val date: LocalDate,
    val minutes: Int,
    val done: Boolean = false,
)
```

**O JSON não vai direto para o `StudySession`.** Ele vai para uma segunda classe com o formato do
JSON, um **DTO**, de *data transfer object*, e uma função pequena transforma um no outro. Parece
duplicação e é o contrário: o DTO muda quando o servidor muda, o modelo muda quando o app muda, e a
função entre os dois é o único lugar que conhece ambos. Uma tela que lesse o DTO direto quebraria
no dia em que o servidor renomeasse um campo, e todos os testes dela também.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Uma sessão de estudo viaja da esquerda para a direita. O servidor manda texto JSON com course_id em snake case e a data como string. Uma biblioteca de serialização o transforma num SessionDto, os mesmos campos com os mesmos nomes. Uma função chamada toDomain transforma o DTO num StudySession, com courseId e um LocalDate. As telas só veem o StudySession. Uma mudança no servidor para no DTO e na função.\"><rect x=\"0\" y=\"0\" width=\"720\" height=\"200\" fill=\"var(--ink)\"></rect><rect x=\"20\" y=\"50\" width=\"190\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"115\" y=\"74\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">texto JSON</text><text x=\"115\" y=\"96\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"course_id\"</text><text x=\"115\" y=\"114\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"2026-10-27\"</text><rect x=\"265\" y=\"50\" width=\"190\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"360\" y=\"74\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">SessionDto</text><text x=\"360\" y=\"96\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no formato do servidor</text><text x=\"360\" y=\"114\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">muda quando ele muda</text><rect x=\"510\" y=\"50\" width=\"190\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"605\" y=\"74\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">StudySession</text><text x=\"605\" y=\"96\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no formato do app</text><text x=\"605\" y=\"114\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o que toda tela lê</text><line x1=\"212\" y1=\"90\" x2=\"262\" y2=\"90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><line x1=\"457\" y1=\"90\" x2=\"507\" y2=\"90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><text x=\"237\" y=\"152\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a biblioteca</text><text x=\"482\" y=\"152\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">toDomain()</text><text x=\"360\" y=\"182\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">uma mudança no servidor para aqui, no DTO e na função</text></svg>", "caption": "O JSON é lido num DTO no formato do servidor, e uma função o transforma no modelo que as telas usam."}
```

## Duas bibliotecas que fazem o mesmo trabalho

Esta aula faz o trabalho duas vezes, com as duas bibliotecas que um código Android tem mais chance
de usar:

- **kotlinx.serialization**, da JetBrains, quem faz o Kotlin. Um plugin do compilador escreve o
  código que lê e escreve cada classe enquanto o seu código compila, então nada é procurado por
  reflexão quando o app roda.
- **Moshi**, da Square, a empresa por trás do Retrofit e do OkHttp. Ele lê e escreve por meio de
  adaptadores e, com o gerador de código dele, rodado pelo KSP, esses adaptadores também são gerados
  durante o build.

O código novo deste curso usa kotlinx.serialization, porque é do próprio Kotlin e as rotas tipadas
da aula 9 já dependem do plugin dele. O Moshi ganha a seção 06 porque muito código Android existente
o usa, e as duas discordam num padrão que importa.
