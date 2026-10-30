---
title: O que o planejador leva para o Android
version: 1
---

Vinte aulas atrás o planejador era `val minutes = 45`. Ele termina como um guardador de estado com um
estado selado, alimentado por uma fonte suspensa, observado por um `StateFlow`, testado em tempo virtual
e construído por um catálogo do Gradle. **Quase toda peça dele tem um nome no Android**, e o
`android-apps` parte disso, não do zero:

| neste curso | no `android-apps` |
|---|---|
| `WeekModel`, que recebe um escopo (aula 17) | um `ViewModel`, cujo escopo é o `viewModelScope` |
| `WeekUi`, selado, desenhado com `when` (aulas 9, 17) | o estado que uma tela Compose desenha, com o mesmo `when` |
| `state.collect { … }` numa corrotina da tela | `collectAsStateWithLifecycle()` num composable |
| `SharedFlow` para mensagens (aula 17) | eventos de uma vez só, como uma snackbar |
| `Dispatchers.IO` para o arquivo (aula 14) | o mesmo, para o banco de dados e a rede |
| `runTest`, `backgroundScope` (aula 18) | os mesmos, mais um dispatcher no lugar da thread principal do Android |
| `gradle/libs.versions.toml` (aula 19) | o catálogo com que todo projeto Android novo é criado |
| `jvmToolchain(21)`: onde este bytecode roda? (aula 19) | `minSdk`: o Android mais velho em que o app roda |

O que é novo lá é o próprio Android: o SDK, o emulador, o Jetpack Compose para a tela, o Room para o
armazenamento, o ciclo de vida que destrói e reconstrói uma tela quando o celular gira. **Nada disso é
Kotlin novo.** Todo recurso da linguagem que aquele curso usa está nestas vinte aulas, e quando o código
dele diz `viewModelScope.launch { _state.update { … } }`, cada palavra dessa linha foi rodada aqui.

Os três lugares fora do Android desta aula também não são desvios. Uma equipe que escreve o app muitas
vezes escreve o servidor com que ele fala, em Ktor, dividindo as classes `@Serializable` por um módulo
multiplataforma. As habilidades passam de um para o outro, e o código também.
