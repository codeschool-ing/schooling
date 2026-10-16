---
title: Matchers, ações e asserções
version: 1
---

**Toda linha de Espresso tem as mesmas três partes: achar uma view, fazer algo com ela, conferir
algo nela.** `onView(matcher)` acha, `perform(action)` faz, `check(assertion)` confere, e uma linha
pode ter a primeira e uma das outras ou as duas. Lido em voz alta, o segundo teste da seção 03 é
*na linha que guarda o `sh-103`, faça um clique; na view com id `title`, confira que ela corresponde
ao texto "O Pagador de Promessas"*.

```schooling-example
{
 "language": "kotlin",
 "file": "ListTest.kt",
 "parts": [
  {
   "code": "@RunWith(AndroidJUnit4::class)\nclass ListTest {\n    @get:Rule\n    val activity = ActivityScenarioRule(MainActivity::class.java)",
   "note": "O `AndroidJUnit4` roda a classe no aparelho. A regra inicia a `MainActivity` do zero antes de cada teste e a fecha depois, então nenhum teste vê a tela que outro deixou."
  },
  {
   "code": "        onView(withId(R.id.refresh)).check(matches(isDisplayed()))",
   "note": "Ache a view cujo id é `refresh`, sem ação, e confira que ela está na tela. `R.id.refresh` é a constante do próprio app, a que o layout da lição 14 declarou: dentro do app não é preciso o prefixo do pacote."
  },
  {
   "code": "        onData(showWithId(\"sh-103\")).inAdapterView(withId(R.id.shows)).perform(click())",
   "note": "Uma linha de uma `ListView` é achada pelos dados, não pela view: o item da lista `shows` que corresponde a `showWithId(\"sh-103\")`. O Espresso rola até ele se for preciso, e então clica."
  },
  {
   "code": "        onView(withId(R.id.title)).check(matches(withText(\"O Pagador de Promessas\")))\n        onView(withId(R.id.price)).check(matches(withText(\"R$ 65,00\")))",
   "note": "A tela do espetáculo está aberta agora, então `title` e `price` são views dela. O texto pertence à asserção, como a lição 14 disse, e nunca ao matcher que acha a view."
  },
  {
   "code": "fun showWithId(id: String): Matcher<Any> =\n    object : BoundedMatcher<Any, Show>(Show::class.java) {\n        override fun describeTo(description: Description) {\n            description.appendText(\"a show with id $id\")\n        }\n\n        override fun matchesSafely(item: Show) = item.id == id\n    }",
   "note": "Um matcher nosso. O `BoundedMatcher` só olha itens que são um `Show`, e o `matchesSafely` diz qual. O `describeTo` é o que o Espresso imprime quando nada correspondeu, então ele deve se ler como uma frase."
  }
 ]
}
```

## Por que uma lista precisa de `onData`

Uma `ListView` não cria uma view para cada item. Ela cria linhas suficientes para encher a tela e
**as reaproveita ao rolar**, pondo o texto do próximo item numa linha que acabou de sair pelo alto.
Então a linha de um item mais abaixo na lista não existe até que se role até ele, e o `onView` só
acha views que existem. O `onData` pede o item ao adapter da lista, rola até a linha dele ser
desenhada, e então age sobre essa linha. O Tickets tem três espetáculos e eles cabem em qualquer
tela, mas um teste escrito com `onView` quebraria no dia em que o boxoffice vendesse um quarto.

**A linha é escolhida pelo que guarda, não por onde está.** `onData(…).atPosition(2)` também acharia
a terceira linha, e acharia outro espetáculo no dia em que o boxoffice os listasse em outra ordem.
`showWithId("sh-103")` continua achando o certo, e é a caixa cinza da seção 02 no seu momento mais
útil: o objeto `Show` é do próprio app, e nenhum leitor de tela poderia ter oferecido o id.

## As partes que você mais vai usar

| tipo | escrito | faz |
|---|---|---|
| matcher | `withId(R.id.banner)` | a view com esse id |
| matcher | `withText("Refresh")`, `withText(startsWith("Offline"))` | a view que mostra esse texto |
| matcher | `withContentDescription("…")` | a view que um leitor de tela nomeia assim |
| matcher | `isDisplayed()`, `isEnabled()`, `isChecked()` | uma view nesse estado; `isChecked()` é a chave de lembrete da lição 21 |
| matcher | `allOf(…)`, `not(…)` | vários matchers ao mesmo tempo, ou o contrário de um |
| ação | `click()`, `longClick()` | um toque, um toque longo |
| ação | `typeText("…")`, `replaceText("…")` | digitar num campo |
| ação | `scrollTo()`, `swipeUp()` | rolar, para views fora de uma lista (lição 21) |
| ação | `pressBack()` | o botão voltar do Android, do próprio `Espresso` |
| asserção | `matches(matcher)` | a view achada passa no matcher |
| asserção | `doesNotExist()` | nenhuma view corresponde |

**`not(isDisplayed())` e `doesNotExist()` são verificações diferentes.** A faixa do Tickets está no
layout em todo início, escondida com `visibility="gone"`, então ela existe e não está visível:
`matches(not(isDisplayed()))` passa e `doesNotExist()` falha. Uma view que nunca foi inflada, como o
`remind` na tela de lista, é o contrário. A seção 06 confere a faixa, e precisa da primeira.

Quando um matcher não acha nada, o Espresso falha com `NoMatchingViewException` e imprime a hierarquia
inteira de views em que procurou, parecido com o page source do Appium na lição 15. Quando acha mais
de uma, falha com `AmbiguousViewMatcherException`, que é o que `withId(R.id.title)` faria na tela de
lista, onde toda linha tem um `title`.
