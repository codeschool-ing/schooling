---
title: The planner's week, as a state holder
version: 1
---

Everything since lesson 9 meets here. Lesson 9's sealed state for a screen, lesson 13's failures as
values, lesson 15's scope and this lesson's backing `StateFlow` become one class: **a state holder that
loads the week, exposes its state as a `StateFlow` of a sealed type, and changes it only through its
own functions**. On Android this class is called a ViewModel, and `android-apps` writes the same one with
the framework's base class.

```schooling-example
{"language": "kotlin", "file": "src/main/kotlin/WeekModel.kt", "parts": [{"code": "import kotlinx.coroutines.CoroutineScope\nimport kotlinx.coroutines.delay\nimport kotlinx.coroutines.flow.MutableStateFlow\nimport kotlinx.coroutines.flow.StateFlow\nimport kotlinx.coroutines.flow.asStateFlow\nimport kotlinx.coroutines.flow.update\nimport kotlinx.coroutines.launch\nimport kotlinx.coroutines.runBlocking\nimport java.io.IOException"}, {"code": "sealed interface WeekUi {\n    data object Loading : WeekUi\n    data class Loaded(val sessions: List<Int>) : WeekUi\n    data class Failed(val message: String) : WeekUi\n}", "note": "Lesson 9's three states, named for this project so they do not collide with anything in it."}, {"code": "class WeekModel(\n    private val scope: CoroutineScope,\n    private val source: suspend () -> List<Int>,\n) {\n    private val _state = MutableStateFlow<WeekUi>(WeekUi.Loading)\n    val state: StateFlow<WeekUi> = _state.asStateFlow()", "note": "The model is given the scope its work runs in and a function that loads the sessions. Passing them in, rather than reaching for globals, is lesson 10's lesson, and lesson 18 relies on it to test the class."}, {"code": "    fun refresh() = scope.launch {\n        _state.value = WeekUi.Loading\n        _state.value = try {\n            WeekUi.Loaded(source())\n        } catch (e: IOException) {\n            WeekUi.Failed(e.message ?: \"could not load\")\n        }\n    }", "note": "Loading, then the result. Only `IOException` is caught: a missing file is expected, a bug is not, and cancellation must pass through, as lesson 15 showed."}, {"code": "    fun add(minutes: Int) = _state.update { s ->\n        if (s is WeekUi.Loaded) s.copy(sessions = s.sessions + minutes) else s\n    }\n}", "note": "A session added to a loaded week makes a new `Loaded` with lesson 8's `copy`; in any other state there is no week to add to."}, {"code": "fun describe(s: WeekUi): String = when (s) {\n    WeekUi.Loading -> \"loading…\"\n    is WeekUi.Loaded -> \"${s.sessions.size} sessions, ${s.sessions.sum()} min\"\n    is WeekUi.Failed -> \"could not load the week: ${s.message}\"\n}", "note": "The screen: a `when` over the state, as lesson 9 promised."}, {"code": "fun main() = runBlocking {\n    val model = WeekModel(this) {\n        delay(200)\n        listOf(45, 30)\n    }\n    val screen = launch { model.state.collect { println(describe(it)) } }\n    model.refresh().join()\n    model.add(60)\n    delay(50)\n    screen.cancel()\n}", "note": "A source that takes 200 ms, a screen collecting the state, a refresh, and one session added."}]}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=WeekModelKt
loading…
2 sessions, 75 min
3 sessions, 135 min
```

The screen drew three states: loading, the week as loaded, and the week after the student added a
session. **It never asked for them**: it collected `state` once, and every change the model made reached
it. Nothing outside the model can set the state, and every state the screen can be given is one of
three that `describe` handles, checked by the compiler.

This class is lesson 18's subject as well. A test can give `WeekModel` a source that fails, or one that
returns at once, and read `state.value` to check what the screen would have drawn, with no screen at all.
