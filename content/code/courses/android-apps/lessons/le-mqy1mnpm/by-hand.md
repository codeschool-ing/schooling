---
title: Injection by hand, before any library
version: 1
---

**Dependency injection is a plain idea with a forbidding name: a class is given what it needs
instead of fetching it.** `WeekViewModel` has done that since lesson 10, when it received its
`SavedStateHandle` through the constructor and section 07 of that lesson could pass one built from a
map. Lesson 11 gave it a `SessionStore` the same way, which is why `CancelTest` could hand it a store
that takes ten seconds to write.

The part lesson 11 left untidy is who builds the store. It wrote an `object Stores` holding the one
`InMemorySessionStore`, and a factory in the ViewModel's companion that reached into it. That works,
and it does not grow. A second screen needs the same store and writes its own factory; a third
needs the store and a clock and a network client; and every factory is a hand-written list of what
to pass, which nobody checks until a screen crashes at run time with the wrong thing.

The tidy version, still with no library, is one class that builds everything once, in one place,
usually called a **container**:

```kotlin
class AppContainer {
    val clock: Clock = Clock.systemDefaultZone()
    val sessions: SessionStore = InMemorySessionStore()
}
```

The `Application` holds one container, each activity asks its `Application` for it, and each
ViewModel factory takes what it needs from there. Google's own guide to Android architecture
teaches exactly this first, as manual dependency injection, and for an app of three screens it is
enough.

**What it leaves to you is the wiring.** Every new class is one more line in the container, one more
argument in some factory, and one more decision about how long the object lives: one per app, one per
screen, a new one each time. Get the last one wrong and two screens disagree about the sessions,
because each built its own store.

## What Hilt does instead

**Hilt writes the container for you, at compile time, from annotations.** You mark a constructor
with `@Inject` to say "build me with these", a class with `@Singleton` to say "one per app", and a
ViewModel with `@HiltViewModel` to say "build this one for a screen". Hilt, which is built on Google's
Dagger, generates the code that calls those constructors in the right order, and **refuses to compile
when something cannot be built**. That last property is the reason to use it: the mistake that the
hand-written factory makes at run time becomes a build error, which section 05 produces on purpose.

The cost is a code generator in the build, KSP, and a vocabulary of a dozen annotations. This
lesson uses nine of them in the app and three more in its test.
