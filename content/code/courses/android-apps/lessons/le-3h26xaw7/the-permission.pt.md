---
title: A permissão que o Android 13 trouxe
version: 1
---

**A partir do Android 13, a API 33, um app só pode postar notificações depois de o estudante dizer
sim.** Até então todo app podia, e apps demais usaram notificações para propaganda, então o Google a
tornou uma permissão de tempo de execução, `POST_NOTIFICATIONS`, como a câmera ou a localização. A
aula 12 de `mobile-fundamentals` discute quando pedir uma permissão; a aula 20 deste curso constrói o
pedido. Esta seção é sobre o que o app faz com a resposta, e com os celulares em que não há pergunta.

## Declarada no manifesto, concedida em tempo de execução

O manifesto da seção 03 já traz a linha:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

**Declarar é necessário e não é suficiente.** Sem a linha, o sistema nunca mostra a caixa de diálogo
ao estudante, e o app nunca pode ter a permissão no Android 13 ou posterior. Com ela, a permissão
existe para ser pedida, e é a resposta do estudante que a concede.

Há uma exceção que vale conhecer, da documentação do Google e não executada aqui. Um app que mira a 32 ou menos, instalado no Android 13, tem a caixa de diálogo mostrada pelo próprio sistema, por volta do momento em que o app cria o primeiro canal de notificação. Este projeto mira a 36, então é trabalho
do app pedir, num momento que ele escolhe.

## Quatro celulares, uma função

O `canNotify` da seção 04 é a decisão inteira. Os quatro primeiros testes o rodam em quatro celulares:
Android 15 com e sem a permissão, Android 15 com a permissão e as notificações do app desligadas pelo
estudante, e Android 12, onde a permissão não existe. O `@Config(sdk = [32])` do Robolectric roda um
teste como Android 12. Os dois últimos testes são sobre o que acontece sem o `canNotify`, e o fim
desta seção os lê:

```kotlin
// app/src/test/java/com/example/planner/notify/PermissionTest.kt
package com.example.planner.notify

import android.Manifest
import android.annotation.SuppressLint
import android.app.Application
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.test.core.app.ApplicationProvider
import com.example.planner.R
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
class PermissionTest {
    private val app = ApplicationProvider.getApplicationContext<Application>()
    private val manager = app.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    private fun report(label: String) {
        val shown = showReminder(app, "kotlin", "Kotlin", 45)
        val count = shadowOf(manager).allNotifications.size
        println("API ${Build.VERSION.SDK_INT}, $label: shown = $shown, in the shade = $count")
    }

    @Test fun notGranted() = report("not granted")

    @Test fun granted() {
        shadowOf(app).grantPermissions(Manifest.permission.POST_NOTIFICATIONS)
        report("granted")
    }

    @Test fun grantedButTurnedOff() {
        shadowOf(app).grantPermissions(Manifest.permission.POST_NOTIFICATIONS)
        shadowOf(manager).setNotificationsEnabled(false)
        report("granted, then turned off in settings")
    }

    @Config(sdk = [32])
    @Test fun beforeAndroid13() = report("never asked")

    @Config(sdk = [32])
    @Test fun theCheckAloneOnAndroid12() {
        val r = ContextCompat.checkSelfPermission(app, Manifest.permission.POST_NOTIFICATIONS)
        val answer = if (r == PackageManager.PERMISSION_GRANTED) "granted" else "denied"
        println("API ${Build.VERSION.SDK_INT}, checkSelfPermission without the SDK_INT test: $answer")
    }

    @SuppressLint("MissingPermission")
    @Test fun notifyWithNoCheckAtAll() {
        val n = NotificationCompat.Builder(app, CHANNEL_REMINDERS)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("unchecked")
            .build()
        NotificationManagerCompat.from(app).notify(1, n)
        val count = shadowOf(manager).allNotifications.size
        println("API ${Build.VERSION.SDK_INT}, not granted, notify called anyway: in the shade = $count")
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*PermissionTest.notGranted' 2>&1 | grep '^    '
    API 35, not granted: shown = false, in the shade = 0
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*PermissionTest.granted' 2>&1 | grep '^    '
    API 35, granted: shown = true, in the shade = 1
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*PermissionTest.grantedButTurnedOff' 2>&1 | grep '^    '
    API 35, granted, then turned off in settings: shown = false, in the shade = 0
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*PermissionTest.beforeAndroid13' 2>&1 | grep '^    '
    API 32, never asked: shown = true, in the shade = 1
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*PermissionTest.theCheckAloneOnAndroid12' 2>&1 | grep '^    '
    API 32, checkSelfPermission without the SDK_INT test: granted
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*PermissionTest.notifyWithNoCheckAtAll' 2>&1 | grep '^    '
    API 35, not granted, notify called anyway: in the shade = 1
```

**A resposta é `false` em duas situações diferentes, e elas pedem respostas diferentes.** Não
concedida quer dizer que o app ainda pode pedir, e a aula 20 mostra quando e como. Concedida e depois desligada nas configurações quer dizer que o estudante tomou uma decisão num lugar que o seu app não controla. Pedir de novo não é possível; a resposta honesta é mostrar o lembrete dentro do app e, no máximo, uma linha dizendo onde fica a configuração.

No Android 12 a função respondeu `true` sem nada concedido, porque o `canNotify` pula a conferência da
permissão abaixo de 33. **O teste de `SDK_INT` deixa a regra escrita no código, em vez de depender do
que o `checkSelfPermission` responde sobre uma permissão que aquela versão do Android não define.** O
quinto resultado mostra o que o Android 12 do Robolectric responde para a conferência sozinha:
concedida. O que um celular de verdade com Android 12 responde não foi conferido para este curso, e
com o teste de `SDK_INT` o planner não depende disso.

## O que acontece se o app não confere

O último teste pula todas as conferências e chama o `notify` direto, sem a permissão, no Android 15.
**O Robolectric postou**: uma notificação na gaveta. Isso é um limite do substituto, não a regra. Num
celular, a documentação do Google diz que a notificação de um app sem a permissão é descartada, sem
exceção e sem nada na gaveta; isso **não foi executado** aqui. É mais um motivo para a conferência
ficar no `showReminder`: um teste de um código que a pulasse passaria, e o estudante não veria nada.
