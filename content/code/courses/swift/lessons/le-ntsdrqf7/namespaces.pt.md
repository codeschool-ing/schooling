---
title: Espaços de nome sem palavra-chave
version: 1
---

O Swift não tem a palavra-chave `namespace`, e não precisa. **Um módulo já é um espaço de nome**:
todo nome que ele declara pode ser escrito por inteiro como `NomeDoModulo.Nome`, e dois módulos
podem ter cada um o seu `Week` sem que nenhum quebre. Dentro de um módulo, **tipos se aninham**, e um
tipo sem casos e sem instâncias é como o Swift agrupa nomes que andam juntos.

## Agrupando constantes num enum

O planner tem alguns números com que todas as partes concordam. Constantes globais soltas
funcionariam e lotariam o autocompletar de todo arquivo; uma struct funcionaria e poderia ser criada
por engano. Um enum **sem casos** não pode ser criado de jeito nenhum, o que o torna o recipiente
convencional:

```swift
// Sources/PlannerCore/Goals.swift
public enum Goals {
    public static let weekly = 300
    public static let daily = 60

    public enum Level: String {
        case light, steady, intense
    }

    public static func level(for minutes: Int) -> Level {
        switch minutes {
        case ..<weekly: .light
        case weekly..<(weekly * 2): .steady
        default: .intense
        }
    }
}
```

Todo nome lá dentro é alcançado por `Goals`: `Goals.weekly`, `Goals.level(for:)` e o tipo aninhado
`Goals.Level`, cujo nome completo diz a que ele pertence. `Level` poderia ser um enum de nível
superior, e o aninhamento não custa nada na execução; só diz que um nível não significa nada fora
das metas.

## Duas Weeks num programa

O executável agora declara um `Week` próprio, um rótulo para a tela, e ainda precisa do da
biblioteca:

```swift
// Sources/plan/main.swift
import PlannerCore

struct Week {
    let label: String
}

let mine = Week(label: "week 44")
var theirs = PlannerCore.Week()
theirs.add(200)
theirs.add(150)

print(mine.label, theirs.total, Goals.level(for: theirs.total))
print(String(reflecting: Week.self), String(reflecting: PlannerCore.Week.self))
print(Goals.weekly - theirs.total)
let goals = Goals()
```

```
ana@vm:~/sw/l17/planner$ swift build 2>&1 | grep -v frontend
Building for debugging...
[Constructing description]
[Planning deferred tasks]
[6 / 10] PlannerCore
[12 / 13] PlannerCore
error: SwiftCompile normal x86_64 failed with a nonzero exit code. Command line:     cd /home/ana/sw/l17
    
/home/ana/sw/l17/planner/Sources/plan/main.swift:16:13: error: 'Goals' cannot be constructed because it has no accessible initializers
14 | print(String(reflecting: Week.self), String(reflecting: PlannerCore.Week.self))
15 | print(Goals.weekly - theirs.total)
16 | let goals = Goals()
   |             `- error: 'Goals' cannot be constructed because it has no accessible initializers
17 | 
error: SwiftCompile normal x86_64 /home/ana/sw/l17/planner/Sources/plan/main.swift failed with a nonzero exit code. Command line:     cd /home/ana/sw/l17
    builtin-SwiftPerFileCompile main.swift
/home/ana/sw/l17/planner/Sources/plan/main.swift:16:13: error: 'Goals' cannot be constructed because it has no accessible initializers
14 | print(String(reflecting: Week.self), String(reflecting: PlannerCore.Week.self))
15 | print(Goals.weekly - theirs.total)
16 | let goals = Goals()
   |             `- error: 'Goals' cannot be constructed because it has no accessible initializers
17 | 
error: Build failed
```

A última linha é o motivo do enum vazio: `'Goals' cannot be constructed because it has no accessible
initializers`. Tire-a e o programa roda:

```swift
// Sources/plan/main.swift
import PlannerCore

struct Week {
    let label: String
}

let mine = Week(label: "week 44")
var theirs = PlannerCore.Week()
theirs.add(200)
theirs.add(150)

print(mine.label, theirs.total, Goals.level(for: theirs.total))
print(String(reflecting: Week.self), String(reflecting: PlannerCore.Week.self))
print(Goals.weekly - theirs.total)
```

```
ana@vm:~/sw/l17/planner$ swift build 2>&1 | grep -v frontend
Building for debugging...
[Using on-disk description]
[3 / 7] plan-product
[7 / 8] plan-product
[8 / 8] plan-product
Build complete! (0.99 secs)
ana@vm:~/sw/l17/planner$ .build/debug/plan
week 44 350 steady
plan.Week PlannerCore.Week
-50
```

**Um `Week` simples dentro do `plan` quer dizer o do próprio `plan`.** Um nome declarado no módulo
atual vence um importado, e `PlannerCore.Week` passa por cima dele. O `String(reflecting:)` imprime
o nome completo de cada tipo, `plan.Week` e `PlannerCore.Week`: um nome, dois módulos, nenhum
conflito. 350 minutos é `steady`, e imprimir um caso de enum imprime o nome dele.

## Quando o conflito é o nome do módulo

Nomes completos precisam de uma coisa: nenhum tipo com o mesmo nome do módulo. Num módulo chamado
`Planner` que declara um tipo chamado `Planner`, a palavra `Planner.` em outro arquivo é lida como o
tipo, e os nomes completos do módulo deixam de ser alcançáveis. É por isso que a biblioteca deste
pacote é `PlannerCore`. **Dê a um módulo o nome do que ele contém como um todo, e aos tipos dele o
nome do que cada um é.**

A biblioteca padrão é um módulo como qualquer outro, chamado `Swift`. `Swift.print` e `Swift.max`
são os nomes completos de funções que você usa desde a aula 1, e escrevê-los por extenso é como um
tipo que tem um método `max` próprio chama o global.
