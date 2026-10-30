---
title: O processo que o sistema leva embora
version: 1
---

**Um ViewModel vive na memória, e a memória é a primeira coisa que o Android recupera.** Quando o
estudante troca para outro app e o celular fica sem memória, o sistema mata o processo do planner sem
chamar nada dentro dele. Quando o estudante volta, o Android inicia um processo novo, recria a
activity e entrega a ela um `Bundle`: a pequena quantidade de estado que a activity antiga salvou
antes de ir para o segundo plano. Todo o resto, todo ViewModel incluído, sumiu. A aula 5 de
`mobile-fundamentals` descreve isso do lado da plataforma.

O `SavedStateHandle` é o caminho do ViewModel até esse `Bundle`. É um mapa de chaves para valores
pequenos, entregue ao construtor do ViewModel pela fábrica padrão, e o que estiver nele quando a
activity salva o estado é escrito no `Bundle` e lido de volta num handle novo depois. É por isso que
o `WeekViewModel` escreve o rascunho nele a cada tecla, em `onDraftChange`, e o lê na primeira linha.

## Imitando isso num teste

A coisa real precisa de um aparelho. **Não executado**: a documentação do Google reproduz isso num
celular ou num emulador pondo o app em segundo plano e rodando `adb shell am kill
com.example.planner`, que mata um processo em segundo plano do jeito que o sistema mata, e depois
reabrindo o app pelos recentes. A máquina de gravação não tinha nenhum dos dois.

O que um teste consegue é separar as duas metades. O Robolectric conduz uma activity pelo ciclo de
vida à mão: este teste salva o estado da activity num `Bundle`, destrói a activity *não* como mudança
de configuração, para que os ViewModels dela sejam descartados, e constrói uma activity novinha a
partir do `Bundle`. É a sequência por que passa um processo morto, menos o processo:

```kotlin
// app/src/test/java/com/example/planner/ProcessDeathTest.kt
package com.example.planner

import android.os.Bundle
import androidx.lifecycle.ViewModelProvider
import com.example.planner.ui.WeekViewModel
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import java.time.LocalDate

@RunWith(RobolectricTestRunner::class)
class ProcessDeathTest {
    @Test fun theDraftSurvivesAndTheListDoesNot() {
        val first = Robolectric.buildActivity(MainActivity::class.java).setup()
        val before = ViewModelProvider(first.get())[WeekViewModel::class.java]
        before.onDraftChange("45")
        before.onAdd(LocalDate.of(2026, 10, 26))
        before.onDraftChange("30")
        println("before: ${before.state.value.sessions.size} session(s), draft \"${before.state.value.draftMinutes}\"")

        val saved = Bundle()
        first.saveInstanceState(saved).pause().stop().destroy()

        val second = Robolectric.buildActivity(MainActivity::class.java).setup(saved)
        val after = ViewModelProvider(second.get())[WeekViewModel::class.java]
        println("after:  ${after.state.value.sessions.size} session(s), draft \"${after.state.value.draftMinutes}\"")
        println("same ViewModel: ${before === after}")
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*ProcessDeathTest' 2>&1 | grep -E "^(BUILD|[0-9]+ actionable)|PASSED|FAILED|^    (before|after|same)"
    before: 1 session(s), draft "30"
    after:  0 session(s), draft "30"
    same ViewModel: false
ProcessDeathTest > theDraftSurvivesAndTheListDoesNot PASSED
BUILD SUCCESSFUL in 14s
30 actionable tasks: 1 executed, 29 up-to-date
```

**O rascunho voltou e a sessão não.** A activity nova ganhou um ViewModel novo, como ganharia num
processo novo, e esse ViewModel encontrou `"30"` no handle porque o `Bundle` o trouxe. A sessão só
existiu na memória do ViewModel antigo.

## O que vai no handle, e o que não vai

O `Bundle` é escrito num processo do sistema e tem limite de tamanho: a documentação do Google avisa
que um muito grande faz o salvamento falhar com `TransactionTooLargeException`, e recomenda
mantê-lo bem abaixo de 50 kB. **Então o handle guarda o que o estudante estava fazendo no meio, e
nunca os dados em si**: o texto sendo digitado, a aba aberta, o id do curso na tela. A lista de
sessões é dado, e dado que precisa sobreviver a um processo pertence a um banco de dados, que é a aula
15. Até lá o planner perde as sessões quando o processo morre, e esta seção é o motivo honesto.
