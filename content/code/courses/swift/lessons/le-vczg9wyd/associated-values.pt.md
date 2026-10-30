---
title: Valores associados
version: 1
---

Uma atividade de estudo é leitura, um vídeo ou uma lista de exercícios, e cada tipo carrega dados
diferentes: páginas para a leitura, minutos para um vídeo, quantos exercícios foram feitos de
quantos. Uma struct com três campos opcionais permitiria absurdos, um vídeo com páginas, e faria todo
leitor verificar quais campos estão preenchidos. **Um valor associado é um dado preso a um caso**, e
só aquele caso o carrega:

```swift
// Associated.swift
enum Activity {
    case reading(pages: Int)
    case video(minutes: Int)
    case exercises(done: Int, of: Int)
}
let plan: [Activity] = [
    .reading(pages: 12),
    .video(minutes: 20),
    .exercises(done: 7, of: 10),
]
for activity in plan {
    print(activity)
}
func minutes(for activity: Activity) -> Int {
    switch activity {
    case .reading(let pages):
        return pages * 3
    case .video(let minutes):
        return minutes
    case .exercises(let done, _):
        return done * 4
    }
}
print(plan.map(minutes(for:)).reduce(0, +))
```

```
ana@vm:~/sw/l07$ swift Associated.swift
reading(pages: 12)
video(minutes: 20)
exercises(done: 7, of: 10)
84
```

**Cada caso é um formato diferente, e o tipo é os três.** O array guarda um de cada, e o `print`
mostra cada caso com os seus dados rotulados. O único jeito de ler os dados é perguntar qual caso é,
e o `switch` de `minutes(for:)` faz isso: `case .reading(let pages)` casa com uma leitura e liga o
número de páginas a uma constante nova, `pages`, para o corpo daquele caso. O `_` pula um valor de
que o código não precisa, o total de exercícios aqui. A estimativa, três minutos por página e quatro
por exercício, dá 36 + 20 + 28 = 84.

`plan.map(minutes(for:))` passa a própria função para o `map`, do jeito que a lição 3 passou funções
como valores.

## Raw ou associado, não os dois

Um raw value é o mesmo para toda instância de um caso, fixado quando o enum é escrito: `.friday` é
sempre `"friday"`. Um valor associado é escolhido cada vez que um valor é criado: um vídeo dura 20
minutos, outro 45. **Um enum pode ter um tipo ou o outro, nunca os dois**, porque um caso com dados
presos não pode ser também uma única string constante.

Esse é o formato que a lição 2 chamou de a verdade sobre os opcionais, e a seção 06 volta a ele: um
`Int?` é um enum com dois casos, um dos quais carrega um `Int`.
