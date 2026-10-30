---
title: Dois caches, e o pedido que nunca sai do celular
version: 1
---

**O Coil guarda uma imagem em dois lugares, e confere os dois em ordem antes de perguntar à rede.** O
**cache em memória** guarda bitmaps decodificados, prontos para desenhar, e some quando o processo
termina. O **cache em disco** guarda os bytes baixados, sobrevive a um reinício e precisa de uma
decodificação para virar bitmap de novo. Uma lista rolada que traz um cartão de volta à tela encontra
a capa na memória; um app aberto na manhã seguinte a encontra no disco; só uma imagem nunca vista
custa uma requisição.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Um pedido de capa vai primeiro ao cache em memória, que guarda bitmaps decodificados; se achar, desenha na hora. Se não, vai ao cache em disco, que guarda os bytes baixados; se achar, decodifica e desenha. Só quando os dois falham vai à rede e baixa.\"><rect x=\"0\" y=\"0\" width=\"720\" height=\"200\" fill=\"var(--ink)\"></rect><rect x=\"20\" y=\"40\" width=\"150\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"95\" y=\"68\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">um pedido</text><text x=\"95\" y=\"90\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">de uma capa</text><rect x=\"200\" y=\"40\" width=\"150\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"275\" y=\"68\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">cache em memória</text><text x=\"275\" y=\"90\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um bitmap decodificado</text><rect x=\"380\" y=\"40\" width=\"150\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"455\" y=\"68\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">cache em disco</text><text x=\"455\" y=\"90\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">os bytes baixados</text><rect x=\"560\" y=\"40\" width=\"150\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect><text x=\"635\" y=\"68\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">rede</text><text x=\"635\" y=\"90\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um download novo</text><line x1=\"172\" y1=\"75\" x2=\"198\" y2=\"75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><line x1=\"352\" y1=\"75\" x2=\"378\" y2=\"75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><line x1=\"532\" y1=\"75\" x2=\"558\" y2=\"75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><text x=\"105\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\"></text><text x=\"285\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">achou: desenha já</text><text x=\"465\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">achou: decodifica e desenha</text><text x=\"645\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">só aqui: baixa</text><text x=\"360\" y=\"180\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">cada passo só é tentado quando o anterior não achou</text></svg>", "caption": "O Coil procura na memória, depois no disco, e só pergunta à rede quando os dois falham."}
```

O app configura um carregador para si, e o lugar para isso é a classe de aplicação, para que todo
`AsyncImage` de toda tela compartilhe os mesmos caches:

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

**Os dois limites são decisões.** `maxSizePercent(context, 0.20)` dá ao cache em memória um quinto da
memória que o Android permite ao app, um número que o sistema decide por aparelho. Cinquenta
megabytes no disco guardam arquivos, não bitmaps, então quantas capas cabem depende do que o
servidor manda. Quando um dos
caches enche, o Coil descarta a imagem usada há mais tempo, então um cache nunca é motivo para o app
ficar sem nada. O `cacheDir` também importa: é o diretório que o Android pode esvaziar quando o
celular está sem espaço, o que é exatamente o certo para algo que dá para baixar de novo.

O teste carrega uma capa quatro vezes, com o cache em memória limpo antes da última:

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

**Uma requisição para quatro carregamentos.** O primeiro veio da rede; os dois seguintes da memória,
com o bitmap já decodificado e no tamanho; o último, depois que o cache em memória foi esvaziado, do
disco, lido e decodificado de novo mas não baixado. A última linha é o cache em memória depois dessa
decodificação final: uma capa de 852.800 bytes, dentro de um limite de 3.355.443, que é o que a regra
dos 20 % calculou para o aparelho que o Robolectric imita. A seção 06 bate nesse limite de propósito.

**O servidor tem voz no cache em disco.** As capas foram servidas com `Cache-Control: max-age=3600`,
e o fetcher de rede do Coil respeita cabeçalhos de cache HTTP: uma resposta marcada `no-store` nem é
escrita no disco. Se as capas nunca parecem vir do disco, olhe os cabeçalhos antes do código.
