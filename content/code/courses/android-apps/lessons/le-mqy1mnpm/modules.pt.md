---
title: Módulos, para o que um construtor não consegue dizer
version: 1
---

**`@Inject constructor` cobre toda classe que você escreve. Não cobre uma interface nem uma classe
que outra pessoa escreveu**, porque não há construtor seu para anotar. O ViewModel pede um
`SessionStore`, que é uma interface, e um `java.time.Clock`, que pertence ao JDK. Para os dois, o
Hilt precisa ser avisado, e um **módulo** é onde você avisa.

```kotlin
// app/src/main/java/com/example/planner/di/StoreModule.kt
package com.example.planner.di

import com.example.planner.data.InMemorySessionStore
import com.example.planner.data.SessionStore
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent

@Module
@InstallIn(SingletonComponent::class)
abstract class StoreModule {
    @Binds
    abstract fun sessionStore(impl: InMemorySessionStore): SessionStore
}
```

```kotlin
// app/src/main/java/com/example/planner/di/ClockModule.kt
package com.example.planner.di

import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import java.time.Clock

@Module
@InstallIn(SingletonComponent::class)
object ClockModule {
    @Provides
    fun clock(): Clock = Clock.systemDefaultZone()
}
```

Os dois módulos usam os dois jeitos de responder:

- **`@Binds`** diz "quando alguém pedir esta interface, entregue aquela implementação". A função não
  tem corpo, porque não há nada para rodar: o Hilt já sabe construir o `InMemorySessionStore` pelo
  construtor `@Inject`, e a função só liga um tipo ao outro. É por isso que o `StoreModule` é uma
  classe abstrata.
- **`@Provides`** diz "quando alguém pedir este tipo, chame esta função". Serve para o que você não
  consegue anotar, uma classe do JDK aqui, e para qualquer objeto que precise de um builder: o
  cliente de rede da aula 13 é um deles.

`@InstallIn(SingletonComponent::class)` diz a qual **componente** as respostas pertencem, e portanto
quanto tempo o que elas produzem pode viver. O componente singleton vive tanto quanto o app. Um
`ViewModelComponent` vive tanto quanto um ViewModel, e um `ActivityComponent` tanto quanto uma
activity; uma ligação instalada num componente mais curto só é visível dentro dele.

**Por que injetar o relógio.** O `onAdd` da aula 10 recebia a data como parâmetro para que um teste
pudesse fixá-la, e a rota chamava `LocalDate.now()`. Com um `Clock` no grafo, o ViewModel pede "hoje"
ao relógio que recebeu, o app lhe dá o do sistema, e o teste da seção 07 lhe dá 28 de outubro de
2026 ao meio-dia, sempre.

Por que dois módulos, e não um: a seção 07 troca o store e o relógio num teste **desinstalando** os
módulos que os fornecem, e o módulo é a unidade que se pode desinstalar. Um módulo por coisa que um
teste talvez queira trocar é um hábito que não custa nada agora.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 330\" role=\"img\" data-fig=\"l12-graph\" aria-label=\"Duas caixas, uma dentro da outra. O componente singleton, um por app, guarda um Clock fornecido pelo ClockModule e um SessionStore ligado pelo StoreModule ao único InMemorySessionStore. Dentro da activity, o componente de ViewModel, um por tela, guarda o WeekViewModel e o SavedStateHandle daquela tela. Entre os dois, uma linha de texto diz que o store e o relógio descem para todo WeekViewModel; dentro da tela, setas saem do SavedStateHandle e da chamada hiltViewModel() da activity para o WeekViewModel.\"><defs><marker id=\"l12-graph-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l12-graph-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"600\" height=\"110\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">componente singleton: um por app</text><rect x=\"40\" y=\"60\" width=\"250\" height=\"54\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"165\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Clock</text><text x=\"165\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">@Provides ClockModule</text><rect x=\"350\" y=\"60\" width=\"250\" height=\"54\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"475\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SessionStore</text><text x=\"475\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">@Binds → InMemorySessionStore</text><rect x=\"20\" y=\"160\" width=\"600\" height=\"150\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">activity, @AndroidEntryPoint</text><rect x=\"40\" y=\"196\" width=\"560\" height=\"100\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"56\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">componente de ViewModel: um por tela</text><rect x=\"200\" y=\"228\" width=\"240\" height=\"54\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"320\" y=\"255\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">WeekViewModel</text><rect x=\"460\" y=\"228\" width=\"128\" height=\"54\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"524\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">SavedStateHandle</text><text x=\"524\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o desta tela</text><rect x=\"52\" y=\"228\" width=\"130\" height=\"54\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"117\" y=\"255\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">hiltViewModel() pede</text><text x=\"320\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">store e relógio descem para todo WeekViewModel</text><path d=\"M458 255 L444 255\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\" marker-end=\"url(#l12-graph-ah-amber)\"></path><path d=\"M184 255 L196 255\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\" marker-end=\"url(#l12-graph-ah-amber)\"></path></svg>", "caption": "O grafo que o Hilt monta para o planner: o que vive tanto quanto o app, o que vive tanto quanto uma tela, e de onde vem cada um dos três argumentos do WeekViewModel."}
```
