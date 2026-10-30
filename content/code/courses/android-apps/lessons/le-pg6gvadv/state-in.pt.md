---
title: Do fluxo do store ao estado da tela
version: 1
---

**A tela precisa de um `StateFlow` que possa ler a qualquer momento; o store oferece um `Flow` que só
produz valores enquanto alguém o coleta.** A aula 17 de `kotlin` deu nome à diferença: um fluxo frio
não faz nada até ser coletado, um `StateFlow` quente sempre tem um valor atual. O `stateIn` é a ponte
entre os dois, e os argumentos que ele recebe são as decisões de que esta seção trata.

Eis o ViewModel da semana reescrito em torno do store:

```schooling-example
{"language": "kotlin", "file": "app/src/main/java/com/example/planner/ui/WeekViewModel.kt", "parts": [{"code": "package com.example.planner.ui\n\nimport androidx.lifecycle.SavedStateHandle\nimport androidx.lifecycle.ViewModel\nimport androidx.lifecycle.createSavedStateHandle\nimport androidx.lifecycle.viewModelScope\nimport androidx.lifecycle.viewmodel.initializer\nimport androidx.lifecycle.viewmodel.viewModelFactory\nimport com.example.planner.data.SessionStore\nimport com.example.planner.data.Stores\nimport com.example.planner.data.StudySession\nimport kotlinx.coroutines.channels.Channel\nimport kotlinx.coroutines.flow.Flow\nimport kotlinx.coroutines.flow.SharingStarted\nimport kotlinx.coroutines.flow.StateFlow\nimport kotlinx.coroutines.flow.combine\nimport kotlinx.coroutines.flow.receiveAsFlow\nimport kotlinx.coroutines.flow.stateIn\nimport kotlinx.coroutines.launch\nimport java.time.LocalDate"}, {"code": "data class WeekUiState(\n    val sessions: List<StudySession> = emptyList(),\n    val draftMinutes: String = \"\",\n    val loading: Boolean = false,\n) {\n    val totalMinutes: Int get() = sessions.sumOf { it.minutes }\n    val doneCount: Int get() = sessions.count { it.done }\n    val canAdd: Boolean get() = draftMinutes.toIntOrNull() in 5..240\n}\n\nsealed interface WeekEvent {\n    data class Added(val minutes: Int) : WeekEvent\n}", "note": "O estado da aula 10, com um campo a mais: `loading`, verdadeiro até a primeira lista chegar do store. O `WeekEvent` é assunto da seção 06."}, {"code": "class WeekViewModel(\n    private val store: SessionStore,\n    private val saved: SavedStateHandle,\n) : ViewModel() {\n    private val draft: StateFlow<String> = saved.getStateFlow(DRAFT, \"\")", "note": "O store chega pelo construtor. O rascunho não é mais copiado para um campo: `getStateFlow` transforma a chave do handle num fluxo, então o handle é o único lugar onde ele mora."}, {"code": "    val state: StateFlow<WeekUiState> =\n        combine(store.sessions(), draft) { sessions, text ->\n            WeekUiState(sessions = sessions, draftMinutes = text)\n        }.stateIn(\n            scope = viewModelScope,\n            started = SharingStarted.WhileSubscribed(5_000),\n            initialValue = WeekUiState(loading = true),\n        )", "note": "Duas origens frias viram um `StateFlow` quente. O `combine` cria um estado novo sempre que qualquer uma muda; o `stateIn` roda isso no `viewModelScope`, começa quando a tela coleta e para cinco segundos depois que o último coletor sai."}, {"code": "    private val _events = Channel<WeekEvent>(Channel.BUFFERED)\n    val events: Flow<WeekEvent> = _events.receiveAsFlow()\n    private var nextId = 1L", "note": "Um channel para coisas que acontecem uma vez, lidas por exatamente um coletor. A seção 06 explica por que ele não faz parte do estado."}, {"code": "    fun onDraftChange(text: String) {\n        saved[DRAFT] = text\n    }\n\n    fun onAdd(date: LocalDate) {\n        val minutes = draft.value.toIntOrNull() ?: return\n        if (minutes !in 5..240) return\n        saved[DRAFT] = \"\"\n        viewModelScope.launch {\n            store.add(StudySession(nextId++, \"android\", date, minutes))\n            _events.send(WeekEvent.Added(minutes))\n        }\n    }\n\n    fun onToggleDone(id: Long) {\n        viewModelScope.launch { store.toggleDone(id) }\n    }", "note": "As funções não tocam mais no estado. Elas escrevem no handle ou no store, e o estado novo chega pelo `combine`, do mesmo jeito que chegaria uma mudança feita por qualquer outra parte."}, {"code": "    companion object {\n        private const val DRAFT = \"draft\"\n\n        val Factory = viewModelFactory {\n            initializer { WeekViewModel(Stores.sessions, createSavedStateHandle()) }\n        }\n    }\n}", "note": "Um ViewModel com argumentos no construtor precisa de uma fábrica que saiba construí-lo. `createSavedStateHandle()` lhe dá o mesmo handle que a fábrica padrão da aula 10 dava. A aula 12 troca esta fábrica escrita à mão pelo Hilt."}]}
```

## Os três argumentos do `stateIn`

**`scope = viewModelScope`** é onde o fluxo de origem roda: o `combine` e o fluxo do store dentro
dele. A seção 02 mostrou esse escopo terminando com o ViewModel, então nada aqui sobrevive ao dono da
tela.

**`initialValue`** é o que `state.value` guarda antes de a primeira lista chegar. Um `StateFlow`
sempre precisa ter um valor, e o honesto aqui é "carregando", que a tela desenha como tal. Uma lista
vazia seria mentira: diria "nenhuma sessão" durante o tempo que leva para lê-las.

**`started = SharingStarted.WhileSubscribed(5_000)`** decide quando a origem roda. A tabela da aula
17 de `kotlin` comparou as três escolhas; no Android o argumento por esta é o ciclo de vida:

| `started` | o store é coletado | o custo |
|---|---|---|
| `Eagerly` | da criação do ViewModel até o fim dele | a tela em segundo plano continua lendo o store, para ninguém |
| `Lazily` | do primeiro coletor até o fim do ViewModel | o mesmo, depois que alguém olhou |
| `WhileSubscribed(5_000)` | enquanto a tela coleta, e cinco segundos depois que ela para | uma rotação dura menos de cinco segundos, então não recomeça; uma tela deixada em segundo plano para depois de cinco |

**Os cinco segundos são a paciência de uma rotação.** Durante uma rotação a tela antiga para de
coletar e a nova começa de novo um instante depois; sem a carência, o fluxo do store seria desmontado
e montado de novo a cada giro do celular. A seção 04 mede exatamente isso no planner.

## `combine`, e por que o rascunho está nele

O estado agora tem duas origens, as sessões do store e o rascunho do handle, e o `combine` cria um
`WeekUiState` novo sempre que qualquer uma muda. Isso quer dizer que **nenhuma função do ViewModel
monta mais o estado à mão**. O `onAdd` escreve a sessão no store e o rascunho limpo no handle, e o
estado novo chega sozinho, exatamente como chegaria se outra parte do app tivesse adicionado a
sessão. Um caminho só para toda mudança é o que faz do repositório da aula 16, onde a rede também
pode mudar a lista, um passo pequeno a partir daqui.
