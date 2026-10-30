---
title: Transformar sem desempacotar
version: 1
---

Às vezes a pergunta não é "há um valor?", e sim "se houver, transforme-o em outra coisa". Uma duração
digitada em minutos deveria virar segundos; uma que falta deveria continuar faltando. **Um opcional
tem um método `map` que aplica uma função ao valor de dentro, se houver, e mantém o `nil` se não
houver.** O resultado continua opcional.

```swift
// OptionalMap.swift
func seconds(_ minutes: Int) -> Int {
    minutes * 60
}
let typed: Int? = Int("45")
let missing: Int? = Int("forty")
print(String(describing: typed.map(seconds)))
print(String(describing: missing.map(seconds)))
let entries = ["45", "forty", "30"]
let numbers = entries.compactMap { Int($0) }
print(numbers)
```

```
ana@vm:~/sw/l02$ swift OptionalMap.swift
Optional(2700)
nil
[45, 30]
```

`typed.map(seconds)` deu `Optional(2700)`, e a mesma chamada em `missing` deu `nil` sem chamar
`seconds`. É a mesma ideia do `?.`: **faça isto com o valor se ele estiver lá, senão repasse o
`nil`**, escrita para uma função em vez de uma propriedade.

## Tirando os nils de uma lista

As duas últimas linhas pegam uma lista de strings, tentam transformar cada uma num `Int` e guardam só
as que deram certo. O `compactMap` faz exatamente isso: roda o código entre chaves em cada item, recebe
um `Int?` de volta a cada vez, e **junta os valores descartando os `nil`**. O resultado é `[45, 30]`,
um array de `Int` simples.

As chaves `{ Int($0) }` são uma closure, uma pequena função escrita no lugar, com `$0` valendo cada
item. A aula 3 explica closures e esse `$0` direito, e a aula 4 é sobre `map`, `filter` e os
parentes deles em arrays. Por enquanto basta reconhecer o `compactMap` como "converta cada um, guarde
os que deram certo", que é o laço da seção 03 numa linha.

## Quatro jeitos, uma regra

Cada jeito de abrir um opcional decide o que acontece com o `nil`:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l02-four-ways\" aria-label=\"Uma tabela com quatro jeitos de abrir o opcional Int(typed), que guarda 45 ou nil. Com if let, 45 fica disponível dentro das chaves, e nil as pula. Com guard let, 45 fica disponível abaixo do guard, e nil sai da função. Com ?? 0, 45 dá 45 e nil dá 0, o padrão. Com ponto de exclamação, 45 dá 45 e nil para o programa.\"><rect x=\"20\" y=\"120\" width=\"130\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"85\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">Int(typed)</text><text x=\"85\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">45, ou nil</text><text x=\"260\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">escreva</text><text x=\"450\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">com 45</text><text x=\"615\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">com nil</text><rect x=\"180\" y=\"50\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"260\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">if let m = …</text><line x1=\"150\" y1=\"150\" x2=\"180\" y2=\"70\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"450\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">m vale 45 nas chaves</text><text x=\"615\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">as chaves são puladas</text><rect x=\"180\" y=\"110\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"260\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">guard let m = … else</text><line x1=\"150\" y1=\"150\" x2=\"180\" y2=\"130\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"450\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">m vale 45 abaixo dele</text><text x=\"615\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a função sai</text><rect x=\"180\" y=\"170\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"260\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">… ?? 0</text><line x1=\"150\" y1=\"150\" x2=\"180\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"450\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">45</text><text x=\"615\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">0, o padrão</text><rect x=\"180\" y=\"230\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"260\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">…!</text><line x1=\"150\" y1=\"150\" x2=\"180\" y2=\"250\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"450\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">45</text><text x=\"615\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">o programa para</text></svg>", "caption": "Quatro jeitos de abrir um opcional. Eles concordam sobre o 45 e só diferem no que o nil faz."}
```

**Escolha pelo que `nil` quer dizer no lugar em que você está escrevendo.** Se quer dizer pular,
`if let`. Se quer dizer que a função não pode seguir, `guard let`. Se quer dizer um padrão tão bom
quanto um valor, `??`. Se quer dizer que o programa está quebrado, `!` — e então tenha certeza.
