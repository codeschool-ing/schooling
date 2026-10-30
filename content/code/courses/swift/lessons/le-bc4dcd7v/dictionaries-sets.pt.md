---
title: Dicionários e conjuntos
version: 1
---

Mais duas coleções, e cada uma responde a uma pergunta diferente da do array. **Um dicionário responde
"o que vai com esta chave?"**: os minutos estudados de cada curso. **Um conjunto responde "isto está
aqui?"**: os dias em que um curso tem sessões. Nenhum dos dois guarda ordem.

## Um dicionário procura pela chave

```swift
// Dictionaries.swift
var minutesByCourse = ["Swift": 135, "Kotlin": 60]
minutesByCourse["SQL"] = 30
minutesByCourse["Swift", default: 0] += 45
minutesByCourse["Go", default: 0] += 20
print(minutesByCourse["Swift"] ?? 0)
print(String(describing: minutesByCourse["Rust"]))
minutesByCourse["Kotlin"] = nil
print(minutesByCourse.count)
for course in minutesByCourse.keys.sorted() {
    print(course, minutesByCourse[course] ?? 0)
}
```

```
ana@vm:~/sw/l04$ swift Dictionaries.swift
180
nil
3
Go 20
SQL 30
Swift 180
```

O tipo é `[String: Int]`: chaves de um tipo, valores de outro. **Ler pela chave dá um opcional**, já
que a chave pode não estar lá, e `"Rust"` não estava. O `?? 0` é a resposta da aula 2. A forma com
`default:` é a que se usa para um total acumulado: lê 0 para uma chave que falta, soma e guarda o
resultado, então `"Go"` chegou com 20 sem ser criado antes. Atribuir `nil` remove uma chave.

## Um dicionário não tem ordem

O último laço ordenou as chaves antes de imprimi-las. Não era enfeite:

```swift
// Unordered.swift
let minutesByCourse = ["Swift": 135, "Kotlin": 60, "SQL": 30, "Go": 20]
print(minutesByCourse)
```

```
ana@vm:~/sw/l04$ swift Unordered.swift
["Swift": 135, "Go": 20, "SQL": 30, "Kotlin": 60]
ana@vm:~/sw/l04$ swift Unordered.swift
["Kotlin": 60, "SQL": 30, "Swift": 135, "Go": 20]
ana@vm:~/sw/l04$ swift Unordered.swift
["Kotlin": 60, "Swift": 135, "SQL": 30, "Go": 20]
```

**O mesmo programa, rodado três vezes, imprimiu o mesmo dicionário em ordens diferentes.** Um
dicionário guarda as chaves onde o hash delas manda, e o Swift semeia o hash de forma diferente em cada
processo, de propósito: isso torna impossível depender da ordem por acidente. Quando um relatório
precisa de ordem, ordene as chaves, como o primeiro programa fez, ou use um array de pares.

## Um conjunto guarda cada valor uma vez

```swift
// Sets.swift
var swiftDays: Set = ["Mon", "Wed", "Fri"]
let kotlinDays: Set = ["Wed", "Thu"]
print(swiftDays.contains("Wed"), swiftDays.contains("Tue"))
let result = swiftDays.insert("Mon")
print(result.inserted, swiftDays.count)
print(swiftDays.intersection(kotlinDays).sorted())
print(swiftDays.union(kotlinDays).sorted())
print(swiftDays.subtracting(kotlinDays).sorted())
```

```
ana@vm:~/sw/l04$ swift Sets.swift
true false
false 3
["Wed"]
["Fri", "Mon", "Thu", "Wed"]
["Fri", "Mon"]
```

Inserir `"Mon"` uma segunda vez não fez nada, e o `insert` disse isso: `inserted` é `false` e a
contagem continua três. **O `contains` num conjunto leva o mesmo tempo curto seja qual for o tamanho
do conjunto**, o que num array significaria percorrer cada item. As três operações respondem às
perguntas que um planner faz: os dias que os dois cursos compartilham, os dias com alguma sessão, os
dias que só o Swift tem. Elas imprimem ordenadas pelo mesmo motivo do dicionário.

| pergunta | coleção |
|---|---|
| em que ordem, e o que está na posição 3? | array |
| qual é o valor desta chave? | dicionário |
| este está aqui, e o que dois têm em comum? | conjunto |
