---
title: Modules, for what a constructor cannot say
version: 1
---

**`@Inject constructor` covers every class you write. It cannot cover an interface or a class
somebody else wrote**, because there is no constructor of yours to annotate. The ViewModel asks for
a `SessionStore`, which is an interface, and for a `java.time.Clock`, which belongs to the JDK. For
both, Hilt needs to be told, and a **module** is where you tell it.

```kotlin
// app/src/main/java/com/example/planner/di/StoreModule.kt
package com.example.planner.di

import com.example.planner.data.InMemorySessionStore
import com.example.planner.data.SessionStore
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent

@Module
@InstallIn(SingletonComponent::class)
abstract class StoreModule {
    @Binds
    abstract fun sessionStore(impl: InMemorySessionStore): SessionStore
}
```

```kotlin
// app/src/main/java/com/example/planner/di/ClockModule.kt
package com.example.planner.di

import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import java.time.Clock

@Module
@InstallIn(SingletonComponent::class)
object ClockModule {
    @Provides
    fun clock(): Clock = Clock.systemDefaultZone()
}
```

The two modules use the two ways of answering:

- **`@Binds`** says "when somebody asks for this interface, give them that implementation". The
  function has no body, because there is nothing to run: Hilt already knows how to build
  `InMemorySessionStore` from its `@Inject` constructor, and the function only maps one type to the
  other. That is why `StoreModule` is an abstract class.
- **`@Provides`** says "when somebody asks for this type, call this function". It is for what you
  cannot annotate, a JDK class here, and any object that needs a builder: lesson 13's network client
  is one.

`@InstallIn(SingletonComponent::class)` says which **component** the answers belong to, and so how
long what they produce can live. The singleton component lives as long as the app. A
`ViewModelComponent` lives as long as one ViewModel, and an `ActivityComponent` as long as one
activity; a binding installed in a shorter component is visible only inside it.

**Why the clock is injected at all.** Lesson 10's `onAdd` took the date as a parameter so that a test
could fix it, and the route called `LocalDate.now()`. With a `Clock` in the graph, the ViewModel asks
for "today" from the clock it was given, the app gives it the system's, and section 07's test gives
it 28 October 2026 at noon, every time.

Why two modules rather than one: section 07 replaces the store and the clock in a test by
**uninstalling** the modules that provide them, and a module is the unit you can uninstall. One
module per thing a test may want to swap is a habit that costs nothing now.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 330\" role=\"img\" data-fig=\"l12-graph\" aria-label=\"Two nested boxes. The singleton component, one per app, holds a Clock provided by ClockModule and a SessionStore bound by StoreModule to the single InMemorySessionStore. Inside the activity, the ViewModel component, one per screen, holds the WeekViewModel and that screen's own SavedStateHandle. Between the two, a line of text says the store and the clock are handed down to every WeekViewModel; inside the screen, arrows run from the SavedStateHandle and from the activity's hiltViewModel() call to the WeekViewModel.\"><defs><marker id=\"l12-graph-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l12-graph-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"600\" height=\"110\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">singleton component: one per app</text><rect x=\"40\" y=\"60\" width=\"250\" height=\"54\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"165\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Clock</text><text x=\"165\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">@Provides ClockModule</text><rect x=\"350\" y=\"60\" width=\"250\" height=\"54\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"475\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SessionStore</text><text x=\"475\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">@Binds → InMemorySessionStore</text><rect x=\"20\" y=\"160\" width=\"600\" height=\"150\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">activity, @AndroidEntryPoint</text><rect x=\"40\" y=\"196\" width=\"560\" height=\"100\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"56\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">ViewModel component: one per screen</text><rect x=\"200\" y=\"228\" width=\"240\" height=\"54\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"320\" y=\"255\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">WeekViewModel</text><rect x=\"460\" y=\"228\" width=\"128\" height=\"54\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"524\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">SavedStateHandle</text><text x=\"524\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">this screen's own</text><rect x=\"52\" y=\"228\" width=\"130\" height=\"54\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"117\" y=\"255\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">hiltViewModel() asks</text><text x=\"320\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor-dim)\">store and clock are handed down to every WeekViewModel</text><path d=\"M458 255 L444 255\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\" marker-end=\"url(#l12-graph-ah-amber)\"></path><path d=\"M184 255 L196 255\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\" marker-end=\"url(#l12-graph-ah-amber)\"></path></svg>", "caption": "The graph Hilt builds for the planner: what lives as long as the app, what lives as long as one screen, and where each of WeekViewModel's three arguments comes from."}
```
