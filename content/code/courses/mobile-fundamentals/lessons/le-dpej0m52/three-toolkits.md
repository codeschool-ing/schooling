---
title: The same two tabs in three toolkits
version: 1
---

**Each platform's toolkit has a navigation library, and each one holds the same thing `backstack.ts`
holds: a list of screens per stack, and a rule for what back does.** The spelling differs. Below are
the planner's tabs in Jetpack Compose with Navigation Compose, in SwiftUI, and in React Navigation.
They are adapted from each library's documentation, they are fragments rather than whole apps, and
**they were not compiled or run for this course**. Read them to recognise the stack, the tabs and the
root in each one.

## Android: Navigation Compose

```kotlin
// Navigation Compose: routes are values, and the NavHost holds the stack
@Serializable object Courses
@Serializable data class Course(val id: String)

NavHost(navController, startDestination = Courses) {
    composable<Courses> {
        CourseList(onOpen = { id -> navController.navigate(Course(id)) })
    }
    composable<Course> { entry -> CourseDetail(entry.toRoute<Course>().id) }
}

// A tap on the bottom bar's Week item: save this tab's stack, restore Week's.
navController.navigate(Week) {
    popUpTo(navController.graph.findStartDestination().id) { saveState = true }
    launchSingleTop = true
    restoreState = true
}
```

**`navigate` is `open`, and `startDestination` is the root.** The second block is the one to notice. It
is how Android's guide to multiple back stacks switches tabs: `popUpTo` the start destination with
`saveState` puts the current tab's stack aside instead of throwing it away, and `restoreState` brings
back the stack the other tab had. Without those two flags every tab switch would start the tab again
from its root, which is the mistake the guide exists to prevent. System back needs no code at all here;
the library pops its own stack, and at the start destination it lets the system take the app away.

## iOS: SwiftUI

```swift
// SwiftUI: a TabView of two tabs, each with a NavigationStack of its own
TabView {
    Tab("Courses", systemImage: "book") {
        NavigationStack {
            CourseList()
                .navigationDestination(for: Course.self) { course in
                    CourseDetail(course: course)
                }
        }
    }
    Tab("Week", systemImage: "calendar") {
        NavigationStack { WeekView() }
    }
}
```

**Two `NavigationStack`s inside one `TabView` is the planner's structure, written out.** Each tab owns a
stack, so switching keeps both. A `NavigationLink` inside `CourseList` pushes a `Course`, and the
destination modifier says which view draws it. Apple's documentation for `NavigationStack` says the
stack "doesn't allow the root view to be removed" and that the system disables the back controls when
only the root is showing, which is `backButton` returning `false`. There is no system back to answer.

## React Native: React Navigation

```tsx
// React Navigation: a native stack nested inside each bottom tab
const Tabs = createBottomTabNavigator();
const CoursesStack = createNativeStackNavigator();

function CoursesTab() {
  return (
    <CoursesStack.Navigator>
      <CoursesStack.Screen name="CourseList" component={CourseList} />
      <CoursesStack.Screen name="CourseDetail" component={CourseDetail} />
    </CoursesStack.Navigator>
  );
}

export default function App() {
  return (
    <NavigationContainer>
      <Tabs.Navigator>
        <Tabs.Screen name="Courses" component={CoursesTab} />
        <Tabs.Screen name="Week" component={WeekScreen} />
      </Tabs.Navigator>
    </NavigationContainer>
  );
}
```

**A stack navigator nested inside a tab navigator gives each tab its own stack**, and React Navigation's
documentation calls this nesting. The same JavaScript runs on both platforms, and the library answers
each one in its own way: Android's system back pops the nested stack and then leaves, while on an
iPhone the native stack draws a back button and the edge swipe. A second press on the tab already
showing pops the nested stack to its first screen; the bottom tabs' documentation lists that as the
default, under `tabBarRepeatedPressBehavior`.

| | Navigation Compose | SwiftUI | React Navigation |
|---|---|---|---|
| a stack | `NavHost` and its `navController` | `NavigationStack` | a stack navigator |
| push | `navigate(Course(id))` | a `NavigationLink` | `navigation.navigate("CourseDetail")` |
| tabs | a bottom bar, with saved state | `TabView` of `Tab`s | a bottom tab navigator |
| the root | `startDestination` | the view inside the stack | the first screen of the stack |

Each library gets a lesson of its own after the fork: Navigation Compose in lesson 9 of
`android-apps`, `NavigationStack` in lesson 9 of `ios-apps`, and React Navigation in lesson 8 of
`react-native`: one of the three, depending on the route you take at the fork.
