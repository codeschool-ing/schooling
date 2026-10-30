---
title: Observadores: willSet e didSet
version: 1
---

Às vezes uma propriedade armazenada deve continuar armazenada e ainda assim rodar código quando muda:
para manter um valor dentro de um limite, registrar uma mudança, avisar uma tela que precisa
redesenhar. **Um observador de propriedade é código preso a uma propriedade armazenada que roda em
volta de toda atribuição.** O `willSet` roda logo antes de o valor novo ser guardado, e o `didSet`
logo depois:

```swift
// Observers.swift
struct StudySession {
    var minutes: Int {
        willSet { print("will change from \(minutes) to \(newValue)") }
        didSet {
            if minutes > 600 { minutes = 600 }
            print("changed from \(oldValue) to \(minutes)")
        }
    }
}
var session = StudySession(minutes: 45)
session.minutes = 60
session.minutes = 900
print(session.minutes)
```

```
ana@vm:~/sw/l06$ swift Observers.swift
will change from 45 to 60
changed from 45 to 60
will change from 60 to 900
changed from 60 to 600
600
```

Três coisas valem ser lidas na saída.

**Criar a sessão não imprimiu nada.** O inicializador pôs 45 em `minutes`, e nenhum observador rodou:
observadores rodam em atribuições a uma instância que já existe, nunca durante a inicialização dela.
Um valor que precisa ser verificado desde o primeiro momento precisa da verificação no inicializador
também, o que a seção 07 mostra.

**O `willSet` vê o `newValue`, o `didSet` vê o `oldValue`.** Cada um recebe, com esse nome, o valor
que de outro jeito não veria, e a própria propriedade guarda o outro.

**O `didSet` pode atribuir à propriedade de novo**, e essa atribuição não dispara os observadores uma
segunda vez. O 900 foi guardado, o `didSet` o trocou por 600, e a linha que ele imprimiu já mostra o
valor limitado. É assim que um observador mantém uma propriedade dentro de uma faixa, um padrão que
a lição 16 transforma num wrapper reutilizável.

## Para que serve um observador num app

Num iPhone, uma tela precisa redesenhar quando os dados por baixo dela mudam, e o jeito mais antigo de
arranjar isso é um observador na propriedade que chama a tela. O SwiftUI faz isso por você, com
property wrappers construídos sobre a mesma ideia, e a lição 16 os olha de fora. **Um observador não
é uma propriedade computada**: o valor continua armazenado, e o observador só acrescenta código em
volta das mudanças. Uma propriedade não pode ser computada e observada ao mesmo tempo, já que o
próprio setter de uma propriedade computada já é o lugar desse código.
