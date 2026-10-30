---
title: O @ na frente de uma propriedade
version: 1
---

A primeira tela de SwiftUI que alguém escreve tem uma linha como esta. Ela aparece aqui como a
documentação da Apple a mostra, e **não é rodada neste curso**: o SwiftUI é um dos frameworks da Apple
e não existe no Linux, o que a aula 1 disse e a aula 20 retoma.

```swift
struct TimerView: View {
    @State private var minutes = 45

    var body: some View {
        Stepper("\(minutes) minutes", value: $minutes, in: 0...600, step: 5)
    }
}
```

`@State` na frente de `var minutes`, e `$minutes` mais abaixo: duas sintaxes que este curso ainda não
viu. **`@State` é um property wrapper**, e `$minutes` é o valor que ele projeta. Nenhum dos dois é
exclusivo do SwiftUI. Os dois são recursos da linguagem, e vale entendê-los de fora antes de usá-los
todo dia no `ios-apps`, porque um property wrapper muda o que ler e escrever uma propriedade faz, e
nada no lugar em que você a lê avisa isso.

## A repetição que um wrapper elimina

Comece por um problema que o planner tem de verdade. Os minutos de uma sessão de estudo precisam ficar
entre 0 e 600, e a meta da semana também, e uma pausa também. A aula 6 lhe deu as ferramentas para
fazer isso à mão: uma propriedade armazenada privada e uma computada na frente dela.

```swift
// ByHand.swift
struct StudySession {
    private var storedMinutes = 0
    var minutes: Int {
        get { storedMinutes }
        set { storedMinutes = min(max(newValue, 0), 600) }
    }
}

var session = StudySession()
session.minutes = 45
print(session.minutes)
session.minutes = 900
print(session.minutes)
session.minutes = -5
print(session.minutes)
```

```
ana@vm:~/sw/l16$ swift ByHand.swift
45
600
0
```

Funciona: 900 virou 600 e −5 virou 0. **Custa seis linhas por propriedade**, e a regra, de 0 a 600,
fica escrita dentro do setter de cada uma. Uma segunda propriedade que precisa da mesma regra são mais
seis linhas e uma segunda cópia da regra, e o dia em que alguém trocar 600 por 720 numa cópia e não na
outra é o dia em que as duas discordam.

Um property wrapper é esse padrão, o valor armazenado e o código que o protege, escrito **uma vez**
como um tipo, e aplicado com um `@` a quantas propriedades precisarem dele. A seção 03 o escreve.

## O que o compilador faz com o @

Quando o compilador vê `@Something var x`, ele gera, a partir da sua única linha, o que o
`ByHand.swift` escreveu à mão: uma propriedade armazenada escondida, `_x`, guardando uma instância de
`Something`, e um `x` computado cujo getter e setter passam por essa instância. **Ler `x` chama
código.** No SwiftUI o código por trás do `@State` guarda o valor fora da view e avisa o SwiftUI para
redesenhar quando ele muda, e é por isso que atribuir a `minutes` numa view do SwiftUI atualiza a
tela. A seção 04 mostra de onde vem o `$minutes`.
