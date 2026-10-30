---
title: Coisas que acontecem uma vez
version: 1
---

**Um snackbar dizendo "Added 45 min" não é estado.** Estado é o que é verdade agora: a lista, o
total, o rascunho. O snackbar informa que algo aconteceu, uma vez, e depois de mostrado nada na tela
deveria lembrar dele. Ponha-o no `WeekUiState` como `message: String?` e o problema começa na
primeira rotação: a tela nova lê o estado, encontra a mensagem e a mostra de novo.

O planner o envia por um `Channel`:

```kotlin
private val _events = Channel<WeekEvent>(Channel.BUFFERED)
val events: Flow<WeekEvent> = _events.receiveAsFlow()
```

Um channel entrega cada elemento a **um** receptor e depois ele some, o que é exatamente "uma vez".
Três propriedades fazem dele uma boa escolha para uma tela:

- **Ele espera um receptor.** `Channel.BUFFERED` guarda até 64 elementos, então um evento enviado
  enquanto a tela gira, sem coletor por um instante, é entregue quando o `LaunchedEffect` da tela nova
  começa a coletar. Um `MutableSharedFlow` sem replay o descartaria.
- **Ele é consumido.** A tela nova depois de uma rotação não recebe um evento que a antiga já pegou.
- **`receiveAsFlow()` deixa a tela coletá-lo como qualquer fluxo**, no `LaunchedEffect` da seção
  05.

## A outra escola

O guia de arquitetura do Google para Android defende o oposto: que todo evento que um ViewModel
produz vire estado, um campo `userMessage` no estado da tela, e que a tela chame o ViewModel de volta
depois de mostrá-lo, para que o ViewModel limpe o campo. O argumento é que estado pode ser testado
lendo `state.value`, sobrevive ao processo num `SavedStateHandle` se precisar, e não pode se perder
entre um envio e uma recepção.

Os dois funcionam, e falham de jeitos diferentes. Uma mensagem no estado precisa que a tela avise
"mostrei", e esquecer essa chamada a mostra a cada rotação. Um channel não precisa de confirmação e
pode, num caso estreito, perder um evento: se o coletor for cancelado depois de recebê-lo e antes de
mostrá-lo. **Este curso usa o channel para mensagens que são só informação**, como "Added 45 min",
em que perder uma não custa nada, e poria no estado qualquer coisa que o estudante precise ver, um
erro que impede um salvamento, por exemplo.
