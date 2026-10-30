---
title: Loading more as the student scrolls
version: 1
---

**A list that loads everything before showing anything is slow to open, and a list that loads
only one page stops dead at its end.** The usual answer is to load a page, show it, and ask for the
next when the student nears the end of what is loaded. The list's state already knows how near that
is: the index of the last item on screen against the total.

The planner's sessions will come from a server in lesson 13. Until then, a small class stands in for
one, handing out sessions twenty at a time from a total of sixty:

```kotlin
// app/src/main/java/com/example/planner/data/SessionPager.kt
package com.example.planner.data

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import java.time.LocalDate

// Stands in for a server that hands out sessions a page at a time.
class SessionPager(private val start: LocalDate, private val total: Int, private val pageSize: Int) {
    var loaded by mutableStateOf(sessionsFrom(start, pageSize))
        private set
    var pages = 1
        private set

    fun loadMore() {
        if (loaded.size >= total) return
        loaded = sessionsFrom(start, minOf(total, loaded.size + pageSize))
        pages++
    }
}
```

`loaded` is `mutableStateOf`, so the list recomposes when a page arrives. And the list that asks for
pages:

```kotlin
// app/src/main/java/com/example/planner/ui/EndlessList.kt
package com.example.planner.ui

import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import com.example.planner.data.SessionPager

@Composable
fun EndlessList(pager: SessionPager, modifier: Modifier = Modifier) {
    val state = rememberLazyListState()
    val nearTheEnd by remember {
        derivedStateOf {
            val info = state.layoutInfo
            val last = info.visibleItemsInfo.lastOrNull()?.index ?: 0
            info.totalItemsCount > 0 && last >= info.totalItemsCount - 5
        }
    }
    LaunchedEffect(nearTheEnd) {
        if (nearTheEnd) pager.loadMore()
    }
    LazyColumn(modifier, state = state) {
        items(pager.loaded, key = { it.id }) { SessionItem(it) }
    }
}
```

`nearTheEnd` becomes true when the last visible item is within five of the last loaded one. It is a
`derivedStateOf`, the shape from section 05, so the composable is not recomposed for every pixel of
scrolling, only when the answer changes. `LaunchedEffect(nearTheEnd)` runs its block each time that
value changes, and asks for a page when it has become true. Lesson 11 explains `LaunchedEffect`
properly; here it is enough that it runs code in response to a value, outside composition.

**`totalItemsCount > 0` is there because the first version of this file did not have it**, and
loaded two pages before anybody scrolled. On the first composition the list has not been laid out
yet: `visibleItemsInfo` is empty and `totalItemsCount` is 0, so "the last visible index is within
five of the end" reads as 0 ≥ −5, which is true. An empty layout looks exactly like a list scrolled
to its end, and a condition that does not tell them apart fires on every screen that opens.

The test opens the list and scrolls to the end of what is loaded, three times:

```kotlin
// app/src/test/java/com/example/planner/EndlessListTest.kt
package com.example.planner

import androidx.compose.ui.test.hasScrollAction
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.performScrollToIndex
import com.example.planner.data.SessionPager
import com.example.planner.ui.EndlessList
import java.time.LocalDate
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(qualifiers = "w360dp-h640dp-xhdpi")
class EndlessListTest {
    @get:Rule val rule = createComposeRule()

    @Test fun loadsAsItScrolls() {
        val pager = SessionPager(LocalDate.of(2026, 10, 26), total = 60, pageSize = 20)
        rule.setContent { EndlessList(pager) }
        rule.runOnIdle { println("on screen: ${pager.loaded.size} loaded, ${pager.pages} page(s)") }
        repeat(3) {
            val last = rule.runOnIdle { pager.loaded.size - 1 }
            rule.onNode(hasScrollAction()).performScrollToIndex(last)
            rule.runOnIdle { println("scrolled to $last: ${pager.loaded.size} loaded, ${pager.pages} page(s)") }
        }
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*.EndlessListTest' 2>&1 | grep -E '^BUILD|FAILED'
BUILD SUCCESSFUL in 31s
ana@vm:~/planner$ grep -h -e 'loaded' app/build/test-results/testDebugUnitTest/TEST-com.example.planner.EndlessListTest.xml | sed 's/.*CDATA\[//'
on screen: 20 loaded, 1 page(s)
scrolled to 19: 40 loaded, 2 page(s)
scrolled to 39: 60 loaded, 3 page(s)
scrolled to 59: 60 loaded, 3 page(s)
```

**One page on screen, then one more per trip to the end.** The pretend screen is 640 dp tall and a
session row 48 dp, so about thirteen rows show and the twentieth is out of sight: one page is enough
to open with. Scrolling to item 19 brought the last visible index within five of the end and the
second page arrived, and the same at item 39. At item 59 there is nothing left: `loadMore` returns
without loading and the counts stay put.

## What this leaves out, and what does it properly

This version has no loading indicator, no error when the server is unreachable, and no protection
against asking twice for the same page while a request is in flight. **Google's Paging 3 library**,
`androidx.paging`, is the full answer: it pages from a database and a network together, retries,
exposes loading and error states for the list to draw, and works with `LazyColumn` through
`collectAsLazyPagingItems()`. It is a library of its own with a design of its own, and this course
does not build with it; the shape above, a state that knows where the end is and a request when it
gets close, is what it does underneath.
