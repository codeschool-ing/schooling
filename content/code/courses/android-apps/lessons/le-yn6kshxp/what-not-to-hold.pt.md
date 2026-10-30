---
title: O que um ViewModel nunca deve guardar
version: 1
---

**Um ViewModel sobrevive à activity, então não pode guardar uma referência à activity.** Isso decorre
direto da seção 04, e mesmo assim é o erro mais comum com um. O caminho até ele costuma ser inocente:
o ViewModel quer formatar uma string, strings moram nos recursos, recursos precisam de um `Context`, e
o `Context` mais próximo é a activity que o criou.

```kotlin
// app/src/main/java/com/example/planner/ui/LeakyViewModel.kt
package com.example.planner.ui

import android.content.Context
import androidx.lifecycle.ViewModel

class LeakyViewModel(private val context: Context) : ViewModel() {
    fun greeting(): String = context.getString(com.example.planner.R.string.app_name)
}
```

Compila e funciona, até o celular girar. Aí a activity é destruída, uma nova é construída, e este
ViewModel, mantido vivo de propósito pelo `ViewModelStore`, continua apontando para a antiga. A
activity antiga não pode ser coletada, nem a janela dela, nem as views e tudo o que elas guardam:
**uma tela inteira presa na memória à toa, uma vez por rotação**. O próprio linter do Android conhece
o padrão:

```
ana@vm:~/planner$ ./gradlew --console=plain lintDebug 2>&1 | grep -E "^BUILD"
BUILD SUCCESSFUL in 28s
ana@vm:~/planner$ grep -A2 "\[StaticFieldLeak\]" app/build/reports/lint-results-debug.txt
/home/ana/planner/app/src/main/java/com/example/planner/ui/LeakyViewModel.kt:7: Warning: This field leaks a context object [StaticFieldLeak]
class LeakyViewModel(private val context: Context) : ViewModel() {
                     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

O build ainda dá certo: o lint relata um aviso e não falha por causa dele, a menos que o arquivo de
build diga `lint { warningsAsErrors = true }`. `StaticFieldLeak` é o nome da verificação, e a
explicação fala de campos estáticos porque esse foi o primeiro jeito de vazar um contexto; um campo
de um objeto que sobrevive à activity é o mesmo vazamento.

## Para onde vai o `Context`

Volte ao `WeekViewModel`. Ele nunca formata uma frase: o `WeekUiState` traz `totalMinutes`,
`doneCount` e a lista, e a `WeekScreen` os transforma em palavras com
`stringResource(R.string.week_total, …)`. **O ViewModel produz valores e a tela produz texto**, o que
também quer dizer que a frase acompanha o idioma do celular sem o ViewModel saber que existem
idiomas. A seção 07 da aula 1 é onde essa escolha é feita.

Mais três coisas para manter de fora, pelo mesmo motivo ou por um parecido:

| fora de um ViewModel | por quê |
|---|---|
| uma `Activity`, uma `View`, um `Fragment` | cada um vive menos que o ViewModel, então cada um é um vazamento |
| um `NavController` ou qualquer outra coisa da composição | pertence a uma composição; navegar é algo que a tela faz quando um evento pede |
| um lambda que captura qualquer uma das anteriores | a captura é uma referência escondida, o mesmo vazamento sem campo para ler |

Quando um ViewModel precisa mesmo de algo da plataforma, a resposta da aula 12 em diante é pedir essa
coisa pelo construtor, um `SessionStore` em vez de um `Context`. O objeto `Application` vive tanto
quanto o processo, então não vaza, e `AndroidViewModel` é uma classe base que o recebe. Ainda assim é
um `Context` numa classe que a seção 07 quer testar sem Android, então este curso não a usa.
