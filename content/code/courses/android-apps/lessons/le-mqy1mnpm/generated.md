---
title: What Hilt generates, and the error it saves you from
version: 1
---

**Hilt is not magic and not reflection: it is source code written during the build.** KSP runs the
Hilt compiler over the annotations, and the result sits in the build directory as ordinary Java,
compiled into the app with everything else. Counting it is the quickest way to see how much wiring
the annotations replaced: 22 files, for the annotations on six classes of yours.

```
ana@vm:~/planner$ find app/build/generated/ksp/debug app/build/generated/hilt -name "*.java" | wc -l
22
ana@vm:~/planner$ find app/build/generated/ksp/debug app/build/generated/hilt -name "*.java" | sed "s|.*/||" | sort | grep -E "^(Hilt_|DaggerPlannerApp|PlannerApp_Hilt|WeekViewModel_(Factory|HiltModules)\.)"
DaggerPlannerApp_HiltComponents_SingletonC.java
Hilt_MainActivity.java
Hilt_PlannerApp.java
PlannerApp_HiltComponents.java
WeekViewModel_Factory.java
WeekViewModel_HiltModules.java
```

Three names in that list say what Hilt did with them. `Hilt_MainActivity`
is a base class that injects the activity, and the build quietly makes `MainActivity` extend it,
which is why `@AndroidEntryPoint` needs nothing else from you; `Hilt_PlannerApp` does the same for the application. `WeekViewModel_HiltModules` registers
the ViewModel so that `hiltViewModel()` can find it by class. And `DaggerPlannerApp_HiltComponents_SingletonC`
is the singleton component itself: the class that holds the one `InMemorySessionStore` and knows to
call `ClockModule.clock()` when a `Clock` is wanted.

## A binding that is missing

The property worth having is that **a graph that cannot be completed does not compile**. To see it,
take `StoreModule` out of the project, so that nothing says which `SessionStore` to build, and build:

```
ana@vm:~/planner$ mv app/src/main/java/com/example/planner/di/StoreModule.kt /tmp/
ana@vm:~/planner$ ./gradlew --console=plain assembleDebug 2>&1 | grep -E -A8 "MissingBinding" | head -9
/home/ana/planner/app/build/generated/hilt/component_sources/debug/com/example/planner/PlannerApp_HiltComponents.java:138: error: [Dagger/MissingBinding] com.example.planner.data.SessionStore cannot be provided without an @Provides-annotated method.
  public abstract static class SingletonC implements PlannerApp_GeneratedInjector,
                         ^
  
      com.example.planner.data.SessionStore is injected at
          [com.example.planner.PlannerApp_HiltComponents.ViewModelC] com.example.planner.ui.WeekViewModel(store, …)
      com.example.planner.ui.WeekViewModel is injected at
          [com.example.planner.PlannerApp_HiltComponents.ViewModelC] com.example.planner.ui.WeekViewModel_HiltModules.BindsModule.binds(arg0)
      @dagger.hilt.android.internal.lifecycle.HiltViewModelMap java.util.Map<java.lang.Class<?>,javax.inject.Provider<androidx.lifecycle.ViewModel>> is requested at
ana@vm:~/planner$ mv /tmp/StoreModule.kt app/src/main/java/com/example/planner/di/
ana@vm:~/planner$ ./gradlew --console=plain assembleDebug 2>&1 | grep -E "^BUILD"
BUILD SUCCESSFUL in 13s
```

The message names the type nobody provides, `SessionStore`, and the path that needed it: the
`WeekViewModel` constructor, reached from the ViewModel map that `hiltViewModel()` reads. **Without
Hilt, the same mistake compiles**, and the screen crashes the first time it opens, on the phone of
whoever opens it first. Putting the module back makes the build pass again, as the last two lines
show.

Two other mistakes produce messages of the same kind: two bindings for the same type
(`DuplicateBindings`), and an object with a short life asked for by one with a long life, such as a
`@Singleton` that wants a screen's `SavedStateHandle`. In each case the build output names both ends.
