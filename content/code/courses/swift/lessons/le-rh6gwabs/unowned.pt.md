---
title: unowned, e a quebra quando ele está errado
version: 1
---

O `weak` custa um opcional em cada leitura. Quando um objeto nunca pode viver mais que outro, o Swift
oferece uma referência que também não conta e não é opcional: **`unowned`**. Ela é uma promessa de
que o objeto ainda estará lá sempre que essa referência for usada. Se a promessa for quebrada, o
programa não lê memória liberada em silêncio. Ele para.

```swift
// Unowned.swift
final class Course {
    let name: String
    init(name: String) { self.name = name }
    deinit { print("\(name): course freed") }
}

final class StudySession {
    let minutes: Int
    unowned let course: Course
    init(minutes: Int, course: Course) {
        self.minutes = minutes
        self.course = course
    }
}

var swift: Course? = Course(name: "Swift")
let session = StudySession(minutes: 45, course: swift!)
print("\(session.minutes) minutes of \(session.course.name)")
swift = nil
print("\(session.minutes) minutes of \(session.course.name)")
```

```
ana@vm:~/sw/l11$ swiftc Unowned.swift -o unowned
ana@vm:~/sw/l11$ SWIFT_BACKTRACE=enable=no ./unowned
45 minutes of Swift
Swift: course freed
Fatal error: Attempted to read an unowned reference but object 0x55cc4b7b6e30 was already destroyed
Current stack trace:
0    libswiftCore.so                    0x00007f3b6f962cd0 swift_reportError + 33
1    libswiftCore.so                    0x00007f3b6fc77e17 <unavailable> + 4685335
2    libswiftCore.so                    0x00007f3b6fc77e9b <unavailable> + 4685467
3    libswiftCore.so                    0x00007f3b6fc77f82 <unavailable> + 4685698
4    libswiftCore.so                    0x00007f3b6fc76104 <unavailable> + 4677892
5    unowned                            0x000055cc18385d09 <unavailable> + 7433
6    libc.so.6                          0x00007f3b6f42a1ca <unavailable> + 172490
7    libc.so.6                          0x00007f3b6f42a200 __libc_start_main + 139
8    unowned                            0x000055cc183852f5 <unavailable> + 4853
```

O primeiro `print` funciona: o curso existe, e `session.course.name` o lê sem `?`. Depois o
`swift = nil` larga a única referência forte, e o curso é liberado, como diz o `deinit` dele. **O
segundo `print` lê uma referência unowned para um objeto que já foi, e o runtime encerra o programa**
com uma mensagem que diz exatamente isso, `Attempted to read an unowned reference but object … was
already destroyed`. Em seguida vem o stack trace de onde aconteceu: primeiro quadros do runtime do Swift,
depois o próprio `unowned`, o programa que leu a referência.

O `SWIFT_BACKTRACE=enable=no` antes do comando desliga o relatório completo de quebra do Swift, que no
Linux passa de cinquenta linhas de registradores e memória, e mantém o stack trace curto que você vê.
Ele muda o relatório e nada mais; sem ele o programa quebra na mesma linha.

## Escolhendo entre os dois

| | `weak` | `unowned` |
|---|---|---|
| soma na contagem | não | não |
| tipo | sempre um `var` opcional | não opcional, `let` ou `var` |
| quando o objeto já foi | lê `nil` | para o programa |
| use quando | o outro objeto pode ir primeiro | o outro objeto nunca vai primeiro |

**Na dúvida, use `weak`.** Uma referência unowned que estava certa quando foi escrita vira uma quebra
no dia em que alguém muda quem segura o quê, e a quebra acontece longe da mudança. O caso honesto
clássico é um objeto criado pelo dono e nunca entregue a mais ninguém: uma sessão criada dentro de um
método do próprio curso, por exemplo, cujo curso por construção vive mais que ela. Mesmo aí, o `weak`
custa um `?`, e esse `?` sai mais barato que uma quebra que ninguém consegue reproduzir.
