---
title: Two caches, and the request that never leaves the phone
version: 1
---

**Coil keeps an image in two places, and checks them in order before it asks the network.** The
**memory cache** holds decoded bitmaps, ready to draw, and is gone when the process ends. The **disk
cache** holds the downloaded bytes, survives a restart, and needs a decode to become a bitmap again.
A scrolled list that brings a card back on screen finds its cover in memory; an app opened the next
morning finds it on disk; only a picture seen nowhere before costs a request.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"A request for a cover goes first to the memory cache, which holds decoded bitmaps; if found, it is drawn at once. If not, it goes to the disk cache, which holds the downloaded bytes; if found, they are decoded and drawn. Only when both miss does it go to the network and download.\"><rect x=\"0\" y=\"0\" width=\"720\" height=\"200\" fill=\"var(--ink)\"></rect><rect x=\"20\" y=\"40\" width=\"150\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"95\" y=\"68\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">a request</text><text x=\"95\" y=\"90\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">for a cover</text><rect x=\"200\" y=\"40\" width=\"150\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"275\" y=\"68\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">memory cache</text><text x=\"275\" y=\"90\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a decoded bitmap</text><rect x=\"380\" y=\"40\" width=\"150\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"455\" y=\"68\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">disk cache</text><text x=\"455\" y=\"90\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the downloaded bytes</text><rect x=\"560\" y=\"40\" width=\"150\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect><text x=\"635\" y=\"68\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">network</text><text x=\"635\" y=\"90\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a new download</text><line x1=\"172\" y1=\"75\" x2=\"198\" y2=\"75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><line x1=\"352\" y1=\"75\" x2=\"378\" y2=\"75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><line x1=\"532\" y1=\"75\" x2=\"558\" y2=\"75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><text x=\"105\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\"></text><text x=\"285\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">found: draw it now</text><text x=\"465\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">found: decode, then draw</text><text x=\"645\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">only here: download</text><text x=\"360\" y=\"180\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">each step is tried only when the one before it missed</text></svg>", "caption": "Coil looks in memory, then on disk, and asks the network only when both miss."}
```

The app configures one loader for itself, and the place to do that is the application class, so
that every `AsyncImage` in every screen shares the same caches:

```kotlin
// app/src/main/java/com/example/planner/PlannerApp.kt
package com.example.planner

import android.app.Application
import android.content.Context
import coil3.ImageLoader
import coil3.PlatformContext
import coil3.SingletonImageLoader
import coil3.disk.DiskCache
import coil3.memory.MemoryCache
import okio.Path.Companion.toOkioPath

fun plannerImageLoader(context: Context): ImageLoader = ImageLoader.Builder(context)
    .memoryCache {
        MemoryCache.Builder()
            .maxSizePercent(context, 0.20)
            .build()
    }
    .diskCache {
        DiskCache.Builder()
            .directory(context.cacheDir.resolve("covers").toOkioPath())
            .maxSizeBytes(50L * 1024 * 1024)
            .build()
    }
    .build()

class PlannerApp : Application(), SingletonImageLoader.Factory {
    override fun newImageLoader(context: PlatformContext): ImageLoader = plannerImageLoader(this)
}
```

**Both limits are decisions.** `maxSizePercent(context, 0.20)` gives the memory cache a fifth of the
memory Android allows the app, a figure the system decides per device. Fifty megabytes on disk holds
files, not bitmaps, so how many covers fit depends on what the server sends. When either cache is full, Coil evicts the
image used least recently, so a cache is never a reason for the app to run out of anything.
`cacheDir` matters too: it is the directory Android may empty when the phone is short of space, which
is exactly right for something that can be downloaded again.

The test loads one cover four times, with the memory cache cleared before the last:

```kotlin
// app/src/test/java/com/example/planner/CacheTest.kt
package com.example.planner

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import coil3.imageDecoderEnabled
import coil3.request.ImageRequest
import coil3.request.SuccessResult
import kotlinx.coroutines.runBlocking
import mockwebserver3.MockWebServer
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class CacheTest {
    @Test
    fun memoryThenDisk(): Unit = runBlocking {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val server = MockWebServer().apply { serveCovers(4) }
        server.start()
        val loader = plannerImageLoader(context).newBuilder().imageDecoderEnabled(false).build()
        val url = server.url("/covers/android.png").toString()
        suspend fun load(label: String) {
            val result = loader.execute(ImageRequest.Builder(context).data(url).size(720, 400).build())
            println("$label: ${(result as SuccessResult).dataSource}")
        }

        load("first")
        load("second")
        load("third")
        loader.memoryCache?.clear()
        load("after clearing memory")
        println("requests: ${server.requestCount}")
        println("memory cache: ${loader.memoryCache?.size} of ${loader.memoryCache?.maxSize} bytes")
        server.close()
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*CacheTest" 2>&1 | grep -E "^    [a-z]|PASSED|FAILED|^BUILD|^e: "
    first: NETWORK
    second: MEMORY_CACHE
    third: MEMORY_CACHE
    after clearing memory: DISK
    requests: 1
    memory cache: 852800 of 3355443 bytes
CacheTest > memoryThenDisk PASSED
BUILD SUCCESSFUL in 22s
```

**One request for four loads.** The first came from the network; the next two from memory, the
bitmap already decoded and sized; the last, after the memory cache was emptied, from disk, read and
decoded again but not downloaded. The last line is the memory cache after that final decode: one
cover of 852,800 bytes, inside a limit of 3,355,443, which is what the 20 % rule worked out for the
device Robolectric plays. Section 06 runs into that limit on purpose.

**The server has a say in the disk cache.** The covers were served with `Cache-Control: max-age=3600`,
and Coil's network fetcher respects HTTP caching headers: a response marked `no-store` is not
written to disk at all. If covers never seem to come from disk, look at the headers before the code.
