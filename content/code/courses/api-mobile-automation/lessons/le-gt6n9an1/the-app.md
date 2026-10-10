---
title: Tickets, the app the course tests
version: 1
---

**The app every lesson of the second half tests is called Tickets.** It asks boxoffice for the
shows, lists them with their dates and the seats left, and opens a show when you tap it. On the
show's screen a switch offers a reminder on the day, which needs Android's permission to send
notifications. When boxoffice cannot be reached, it shows the list it saw last with a banner saying
so, and when it has never seen one, it says it could not reach the box office.

That is little, on purpose: each feature is there because a later lesson tests it. The list is
for Espresso in lesson 16 and Appium in lesson 15, the switch and its permission for lesson 21, and
the saved list and its banner for lesson 22.

**It is written in Kotlin with nothing but Android's own classes**, no libraries, so that every
line is shown here and nothing is downloaded but what Android Studio brings. Kotlin is Android's
main language; you do not need to write it for this course, only to read what a test is pointed at.

## The project

1. In Android Studio choose *New Project*, then **Empty Views Activity**, and press *Next*.
2. Name it `Tickets`, with the package name `example.tickets`. Set the save location to a folder
   called `tickets` inside your boxoffice project (`~/boxoffice/tickets`), the language to
   **Kotlin**, the minimum SDK to **API 26**, and the build configuration language to *Kotlin DSL*.
3. Press *Finish* and wait for the first build to end. Android Studio downloads Gradle and the
   libraries the template asks for, which takes a few minutes the first time.

The template already has a `MainActivity` and a layout; the files below replace them and add the
rest. In the *Project* panel, switch the view from *Android* to *Project* to see the folders as
they are on disk. Copy each file with the button on its block.

## What the app is allowed to do

The manifest names the app's screens and the permissions it asks for. It replaces the template's;
save it as `tickets/app/src/main/AndroidManifest.xml`:

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

Android refuses plain HTTP unless the app names the addresses it may use it with, and boxoffice is
plain HTTP. This file names the emulator's address for your computer and nothing else. Make the
folder `xml` under `res` and save it as `tickets/app/src/main/res/xml/network_security_config.xml`:

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

## The words and the screens

Every sentence the app shows, in one file. 
Save it as `tickets/app/src/main/res/values/strings.xml`:

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

The list screen: a banner for the offline copy, a button, an error line and the list. Each element
a test needs to find has an `android:id`, which section 06 is about. 
Save it as `tickets/app/src/main/res/layout/activity_main.xml`:

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

One row of the list, a title above a line of detail. 
Save it as `tickets/app/src/main/res/layout/item_show.xml`:

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

The show's screen. Save it as `tickets/app/src/main/res/layout/activity_show.xml`:

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

## The code

The shows, how to ask boxoffice for them, and the copy kept for when it cannot be reached. 
Save it as `tickets/app/src/main/java/example/tickets/Shows.kt`:

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

`baseUrl` is the one line to change for a phone on a cable: `"http://localhost:8080"`, after the
`adb reverse` of the last section. `busy` counts the loads in flight, and lesson 16 is the reason it
exists.

The list screen. It loads the shows on a background thread, because Android forbids network calls
on the thread that draws the screen, and draws the result back on it. 
Save it as `tickets/app/src/main/java/example/tickets/MainActivity.kt`:

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

The show's screen, and the permission it asks for only at the moment it is needed. 
Save it as `tickets/app/src/main/java/example/tickets/ShowActivity.kt`:

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

## Running it

With boxoffice running and the emulator started, press **Run** (the green triangle) in Android
Studio. It builds the APK, installs it on the emulator and opens it: three shows, the third with 4
seats left. Tap one, then use the back button to return.

**This app was not built or run for this course.** The machine the course was recorded on cannot
run Android Studio's build, which downloads from a server that machine cannot reach, and has no
emulator to run it on. What was checked there is that every file above compiles: the resources were
linked by Android's own resource compiler and the Kotlin was compiled against Android 15. A screen
described in this half of the course is described from the code, not from a screenshot.
