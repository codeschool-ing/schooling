---
title: Montando uma, e postando
version: 1
---

**Uma notificação é montada a partir de algumas partes obrigatórias e de um punhado de opcionais**,
com o `NotificationCompat.Builder`: um canal, um ícone pequeno, um título, uma linha de texto e o que
um toque faz. O lembrete do planner precisa exatamente disso.

O ícone pequeno vem primeiro porque é a parte que as pessoas erram. Ele é desenhado pelo sistema na
barra de status, numa cor só, a partir apenas da forma do ícone: **todo pixel não transparente vira a
mesma cor**, então um ícone colorido de launcher vira um quadrado sólido. Ele precisa ser uma
silhueta sobre fundo transparente, que é o que este vetor é, uma página com três linhas:

```xml
<!-- app/src/main/res/drawable/ic_notification.xml -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FFFFFFFF"
        android:pathData="M6,2h12a2,2 0,0 1,2 2v16a2,2 0,0 1,-2 2H6a2,2 0,0 1,-2 -2V4a2,2 0,0 1,2 -2zM8,7v2h8V7zM8,11v2h8v-2zM8,15v2h5v-2z" />
</vector>
```

## A função

```schooling-example
{"language": "kotlin", "file": "app/src/main/java/com/example/planner/notify/Reminders.kt", "parts": [{"code": "// app/src/main/java/com/example/planner/notify/Reminders.kt\npackage com.example.planner.notify\n\nimport android.Manifest\nimport android.annotation.SuppressLint\nimport android.app.PendingIntent\nimport android.content.Context\nimport android.content.Intent\nimport android.content.pm.PackageManager\nimport android.os.Build\nimport androidx.core.app.NotificationCompat\nimport androidx.core.app.NotificationManagerCompat\nimport androidx.core.content.ContextCompat\nimport com.example.planner.MainActivity\nimport com.example.planner.R\n"}, {"code": "const val EXTRA_COURSE_ID = \"courseId\"\n", "note": "O nome do extra é uma constante porque dois outros lugares o leem: a activity que um toque abre, e o teste da seção 06."}, {"code": "fun canNotify(context: Context): Boolean {\n    if (Build.VERSION.SDK_INT >= 33 &&\n        ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) !=\n        PackageManager.PERMISSION_GRANTED\n    ) return false\n    return NotificationManagerCompat.from(context).areNotificationsEnabled()\n}\n", "note": "**Os dois primeiros portões da seção 02, conferidos pelo próprio app.** `Build.VERSION.SDK_INT` é o Android que o celular está rodando; abaixo de 33 não há permissão a ter. Depois, o interruptor do estudante para o app inteiro."}, {"code": "@SuppressLint(\"MissingPermission\") // canNotify checks it on the first line\nfun showReminder(context: Context, courseId: String, courseName: String, minutes: Int): Boolean {\n    if (!canNotify(context)) return false", "note": "O `notify` é marcado como exigindo a permissão, e a verificação do lint não enxerga que o `canNotify` a conferiu em outra função, então o aviso é silenciado aqui, com o motivo ao lado."}, {"code": "    val open = Intent(context, MainActivity::class.java)\n        .putExtra(EXTRA_COURSE_ID, courseId)\n        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)\n    val tap = PendingIntent.getActivity(\n        context,\n        courseId.hashCode(),\n        open,\n        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,\n    )", "note": "O que um toque faz é um `PendingIntent`: um intent que o sistema dispara depois, em nome do app. A seção 06 trata das flags e do request code dele."}, {"code": "    val notification = NotificationCompat.Builder(context, CHANNEL_REMINDERS)\n        .setSmallIcon(R.drawable.ic_notification)\n        .setContentTitle(context.getString(R.string.reminder_title, courseName))\n        .setContentText(context.getString(R.string.reminder_text, minutes))\n        .setContentIntent(tap)\n        .setAutoCancel(true)\n        .build()", "note": "O builder: o canal, o ícone em silhueta, um título e uma linha, o toque, e `setAutoCancel`, que remove a notificação quando ela é tocada."}, {"code": "    NotificationManagerCompat.from(context).notify(courseId.hashCode(), notification)\n    return true\n}", "note": "O id, aqui o `hashCode` do id do curso, é a identidade da notificação na gaveta. Postar de novo com o mesmo id a substitui, o que a seção 06 testa."}]}
```

## O que a gaveta recebe

Um teste não vê a gaveta, mas pode perguntar o que foi postado. Este concede a permissão primeiro,
porque sem ela o primeiro portão barra tudo, que é o assunto da seção 05:

```kotlin
// app/src/test/java/com/example/planner/notify/ReminderTest.kt
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
class ReminderTest {
    private val app = ApplicationProvider.getApplicationContext<Application>()
    private val manager = app.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    @Test fun whatTheShadeReceives() {
        shadowOf(app).grantPermissions(Manifest.permission.POST_NOTIFICATIONS)
        val shown = showReminder(app, "kotlin", "Kotlin", 45)
        val n = shadowOf(manager).allNotifications.single()
        println("shown = $shown")
        println("  title   ${n.extras.getString(NotificationCompat.EXTRA_TITLE)}")
        println("  text    ${n.extras.getString(NotificationCompat.EXTRA_TEXT)}")
        println("  channel ${n.channelId}")
        println("  icon    ${app.resources.getResourceEntryName(n.smallIcon.resId)}")
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*ReminderTest' 2>&1 | grep -E '^    |PASSED|FAILED|^BUILD'
    shown = true
      title   Kotlin today
      text    45 minutes planned. Tap to open the course.
      channel reminders
      icon    ic_notification
ReminderTest > whatTheShadeReceives PASSED
BUILD SUCCESSFUL in 14s
```

Tudo o que o estudante vai ver está ali: o curso no título, os minutos no texto, o canal da seção 03 e
o ícone desta seção. As palavras vieram do `strings.xml`, com o curso e os minutos encaixados pelo
`getString`, e é por isso que um celular em português leria uma frase em português assim que o
`values-pt` tiver uma.

**O `notify` não devolveu nada, e o `showReminder` só respondeu `true` porque conferiu antes.** A
seção 05 mostra o que acontece quando ele não confere.
