---
title: A chamada segura, ?.
version: 1
---

`?.` é um ponto que verifica antes. `note?.length` pede o comprimento a `note` se `note` for uma
string, e dá `null` sem perguntar se `note` for `null`. **O resultado de uma chamada segura é sempre
anulável**, porque um dos dois desfechos é `null`: `note?.length` é um `Int?`, não um `Int`.

O planejador guarda três anotações, uma faltando e uma vazia:

```kotlin
// SafeCall.kt
fun main() {
    val notes: List<String?> = listOf("read chapter 3", null, "")
    for (note in notes) {
        println(note?.length)
    }
    val second: String? = notes[1]
    println(second?.uppercase()?.length)
    val total: Int? = notes[0]?.length
    println(total)
}
```

```
ana@vm:~/kt/l02$ kotlinc SafeCall.kt -include-runtime -d safecall.jar && java -jar safecall.jar
14
null
0
null
14
```

`for (note in notes)` executa o corpo uma vez por item da lista, com `note` representando cada item
por vez; a lição 5 tem muito mais a dizer sobre listas. As três linhas de saída são os três desfechos
que vale distinguir: **um comprimento, `null` para a anotação que falta e `0` para a vazia.** Uma
string vazia é uma string. Só `null` é ausência, e o `?.` trata as duas de jeitos diferentes de
propósito.

## Uma corrente para no primeiro null

`second?.uppercase()?.length` são duas chamadas seguras seguidas. `second` é `null`, então o primeiro
`?.` dá `null`, o segundo `?.` é perguntado sobre esse `null` e dá `null` de novo. Nada depois do
primeiro valor ausente roda. É por isso que uma corrente de chamadas seguras se lê como uma pergunta
só: "o comprimento da forma maiúscula da segunda anotação, se ela existir".

O contrário, um `.` simples depois de um `?.`, não compila, porque o valor à esquerda dele é
anulável. Depois que uma corrente fica segura, ela continua segura até alguma coisa responder o caso
do null, e a seção 04 é essa coisa.

## Fazer algo só quando o valor existe

Uma chamada segura também chama uma função cujo resultado não interessa. `note?.let { println(it) }`
executa o bloco entre chaves só quando `note` não é `null`, com `it` representando o valor. É uma
forma comum em Kotlin e em código Android, e a lição 6 explica o `let` direito, junto com os quatro
irmãos dele; por enquanto basta reconhecê-la como "se existir, faça isto".

## Quanto custa uma chamada segura

Nada que se note. O compilador transforma `note?.length` exatamente no `if` que você teria escrito à
mão: compara com `null`, desvia, chama. **A diferença é que você não consegue esquecer de escrevê-lo**,
porque sem o `?` o código não compila.
