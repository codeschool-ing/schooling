---
title: The memory a picture eats, which is not its file size
version: 1
---

**A compressed file of 53 kB can become a bitmap of 48 MB, and the bitmap is what lives in memory.**
A PNG or a JPEG is compressed; a screen cannot draw compressed bytes. To draw an image, Android
decodes it into a bitmap: every pixel, uncompressed, four bytes each in the usual `ARGB_8888`
format, one byte for each of alpha, red, green and blue. So the memory a picture takes has nothing
to do with its file and everything to do with its pixels:

> **bytes = width × height × 4**

A phone photo of 4000 × 3000 pixels is 4000 × 3000 × 4 = 48,000,000 bytes, about 46 MB, whatever
its JPEG weighed. The card of section 02 shows it in a strip 120 dp tall on a screen perhaps 360 dp
wide: on a phone with two pixels per dp, a region of 720 × 240 pixels. Every pixel decoded beyond
that is memory spent on detail nobody can see.

The test serves a 4000 × 3000 cover from a MockWebServer and asks Coil for it twice: once with no
size, and once at 720 × 400, a strip at a generous height:

```kotlin
// app/src/test/java/com/example/planner/BitmapMemoryTest.kt
package com.example.planner

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Color
import androidx.test.core.app.ApplicationProvider
import coil3.ImageLoader
import coil3.imageDecoderEnabled
import coil3.request.ErrorResult
import coil3.request.ImageRequest
import coil3.request.SuccessResult
import coil3.toBitmap
import java.io.ByteArrayOutputStream
import kotlinx.coroutines.runBlocking
import mockwebserver3.MockResponse
import mockwebserver3.MockWebServer
import okio.Buffer
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

fun coverPng(): ByteArray {
    val bitmap = Bitmap.createBitmap(4000, 3000, Bitmap.Config.ARGB_8888)
    bitmap.eraseColor(Color.rgb(40, 120, 200))
    return ByteArrayOutputStream().also { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }.toByteArray()
}

fun MockWebServer.serveCovers(count: Int) {
    val png = coverPng()
    repeat(count) {
        enqueue(
            MockResponse.Builder()
                .addHeader("Content-Type", "image/png")
                .addHeader("Cache-Control", "max-age=3600")
                .body(Buffer().write(png))
                .build(),
        )
    }
}

@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class BitmapMemoryTest {
    @Test
    fun theSizeIsTheMemory(): Unit = runBlocking {
        val context = ApplicationProvider.getApplicationContext<Context>()
        println("the file: ${coverPng().size} bytes")
        val server = MockWebServer().apply { serveCovers(3) }
        server.start()
        val loader = ImageLoader.Builder(context).imageDecoderEnabled(false).build()

        for (size in listOf(null, 720 to 400)) {
            val request = ImageRequest.Builder(context)
                .data(server.url("/covers/android-$size.png").toString())
                .apply { if (size != null) size(size.first, size.second) }
                .build()
            val image = (loader.execute(request) as SuccessResult).image
            println("asked for ${size ?: "the original"}: ${image.width} x ${image.height}, ${image.toBitmap().allocationByteCount} bytes")
        }

        val plain = ImageLoader.Builder(context).build()
        val result = plain.execute(ImageRequest.Builder(context).data(server.url("/covers/plain.png").toString()).build())
        println("without imageDecoderEnabled(false): ${(result as? ErrorResult)?.throwable}")
        server.close()
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*BitmapMemoryTest" 2>&1 | grep -E "^    [a-z]|PASSED|FAILED|^BUILD|^e: "
    the file: 53279 bytes
    asked for the original: 4000 x 3000, 48000000 bytes
    asked for (720, 400): 533 x 400, 852800 bytes
    without imageDecoderEnabled(false): android.graphics.ImageDecoder$DecodeException: Only supported on AndroidException in input: null
BitmapMemoryTest > theSizeIsTheMemory PASSED
BUILD SUCCESSFUL in 20s
```

**The same picture, asked for at two sizes, is 48,000,000 bytes or 852,800.** Fifty-six times less
memory, and on a screen 720 pixels wide nobody could tell the two apart. The PNG itself was 53 kB,
because a picture of one flat colour compresses almost to nothing, and the bitmap did not care:
decoding undoes the compression completely.

Two details in the output deserve a sentence each. **The small one is 533 × 400, not 720 × 400**,
because Coil keeps the picture's proportions and fits it inside the size asked for; 4:3 at a height
of 400 is 533 wide. And **`AsyncImage` asks for the right size by itself**, from the space the
composable was measured into, which is why section 02 never mentioned a size. The danger is in the
places that load an image some other way, such as a notification or a share sheet, and in a
composable that has no bounded size, where "the size of the space" is "as large as the image".

## A line that is there for Robolectric

`imageDecoderEnabled(false)` makes Coil decode with Android's older `BitmapFactory` instead of
`ImageDecoder`. **On a phone you leave it out.** Under Robolectric it is needed, and the last line of
the output shows why: a loader built without it failed to decode, with the message the stand-in
framework gives for a part of Android it does not implement. Coil reported the failure as an
`ErrorResult` rather than crashing, which is also what `AsyncImage` does with a broken image: it
draws the `error` painter of section 02.

**Every number above is still Android's own arithmetic**: `allocationByteCount` is the bitmap's size
as the framework computes it, and width × height × 4 is what it computes.
