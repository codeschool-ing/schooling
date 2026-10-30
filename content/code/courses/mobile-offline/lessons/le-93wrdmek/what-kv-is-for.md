---
title: What key-value storage is for
version: 1
---

**Key-value storage is for a handful of small settings the app reads at launch, and for nothing
that grows.** The theme, the day the week starts on, whether reminders are on, the last course the
person opened. Each is one name and one small value, and the app wants all of them before it draws
its first screen.

The usual mistake is to treat it as a small database because it is the easiest storage to reach.
It is not one. **Every platform's key-value store keeps the whole set in one file, reads all of it
into memory, and rewrites all of it on a change.** That is exactly right for ten settings and
exactly wrong for a thousand sessions, and the last section of this lesson measures the
difference.

## The same three settings on three platforms

*These listings were not run for this course; they are quoted from the Android, Apple and React
Native Async Storage documentation, as each documents its own store.*

On Android, **Jetpack DataStore** replaces `SharedPreferences`, which Google's documentation now
steers new code away from. A write is a suspending function and a read is a `Flow`, so neither
blocks the screen:

```kotlin
val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "settings")
val THEME = stringPreferencesKey("theme")

suspend fun setTheme(context: Context, theme: String) {
    context.dataStore.edit { prefs -> prefs[THEME] = theme }
}

fun theme(context: Context): Flow<String> =
    context.dataStore.data.map { prefs -> prefs[THEME] ?: "light" }
```

On iOS, **`UserDefaults`** writes the property list lesson 1 found in `Library/Preferences/`, and
SwiftUI's `@AppStorage` is the same store with a property wrapper around it:

```swift
UserDefaults.standard.set("dark", forKey: "theme")
let theme = UserDefaults.standard.string(forKey: "theme") ?? "light"

struct SettingsView: View {
    @AppStorage("theme") var theme = "light"
    var body: some View { Text(theme) }
}
```

In React Native, **Async Storage** stores strings and answers with promises:

```typescript
import AsyncStorage from "@react-native-async-storage/async-storage";

await AsyncStorage.setItem("theme", "dark");
const theme = (await AsyncStorage.getItem("theme")) ?? "light";
```

## And MMKV

**MMKV** is a key-value store Tencent wrote for WeChat and published for Android and iOS, and
`react-native-mmkv` brings it to React Native. It maps its file into memory, so a read is a memory
access rather than a trip to the disk, and the calls are synchronous. That is its appeal, and the
reason to keep it for the same small settings: being fast does not change what belongs there.

| store | platform | read | write |
|---|---|---|---|
| DataStore | Android | `Flow`, off the main thread | suspending `edit` |
| `SharedPreferences` | Android | synchronous, from memory | `apply()` in the background, `commit()` blocking |
| `UserDefaults` | iOS | synchronous, from memory | the system saves it |
| Async Storage | React Native | promise | promise |
| MMKV | all three | synchronous, mapped memory | synchronous |

The table differs in the columns that matter least. What all five share is the shape this lesson
builds next: names, small values, one file.
