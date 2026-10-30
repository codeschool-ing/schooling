---
title: Fora da thread principal, em três plataformas
version: 1
---

**A correção de um travamento é tirar o trabalho lento para outra thread e trazer só o resultado de
volta à principal.** Cada plataforma tem um jeito padrão, e cada uma tem a mesma armadilha: mexer na
interface a partir da outra thread, o que toda plataforma proíbe. *As listagens foram escritas a
partir da documentação de cada plataforma e não foram rodadas.*

## Kotlin: uma coroutine no dispatcher de IO

```kotlin
// WeekViewModel.kt: read the sessions on a background dispatcher, publish on the main one
fun loadWeek(monday: LocalDate) = viewModelScope.launch {
    val sessions = withContext(Dispatchers.IO) { repository.sessionsFrom(monday) }
    _week.value = WeekState(sessions, sessions.sumOf { it.minutes })
}
```

O `viewModelScope.launch` começa na thread principal; o `withContext(Dispatchers.IO)` roda a leitura
do banco num pool feito para trabalho que bloqueia, e volta à thread principal para a atribuição. O
**StrictMode** do Android, ligado nos builds de debug, aponta acesso a disco e a rede na thread
principal antes que um usuário encontre o ANR.

## Swift: um actor longe do main actor

```swift
// WeekModel.swift: the read happens off the main actor, the published state on it
@MainActor final class WeekModel: ObservableObject {
    @Published var total = 0
    func load(monday: Date) async {
        let sessions = await store.sessions(from: monday)   // store is an actor of its own
        total = sessions.reduce(0) { $0 + $1.minutes }
    }
}
```

O modelo pertence ao **main actor**, então o estado publicado dele só é mexido ali; o `store` é
outro actor, então o `await` roda o trabalho dele em outro lugar e suspende quem chamou em vez de
bloqueá-lo.

## React Native: a thread JavaScript é a que trava

```typescript
// useWeek.ts: the query runs in native code, asynchronously, and the JavaScript thread waits without blocking
export function useWeek(monday: string) {
  const [total, setTotal] = useState(0);
  useEffect(() => {
    db.getAllAsync<{ minutes: number }>("select minutes from sessions where date >= ?", [monday])
      .then((rows) => setTotal(rows.reduce((n, r) => n + r.minutes, 0)));
  }, [monday]);
  return total;
}
```

O React Native tem a própria thread principal para as views nativas e uma **thread JavaScript** para
o seu código. Uma computação longa em JavaScript congela todo tratador de toque e toda animação
conduzidos pelo JavaScript, então a mesma regra vale ali: a chamada ao banco é assíncrona, feita em
código nativo pelo `expo-sqlite`, e só a soma acontece em JavaScript.

## Medindo a cura

Tirar trabalho da thread principal não o deixa mais rápido; deixa o app **responder** enquanto ele
acontece. O número que mostra que a cura funcionou é a taxa de ANR percebida pelo usuário caindo no
Android vitals e os relatórios de travamento sumindo, e não a duração do trabalho, que a lição 15
mede à parte.
