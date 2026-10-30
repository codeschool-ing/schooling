---
title: Escrevendo uma lambda
version: 1
---

Uma lambda é chaves em volta de uma lista de parâmetros, uma seta e um corpo. Quatro regras cobrem
quase toda lambda que você vai ler:

```schooling-example
{"language": "kotlin", "file": "Lambdas.kt", "parts": [{"code": "fun main() {\n    val isLong = { minutes: Int -> minutes >= 60 }", "note": "Sem nada à esquerda dizendo o que o parâmetro é, a própria lambda declara o tipo. O tipo de `isLong` então é inferido: `(Int) -> Boolean`."}, {"code": "    val half: (Int) -> Int = { it / 2 }", "note": "**Uma lambda com exatamente um parâmetro pode deixá-lo sem nome** e chamá-lo de `it`, quando o tipo é conhecido por outro lado, aqui o tipo declarado à esquerda."}, {"code": "    val describe: (Int) -> String = { minutes ->\n        val hours = minutes / 60\n        val rest = minutes % 60\n        \"$hours h $rest min\"\n    }", "note": "Uma lambda pode ter várias linhas. **O valor da última expressão é o resultado**: não há `return`."}, {"code": "    val courseOnly: (String, Int) -> String = { course, _ -> course }", "note": "`_` nomeia um parâmetro que a lambda não usa, o que diz isso a quem lê e cala o aviso do compilador."}, {"code": "    println(isLong(90))\n    println(half(45))\n    println(describe(135))\n    println(courseOnly(\"Kotlin\", 45))\n}"}]}
```

```
ana@vm:~/kt/l04$ kotlinc Lambdas.kt -include-runtime -d lambdas.jar && java -jar lambdas.jar
true
22
2 h 15 min
Kotlin
```

## O `return` não significa o que parece

A última expressão é o resultado, então um `return` dentro de uma lambda não é necessário, e na
maioria dos lugares não é permitido:

```kotlin
// LambdaReturn.kt
fun main() {
    val double: (Int) -> Int = { m -> return m * 2 }
    println(double(45))
}
```

```
ana@vm:~/kt/l04$ kotlinc LambdaReturn.kt -include-runtime -d lambdareturn.jar
LambdaReturn.kt:3:39: error: 'return' is prohibited here.
    val double: (Int) -> Int = { m -> return m * 2 }
                                      ^^^^^^
LambdaReturn.kt:3:46: error: return type mismatch: expected 'Unit', actual 'Int'.
    val double: (Int) -> Int = { m -> return m * 2 }
                                             ^^^^^
```

**Um `return` simples em Kotlin sempre retorna da `fun` mais próxima**, e a lambda não é uma. Aqui
seria o `main`, que devolve `Unit` e não consegue devolver `m * 2`, e mesmo onde os tipos batem o
compilador recusa, por um motivo que a seção 08 dá. Quando você precisa sair cedo de uma lambda, a
forma é um retorno com rótulo, `return@rotulo`, que a seção 08 também mostra.

## Quando dar nome ao `it`

O `it` é curto, e fica ilegível quando lambdas se aninham, porque o `it` de dentro esconde o de fora.
**Dê nome ao parâmetro quando a lambda passar de uma linha, ou quando ela estiver dentro de outra
lambda.** `{ it >= 60 }` é claro; `{ session -> session.minutes >= 60 }` fica mais claro no momento em
que há duas coisas de que a lambda poderia estar falando.
