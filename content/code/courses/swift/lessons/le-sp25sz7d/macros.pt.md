---
title: Macros, código que escreve código que você pode ler
version: 1
---

Property wrappers e result builders são reescritas fixas: o compilador conhece as regras do `@` com um
wrapper e do bloco com um builder, e as aplica. **Uma macro é uma reescrita que outra pessoa
escreveu**: um pequeno programa que o compilador roda enquanto compila o seu, que recebe um pedaço do
seu código e devolve código novo para acrescentar a ele. Você usa uma com `#nome(…)` numa expressão, ou
`@Nome` numa declaração.

Este curso já encontrou uma de passagem. O `#expect`, que a lição 18 usa em todo teste, é uma macro.
No `ios-apps` a mais importante é a `@Observable`, que transforma uma classe num modelo que o SwiftUI
observa à procura de mudanças. O SwiftUI não está aqui, e **a `@Observable` está**: ela vive no módulo
`Observation`, que vem com o toolchain também no Linux.

```swift
// Observed.swift
import Observation

@Observable
final class WeekModel {
    var minutes = 0
}

let model = WeekModel()
withObservationTracking {
    print("the screen reads \(model.minutes)")
} onChange: {
    print("minutes is about to change: draw again")
}
model.minutes = 45
model.minutes = 90
print("now \(model.minutes)")
```

```
ana@vm:~/sw/l16$ swiftc Observed.swift -o observed && ./observed
the screen reads 0
minutes is about to change: draw again
now 90
```

O `withObservationTracking` roda a primeira closure e guarda toda propriedade observável que ela leu:
aqui, `minutes`. Quando uma delas está para mudar, ele chama a segunda closure. É o que o SwiftUI faz
com o `body` de uma view: lê o modelo enquanto desenha, e desenha de novo quando o que leu muda. **A
closure `onChange` rodou uma vez, na primeira de duas escritas**, porque o acompanhamento vale uma vez
só: quem quer saber da próxima mudança acompanha de novo, o que o SwiftUI faz a cada vez que
redesenha.

## Olhando por dentro

Um property wrapper esconde a sua expansão; a de uma macro pode ser impressa. A flag do compilador
`-dump-macro-expansions` escreve tudo o que toda macro produziu, 85 linhas para esta única classe, e o
`sed` guarda dois pedaços: o novo armazenamento, e o getter que `minutes` agora tem.

```
ana@vm:~/sw/l16$ swiftc -Xfrontend -dump-macro-expansions Observed.swift -o observed 2>&1 | sed -n '/private  var _minutes/p; /^    get {/,/^    }/p'
private  var _minutes  = 0
    get {
      access(keyPath: \.minutes)
      return _minutes
    }
```

**`minutes` deixou de ser uma propriedade armazenada.** A macro moveu o valor para `_minutes` e deu a
`minutes` um getter que primeiro chama `access(keyPath:)`, que é como o `withObservationTracking`
soube que a closure o leu. O setter, mais abaixo na saída completa, chama `withMutation`, que é como o
`onChange` ficou sabendo da escrita. É a mesma ideia do wrapper da seção 03, um armazenamento escondido
atrás de uma propriedade com código na frente, gerado por um programa em vez de por uma regra da
linguagem.

## O que uma macro não é

- **Não é uma substituição de texto.** Uma macro recebe o seu código já analisado, e o que ela devolve
  passa pela verificação de tipos como código que você escreveu. Uma macro não consegue produzir algo
  que não compilaria escrito à mão.
- **Não muda o que você escreveu.** Ela acrescenta declarações, acessores ou expressões onde o autor
  dela disse que acrescentaria; o seu `var minutes = 0` continua lá, agora com acessores presos.
- **Não é mágica em tempo de execução.** Tudo aconteceu durante a compilação, e o
  `-dump-macro-expansions` mostra tudo. Quando o comportamento de uma macro surpreender você, leia a
  expansão antes de ler qualquer outra coisa.

Escrever uma macro própria pede um pacote separado construído sobre a biblioteca `swift-syntax` da
Apple, e isso fica além deste curso; usá-las bem pede só o que esta seção mostrou. No Xcode, clicar com
o botão direito numa macro e escolher Expand Macro mostra a mesma expansão no próprio código. Esse menu
não foi usado aqui, já que o Xcode não está no Linux.
