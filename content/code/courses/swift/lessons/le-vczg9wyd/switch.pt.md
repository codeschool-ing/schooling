---
title: Um switch precisa cobrir todos os casos
version: 1
---

O `switch` do Swift se parece com a instrução de mesmo nome em C ou Java e se comporta diferente em
dois pontos que importam. **Ele precisa ser exaustivo**: todo valor possível é tratado, ou não
compila. **E um caso não cai no seguinte**: quando o corpo de um caso termina, o switch termina. Uma
versão da função da seção 03 que esqueceu os exercícios:

```swift
// Missing.swift
enum Activity {
    case reading(pages: Int)
    case video(minutes: Int)
    case exercises(done: Int, of: Int)
}
func minutes(for activity: Activity) -> Int {
    switch activity {
    case .reading(let pages):
        return pages * 3
    case .video(let minutes):
        return minutes
    }
}
```

```
ana@vm:~/sw/l07$ swiftc Missing.swift -o missing
Missing.swift:8:5: error: switch must be exhaustive
 6 | }
 7 | func minutes(for activity: Activity) -> Int {
 8 |     switch activity {
   |     |- error: switch must be exhaustive
   |     `- note: add missing case: '.exercises(done: let done, of: let of)'
 9 |     case .reading(let pages):
10 |         return pages * 3
```

**A nota é a parte útil**: ela nomeia o caso que falta, já escrito como um padrão que você poderia
colar. Essa é a recompensa de um enum sobre uma string. Acrescente uma quarta atividade no mês que
vem, um `.quiz`, e todo `switch` sobre `Activity` no programa para de compilar até alguém decidir o
que um quiz significa ali. Com strings, o valor novo cairia em silêncio no que o último ramo fizesse.

## default, e por que evitá-lo

O `default:` casa com tudo que não casou acima dele, e torna qualquer switch exaustivo. É
exatamente esse o perigo com um enum seu: **um `default` desliga a verificação de onde veio a nota
acima**. No dia em que `.quiz` for acrescentado, um switch com `default` compila tranquilo e trata um
quiz como o `default` tratar. Liste os casos, e guarde o `default` para tipos cujos valores não podem
ser listados, como `Int` ou `String`:

```swift
// Grades.swift
func label(for score: Int) -> String {
    switch score {
    case 90...100: return "excellent"
    case 70..<90: return "pass"
    case 0..<70: return "not yet"
    default: return "invalid"
    }
}
print(label(for: 95), label(for: 70), label(for: 69), label(for: 120))
```

```
ana@vm:~/sw/l07$ swift Grades.swift
excellent pass not yet invalid
```

`90...100` é um intervalo fechado, as duas pontas incluídas, e `70..<90` um semiaberto que para antes
do 90. Nenhum switch sobre `Int` consegue listar todos os inteiros, então o compilador exige o
`default` aqui, e ele pega a nota impossível.

## Um enum de outra pessoa

Um enum de um framework pode ganhar casos numa versão posterior do framework, que o seu app compilado
nunca viu. Para esses, o Swift oferece o `@unknown default:`, que trata o caso que ninguém listou e
ainda assim **avisa** na compilação quando o enum contra o qual você compila tem um caso que o seu
switch não nomeia. Você o encontra nos frameworks da Apple; para os seus enums, listar todos os casos
é a proteção inteira e não custa nada.
