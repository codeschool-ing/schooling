---
title: Não existe despedida, então salve na saída
version: 1
---

**Ser morto em segundo plano não manda callback nenhum, em plataforma nenhuma, então o que precisa
sobreviver tem de ser salvo no caminho para o segundo plano, enquanto o app ainda está sendo
avisado das coisas.** Essa é a regra que esta aula existe para dar, e tudo antes desta etapa é a
evidência dela: a referência do Android diz que um processo parado pode ser morto sem que mais
nenhuma linha do código dele seja executada, a da Apple diz para esperar que um app em segundo plano
seja encerrado, e o React Native não tem valor para um processo que não existe mais.

## O lugar errado para salvar

**O erro comum é salvar quando o app fecha**, em `onDestroy`, em `applicationWillTerminate` ou numa
função de limpeza que roda quando o componente raiz é desmontado. Cada um deles roda em algumas
situações, e é por isso que o erro sobrevive aos testes: quem desenvolve e fecha o app à mão vê o
salvamento acontecer. Nenhum deles roda quando o sistema mata um app suspenso para liberar memória,
que é como a maioria dos apps termina de verdade. O usuário encontra o bug uma semana depois, num
celular com menos memória, depois de uma ligação longa.

## O lugar certo

| plataforma | o último momento em que o app com certeza é avisado | o que a documentação manda fazer ali |
|---|---|---|
| Android | `onStop` | o trabalho pesado de encerramento, já que `onPause` é breve demais |
| iOS | `.background`, e `.inactive` antes dele | salvar dados do usuário na desativação; liberar memória ao entrar em segundo plano |
| React Native | o `AppState` mudando para `background` | o mesmo momento, informado ao JavaScript |

Aqui está o planner salvando uma sessão meio digitada nesse momento, em cada um dos três. Estes
fragmentos foram adaptados da documentação de cada plataforma e **não foram compilados nem rodados
para este curso**; estão aqui para você reconhecer a mesma regra em três grafias.

Android, numa Activity, em Kotlin:

```kotlin
override fun onStop() {
    super.onStop()
    // No longer visible: from here the process may die without a word.
    drafts.save(currentDraft)
}
```

iOS, numa view SwiftUI, em Swift:

```swift
.onChange(of: scenePhase) {
    if scenePhase == .background {
        // From here iOS may suspend the app, and then terminate it.
        drafts.save(currentDraft)
    }
}
```

React Native, num componente, em TypeScript:

```tsx
useEffect(() => {
  const sub = AppState.addEventListener("change", (next) => {
    // The last value this code is sure to see before a kill.
    if (next === "background") drafts.save(currentDraft);
  });
  return () => sub.remove();
}, []);
```

**Os três são uma ideia só.** Cada um observa a passagem para o segundo plano e grava o rascunho num
lugar que sobrevive ao processo. No iOS, o guia da Apple vai um passo antes e pede para salvar os
dados do usuário na desativação, a passagem para `.inactive`; um app que salva ali também não perde
nada se a etapa de segundo plano for cortada.

## Salve rápido, e salve pouco

**O tempo na saída é curto e não é seu para esticar.** O guia do Android chama `onPause` de muito
breve, e a referência da Apple dá a `applicationWillTerminate`, a única despedida que às vezes roda,
aproximadamente cinco segundos para terminar. Um salvamento que precisa enviar um arquivo ou reescrever
um banco grande está no lugar errado; ele pertence a um trabalho que o sistema concorda em rodar, que
é o assunto da aula 15. O que cabe na saída é pouco: que curso estava aberto, o que o usuário tinha
digitado, até onde a lista estava rolada.

**E o que foi salvo precisa voltar.** Gravar o rascunho é metade do trabalho; a aula 5 é a outra
metade, pôr de volta na tela depois de um lançamento que, para o app, parece o primeiro de todos. Ela
também pergunta que coisas merecem ser salvas, porque um estado pertence ao disco para sempre, outro
só até o usuário voltar, e outro pode simplesmente ser jogado fora.
