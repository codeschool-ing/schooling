---
title: Lido de qualquer lugar, escrito de um só
version: 1
---

A seção 03 tornou `minutes` público, e com isso veio algo que o planner não pretendia oferecer: o
`plan` acrescentou ao array diretamente. **Qualquer módulo agora pode pôr qualquer número na
semana**, inclusive um negativo, e nada no `PlannerCore` tem a chance de dizer não. A propriedade
deveria ser legível em toda parte e mutável só por um método que a biblioteca controla.

**Um nível de acesso pode ser dado só ao setter de uma propriedade**, escrito entre parênteses depois
da palavra `set`. `public private(set) var minutes` se lê assim: qualquer um pode ler, só este tipo
pode alterar:

```swift
// Sources/PlannerCore/Week.swift
public struct Week {
    public private(set) var minutes: [Int] = []
    public var total: Int { minutes.reduce(0, +) }

    public init() {}

    public mutating func add(_ session: Int) {
        guard session > 0 else { return }
        minutes.append(session)
    }
}
```

O executável não mudou desde a seção 03:

```swift
// Sources/plan/main.swift
import PlannerCore

var week = Week()
week.minutes.append(45)
print(week.total)
```

```
ana@vm:~/sw/l17/planner$ swift build 2>&1 | grep -v frontend
Building for debugging...
[Using on-disk description]
[3 / 6] PlannerCore
[10 / 10] PlannerCore-product
error: SwiftCompile normal x86_64 /home/ana/sw/l17/planner/Sources/plan/main.swift failed with a nonzero exit code. Command line:     cd /home/ana/sw/l17
    builtin-SwiftPerFileCompile main.swift
/home/ana/sw/l17/planner/Sources/plan/main.swift:5:14: error: cannot use mutating member on immutable value: 'minutes' setter is inaccessible
3 | 
4 | var week = Week()
5 | week.minutes.append(45)
  |              `- error: cannot use mutating member on immutable value: 'minutes' setter is inaccessible
6 | print(week.total)
7 | 
error: SwiftCompile normal x86_64 failed with a nonzero exit code. Command line:     cd /home/ana/sw/l17
    
/home/ana/sw/l17/planner/Sources/plan/main.swift:5:14: error: cannot use mutating member on immutable value: 'minutes' setter is inaccessible
3 | 
4 | var week = Week()
5 | week.minutes.append(45)
  |              `- error: cannot use mutating member on immutable value: 'minutes' setter is inaccessible
6 | print(week.total)
7 | 
error: Build failed
```

O mesmo erro sai impresso duas vezes. O build compila a interface de um módulo e o código dele em
duas etapas separadas, cada etapa relata o que achou, e quando as duas tropeçam na mesma linha você
lê duas vezes. Vale ler a mensagem devagar: `cannot use mutating member on immutable value:
'minutes' setter is inaccessible`. Acrescentar muda o array, então precisa do setter, e do `plan` o
setter não existe. Para este chamador, `week.minutes` se comporta exatamente como se tivesse sido
declarado com `let`. **A correção é o método que a biblioteca oferece:**

```swift
// Sources/plan/main.swift
import PlannerCore

var week = Week()
week.add(45)
week.add(-30)
week.add(60)
print(week.minutes, week.total)
```

```
ana@vm:~/sw/l17/planner$ swift build 2>&1 | grep -v frontend
Building for debugging...
[Provisioning 1 / 4]
[3 / 7] plan-product
[8 / 8] plan-product
Build complete! (0.90 secs)
ana@vm:~/sw/l17/planner$ .build/debug/plan
[45, 60] 105
```

O `add(-30)` foi recusado pelo `guard`, e o array mostra só as duas sessões que faziam sentido. A
regra sobre sessões negativas agora mora num lugar só, dentro do módulo, e nenhum chamador consegue
contorná-la.

## As outras combinações

Os parênteses aceitam qualquer nível mais estreito que o da própria propriedade. `internal
private(set)` é a mesma ideia dentro de um módulo, e se escreve `private(set) var` porque `internal`
é o padrão. `public internal(set)` deixa os arquivos da própria biblioteca mudarem o valor à vontade
enquanto outros módulos só leem, o que serve a um valor que vários tipos da biblioteca atualizam
juntos.

**`private(set)` não é imutabilidade.** O valor ainda muda; muda só onde o tipo decide. Uma
propriedade `let` não muda de jeito nenhum depois que o inicializador a define, como a lição 6
mostrou. Escolha `let` quando o valor é fixo durante a vida da instância, e `private(set) var`
quando ele se move sob as regras do próprio tipo.
