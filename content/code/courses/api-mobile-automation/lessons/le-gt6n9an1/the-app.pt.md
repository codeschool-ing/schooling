---
title: Tickets, o app que o curso testa
version: 1
---

**O app que toda lição da segunda metade testa se chama Tickets.** Ele pede os espetáculos ao
boxoffice, lista-os com as datas e os lugares que sobram, e abre um espetáculo quando você toca nele.
Na tela do espetáculo, uma chave oferece um lembrete no dia, o que exige a permissão do Android para
mandar notificações. Quando o boxoffice não responde, ele mostra a última lista que viu com uma faixa
dizendo isso, e quando nunca viu nenhuma, diz que não conseguiu falar com a bilheteria.

É pouco, de propósito: cada recurso está lá porque uma lição seguinte o testa. A lista é para o
Espresso da lição 16 e o Appium da lição 15, a chave e a permissão dela para a lição 21, e a lista
guardada com a faixa para a lição 22.

**Ele é escrito em Kotlin só com as classes do próprio Android**, sem bibliotecas, para que cada linha
apareça aqui e nada seja baixado além do que o Android Studio traz. Kotlin é a linguagem principal do
Android; você não precisa escrevê-la neste curso, só ler aquilo para onde um teste aponta.

## O projeto

1. No Android Studio escolha *New Project*, depois **Empty Views Activity**, e aperte *Next*.
2. Dê o nome `Tickets`, com o nome de pacote `example.tickets`. Defina o local como uma pasta
   chamada `tickets` dentro do seu projeto boxoffice (`~/boxoffice/tickets`), a linguagem como
   **Kotlin**, o SDK mínimo como **API 26** e a linguagem de configuração do build como *Kotlin DSL*.
3. Aperte *Finish* e espere o primeiro build terminar. O Android Studio baixa o Gradle e as
   bibliotecas que o modelo pede, o que leva alguns minutos da primeira vez.

O modelo já tem uma `MainActivity` e um layout; os arquivos abaixo os substituem e acrescentam o
resto. No painel *Project*, troque a visão de *Android* para *Project* para ver as pastas como estão
no disco. Copie cada arquivo com o botão do bloco.

## O que o app tem permissão de fazer

O manifesto nomeia as telas do app e as permissões que ele pede. Ele substitui o do modelo;
salve como `tickets/app/src/main/AndroidManifest.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- tickets/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <application
        android:label="@string/app_name"
        android:networkSecurityConfig="@xml/network_security_config"
        android:theme="@android:style/Theme.Material.Light.DarkActionBar">

        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <activity android:name=".ShowActivity" />
    </application>
</manifest>
```

O Android recusa HTTP puro a menos que o app nomeie os endereços com que pode usá-lo, e o boxoffice é
HTTP puro. Este arquivo nomeia o endereço do emulador para o seu computador e nada mais. Crie a pasta
`xml` dentro de `res` e salve como `tickets/app/src/main/res/xml/network_security_config.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- tickets/app/src/main/res/xml/network_security_config.xml
     boxoffice speaks plain HTTP, which Android refuses unless an address is named here.
     10.0.2.2 is the computer running the emulator; nothing else is allowed. -->
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="false">10.0.2.2</domain>
        <domain includeSubdomains="false">localhost</domain>
    </domain-config>
</network-security-config>
```

## As palavras e as telas

Toda frase que o app mostra, num arquivo só. Os textos ficam em inglês, como no código, e a seção 06
diz por que um teste não deve depender deles. Salve como
`tickets/app/src/main/res/values/strings.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- tickets/app/src/main/res/values/strings.xml -->
<resources>
    <string name="app_name">Tickets</string>
    <string name="refresh">Refresh</string>
    <string name="seats_left">%1$d seats left</string>
    <string name="sold_out">Sold out</string>
    <string name="offline">Offline: showing the list from %1$s</string>
    <string name="failed">Could not reach the box office. Check the connection and press Refresh.</string>
    <string name="remind">Remind me on the day</string>
    <string name="remind_denied">Notifications are off for Tickets, so no reminder can be sent.</string>
</resources>
```

A tela da lista: uma faixa para a cópia offline, um botão, uma linha de erro e a lista. Cada elemento
que um teste precisa encontrar tem um `android:id`, que é o assunto da seção 06. Salve como
`tickets/app/src/main/res/layout/activity_main.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- tickets/app/src/main/res/layout/activity_main.xml -->
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:fitsSystemWindows="true"
    android:orientation="vertical"
    android:padding="16dp">

    <TextView
        android:id="@+id/banner"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:padding="8dp"
        android:background="#FFF3C4"
        android:textColor="#3D2E00"
        android:visibility="gone" />

    <Button
        android:id="@+id/refresh"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="@string/refresh" />

    <TextView
        android:id="@+id/error"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="@string/failed"
        android:visibility="gone" />

    <ListView
        android:id="@+id/shows"
        android:layout_width="match_parent"
        android:layout_height="match_parent" />
</LinearLayout>
```

Uma linha da lista, um título acima de uma linha de detalhe. Salve como
`tickets/app/src/main/res/layout/item_show.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- tickets/app/src/main/res/layout/item_show.xml -->
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:orientation="vertical"
    android:paddingVertical="12dp">

    <TextView
        android:id="@+id/title"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:textSize="18sp" />

    <TextView
        android:id="@+id/detail"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content" />
</LinearLayout>
```

A tela do espetáculo. Salve como `tickets/app/src/main/res/layout/activity_show.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- tickets/app/src/main/res/layout/activity_show.xml -->
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:fitsSystemWindows="true"
    android:orientation="vertical"
    android:padding="16dp">

    <TextView
        android:id="@+id/title"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:textSize="22sp" />

    <TextView
        android:id="@+id/time"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content" />

    <TextView
        android:id="@+id/price"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content" />

    <TextView
        android:id="@+id/seats"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content" />

    <Switch
        android:id="@+id/remind"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="24dp"
        android:text="@string/remind" />

    <TextView
        android:id="@+id/remind_denied"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="@string/remind_denied"
        android:visibility="gone" />
</LinearLayout>
```

## O código

Os espetáculos, como pedi-los ao boxoffice, e a cópia guardada para quando ele não responde. Salve
como `tickets/app/src/main/java/example/tickets/Shows.kt`:

```kotlin
// tickets/app/src/main/java/example/tickets/Shows.kt
package example.tickets

import android.content.Context
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

data class Show(
    val id: String,
    val title: String,
    val startsAt: String,
    val priceCents: Int,
    val seatsLeft: Int,
) {
    /** "R$ 80,00", from whole cents and never through a floating-point number. */
    fun price() = "R$ %d,%02d".format(priceCents / 100, priceCents % 100)

    /** "2026-11-06T20:00:00-03:00" becomes "06/11 20:00", the time as the theatre states it. */
    fun time() = startsAt.substring(8, 10) + "/" + startsAt.substring(5, 7) + " " + startsAt.substring(11, 16)
}

/** What a load produced: a fresh list, the copy kept from the last one, or nothing at all. */
sealed class Loaded {
    data class Fresh(val shows: List<Show>) : Loaded()
    data class Offline(val shows: List<Show>, val savedAt: String) : Loaded()
    object Failed : Loaded()
}

object Shows {
    /** boxoffice as the emulator sees it: 10.0.2.2 is the computer the emulator runs on. */
    var baseUrl = "http://10.0.2.2:8080"

    /** How many loads are running. A test waits until it is back to zero (lesson 16). */
    @Volatile
    var busy = 0

    fun parse(body: String): List<Show> {
        val list = JSONObject(body).getJSONArray("shows")
        return (0 until list.length()).map { i ->
            val s = list.getJSONObject(i)
            Show(s.getString("id"), s.getString("title"), s.getString("starts_at"),
                s.getInt("price_cents"), s.getInt("seats_left"))
        }
    }

    /** Asks boxoffice for the shows. Runs on a background thread, never on the main one. */
    fun load(context: Context): Loaded {
        val saved = context.getSharedPreferences("shows", Context.MODE_PRIVATE)
        return try {
            val connection = URL("$baseUrl/v1/shows").openConnection() as HttpURLConnection
            connection.connectTimeout = 5000
            connection.readTimeout = 5000
            val body = connection.inputStream.bufferedReader().use { it.readText() }
            val shows = parse(body)
            val now = SimpleDateFormat("HH:mm", Locale.ROOT).format(Date())
            saved.edit().putString("body", body).putString("at", now).apply()
            Loaded.Fresh(shows)
        } catch (e: Exception) {
            val body = saved.getString("body", null) ?: return Loaded.Failed
            Loaded.Offline(parse(body), saved.getString("at", "") ?: "")
        }
    }
}
```

`baseUrl` é a única linha a mudar para um celular no cabo: `"http://localhost:8080"`, depois do
`adb reverse` da seção anterior. `busy` conta as cargas em andamento, e a lição 16 é o motivo de ele
existir.

A tela da lista. Ela carrega os espetáculos numa thread de fundo, porque o Android proíbe chamadas de
rede na thread que desenha a tela, e desenha o resultado de volta nela. Salve como
`tickets/app/src/main/java/example/tickets/MainActivity.kt`:

```kotlin
// tickets/app/src/main/java/example/tickets/MainActivity.kt
package example.tickets

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.ListView
import android.widget.TextView

class MainActivity : Activity() {
    private lateinit var list: ListView
    private lateinit var banner: TextView
    private lateinit var error: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        list = findViewById(R.id.shows)
        banner = findViewById(R.id.banner)
        error = findViewById(R.id.error)
        findViewById<Button>(R.id.refresh).setOnClickListener { refresh() }
        list.setOnItemClickListener { _, _, position, _ ->
            val show = list.getItemAtPosition(position) as Show
            startActivity(Intent(this, ShowActivity::class.java)
                .putExtra("id", show.id)
                .putExtra("title", show.title)
                .putExtra("time", show.time())
                .putExtra("price", show.price())
                .putExtra("seats", show.seatsLeft))
        }
        refresh()
    }

    private fun refresh() {
        Shows.busy++
        Thread {
            val loaded = Shows.load(this)
            runOnUiThread {
                display(loaded)
                Shows.busy--
            }
        }.start()
    }

    private fun display(loaded: Loaded) {
        banner.visibility = View.GONE
        error.visibility = View.GONE
        when (loaded) {
            is Loaded.Fresh -> list.adapter = ShowAdapter(loaded.shows)
            is Loaded.Offline -> {
                list.adapter = ShowAdapter(loaded.shows)
                banner.text = getString(R.string.offline, loaded.savedAt)
                banner.visibility = View.VISIBLE
            }
            Loaded.Failed -> {
                list.adapter = ShowAdapter(emptyList())
                error.visibility = View.VISIBLE
            }
        }
    }

    private inner class ShowAdapter(shows: List<Show>) :
        ArrayAdapter<Show>(this, R.layout.item_show, R.id.title, shows) {
        override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
            val row = super.getView(position, convertView, parent)
            val show = getItem(position)!!
            row.findViewById<TextView>(R.id.title).text = show.title
            row.findViewById<TextView>(R.id.detail).text = show.time() + " · " +
                if (show.seatsLeft == 0) getString(R.string.sold_out)
                else getString(R.string.seats_left, show.seatsLeft)
            return row
        }
    }
}
```

A tela do espetáculo, e a permissão que ela pede só no momento em que é necessária. Salve como
`tickets/app/src/main/java/example/tickets/ShowActivity.kt`:

```kotlin
// tickets/app/src/main/java/example/tickets/ShowActivity.kt
package example.tickets

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.view.View
import android.widget.Switch
import android.widget.TextView

class ShowActivity : Activity() {
    private lateinit var remind: Switch
    private lateinit var denied: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_show)
        findViewById<TextView>(R.id.title).text = intent.getStringExtra("title")
        findViewById<TextView>(R.id.time).text = intent.getStringExtra("time")
        findViewById<TextView>(R.id.price).text = intent.getStringExtra("price")
        findViewById<TextView>(R.id.seats).text =
            getString(R.string.seats_left, intent.getIntExtra("seats", 0))
        remind = findViewById(R.id.remind)
        denied = findViewById(R.id.remind_denied)
        remind.setOnCheckedChangeListener { _, on -> if (on) askToNotify() }
    }

    /** From Android 13 on, notifications need the person's permission, asked at the moment it matters. */
    private fun askToNotify() {
        if (Build.VERSION.SDK_INT < 33) return
        if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) return
        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), ASK)
    }

    override fun onRequestPermissionsResult(code: Int, permissions: Array<String>, results: IntArray) {
        super.onRequestPermissionsResult(code, permissions, results)
        if (code != ASK) return
        val granted = results.firstOrNull() == PackageManager.PERMISSION_GRANTED
        remind.isChecked = granted
        denied.visibility = if (granted) View.GONE else View.VISIBLE
    }

    private companion object {
        const val ASK = 1
    }
}
```

## Rodando

Com o boxoffice rodando e o emulador iniciado, aperte **Run** (o triângulo verde) no Android Studio.
Ele compila o APK, instala no emulador e o abre: três espetáculos, o terceiro com 4 lugares
sobrando. Toque num deles, depois use o botão voltar para retornar.

**Este app não foi compilado nem executado para este curso.** A máquina onde o curso foi gravado não
consegue rodar o build do Android Studio, que baixa de um servidor que essa máquina não alcança, e
não tem emulador onde rodá-lo. O que foi conferido ali é que todo arquivo acima compila: os recursos
foram ligados pelo próprio compilador de recursos do Android e o Kotlin foi compilado contra o
Android 15. Uma tela descrita nesta metade do curso é descrita a partir do código, não de uma
captura de tela.
