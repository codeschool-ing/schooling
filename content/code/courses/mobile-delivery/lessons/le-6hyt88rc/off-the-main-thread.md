---
title: Off the main thread, on three platforms
version: 1
---

**The fix for a hang is moving the slow work to another thread and bringing only the result back to
the main one.** Each platform has a standard way, and each has the same trap: touching the interface
from the other thread, which every platform forbids. *The listings are written from each platform's
documentation and were not run.*

## Kotlin: a coroutine on the IO dispatcher

```kotlin
// WeekViewModel.kt: read the sessions on a background dispatcher, publish on the main one
fun loadWeek(monday: LocalDate) = viewModelScope.launch {
    val sessions = withContext(Dispatchers.IO) { repository.sessionsFrom(monday) }
    _week.value = WeekState(sessions, sessions.sumOf { it.minutes })
}
```

`viewModelScope.launch` starts on the main thread; `withContext(Dispatchers.IO)` runs the database
read on a pool meant for blocking work, and returns to the main thread for the assignment. Android's
**StrictMode**, switched on in debug builds, flags disk and network access on the main thread before
a user ever meets the ANR.

## Swift: an actor away from the main actor

```swift
// WeekModel.swift: the read happens off the main actor, the published state on it
@MainActor final class WeekModel: ObservableObject {
    @Published var total = 0
    func load(monday: Date) async {
        let sessions = await store.sessions(from: monday)   // store is an actor of its own
        total = sessions.reduce(0) { $0 + $1.minutes }
    }
}
```

The model belongs to the **main actor**, so its published state is only touched there; `store` is
another actor, so `await` runs its work elsewhere and suspends the caller instead of blocking it.

## React Native: the JavaScript thread is the one that hangs

```typescript
// useWeek.ts: the query runs in native code, asynchronously, and the JavaScript thread waits without blocking
export function useWeek(monday: string) {
  const [total, setTotal] = useState(0);
  useEffect(() => {
    db.getAllAsync<{ minutes: number }>("select minutes from sessions where date >= ?", [monday])
      .then((rows) => setTotal(rows.reduce((n, r) => n + r.minutes, 0)));
  }, [monday]);
  return total;
}
```

React Native has its own main thread for native views and a **JavaScript thread** for your code. A
long computation in JavaScript freezes every touch handler and animation driven from JavaScript, so
the same rule applies there: the database call is asynchronous, done in native code by
`expo-sqlite`, and only the summing happens in JavaScript.

## Measuring the cure

Moving work off the main thread does not make it faster; it makes the app **answer** while it
happens. The number that shows the cure worked is the user-perceived ANR rate falling in Android
vitals and the hang reports drying up, not the duration of the work, which lesson 15 measures
separately.
