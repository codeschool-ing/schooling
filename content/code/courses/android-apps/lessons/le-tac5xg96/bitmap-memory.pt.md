---
title: A memória que uma imagem come, que não é o tamanho do arquivo
version: 1
---

**Um arquivo comprimido de 53 kB pode virar um bitmap de 48 MB, e o bitmap é o que mora na
memória.** Um PNG ou um JPEG é comprimido; uma tela não consegue desenhar bytes comprimidos. Para
desenhar uma imagem, o Android a decodifica num bitmap: cada pixel, sem compressão, quatro bytes cada
no formato usual `ARGB_8888`, um byte para alfa, vermelho, verde e azul. Então a memória que uma
imagem ocupa não tem nada a ver com o arquivo e tudo a ver com os pixels:

> **bytes = largura × altura × 4**

Uma foto de celular de 4000 × 3000 pixels são 4000 × 3000 × 4 = 48.000.000 bytes, uns 46 MB, seja
qual for o peso do JPEG. O cartão da seção 02 a mostra numa faixa de 120 dp de altura numa tela de
talvez 360 dp de largura: num celular com dois pixels por dp, uma região de 720 × 240 pixels. Todo
pixel decodificado além disso é memória gasta com detalhe que ninguém consegue ver.

O teste serve uma capa de 4000 × 3000 a partir de um MockWebServer e pede ao Coil duas vezes: uma sem
tamanho, e uma em 720 × 400, uma faixa de altura generosa:

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

**A mesma imagem, pedida em dois tamanhos, tem 48.000.000 bytes ou 852.800.** Cinquenta e seis vezes
menos memória, e numa tela de 720 pixels de largura ninguém distinguiria as duas. O PNG em si tinha
53 kB, porque uma imagem de uma cor só se comprime quase a nada, e o bitmap não ligou: decodificar
desfaz a compressão por completo.

Dois detalhes da saída merecem uma frase cada. **A pequena tem 533 × 400, e não 720 × 400**, porque o
Coil mantém as proporções da imagem e a encaixa dentro do tamanho pedido; 4:3 numa altura de 400 dá
533 de largura. E **o `AsyncImage` pede o tamanho certo sozinho**, a partir do espaço em que o
composable foi medido, e por isso a seção 02 nunca falou de tamanho. O perigo está nos lugares que
carregam uma imagem de outro jeito, como uma notificação ou uma tela de compartilhamento, e num
composable sem tamanho limitado, onde "o tamanho do espaço" é "tão grande quanto a imagem".

## Uma linha que está ali pelo Robolectric

`imageDecoderEnabled(false)` faz o Coil decodificar com o `BitmapFactory`, mais antigo, em vez do
`ImageDecoder`. **Num celular você a deixa de fora.** Sob o Robolectric ela é necessária, e a última
linha da saída mostra por quê: um carregador montado sem ela não conseguiu decodificar, com a
mensagem que o framework substituto dá para uma parte do Android que ele não implementa. O Coil
informou a falha como um `ErrorResult` em vez de quebrar, que é também o que o `AsyncImage` faz com
uma imagem quebrada: desenha o painter `error` da seção 02.

**Todos os números acima continuam sendo a aritmética do próprio Android**: `allocationByteCount` é o
tamanho do bitmap como o framework o calcula, e largura × altura × 4 é o que ele calcula.
