---
title: What the app keeps when Android takes it away
version: 1
---

**An app on a phone is not open or closed. Android moves it between states, and it may end the
app's process without asking.** The person presses Home, and Tickets goes to the background, still
in memory. Another app needs that memory, and Android kills Tickets's process while it waits there.
The person comes back through the list of recent apps. Android starts a new process and rebuilds
the screen they left, from what the old one saved. To the person nothing happened. To the app,
everything it held in memory is gone.

The common belief is that this is rare and belongs to old phones. It happens to every app, every
day, on any phone that runs out of memory. And a second family of events does the same to a single
screen. **Turning the phone, switching to the dark theme, changing the language or the font size
destroys the activity and creates a new one.** The new one is in the same process, and draws itself
for the new configuration.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Four states in a row. In front, resumed; the Home button sends the app to the background, stopped and still in memory; am kill ends the process while it waits there, though the app is still in Recents; the icon brings it back, rebuilt in a new process. Below, a rotation or a change of theme destroys the screen and creates it again in the same process. A rebuilt screen gets back its intent with its extras and what its views saved, such as a switch and a scroll position, and loses what code set on a view and, after a process death, everything in memory.\"><defs><marker id=\"f21states-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"140\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"90\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">in front</text><text x=\"90\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">resumed</text><rect x=\"200\" y=\"70\" width=\"140\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"270\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">in the background</text><text x=\"270\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">stopped, in memory</text><rect x=\"380\" y=\"70\" width=\"140\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"450\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">process killed</text><text x=\"450\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">still in Recents</text><rect x=\"560\" y=\"70\" width=\"140\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"630\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">rebuilt</text><text x=\"630\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">a new process</text><line x1=\"160\" y1=\"90\" x2=\"200\" y2=\"90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f21states-ah)\"></line><text x=\"180\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">HOME</text><line x1=\"340\" y1=\"90\" x2=\"380\" y2=\"90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f21states-ah)\"></line><text x=\"360\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">am kill</text><line x1=\"520\" y1=\"90\" x2=\"560\" y2=\"90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f21states-ah)\"></line><text x=\"540\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">the icon</text><rect x=\"380\" y=\"160\" width=\"320\" height=\"120\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"540\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a rebuilt screen gets back</text><text x=\"540\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">its intent, with the extras</text><text x=\"540\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">what its views saved: a switch, a scroll</text><text x=\"540\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">it loses what code set on a view,</text><text x=\"540\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">and after a process death, all memory</text><line x1=\"630\" y1=\"124\" x2=\"630\" y2=\"158\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f21states-ah)\"></line><rect x=\"20\" y=\"200\" width=\"180\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a rotation, a theme</text><text x=\"110\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">destroyed and created again</text><line x1=\"200\" y1=\"226\" x2=\"376\" y2=\"226\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f21states-ah)\"></line><text x=\"288\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">same process</text><line x1=\"90\" y1=\"124\" x2=\"90\" y2=\"198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f21states-ah)\"></line><text x=\"98\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">turned</text></svg>", "caption": "Two roads to a rebuilt screen. A rotation keeps the process, so objects in memory survive it; a process death does not, and only the saved state comes back."}
```

## What survives, in general

When Android recreates an activity, from a rotation or after its process was killed, the new one
gets three things from the old one:

- the intent it was started with, extras included;
- the state its views save themselves. A view with an `android:id` saves what the person
  changed in it: whether a switch is on, the text typed into a field, how far a list was scrolled.
  It does not save what the code set on it: a text, a colour, whether it is visible;
- what the activity saved itself in `onSaveInstanceState`, a method Tickets does not have.

Files and `SharedPreferences` are on disk and survive everything but an uninstall. **Anything else
in memory survives a rotation and not a process death**: fields of a Kotlin `object`, caches,
counters.

## What Tickets keeps, read from its code

```
ana@laptop:~/boxoffice$ grep -n 'getSharedPreferences\|getStringExtra\|getIntExtra\|var baseUrl\|visibility =' tickets/app/src/main/java/example/tickets/*.kt
tickets/app/src/main/java/example/tickets/MainActivity.kt:50:        banner.visibility = View.GONE
tickets/app/src/main/java/example/tickets/MainActivity.kt:51:        error.visibility = View.GONE
tickets/app/src/main/java/example/tickets/MainActivity.kt:57:                banner.visibility = View.VISIBLE
tickets/app/src/main/java/example/tickets/MainActivity.kt:61:                error.visibility = View.VISIBLE
tickets/app/src/main/java/example/tickets/ShowActivity.kt:20:        findViewById<TextView>(R.id.title).text = intent.getStringExtra("title")
tickets/app/src/main/java/example/tickets/ShowActivity.kt:21:        findViewById<TextView>(R.id.time).text = intent.getStringExtra("time")
tickets/app/src/main/java/example/tickets/ShowActivity.kt:22:        findViewById<TextView>(R.id.price).text = intent.getStringExtra("price")
tickets/app/src/main/java/example/tickets/ShowActivity.kt:24:            getString(R.string.seats_left, intent.getIntExtra("seats", 0))
tickets/app/src/main/java/example/tickets/ShowActivity.kt:42:        denied.visibility = if (granted) View.GONE else View.VISIBLE
tickets/app/src/main/java/example/tickets/Shows.kt:35:    var baseUrl = "http://10.0.2.2:8080"
tickets/app/src/main/java/example/tickets/Shows.kt:52:        val saved = context.getSharedPreferences("shows", Context.MODE_PRIVATE)
```

Put next to the rules above, that output predicts what each event does to Tickets. It is a
prediction, made from the code, and the tests of section 05 are what check it:

| | a rotation | the process killed in the background |
|---|---|---|
| **the list** | `onCreate` runs again, so the shows are fetched again: a second request, and the banner worked out again | the same |
| **the saved copy** (`getSharedPreferences`, `Shows.kt` line 52) | kept | kept: it is a file |
| **a show's title, time, price and seats** (lines 20 to 24) | kept: they come from the intent | kept, from the intent; the seats are the number at the moment of the tap, never refreshed |
| **the reminder switch** | kept: a `Switch` with an id saves whether it is on | kept, the same way |
| **the line `remind_denied`** (line 42) | **lost**: its visibility was set by code, which the view does not save | lost |
| **`Shows.baseUrl`** (line 35) | kept | back to `http://10.0.2.2:8080`: a new process starts the object again |

**One row is a defect.** A person who refused notifications and then turns the phone sees the
switch off, and no longer sees the sentence saying why. Section 03's table called that the state an
app must explain. And nothing in the code reloads the list when the person comes back from the
background, so seat counts on the screen can be hours old. That one is a product question to raise
rather than a defect, since the Refresh button is there.

## Moving the app between states with adb

On the emulator of lesson 14, from a terminal, with Tickets open on the show's screen:

```sh
adb shell input keyevent KEYCODE_HOME
adb shell am kill example.tickets
adb shell am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -n example.tickets/.MainActivity
adb shell am force-stop example.tickets
adb shell settings put system accelerometer_rotation 0
adb shell settings put system user_rotation 1
```

The first line presses Home. The second kills the app's process, and only if it is in the
background, which is what Android itself does when it needs memory. The third sends the intent the
app's icon sends. It brings back the task with the show's screen rebuilt on top. **`force-stop` is
different from `kill`.** It is what *Force stop* in the app's settings does, a person's decision to
end the app, and Android restores nothing afterwards. The next start is a cold one on the list. The
last two turn off automatic rotation and turn the screen to landscape; `user_rotation 0` turns it
back. None of these commands was run for this course: adb on the recording machine has no device
to send them to.

By hand, *Developer options* has a switch called *Don't keep activities*, which destroys every
activity the moment it leaves the screen. It is a quick way to find a screen that loses something,
with nothing but your thumb.

## The same from Appium

The UiAutomator2 driver has a `mobile:` command for each move, called through `driver.execute`:

| command | what it does |
|---|---|
| `mobile: backgroundApp`, `{ seconds: 5 }` | Home, and back after five seconds; a negative number leaves the app in the background |
| `mobile: activateApp`, `{ appId }` | brings the app to the front, as its icon does |
| `mobile: terminateApp`, `{ appId }` | `force-stop`: not a process death, since nothing is restored |
| `mobile: queryAppState`, `{ appId }` | `0` not installed, `1` not running, `3` in the background, `4` in front |
| `driver.setOrientation('LANDSCAPE')` | turns the screen; an older WebDriver command that Appium kept, not a `mobile:` one |

**A process death needs `am kill`, which Appium can only send through a shell on the device**,
`mobile: shell`. A shell on the device runs any command at all. So Appium refuses it unless the
server was started with `--allow-insecure` naming that feature. Stop the server of lesson 15 with
Ctrl-C first. With the feature named alone, the way older guides write it, Appium 3 refuses to
start:

```
ana@laptop:~/boxoffice$ npx appium --address 127.0.0.1 --allow-insecure adb_shell 2>&1 | grep '^Error'
Error: The full feature name must include both the destination automation name or the '*' wildcard to apply the feature to all installed drivers, and the feature name split by a colon. Got 'adb_shell' instead
```

It wants the feature named together with the driver it is for:

```
ana@laptop:~/boxoffice$ npx appium --address 127.0.0.1 --allow-insecure uiautomator2:adb_shell
[Appium] Non-default server args:
[Appium] { address: '127.0.0.1', allowInsecure: [ 'uiautomator2:adb_shell' ] }
[Appium] Appium REST http interface listener started on http://127.0.0.1:4723
```

That server will run shell commands for any client that reaches it. That is why lesson 15 bound it
to `127.0.0.1`, and why a shared server in an office or a device cloud should not be started this
way. Start it like this only for the test that needs it.
