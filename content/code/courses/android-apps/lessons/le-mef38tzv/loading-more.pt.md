---
title: Carregando mais enquanto o estudante rola
version: 1
---

**Uma lista que carrega tudo antes de mostrar qualquer coisa demora a abrir, e uma lista que carrega
uma página só para morta no fim dela.** A resposta de costume é carregar uma página, mostrá-la e
pedir a próxima quando o estudante se aproxima do fim do que foi carregado. O estado da lista já sabe
quão perto isso está: o índice do último item na tela contra o total.

As sessões do planner vão vir de um servidor na aula 13. Até lá, uma classe pequena faz o papel de
um, entregando sessões de vinte em vinte num total de sessenta:

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

`loaded` é `mutableStateOf`, então a lista recompõe quando uma página chega. E a lista que pede as
páginas:

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

`nearTheEnd` fica verdadeiro quando o último item visível está a cinco ou menos do último carregado.
É um `derivedStateOf`, o formato da seção 05, então o composable não é recomposto a cada pixel de
rolagem, só quando a resposta muda. `LaunchedEffect(nearTheEnd)` roda o bloco toda vez que esse valor
muda, e pede uma página quando ele virou verdadeiro. A aula 11 explica o `LaunchedEffect` direito;
aqui basta que ele roda código em resposta a um valor, fora da composição.

**O `totalItemsCount > 0` está ali porque a primeira versão deste arquivo não o tinha**, e carregou
duas páginas antes de alguém rolar. Na primeira composição a lista ainda não foi medida:
`visibleItemsInfo` está vazio e `totalItemsCount` é 0, então "o último índice visível está a cinco do
fim" vira 0 ≥ −5, que é verdade. Um layout vazio parece exatamente uma lista rolada até o fim, e uma
condição que não distingue os dois dispara em toda tela que abre.

O teste abre a lista e rola até o fim do que foi carregado, três vezes:

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

**Uma página na tela, e depois mais uma a cada ida ao fim.** A tela de mentira tem 640 dp de altura e
uma linha de sessão 48 dp, então cerca de treze linhas aparecem e a vigésima fica fora de vista: uma
página basta para abrir. Rolar até o item 19 trouxe o último índice visível para perto do fim e a
segunda página chegou, e o mesmo no item 39. No item 59 não sobra nada: `loadMore` volta sem carregar
e as contagens ficam paradas.

## O que isto deixa de fora, e o que faz isso direito

Esta versão não tem indicador de carregamento, nem erro quando o servidor está inacessível, nem
proteção contra pedir a mesma página duas vezes enquanto uma requisição está em andamento. **A
biblioteca Paging 3 do Google**, `androidx.paging`, é a resposta completa: ela pagina a partir de um
banco e da rede juntos, tenta de novo, expõe estados de carregamento e de erro para a lista desenhar,
e funciona com `LazyColumn` por `collectAsLazyPagingItems()`. É uma biblioteca com desenho próprio, e
este curso não constrói com ela; o formato acima, um estado que sabe onde está o fim e um pedido
quando ele se aproxima, é o que ela faz por baixo.
