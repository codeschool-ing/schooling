---
title: Um compilador que não converte por você
version: 1
---

Muitas linguagens transformam um inteiro em decimal quando você soma os dois, e não dizem nada. **O
Swift nunca converte um tipo numérico em outro a menos que você escreva a conversão.** É o primeiro
lugar em que a rigidez do compilador aparece numa soma comum, e é proposital:

```swift
// Mix.swift
let minutes = 45
let hours = 1.5
let total = minutes + hours
print(total)
```

```
ana@vm:~/sw/l01$ swiftc Mix.swift -o mix
Mix.swift:4:21: error: binary operator '+' cannot be applied to operands of type 'Int' and 'Double'
2 | let minutes = 45
3 | let hours = 1.5
4 | let total = minutes + hours
  |                     |- error: binary operator '+' cannot be applied to operands of type 'Int' and 'Double'
  |                     `- note: overloads for '+' exist with these partially matching parameter lists: (Double, Double), (Int, Int)
5 | print(total)
6 | 
```

O erro diz que o `+` não tem versão que receba um `Int` e um `Double`, e a nota lista as duas que
tem: dois `Double`, ou dois `Int`. **Você escolhe qual quis dizer**, e a escolha importa, porque as
duas respostas são diferentes:

```swift
// MixFixed.swift
let minutes = 45
let hours = 1.5
let asHours = Double(minutes) / 60 + hours
let asMinutes = minutes + Int(hours * 60)
print(asHours, asMinutes)
```

```
ana@vm:~/sw/l01$ swift MixFixed.swift
2.25 135
```

`Double(minutes)` e `Int(hours * 60)` são **conversões**, escritas onde acontecem. Quem lê vê cada
lugar em que um valor muda de tipo e o que foi arredondado no caminho. A seção 06 mostrou que um
literal como `60` se adapta ao outro lado, então `Double(minutes) / 60` não precisa de uma segunda
conversão.

## Um estouro para o programa

Um `Int8` guarda de −128 a 127. Some um a 127 e muitas linguagens dão a volta para −128 sem dizer
nada. O Swift verifica toda operação aritmética com inteiros e **para o programa** em vez disso:

```swift
// Over.swift
let small: Int8 = 127
let more = small + 1
print(more)
```

```
ana@vm:~/sw/l01$ swiftc Over.swift -o over
ana@vm:~/sw/l01$ ./over 2>&1 | head -4

*** Signal 4: Backtracing from 0x562f02b17ed3... done ***

*** Program crashed: Illegal instruction at 0x0000562f02b17ed3 ***
```

O compilador aceitou, porque `small` é um nome e não um literal, e o estouro acontece enquanto o
programa roda. O programa então quebrou antes do `print`, com "Illegal instruction": a verificação
encontrou um estouro e executou uma instrução cujo único propósito é parar o processo. O relatório
completo tem umas cinquenta linhas de endereços e registradores, e o `head -4` guarda as quatro
primeiras; a linha que nomeia a quebra é a quarta.

**Quebrar é o resultado seguro aqui.** Um total que virasse −128 em silêncio seria gravado,
sincronizado e mostrado a uma estudante como a semana dela. Quando você quer de verdade aritmética
que dá a volta, para um checksum, o Swift tem operadores separados para isso, `&+` e `&-`, para que
a intenção fique escrita.

## Texto para número pode falhar

Um número digitado por uma estudante chega como texto. `Int("45")` o converte, e a conversão pode
falhar, porque `"forty-five"` não é um número:

```swift
// Parse.swift
let typed = "45"
let minutes = Int(typed)
print(minutes)
```

```
ana@vm:~/sw/l01$ swift Parse.swift
Parse.swift:4:7: warning: expression implicitly coerced from 'Int?' to 'Any'
2 | let typed = "45"
3 | let minutes = Int(typed)
4 | print(minutes)
  |       |- warning: expression implicitly coerced from 'Int?' to 'Any'
  |       |- note: provide a default value to avoid this warning
  |       |- note: force-unwrap the value to avoid this warning
  |       `- note: explicitly cast to 'Any' with 'as Any' to silence this warning
5 | 
Optional(45)
```

O programa rodou e imprimiu `Optional(45)`, não `45`, depois de um aviso sobre a mesma linha. O
`Int(typed)` não devolve um `Int`. Devolve um `Int?`, um **opcional**: ou um número, ou nada, e o
aviso é o compilador apontando que você imprimiu o embrulho em vez do número. A lição 2 é sobre esse
tipo: o que o `?` quer dizer, os quatro jeitos de tirar o número de dentro e o único jeito que
quebra.
