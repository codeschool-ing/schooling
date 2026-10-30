---
title: O operador elvis, ?:
version: 1
---

Uma chamada segura mantém um valor ausente ausente. Mais cedo ou mais tarde o programa precisa de um
valor de verdade, e o `?:` dá um: `a ?: b` é `a` quando `a` não é `null`, e `b` quando é. Incline a
cabeça para a esquerda e o operador parece um topete e dois olhos, e é daí que vem o nome.

O planejador lê um número de minutos de um texto que a estudante digitou, e texto nem sempre é
número. O `toIntOrNull()` transforma `"45"` em `45` e tudo o que não consegue ler em `null`, então o
tipo dele é `Int?`. O operador elvis transforma isso num `Int`:

```schooling-example
{"language": "kotlin", "file": "Elvis.kt", "parts": [{"code": "fun minutesFrom(input: String): Int {\n    return input.toIntOrNull() ?: 0\n}", "note": "Uma função que promete um `Int`. O `toIntOrNull()` dá um `Int?`, e o `?: 0` responde o caso ausente, então a expressão inteira é um `Int` e a promessa é cumprida."}, {"code": "fun describe(note: String?): String {\n    val text = note ?: return \"no note\"\n    return \"note: $text (${text.length} chars)\"\n}", "note": "O lado direito do `?:` também sai da função. `return` ali quer dizer: se não há anotação, esta função terminou. Depois dessa linha, `text` é uma `String`, nunca null."}, {"code": "fun main() {\n    println(minutesFrom(\"45\"))\n    println(minutesFrom(\"forty\"))\n    println(minutesFrom(\"\"))\n    println(describe(null))\n    println(describe(\"read chapter 3\"))\n}", "note": "Cinco chamadas: duas que dá para ler, duas que não dá, uma sem anotação nenhuma. A lição 3 é sobre funções; aqui elas só dão ao operador um lugar onde ficar."}]}
```

```
ana@vm:~/kt/l02$ kotlinc Elvis.kt -include-runtime -d elvis.jar && java -jar elvis.jar
45
0
0
no note
note: read chapter 3 (14 chars)
```

## Um padrão é uma decisão

`?: 0` faz o programa seguir em frente, e isso nem sempre é o certo. **Uma contagem de zero minutos
para `"forty"` é um palpite que o programa deu em nome da estudante**, e o total da semana agora está
errado sem ninguém ser avisado. O operador elvis torna a decisão fácil de escrever, o que é diferente
de torná-la correta. Três lados direitos, três decisões:

| lado direito | quando é a resposta certa |
|---|---|
| um valor, `?: 0` | quando um valor ausente significa de fato aquele valor: nenhuma sessão quer dizer total 0 |
| `?: return …` | quando o resto da função não tem nada a fazer sem o valor |
| `?: throw IllegalArgumentException("…")` | quando um valor ausente é um erro que alguém precisa ouvir |

`throw` é uma expressão em Kotlin, então fica à direita do `?:` como o `return`. A lição 13 é sobre
falhas e volta a isso; o ponto aqui é que **o operador é o lugar onde um programa diz o que a ausência
significa**, e vale um segundo para escolher.

## Precedência

O `?:` liga mais fraco que quase todo o resto, então `a?.length ?: 0 + 1` é `a?.length ?: (0 + 1)`, e
não `(a?.length ?: 0) + 1`. Quando o lado direito é mais que um valor só, escreva os parênteses.
