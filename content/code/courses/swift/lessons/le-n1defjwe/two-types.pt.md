---
title: Dois tipos onde você esperava um
version: 1
---

A aula 1 terminou em `Int("45")`, que deu `Optional(45)` em vez de `45`. Aquilo não era uma
esquisitice do `Int`. **O Swift divide todo tipo em dois: `String`, que sempre guarda uma string, e
`String?`, que guarda uma string ou nada.** O nada se escreve `nil`, e só o segundo tipo o aceita.

Em muitas linguagens qualquer objeto pode ser nulo, e nada no código diz quais. O compilador deixa
você pedir o comprimento de um valor ausente, e o programa descobre quando roda. O planner de uma
estudante tem anotações que faltam muito mais vezes do que existem, então essa quebra é a mais comum
que há. O Swift leva a pergunta para a compilação:

```swift
// TwoMistakes.swift
let course: String = nil
let note: String? = "read chapter 3"
print(note.count)
```

```
ana@vm:~/sw/l02$ swiftc TwoMistakes.swift -o twomistakes
TwoMistakes.swift:2:22: error: 'nil' cannot initialize specified type 'String'
1 | // TwoMistakes.swift
2 | let course: String = nil
  |             |        `- error: 'nil' cannot initialize specified type 'String'
  |             `- note: add '?' to form the optional type 'String?'
3 | let note: String? = "read chapter 3"
4 | print(note.count)

TwoMistakes.swift:4:7: error: value of optional type 'String?' must be unwrapped to refer to member 'count' of wrapped base type 'String'
2 | let course: String = nil
3 | let note: String? = "read chapter 3"
4 | print(note.count)
  |       |- error: value of optional type 'String?' must be unwrapped to refer to member 'count' of wrapped base type 'String'
  |       |- note: chain the optional using '?' to access member 'count' only for non-'nil' base values
  |       `- note: force-unwrap using '!' to abort execution if the optional value contains 'nil'
5 | 
```

**Dois erros, e cada um é metade da regra.** O primeiro: uma `String` não pode ser `nil`, e a nota
sugere acrescentar `?` para fazer dela uma `String?`. O segundo: `note` é uma `String?`, então pode
ser `nil`, e pedir o `count` de `nil` não tem resposta. O compilador se recusa a adivinhar e lista
dois caminhos, um `?` e um `!`, que são as seções 05 e 06 desta aula.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l02-two-types\" aria-label=\"Duas caixas. A da esquerda, String, guarda strings como &quot;Swift&quot;, &quot;&quot; e &quot;read chapter 3&quot;, e nunca é nil. A da direita, String?, guarda as mesmas strings e também nil. Uma seta de String para String? diz de graça: toda String é uma String?. Uma seta de volta diz: a volta exige uma resposta para nil, com as quatro respostas if let, guard let, ?? e !.\"><defs><marker id=\"l02-two-types-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l02-two-types-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30\" y=\"40\" width=\"230\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"145\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">String</text><text x=\"145\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;Swift&quot;</text><text x=\"145\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;&quot;</text><text x=\"145\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;read chapter 3&quot;</text><text x=\"145\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">nunca nil</text><rect x=\"460\" y=\"40\" width=\"230\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"575\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">String?</text><rect x=\"480\" y=\"78\" width=\"190\" height=\"82\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"575\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;Swift&quot;</text><text x=\"575\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;&quot;</text><text x=\"575\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;read chapter 3&quot;</text><text x=\"575\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">nil</text><text x=\"575\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">uma String, ou nil</text><line x1=\"265\" y1=\"100\" x2=\"455\" y2=\"100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l02-two-types-ah-phosphor)\"></line><text x=\"360\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">de graça: toda String é uma String?</text><line x1=\"455\" y1=\"160\" x2=\"265\" y2=\"160\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\" marker-end=\"url(#l02-two-types-ah-amber)\"></line><text x=\"360\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">a volta exige uma resposta para nil:</text><text x=\"360\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">if let, guard let, ??, !</text></svg>", "caption": "Dois tipos, e a seta entre eles é de graça num sentido só."}
```

## Uma String é sempre uma String?

A seta da figura só é de graça num sentido. **Toda `String` pode ser usada onde se espera uma
`String?`**, porque uma string é uma das coisas que uma `String?` pode guardar. Voltar exige uma
resposta para o caso `nil`, e o resto desta aula são as quatro respostas que o Swift oferece.

```swift
// Nulls.swift
let course: String = "Swift"
var note: String? = nil
print(note == nil)
note = course
print(note == nil, note == "Swift")
let empty: String? = ""
print(empty == nil)
```

```
ana@vm:~/sw/l02$ swift Nulls.swift
true
false true
false
```

`note` começou vazio, recebeu uma string de `course` sem conversão escrita, e daí em diante foi igual
a `"Swift"`. A última linha é a distinção que vale guardar: **`""` é uma string, sem nada dentro;
`nil` não é string nenhuma.** Uma anotação que a estudante apagou e uma que ela nunca escreveu são
dois fatos diferentes, e uma `String?` consegue dizer qual.

## Do que o ? é feito

`String?` é abreviação. O tipo por baixo é `Optional<String>`, uma enumeração com exatamente dois
casos: `.some`, que carrega um valor, e `.none`, que é o que `nil` quer dizer.

```swift
// Spelled.swift
let typed: Optional<Int> = .some(45)
let missing: Int? = .none
print(typed == 45, missing == nil, type(of: typed))
```

```
ana@vm:~/sw/l02$ swift Spelled.swift
true true Optional<Int>
```

Você quase nunca vai escrever `.some` ou `.none`, e ainda não precisa. Vale reconhecer, porque as
mensagens do compilador e o `print` usam o nome longo, e a aula 7 volta ao `Optional` como a
primeira enum que você usou na vida.
