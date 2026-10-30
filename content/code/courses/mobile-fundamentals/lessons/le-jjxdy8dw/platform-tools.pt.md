---
title: O que cada plataforma oferece para isso
version: 1
---

**Android e iOS guardam, cada um, uma pequena quantidade de estado de UI para o app, fora do processo
dele, e a devolvem depois de uma morte; o React Native não tem nada parecido, então o app anota esse
estado sozinho.** Os três fragmentos abaixo salvam a mesma coisa, os minutos digitados no formulário
de sessão nova do planner. Eles foram adaptados da documentação de cada plataforma e **não foram
compilados nem rodados para este curso**: leia-os para reconhecer o mecanismo, não para copiá-los num
projeto.

## Android: estado salvo

**O `rememberSaveable` do Compose é um `remember` que sobrevive a uma reconstrução e a uma morte.** Um
valor guardado com `remember` vive na memória e some depois de qualquer uma das duas; a versão
salvável é gravada no estado salvo que o sistema guarda, e lida de volta quando a tela é criada de
novo:

```kotlin
@Composable
fun SessionForm() {
    var minutes by rememberSaveable { mutableStateOf("") }
    TextField(value = minutes, onValueChange = { minutes = it })
}
```

**Um ViewModel chega ao mesmo depósito pelo `SavedStateHandle`.** O ViewModel em si morre com o
processo, como diz a tabela da etapa anterior; o handle é um pequeno mapa que o sistema salva para ele
e entrega ao ViewModel novo depois de uma morte:

```kotlin
class CourseViewModel(private val saved: SavedStateHandle) : ViewModel() {
    val courseId: String? get() = saved["courseId"]
    fun open(id: String) { saved["courseId"] = id }
}
```

O guia do Android acrescenta um detalhe que importa para a regra da aula 4: as APIs de estado salvo
só salvam os dados escritos nelas quando a Activity é parada. O salvamento acontece no `onStop`, no
caminho para o segundo plano, que é o último momento em que o app com certeza é avisado de algo.

## iOS: scene storage

**O `@SceneStorage` do SwiftUI é uma propriedade guardada por cena e restaurada pelo sistema.** A
documentação da Apple diz que ele funciona de modo muito parecido com State, exceto que o valor
inicial é restaurado pelo sistema se tiver sido salvo antes:

```swift
struct SessionForm: View {
    @SceneStorage("draftMinutes") private var minutes = ""

    var body: some View {
        TextField("Minutes", text: $minutes)
    }
}
```

A mesma página define os limites dele, e são os mesmos limites que o Android põe no estado salvo. Os
dados devem ser leves; dados de modelo não devem ser guardados em SceneStorage. Não é para dados
sensíveis. O sistema não garante quando nem com que frequência os dados serão gravados. E, se a cena
for destruída explicitamente, por exemplo quando a miniatura dela é removida do seletor de apps no
iPadOS, os dados também são destruídos, o que é o usuário fechando a tela de propósito.

## React Native: anote você mesmo

**O React Native não tem estado salvo próprio.** O JavaScript dele continua rodando durante uma
rotação, como a etapa anterior disse, mas, quando o processo é morto, toda variável vai embora, e
nada as devolve. O app grava o estado de UI no armazenamento no caminho para o segundo plano, com o
mesmo listener de `AppState` que a aula 4 usou, e o lê no lançamento seguinte. Um armazenamento
chave-valor de uma biblioteca da comunidade, como o AsyncStorage, é o lugar comum:

```tsx
useEffect(() => {
  const sub = AppState.addEventListener("change", (next) => {
    if (next === "background") {
      AsyncStorage.setItem("ui", JSON.stringify({ courseId, minutes }));
    }
  });
  return () => sub.remove();
}, [courseId, minutes]);
```

**Um armazenamento que o próprio app grava sobrevive a tudo, inclusive ao usuário fechar o app de
propósito.** Isso é mais do que o estado salvo das plataformas faz, e passa uma decisão para quem
desenvolve: apagar o rascunho salvo quando o formulário for enviado, e decidir se um rascunho de
dias atrás ainda deve ser oferecido. O curso `react-native` compara os armazenamentos na aula 14, se
você seguir esse caminho.

## Três ferramentas, uma forma

| | onde o estado fica guardado | o que o apaga | quão grande pode ser |
|---|---|---|---|
| estado salvo do Android | com o sistema, fora do processo | o usuário encerrar a tela | pequeno: a próxima etapa mede |
| `@SceneStorage` do iOS | com o sistema, por cena | a cena ser destruída | "leve" |
| React Native | onde o app gravar | só o app | o que o app deixar, e esse é o perigo |

**As três guardam o mesmo tipo de coisa**: o id do que estava aberto, um número para onde o usuário
estava, e as strings de um formulário não terminado. Nenhuma delas serve para o plano em si. A
próxima etapa roda essa forma no seu computador, com morte e tudo.
