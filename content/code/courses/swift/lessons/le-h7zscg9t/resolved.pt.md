---
title: Package.resolved, e o que um número de versão promete
version: 1
---

O manifesto diz que versões são **aceitáveis**. Não diz qual está **em uso**, e duas pessoas
compilando em dois dias diferentes poderiam receber duas versões diferentes: a mais nova de cada
dia. **O `Package.resolved` registra a escolha exata**, e o SwiftPM o escreveu durante o `resolve` da
seção 04:

```
ana@vm:~/sw/l19/planner$ cat Package.resolved
{
  "originHash" : "94239d2734703aadf2b5c92720b93d6ed3ea3885f2fbda595555fb7c04f244bf",
  "pins" : [
    {
      "identity" : "swift-argument-parser",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/apple/swift-argument-parser",
      "state" : {
        "revision" : "6a52f3251125d74daf04fcbd5e6f08a75d074382",
        "version" : "1.8.2"
      }
    }
  ],
  "version" : 3
}
```

Um **pin** por dependência: de onde veio, a versão escolhida e a **revisão** git, o commit para o
qual a tag daquela versão apontava. A revisão é a identidade de verdade; uma tag pode, em princípio,
ser movida para outro commit, e o pin perceberia. **Faça commit do `Package.resolved` num app ou numa
ferramenta**, para que todo mundo que o compila, e toda execução de CI, use o mesmo código. Uma
biblioteca é a exceção: o app que a usa resolve o grafo inteiro, e os pins da própria biblioteca são
ignorados ali.

O `show-dependencies` desenha o grafo, que aqui é um pacote sem dependências próprias:

```
ana@vm:~/sw/l19/planner$ swift package show-dependencies
.
└── swift-argument-parser<https://github.com/apple/swift-argument-parser@1.8.2>(traits: default)
```

## O que o `from:` permite

Pacotes Swift usam **versionamento semântico**: `MAJOR.MINOR.PATCH`, em que um patch corrige
defeitos, uma versão minor acrescenta coisas sem quebrar nada, e uma versão major pode quebrar código
que usava a anterior. O requisito no manifesto é uma faixa sobre esses números:

| requisito | aceita | o raciocínio |
|---|---|---|
| `from: "1.6.0"` | de 1.6.0 até 2.0.0, sem incluir | qualquer versão compatível, a escolha comum |
| `.upToNextMinor(from: "1.6.0")` | de 1.6.0 até 1.7.0, sem incluir | só correções de defeitos sobre a 1.6 |
| `exact: "1.6.2"` | 1.6.2 e nada mais | raramente certo num manifesto: o `Package.resolved` já fixa |
| `branch: "main"` | o que esse branch tiver agora | não é uma versão; um pacote que usa um não pode ser dependido por versão |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l19-ranges\" aria-label=\"Uma linha com as tags do swift-argument-parser de 1.5.0 a 1.8.2, e 2.0.0, que ainda não existe, no fim. A faixa from: 1.6.0 cobre de 1.6.0 até logo antes de 2.0.0, e o resolve escolheu 1.8.2, a mais nova. A faixa upToNextMinor from 1.6.0 cobre de 1.6.0 a 1.6.2, e o resolve escolheu 1.6.2.\"><path d=\"M50 70 L672 70\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M70 64 L70 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"70\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1.5.0</text><path d=\"M122 64 L122 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"122\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1.5.1</text><path d=\"M174 64 L174 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"174\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1.6.0</text><path d=\"M226 64 L226 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"226\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1.6.1</text><path d=\"M278 64 L278 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"278\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1.6.2</text><path d=\"M330 64 L330 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"330\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1.7.0</text><path d=\"M382 64 L382 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"382\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1.7.1</text><path d=\"M434 64 L434 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"434\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1.7.2</text><path d=\"M486 64 L486 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"486\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1.8.0</text><path d=\"M538 64 L538 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"538\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1.8.1</text><path d=\"M590 64 L590 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"590\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1.8.2</text><path d=\"M652 64 L652 76\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"652\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">2.0.0</text><text x=\"652\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">não lançada</text><rect x=\"166\" y=\"110\" width=\"482\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"174\" y=\"121\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">from: \"1.6.0\"</text><rect x=\"585\" y=\"96\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">a mais nova permitida: 1.8.2</text><rect x=\"166\" y=\"180\" width=\"152\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"328\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">.upToNextMinor(from: \"1.6.0\")</text><rect x=\"273\" y=\"166\" width=\"10\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"278\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">a mais nova permitida: 1.6.2</text><text x=\"360\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">O manifesto desenha a faixa; o resolve escolhe a tag mais nova dentro dela,</text><text x=\"360\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">e o Package.resolved guarda essa escolha até o swift package update.</text></svg>", "caption": "Dois requisitos sobre as mesmas tags. Um requisito de versão é uma faixa, e o pin é um ponto dentro dela, escolhido uma vez e mantido."}
```

Estreitar a faixa move o pin, no próximo `resolve`. O `sed -i` edita o manifesto no lugar, trocando
`from: "1.6.0"` por `.upToNextMinor(from: "1.6.0")`:

```
ana@vm:~/sw/l19/planner$ sed -i 's/from: "1.6.0"/.upToNextMinor(from: "1.6.0")/' Package.swift
ana@vm:~/sw/l19/planner$ grep argument-parser Package.swift
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "1.6.0")),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
ana@vm:~/sw/l19/planner$ swift package resolve
Updating https://github.com/apple/swift-argument-parser
Updated https://github.com/apple/swift-argument-parser (0.57s)
Computing version for https://github.com/apple/swift-argument-parser
Computed https://github.com/apple/swift-argument-parser at 1.6.2 (0.80s)
Working copy of https://github.com/apple/swift-argument-parser resolved at 1.6.2
```

A 1.6.2 é a versão 1.6 mais nova. Agora devolva a faixa ao que era, e resolva de novo:

```
ana@vm:~/sw/l19/planner$ sed -i 's/.upToNextMinor(from: "1.6.0")/from: "1.6.0"/' Package.swift
ana@vm:~/sw/l19/planner$ swift package resolve
ana@vm:~/sw/l19/planner$ grep '"version" : "1' Package.resolved
        "version" : "1.6.2"
```

**O `resolve` não imprimiu nada e manteve a 1.6.2**, embora a 1.8.2 seja permitida de novo e mais
nova. Esse é todo o propósito do arquivo: um pin que satisfaz o manifesto nunca é movido pelo
`resolve` nem pelo `build`, então a dependência de ninguém muda debaixo dos pés porque outra pessoa
publicou uma versão. **A versão só se move quando você pede, com `swift package update`:**

```
ana@vm:~/sw/l19/planner$ swift package update
Updating https://github.com/apple/swift-argument-parser
Updated https://github.com/apple/swift-argument-parser (0.36s)
Computing version for https://github.com/apple/swift-argument-parser
Computed https://github.com/apple/swift-argument-parser at 1.8.2 (0.38s)
Working copy of https://github.com/apple/swift-argument-parser resolved at 1.8.2
ana@vm:~/sw/l19/planner$ grep '"version" : "1' Package.resolved
        "version" : "1.8.2"
```

Atualize quando tiver tempo de ler o que mudou e rodar os testes, e faça commit do novo
`Package.resolved` junto com a mudança que ele causou, para que o histórico diga que salto de versão
veio com que correção. A página de `--help` da seção 04 é a mesma na 1.6.2 e na 1.8.2, e isso é o que
uma versão minor promete; uma versão major é onde você lê as notas de lançamento antes de atualizar.
