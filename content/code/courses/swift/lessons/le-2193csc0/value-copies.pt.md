---
title: Uma struct é copiada
version: 1
---

A imagem que a maioria das pessoas traz de outras linguagens é que uma variável "aponta para" um
objeto, então duas variáveis podem apontar para o mesmo. **Para uma struct essa imagem está
errada.** Uma variável de struct guarda o próprio valor, e atribuí-la a outra variável cria um
segundo valor, independente. Mudar um nunca muda o outro:

```schooling-example
{"language": "swift", "file": "Copies.swift", "parts": [{"code": "// Copies.swift\nstruct StudySession {\n    var course: String\n    var minutes: Int\n}\n", "note": "Uma struct com duas propriedades armazenadas. O Swift escreve o inicializador por você, com um argumento por propriedade, na ordem em que foram declaradas."}, {"code": "var monday = StudySession(course: \"Swift\", minutes: 45)\nvar tuesday = monday\ntuesday.minutes = 60\nprint(monday.minutes, tuesday.minutes)\n", "note": "`tuesday = monday` copia o valor inteiro. Mudar a cópia deixa o original em 45: a primeira linha da saída."}, {"code": "func extend(_ session: StudySession) -> StudySession {\n    var longer = session\n    longer.minutes += 15\n    return longer\n}\nlet longer = extend(monday)\nprint(monday.minutes, longer.minutes)\n", "note": "Uma função também recebe uma cópia, e o parâmetro é uma constante. Para mudá-lo, a função o copia para um `var` seu e devolve o valor novo."}, {"code": "var week = [monday, tuesday]\nvar copy = week\ncopy[0].minutes = 0\nprint(week[0].minutes, copy[0].minutes)", "note": "Um array de structs também é um valor, e cada elemento dele também. A primeira sessão da cópia foi para 0 e a da semana não."}], "output": "45 60\n45 60\n45 0"}
```

O programa está cortado nas suas quatro partes, com uma nota ao lado de cada uma, e o botão de copiar
acima dele leva o arquivo inteiro sem as notas. Três pares de números, e em todo par o primeiro não
se mexeu. **Copiar é a regra em todo lugar por onde uma struct passa**: uma atribuição, um parâmetro,
um valor de retorno e um elemento de um array.

## Um parâmetro é uma cópia constante

A função `extend` não mudou o parâmetro diretamente. Não podia:

```swift
// Param.swift
struct StudySession {
    var course: String
    var minutes: Int
}
func extend(_ session: StudySession) {
    session.minutes += 15
}
```

```
ana@vm:~/sw/l05$ swiftc Param.swift -o param
Param.swift:7:21: error: left side of mutating operator isn't mutable: 'session' is a 'let' constant
5 | }
6 | func extend(_ session: StudySession) {
7 |     session.minutes += 15
  |                     `- error: left side of mutating operator isn't mutable: 'session' is a 'let' constant
8 | }
9 | 
```

**Um parâmetro é um `let`**, então uma função não pode mudar o valor que recebeu, seja qual for o
tipo. Para uma struct, isso é também a única coisa que ela poderia mudar: o valor de quem chamou foi
copiado na entrada, então mudar a cópia não chegaria até quem chamou de qualquer forma. A função do
`Copies.swift` diz o que quer dizer: constrói um valor novo e o devolve, e quem chamou decide o que
fazer com ele. O `inout` da lição 3 é o outro caminho, e o `&` no ponto da chamada está lá para tornar
a exceção visível.

## Por que copiar é o padrão

Um valor que ninguém mais pode mudar é um valor sobre o qual você raciocina localmente. Quando
`monday` vale 45 minutos numa linha, nada em outro ponto do programa pode torná-lo 60 pelas suas
costas, porque nada em outro ponto o guarda. **Todo bug do tipo "alguém mudou os meus dados" é
impossível para uma struct**, e é essa a propriedade em que a lição 15 se apoia quando duas tarefas
rodam ao mesmo tempo.

A preocupação óbvia é o custo: copiar um array de mil sessões a cada atribuição parece caro. A seção
07 mostra que o Swift não copia de fato até alguém escrever, e que a cópia em que você pensa quase
nunca chega a ser feita.
