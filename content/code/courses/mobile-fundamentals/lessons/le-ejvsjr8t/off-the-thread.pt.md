---
title: Tirando o trabalho da thread principal, em três grafias
version: 1
---

**A resposta de toda plataforma tem os mesmos três passos: entregar o trabalho lento a outra
thread, deixar a thread principal seguir desenhando e trazer o resultado de volta à thread
principal antes que ele toque a tela.** O terceiro passo é o que o iniciante esquece. Um resultado
escrito na tela a partir de um worker quebra a segunda regra do Android, e os kits da Apple fazem a
mesma exigência, então o caminho de volta faz parte do padrão tanto quanto o de ida.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l06-two-threads\" aria-label=\"Duas linhas do tempo. Na primeira, a thread principal desenha quadros, depois ordena as sessões, e nenhum quadro é desenhado até a ordenação acabar. Na segunda, a thread principal manda go a um worker e continua desenhando um quadro em cada espaço enquanto o worker ordena; o worker devolve o resultado e a thread principal o mostra.\"><defs><marker id=\"l06-two-threads-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">a ordenação na thread principal</text><text x=\"20\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">thread</text><text x=\"20\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">principal</text><rect x=\"100\" y=\"44\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">quadro</text><rect x=\"144\" y=\"44\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"164.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">quadro</text><rect x=\"188\" y=\"44\" width=\"340\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"358.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">ordenação: nenhum quadro enquanto isso</text><rect x=\"532\" y=\"44\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"552.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">quadro</text><rect x=\"576\" y=\"44\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"596.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">quadro</text><rect x=\"620\" y=\"44\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"640.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">quadro</text><rect x=\"664\" y=\"44\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"684.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">quadro</text><text x=\"20\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">a mesma ordenação num worker</text><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">thread</text><text x=\"20\" y=\"153\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">principal</text><rect x=\"100\" y=\"132\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">quadro</text><rect x=\"144\" y=\"132\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"164.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">quadro</text><rect x=\"188\" y=\"132\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"208.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">quadro</text><rect x=\"232\" y=\"132\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"252.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">quadro</text><rect x=\"276\" y=\"132\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"296.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">quadro</text><rect x=\"320\" y=\"132\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"340.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">quadro</text><rect x=\"364\" y=\"132\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"384.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">quadro</text><rect x=\"408\" y=\"132\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"428.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">quadro</text><rect x=\"452\" y=\"132\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"472.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">quadro</text><rect x=\"496\" y=\"132\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"516.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">quadro</text><rect x=\"540\" y=\"132\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"560.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">quadro</text><rect x=\"584\" y=\"132\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"604.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">quadro</text><rect x=\"628\" y=\"132\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"648.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">quadro</text><text x=\"20\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">worker</text><rect x=\"232\" y=\"212\" width=\"296\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"380.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ordenação</text><path d=\"M208 160 L208 226 L230 226\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-two-threads-ah-paper-dim)\"></path><text x=\"196\" y=\"194\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">go</text><path d=\"M530 226 L552 226 L552 160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-two-threads-ah-paper-dim)\"></path><text x=\"560\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">resultado</text></svg>", "caption": "Mudar o trabalho de lugar não o deixa mais rápido. Deixa-o com outro: a thread principal mantém todos os espaços, e só o resultado volta para ela.", "same": ["worker"]}
```

O que muda entre as plataformas é como a entrega se escreve. Os três trechos abaixo ordenam a
semana do planner fora da thread principal e a mostram na thread principal. Eles foram adaptados
da documentação de cada plataforma, e **não foram compilados nem rodados para este curso**; as
contagens de quadros da seção anterior são a evidência que esta aula tem, e elas vêm do Node.js.

## Kotlin: corrotinas e um dispatcher

```kotlin
// Sort on a background dispatcher; the caller resumes on the main thread
suspend fun sortedWeek(sessions: List<Session>): List<Session> =
    withContext(Dispatchers.Default) {
        sessions.sortedWith(compareBy({ it.date }, { it.minutes }))
    }

// In a ViewModel: the coroutine starts on the main thread
viewModelScope.launch {
    week = sortedWeek(sessions) // back on the main thread here
}
```

Uma corrotina é uma função que pode pausar sem segurar a thread dela. **O dispatcher diz em quais threads ela roda.** A documentação do Android sobre corrotinas cita três: `Dispatchers.Main` para
a interface e trabalho rápido, `Dispatchers.IO` para disco e rede, e `Dispatchers.Default` para
trabalho que ocupa o processador, com ordenar uma lista e interpretar JSON como exemplos dela
mesma. `withContext` leva um bloco para outro dispatcher e volta para o de origem, então a linha
depois da chamada já está na thread principal de novo. O curso `kotlin` dedica uma aula aos
dispatchers, a aula 14.

## Swift: async, await e o main actor

```swift
// Sort away from the main actor; the caller resumes on it
func sortedWeek(_ sessions: [Session]) async -> [Session] {
    await Task.detached(priority: .userInitiated) {
        sessions.sorted { ($0.date, $0.minutes) < ($1.date, $1.minutes) }
    }.value
}

@MainActor
func refresh() async {
    week = await sortedWeek(sessions) // back on the main actor here
}
```

**`@MainActor` marca código que precisa rodar na thread principal**; a documentação da Apple
descreve o main actor como um ator cujo executor é a fila de despacho principal. `Task.detached`
inicia um trabalho que não pertence a nenhum ator, então ele roda no conjunto de threads do
sistema, e `await` é o ponto em que `refresh` solta a thread principal e mais tarde a retoma com o
resultado. Um *actor* é a forma geral da mesma ideia: um objeto cujo estado só uma tarefa mexe por
vez. O curso `swift` dedica as aulas 14 e 15 a isso.

## React Native: uma thread de JavaScript para proteger

```tsx
// Sort once per change of the data, not on every render
const week = useMemo(
  () => [...sessions].sort((a, b) => a.date.localeCompare(b.date) || a.minutes - b.minutes),
  [sessions],
);

// The request waits outside the JavaScript thread; parsing the answer runs on it
useEffect(() => {
  fetch(COURSES_URL)
    .then((response) => response.json())
    .then(setCourses);
}, []);
```

**Aqui a thread a proteger é a de JavaScript**, e o JavaScript puro não tem um `withContext` para
mandar uma ordenação para outro lugar. Então as primeiras ferramentas são para fazer menos nela: o
`useMemo` só ordena de novo quando os dados mudam, e o `fetch` não segura a thread enquanto a rede
responde, embora a interpretação do JSON, quando a resposta chega, rode nela. Um trabalho que
continua longo demais vai para código nativo. Para animação, a documentação do React Native aponta
o native driver, `useNativeDriver: true`, que roda a animação sem pedir cada quadro à thread de
JavaScript. O curso `react-native`, se você seguir esse caminho, tem os 60 quadros por segundo fora
da thread de JavaScript como aula 12.

## Os mesmos três passos

| passo | Kotlin | Swift | React Native |
|---|---|---|---|
| entregar o trabalho | `withContext(Dispatchers.Default)` | `Task.detached { … }` | código nativo, ou fazer menos na thread JS |
| seguir desenhando | a thread principal fica livre enquanto o bloco roda | `await` libera o main actor | a thread de UI desenha; a thread JS precisa ficar curta |
| trazer o resultado de volta | `withContext` volta ao dispatcher de quem chamou | quem chama é `@MainActor` | o resultado chega como callback na thread JS |

Ler de um banco de dados numa thread de fundo, o caso em que a lista trava porque as linhas são
buscadas na thread principal, é a aula 6 do `mobile-offline`.
