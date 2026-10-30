---
title: A list of photos, and the arithmetic of scrolling
version: 1
---

**A list multiplies everything sections 03 and 04 measured.** One cover at the right size is 852,800
bytes; a course list of forty cards is forty of them, and a fast scroll asks for a dozen in a second.
Three things keep that affordable, and the planner already has two of them: covers decoded at the
size of the card, and a memory cache with a limit, which evicts what scrolled away longest ago. The
third is that a card which leaves the screen cancels its request, which `AsyncImage` does by itself
because the request belongs to the composable's lifetime.

The course list is lesson 8's `LazyColumn` with a cover on each card:

```kotlin
// app/src/main/java/com/example/planner/ui/CourseList.kt
package com.example.planner.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import com.example.planner.data.Course

@Composable
fun CourseList(courses: List<Course>, coverOf: (Course) -> String?) {
    LazyColumn(
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        items(courses, key = { it.id }) { course ->
            CourseCard(course.name, coverOf(course))
        }
    }
}
```

```kotlin
// app/src/main/java/com/example/planner/data/Model.kt
package com.example.planner.data

import java.time.LocalDate

data class Course(val id: String, val name: String)

data class StudySession(
    val id: Long,
    val courseId: String,
    val date: LocalDate,
    val minutes: Int,
    val done: Boolean = false,
)
```

**`key = { it.id }` matters more with images than without them.** It ties each item's state, the
loaded cover included, to the course rather than to the position, so a course inserted at the top
does not make every card below it show its neighbour's picture for a frame.

## What the cache holds after a scroll

The test loads forty different covers through the app's loader, first at card size and then, in a
second loader, at full size, as a list without sized requests would, and reads the memory cache
after each run:

```kotlin
// app/src/test/java/com/example/planner/ListMemoryTest.kt
package com.example.planner

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import coil3.imageDecoderEnabled
import coil3.request.ImageRequest
import kotlinx.coroutines.runBlocking
import mockwebserver3.MockWebServer
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class ListMemoryTest {
    @Test
    fun fortyCovers(): Unit = runBlocking {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val server = MockWebServer().apply { serveCovers(80) }
        server.start()
        for (sized in listOf(true, false)) {
            val loader = plannerImageLoader(context).newBuilder()
                .imageDecoderEnabled(false)
                .diskCache(null)
                .build()
            for (i in 1..40) {
                val request = ImageRequest.Builder(context)
                    .data(server.url("/covers/$sized/$i.png").toString())
                    .apply { if (sized) size(720, 400) }
                    .build()
                loader.execute(request)
            }
            val cache = loader.memoryCache!!
            println("sized=$sized: ${cache.size} of ${cache.maxSize} bytes held")
        }
        server.close()
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*ListMemoryTest" 2>&1 | grep -E "^    [a-z]|PASSED|FAILED|^BUILD|^e: "
    sized=true: 2558400 of 3355443 bytes held
    sized=false: 0 of 3355443 bytes held
ListMemoryTest > fortyCovers PASSED
BUILD SUCCESSFUL in 39s
```

**The limit is the first number to read: 3,355,443 bytes.** That is a fifth of the memory the device
Robolectric pretends to be allows an app, and it is small; a phone with more memory gives a larger
limit by the same rule. Sized covers of 852,800 bytes fit three at a time, and the cache keeps the
three seen most recently, which are the ones a scroll back would ask for first.

**Unsized, the cache held nothing at all.** Each bitmap of 48,000,000 bytes is larger than the whole
limit, and Coil does not keep an entry bigger than its cache. Every cover scrolled back into view
would then be decoded again from disk or downloaded again, at 48 MB a time. On a phone whose
limit is ten times larger the story is the same, because ten times 3.4 MB is still less than one
unsized cover. That is how a list of photos stutters on a phone that seems to have memory to spare.

The lesson's four tests, together:

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest 2>&1 | grep -E "PASSED|FAILED|^BUILD"
BitmapMemoryTest > theSizeIsTheMemory PASSED
CacheTest > memoryThenDisk PASSED
ListMemoryTest > fortyCovers PASSED
StatesScreenshotTest > fourStates PASSED
BUILD SUCCESSFUL in 40s
```

**Not run:** the same scroll on a phone, watched with Android Studio's memory profiler, which shows
the bitmaps as allocations as the list moves. The numbers above are the bitmaps' own byte
counts, read on the JVM.
