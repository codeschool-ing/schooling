---
title: What the planner takes to Android
version: 1
---

Twenty lessons ago the planner was `val minutes = 45`. It ends as a state holder with a sealed state,
fed by a suspending source, observed through a `StateFlow`, tested in virtual time and built by a
Gradle catalog. **Almost every piece of it has a name in Android**, and `android-apps` starts from
that, not from zero:

| in this course | in `android-apps` |
|---|---|
| `WeekModel`, given a scope (lesson 17) | a `ViewModel`, whose scope is `viewModelScope` |
| `WeekUi`, sealed, drawn with `when` (lessons 9, 17) | the state a Compose screen draws, with the same `when` |
| `state.collect { … }` in a screen coroutine | `collectAsStateWithLifecycle()` in a composable |
| `SharedFlow` for messages (lesson 17) | one-time events, such as a snackbar |
| `Dispatchers.IO` for the file (lesson 14) | the same, for the database and the network |
| `runTest`, `backgroundScope` (lesson 18) | the same, plus a dispatcher standing in for Android's main thread |
| `gradle/libs.versions.toml` (lesson 19) | the catalog every new Android project is created with |
| `jvmToolchain(21)`: where does this bytecode run? (lesson 19) | `minSdk`: the oldest Android the app runs on |

What is new there is Android itself: the SDK, the emulator, Jetpack Compose for the screen, Room for
storage, the lifecycle that destroys and rebuilds a screen when the phone rotates. **None of it is new
Kotlin.** Every feature of the language that course uses is in these twenty lessons, and when its code
reads `viewModelScope.launch { _state.update { … } }`, each word in that line has been run here.

The three places outside Android in this lesson are not detours either. A team that writes the app
often writes the server it talks to, in Ktor, sharing the `@Serializable` classes through a
multiplatform module. The skills carry over, and so does the code.
