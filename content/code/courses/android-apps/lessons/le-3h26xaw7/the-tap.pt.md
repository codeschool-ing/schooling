---
title: O toque, e a notificação que se substitui
version: 1
---

**Um toque numa notificação é um intent disparado pelo sistema, mais tarde, em nome do app.** É isso que um `PendingIntent` é: um `Intent` embrulhado com a identidade do seu app, para que o sistema possa abrir a sua activity quando o estudante tocar, mesmo que o processo tenha morrido horas antes. O toque
do planner abre a `MainActivity` com o id do curso como extra; a navegação da aula 9 o levaria dali
para a tela do curso.

Três detalhes no código da seção 04 decidem se isso funciona, e cada um tem uma falha que você só
encontraria num celular:

- **`FLAG_IMMUTABLE`.** Desde o Android 12 todo `PendingIntent` precisa dizer se outro app pode
  preencher as lacunas dele, e criar um sem dizer lança uma `IllegalArgumentException`. Imutável é a
  resposta certa sempre que nada precisa mudar o intent, o que é quase sempre: quer dizer que o
  sistema dispara exatamente o que você montou.
- **O request code, `courseId.hashCode()`.** O sistema trata dois `PendingIntent`s como o mesmo se os
  intents coincidem fora os extras, e guarda um só. Com um request code constante, o lembrete de Kotlin
  e o de SQL dividiriam um `PendingIntent`, e com `FLAG_UPDATE_CURRENT` os dois toques abririam o
  curso postado por último. Um request code diferente por curso os mantém separados.
- **`FLAG_ACTIVITY_NEW_TASK` com `FLAG_ACTIVITY_CLEAR_TOP`.** O toque abre a activity de fora do app,
  o que precisa de uma tarefa onde colocá-la; limpar o topo traz de volta a `MainActivity` existente
  em vez de empilhar uma segunda na pilha de volta que a aula 9 descreve.

## Uma notificação por curso

O id da notificação no `notify` faz o mesmo papel na gaveta. Postar com um id que já está aparecendo
**substitui** aquela notificação em vez de acrescentar outra, que é o que um lembrete quer: se o
planner recalcula os minutos de Kotlin, o estudante deve ver o número novo, uma vez.

```kotlin
// app/src/test/java/com/example/planner/notify/ReplaceTest.kt
package com.example.planner.notify

import android.Manifest
import android.app.Application
import android.app.NotificationManager
import android.content.Context
import androidx.core.app.NotificationCompat
import androidx.test.core.app.ApplicationProvider
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf

@RunWith(RobolectricTestRunner::class)
class ReplaceTest {
    private val app = ApplicationProvider.getApplicationContext<Application>()
    private val manager = app.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    @Test fun oneNotificationPerCourseAndATapThatOpensIt() {
        shadowOf(app).grantPermissions(Manifest.permission.POST_NOTIFICATIONS)
        showReminder(app, "kotlin", "Kotlin", 45)
        showReminder(app, "kotlin", "Kotlin", 90)
        showReminder(app, "android", "Android Apps", 25)
        val all = shadowOf(manager).allNotifications
        println("three calls, two courses: ${all.size} notifications")
        for (n in all) {
            val tap = shadowOf(n.contentIntent).savedIntent
            println("  ${n.extras.getString(NotificationCompat.EXTRA_TEXT)}")
            println("    tap opens ${tap.component?.shortClassName}, courseId=${tap.getStringExtra(EXTRA_COURSE_ID)}" +
                ", immutable=${n.contentIntent.isImmutable}, auto-cancel=${n.flags and android.app.Notification.FLAG_AUTO_CANCEL != 0}")
        }
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*ReplaceTest' 2>&1 | grep -E '^    |PASSED|FAILED|^BUILD'
    three calls, two courses: 2 notifications
      25 minutes planned. Tap to open the course.
        tap opens .MainActivity, courseId=android, immutable=true, auto-cancel=true
      90 minutes planned. Tap to open the course.
        tap opens .MainActivity, courseId=kotlin, immutable=true, auto-cancel=true
ReplaceTest > oneNotificationPerCourseAndATapThatOpensIt PASSED
BUILD SUCCESSFUL in 31s
```

Três chamadas, duas notificações. Os 45 minutos de Kotlin foram substituídos pelos 90, e Android Apps
ganhou a sua. Cada toque abre a `MainActivity` com o seu curso, o intent é imutável e o auto-cancel
está ligado, então um toque também tira a notificação da gaveta.

**Um `hashCode` é um id conveniente, não um garantido.** Duas strings diferentes podem ter o mesmo, e
então dois cursos se substituiriam. Com três cursos é um risco que ninguém vai encontrar; um app com
milhares de itens guardaria um id inteiro de verdade para cada um, que é o que o Room da aula 15 dá a
cada sessão.

## Agrupar, e quando não mandar nada

A documentação do Google descreve grupos, que dobram várias notificações de um app numa entrada que
se expande, e uma notificação de resumo para o grupo. Um planner mandando um lembrete por curso num
dia cheio é o caso para o qual eles existem. **A melhor resposta muitas vezes é menos notificações**:
um lembrete por dia que nomeia os cursos do dia, em vez de três. É uma decisão de produto mais do que
técnica, e a aula 17 de `mobile-fundamentals` defende esse ponto.
