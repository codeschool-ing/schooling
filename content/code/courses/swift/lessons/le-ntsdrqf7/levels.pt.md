---
title: Seis níveis, uma pergunta
version: 1
---

Toda declaração em Swift responde a uma pergunta, quer você escreva a resposta, quer não: **de onde
isto pode ser usado?** A resposta é um nível de acesso, e há seis. Cada um é uma região do código, e
cada região contém a de baixo:

| nível | pode ser usado de |
|---|---|
| `private` | a declaração que o envolve, e as extensões dela no mesmo arquivo |
| `fileprivate` | qualquer lugar do mesmo arquivo |
| `internal` | qualquer lugar do mesmo módulo. **O padrão**, quando você não escreve nada |
| `package` | qualquer módulo do mesmo pacote |
| `public` | qualquer módulo que importe este |
| `open` | o mesmo que `public`, e lá uma classe ou um método também pode ser herdado ou sobrescrito |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l17-levels\" aria-label=\"Cinco caixas aninhadas, cada uma dentro da anterior. A mais externa: public e open, qualquer módulo que importe este. Dentro dela: package, todo módulo deste pacote. Dentro dessa: internal, este módulo, o padrão. Dentro dessa: fileprivate, este arquivo. A mais interna: private, esta declaração e suas extensões neste arquivo, guardando var log.\"><rect x=\"20\" y=\"20\" width=\"680\" height=\"290\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"34\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">public / open</text><text x=\"146.8\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">qualquer módulo que importe este</text><rect x=\"50\" y=\"54\" width=\"620\" height=\"238\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"64\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">package</text><text x=\"131.2\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">todo módulo deste pacote</text><rect x=\"80\" y=\"88\" width=\"560\" height=\"186\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"94\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">internal</text><text x=\"168.8\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">este módulo (o padrão)</text><rect x=\"110\" y=\"122\" width=\"500\" height=\"134\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"124\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">fileprivate</text><text x=\"221.6\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">este arquivo</text><rect x=\"140\" y=\"156\" width=\"440\" height=\"82\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"154\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">private</text><text x=\"221.2\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">este tipo, e suas extensões neste arquivo</text><text x=\"360\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">var log</text></svg>", "caption": "Seis níveis de acesso como cinco regiões, cada uma dentro da seguinte. Um nome pode ser usado em qualquer lugar dentro da região que o nível dele nomeia, e em nenhum lugar fora dela."}
```

O erro comum é ler `private` como "escondido de outras pessoas". **Controle de acesso é sobre
código, não sobre pessoas**: diz que outro código pode depender de um nome, para que o nome possa
mudar depois sem quebrar esse código. Uma propriedade `private` é uma promessa de que ninguém fora
do tipo dela depende dela, e o compilador cumpre a promessa por você.

## private e fileprivate, em dois arquivos

Um programa compilado a partir de dois arquivos basta para ver os dois primeiros níveis. O
`Week.swift` guarda um registro de anotações como `private` e os minutos como `fileprivate`, e
acrescenta uma função solta no mesmo arquivo que lê os minutos:

```swift
// Week.swift
struct Week {
    private var log: [String] = []
    fileprivate var minutes: [Int] = []

    mutating func add(_ minutes: Int, note: String) {
        self.minutes.append(minutes)
        log.append(note)
    }
}

extension Week {
    var lastNote: String? { log.last }
}

func total(of week: Week) -> Int {
    week.minutes.reduce(0, +)
}
```

O `main.swift` usa a semana, e depois tenta pegar as duas propriedades armazenadas diretamente:

```swift
// main.swift
var week = Week()
week.add(45, note: "optionals")
week.add(30, note: "closures")
print(total(of: week), week.lastNote ?? "none")
print(week.minutes)
print(week.log)
```

Quando mais de um arquivo forma um programa, as instruções de nível superior vão no arquivo chamado
`main.swift`, e o `swiftc` recebe todos os arquivos numa linha:

```
ana@vm:~/sw/l17/levels$ swiftc Week.swift main.swift -o week
main.swift:6:12: error: 'minutes' is inaccessible due to 'fileprivate' protection level
4 | week.add(30, note: "closures")
5 | print(total(of: week), week.lastNote ?? "none")
6 | print(week.minutes)
  |            `- error: 'minutes' is inaccessible due to 'fileprivate' protection level
7 | print(week.log)
8 | 

Week.swift:4:21: note: 'minutes' declared here
 2 | struct Week {
 3 |     private var log: [String] = []
 4 |     fileprivate var minutes: [Int] = []
   |                     `- note: 'minutes' declared here
 5 | 
 6 |     mutating func add(_ minutes: Int, note: String) {

main.swift:7:12: error: 'log' is inaccessible due to 'private' protection level
5 | print(total(of: week), week.lastNote ?? "none")
6 | print(week.minutes)
7 | print(week.log)
  |            `- error: 'log' is inaccessible due to 'private' protection level
8 | 

Week.swift:3:17: note: 'log' declared here
 1 | // Week.swift
 2 | struct Week {
 3 |     private var log: [String] = []
   |                 `- note: 'log' declared here
 4 |     fileprivate var minutes: [Int] = []
 5 | 
```

Dois erros, um por linha que cruzou uma fronteira, e cada um aponta de volta para a declaração com
uma `note`. Dentro do `Week.swift` as mesmas leituras estavam certas: a extensão leu `log` porque
está no mesmo arquivo que o tipo, e `total(of:)` leu `minutes` porque `fileprivate` cobre o arquivo
inteiro. **O `main.swift` é outro arquivo, então as duas portas fecharam.** Tire as duas últimas
linhas e o programa compila:

```swift
// main.swift
var week = Week()
week.add(45, note: "optionals")
week.add(30, note: "closures")
print(total(of: week), week.lastNote ?? "none")
```

```
ana@vm:~/sw/l17/levels$ swiftc Week.swift main.swift -o week && ./week
75 closures
```

A `total(of:)` é a saída honesta: o arquivo dono de `minutes` oferece uma função, e todo outro
arquivo pergunta a ela. Se `minutes` virar um dicionário de dias mais tarde, só o `Week.swift` muda.

## Qual escrever

**Comece com private e alargue quando o compilador pedir.** Um nome que hoje é `private` pode virar
`internal` amanhã numa mudança de uma palavra que não quebra nada. Estreitar vai no sentido
contrário: depois que outro arquivo, ou outro módulo, usa um nome, torná-lo privado quebra esse
código, e você precisa achar cada uso primeiro.

O `fileprivate` é o mais raro dos dois. Ele vale a pena quando dois tipos de um arquivo cooperam de
perto, como um tipo e o pequeno ajudante que o formata, e nenhum deve ficar visível para o resto do
módulo. Para tudo dentro de um tipo e das extensões dele, o `private` já cobre.

Nada nesta página precisou de uma fronteira de módulo: os dois arquivos foram compilados num
programa só, um módulo só, então os nomes `internal` de cada um eram visíveis para o outro. A seção
03 constrói dois módulos.
