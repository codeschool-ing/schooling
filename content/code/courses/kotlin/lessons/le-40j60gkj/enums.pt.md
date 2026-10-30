---
title: Enums: um conjunto fixo de valores
version: 1
---

Uma sessão está planejada, em andamento ou feita, e nada mais. **Uma enum class declara um tipo cujos
valores são exatamente os listados**, cada um um objeto com nome e posição:

```kotlin
// Enums.kt
enum class Status(val mark: String) {
    PLANNED("[ ]"),
    RUNNING("[~]"),
    DONE("[x]"),
}

fun next(s: Status): Status = when (s) {
    Status.PLANNED -> Status.RUNNING
    Status.RUNNING -> Status.DONE
    Status.DONE -> Status.DONE
}

fun main() {
    for (s in Status.entries) println("${s.ordinal} ${s.name} ${s.mark}")
    println(next(Status.PLANNED))
    println(Status.valueOf("DONE").mark)
}
```

```
ana@vm:~/kt/l09$ kotlinc Enums.kt -include-runtime -d enums.jar && java -jar enums.jar
0 PLANNED [ ]
1 RUNNING [~]
2 DONE [x]
RUNNING
[x]
```

Cada valor é montado com os argumentos do construtor, então `mark` é uma propriedade que todo status
carrega. `entries` os lista na ordem de declaração, `name` é o identificador como texto, `ordinal` é a
posição, e `valueOf` transforma um nome de volta num valor, lançando exceção se não houver esse nome.

## Sem `else`, e por que isso importa

`next` cobre os três status e não tem `else`, e compila, porque o compilador sabe que os três são todos
os que existem. **Essa é a propriedade de que esta aula trata**: acrescente um quarto status, e todo
`when` sobre `Status` sem `else` para de compilar até dizer o que fazer com o novo.

```kotlin
// EnumAdded.kt
enum class Status { PLANNED, RUNNING, PAUSED, DONE }

fun next(s: Status): Status = when (s) {
    Status.PLANNED -> Status.RUNNING
    Status.RUNNING -> Status.DONE
    Status.DONE -> Status.DONE
}

fun main() {
    println(next(Status.PAUSED))
}
```

```
ana@vm:~/kt/l09$ kotlinc EnumAdded.kt -include-runtime -d enumadded.jar
EnumAdded.kt:4:31: error: 'when' expression must be exhaustive. Add the 'PAUSED' branch or an 'else' branch.
fun next(s: Status): Status = when (s) {
                              ^^^^
```

A mensagem nomeia o ramo que falta. Num planejador com quarenta `when` sobre um status, **o compilador
acabou de listar cada lugar que precisa decidir o que pausar significa**. Com um `else` em cada um, a
mesma mudança compilaria, e o `PAUSED` pegaria em silêncio o que quer que o `else` fizesse.

## Onde um enum deixa de bastar

Cada valor de `Status` é um objeto, o mesmo para toda sessão, então só carrega o que é verdade do
próprio status, uma marca, um rótulo. **Uma sessão em andamento tem uma hora de início, e uma feita tem
os minutos; uma planejada não tem nenhum dos dois.** Um enum não guarda dados que mudam por caso e por
sessão. Essa é a lacuna que as sealed classes preenchem.

O `ordinal` também é uma armadilha que vale nomear: ele muda quando alguém insere um valor no meio da
lista, então nunca deve ser salvo num arquivo ou banco de dados. Salve o `name`.
