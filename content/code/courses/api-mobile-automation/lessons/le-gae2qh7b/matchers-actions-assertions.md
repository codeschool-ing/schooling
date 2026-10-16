---
title: Matchers, actions and assertions
version: 1
---

**Every Espresso line has the same three parts: find a view, do something to it, check something
about it.** `onView(matcher)` finds, `perform(action)` does, `check(assertion)` checks. A line
may have the first and either or both of the others. Read aloud, the second test of section 03 is
*on the row holding `sh-103`, perform a click; on the view with id `title`, check that it matches
the text "O Pagador de Promessas"*.

```schooling-example
{
 "language": "kotlin",
 "file": "ListTest.kt",
 "parts": [
  {
   "code": "@RunWith(AndroidJUnit4::class)\nclass ListTest {\n    @get:Rule\n    val activity = ActivityScenarioRule(MainActivity::class.java)",
   "note": "`AndroidJUnit4` runs the class on the device. The rule starts `MainActivity` fresh before each test and closes it after, so no test sees the screen another one left."
  },
  {
   "code": "        onView(withId(R.id.refresh)).check(matches(isDisplayed()))",
   "note": "Find the view whose id is `refresh`, with no action, and check that it is on the screen. `R.id.refresh` is the app's own constant, the one lesson 14's layout declared: inside the app, no package prefix is needed."
  },
  {
   "code": "        onData(showWithId(\"sh-103\")).inAdapterView(withId(R.id.shows)).perform(click())",
   "note": "A row of a `ListView` is found through its data, not its view: the item of the list `shows` that matches `showWithId(\"sh-103\")`. Espresso scrolls to it if needed, then clicks it."
  },
  {
   "code": "        onView(withId(R.id.title)).check(matches(withText(\"O Pagador de Promessas\")))\n        onView(withId(R.id.price)).check(matches(withText(\"R$ 65,00\")))",
   "note": "The show's screen is open now, so `title` and `price` are its views. Text belongs in the assertion, as lesson 14 said, and never in the matcher that finds the view."
  },
  {
   "code": "fun showWithId(id: String): Matcher<Any> =\n    object : BoundedMatcher<Any, Show>(Show::class.java) {\n        override fun describeTo(description: Description) {\n            description.appendText(\"a show with id $id\")\n        }\n\n        override fun matchesSafely(item: Show) = item.id == id\n    }",
   "note": "A matcher of our own. `BoundedMatcher` only looks at items that are a `Show`, and `matchesSafely` says which one. `describeTo` is what Espresso prints when nothing matched, so it should read as a sentence."
  }
 ]
}
```

## Why a list needs `onData`

A `ListView` does not make a view for every item. It makes enough rows to fill the screen and **reuses them as you scroll**. The next item's
text goes into a row that has just gone off the top. So a row for an item further down the list
does not exist until it is scrolled to, and `onView` can only find views that exist. `onData` asks
the list's adapter for the item instead. It scrolls until the item's row is drawn, then acts on that
row. Tickets has three shows and they fit on any screen. But a test written with `onView` would
break the day boxoffice sells a fourth.

**The row is chosen by what it holds, not where it is.** `onData(…).atPosition(2)` would also find
the third row, and it would find a different show the day boxoffice lists them in another order.
`showWithId("sh-103")` keeps finding the right one. It is the gray box of section 02 at its most
useful: the `Show` object is the app's own, and no screen reader could have offered the id.

## The parts you will use most

| kind | written | does |
|---|---|---|
| matcher | `withId(R.id.banner)` | the view with that id |
| matcher | `withText("Refresh")`, `withText(startsWith("Offline"))` | the view showing that text |
| matcher | `withContentDescription("…")` | the view a screen reader names so |
| matcher | `isDisplayed()`, `isEnabled()`, `isChecked()` | a view in that state; `isChecked()` is the reminder switch of lesson 21 |
| matcher | `allOf(…)`, `not(…)` | several matchers at once, or the opposite of one |
| action | `click()`, `longClick()` | a tap, a long press |
| action | `typeText("…")`, `replaceText("…")` | typing into a field |
| action | `scrollTo()`, `swipeUp()` | scrolling, for views outside a list (lesson 21) |
| action | `pressBack()` | Android's back button, from `Espresso` itself |
| assertion | `matches(matcher)` | the view found passes the matcher |
| assertion | `doesNotExist()` | no view matches at all |

**`not(isDisplayed())` and `doesNotExist()` are different checks.** Tickets's banner is in the
layout on every start, hidden with `visibility="gone"`. So it exists and is not displayed:
`matches(not(isDisplayed()))` passes and `doesNotExist()` fails. A view that was never inflated,
like `remind` on the list screen, is the other way round. Section 06 checks the banner, and needs
the first.

When a matcher finds nothing, Espresso fails with `NoMatchingViewException`. It prints the whole
view hierarchy it searched, much like Appium's page source in lesson 15. When a matcher finds more
than one, it fails with `AmbiguousViewMatcherException`. `withId(R.id.title)` would do that on the
list screen, where every row has a `title`.
