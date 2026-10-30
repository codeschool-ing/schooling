---
title: The tools, and what they collect by default
version: 1
---

**Most teams send events to an analytics product rather than to their own SQLite table, and every
product collects more by default than the planner's schema allows.** The work is to configure the
product down to the decision, not to accept its defaults. *None was set up for this course; read from
each product's documentation, October 2026.*

| product | what it is | what to switch off for the planner's rules |
|---|---|---|
| **Google Analytics for Firebase** | free, part of Firebase, on both platforms and React Native | the advertising identifier, Google signals, automatic screen names if they include content |
| **Amplitude**, **Mixpanel** | paid, with free tiers, built around funnels and cohorts | IP address storage, the automatic collection of device identifiers |
| **PostHog** | open source, can run on your own servers | session recording, autocapture of every tap and its text |

**Autocapture** deserves its own sentence. It records every tap with the text of the element tapped,
which on a planner screen includes course names and notes. It is the opposite of a schema, and it is
switched on by default in several products.

## One function in front of the product

Whatever the product, the app calls it in one place, a `track` function like the one in section "A
funnel", which checks the schema and only then hands the event over:

```kotlin
// Analytics.kt: the schema checked first, then Firebase
object Analytics {
    private val schema = mapOf("session_done" to setOf("minutes"), "course_added" to setOf("course_count"))
    fun track(name: String, props: Map<String, Long>) {
        val allowed = schema[name] ?: error("event $name is not in the schema")
        require(props.keys.all { it in allowed }) { "event $name: property not in the schema" }
        Firebase.analytics.logEvent(name) { props.forEach { (k, v) -> param(k, v) } }
    }
}
```

```swift
// Analytics.swift: the same check in front of Firebase
enum Analytics {
    static let schema: [String: Set<String>] = ["session_done": ["minutes"], "course_added": ["course_count"]]
    static func track(_ name: String, _ props: [String: Int]) {
        guard let allowed = schema[name], Set(props.keys).isSubset(of: allowed) else {
            assertionFailure("event \(name) or a property is not in the schema"); return
        }
        FirebaseAnalytics.Analytics.logEvent(name, parameters: props)
    }
}
```

```typescript
// analytics.ts in React Native: the lesson's own function, with the product behind it
import analytics from "@react-native-firebase/analytics";
export async function track(name: string, props: Record<string, number> = {}) {
  const allowed = SCHEMA[name];
  if (!allowed || Object.keys(props).some((k) => !allowed.includes(k))) throw new Error(`${name} is not in the schema`);
  await analytics().logEvent(name, props);
}
```

*The three listings are written from Firebase's documentation and were not run.* Swapping the
product later then means changing one function, not every screen, and the schema survives the swap.
