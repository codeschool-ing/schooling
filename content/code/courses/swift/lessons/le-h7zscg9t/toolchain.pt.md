---
title: O toolchain, as versões e os modos
version: 1
---

Três números de versão se encontram em todo build Swift, e é fácil confundi-los porque dois se
parecem. **A versão do toolchain** é o compilador que você instalou, 6.4.2. **A versão de
ferramentas** é a primeira linha de um manifesto, o toolchain mais antigo com que o pacote diz
compilar. **O modo de linguagem** é o conjunto de regras que o compilador aplica ao fonte, Swift 5 ou
Swift 6, e é o que muda o rigor das verificações de concorrência da lição 15.

```
ana@vm:~/sw/l19/planner$ swift --version
Swift version 6.4.2 (swift-6.4.2-RELEASE)
Target: x86_64-unknown-linux-gnu
ana@vm:~/sw/l19/planner$ swift package tools-version
6.2.0
ana@vm:~/sw/l19/planner$ touch Sources/PlannerCore/Week.swift
ana@vm:~/sw/l19/planner$ swift build -v 2>&1 | grep -o -e '-swift-version [0-9]*' | uniq -c
     31 -swift-version 6
```

O toolchain responde 6.4.2. O pacote diz 6.2.0, que é a primeira linha da seção 03. Nenhum dos dois
é o modo de linguagem, e o `swift build -v` mostra os comandos que ele dá ao compilador, onde o modo é
uma flag: o `grep` a guarda e o `uniq -c` a conta. **Toda compilação deste pacote usou
`-swift-version 6`**, porque um manifesto com versão de ferramentas 6.0 ou mais nova compila os
targets no modo Swift 6, a menos que diga outra coisa.

## A primeira linha decide o modo

O `swift package tools-version --set` reescreve essa primeira linha. Ponha 5.10, compile e devolva:

```
ana@vm:~/sw/l19/planner$ swift package tools-version --set 5.10
ana@vm:~/sw/l19/planner$ head -2 Package.swift
// swift-tools-version: 5.10
// Package.swift
ana@vm:~/sw/l19/planner$ touch Sources/PlannerCore/Week.swift
ana@vm:~/sw/l19/planner$ swift build -v 2>&1 | grep -o -e '-swift-version [0-9]*' | uniq -c
      7 -swift-version 5
ana@vm:~/sw/l19/planner$ swift package tools-version --set 6.2
ana@vm:~/sw/l19/planner$ head -2 Package.swift
// swift-tools-version: 6.2
// Package.swift
```

**O mesmo toolchain compilou os mesmos arquivos no modo Swift 5** assim que o manifesto disse 5.10,
porque um pacote escrito para 5.10 foi escrito antes de as regras do Swift 6 existirem e não é cobrado
por elas. As contagens são quantos comandos do compilador levaram a flag, e diferem porque cada build
refez uma quantidade diferente de trabalho; o que importa é que, dentro de cada build, todos
concordaram. Note também que o `--set` manteve a segunda linha, o comentário com o nome do arquivo.

Era assim que o `swiftc` e o `swift Hello.swift` da lição 1 se comportavam: **um arquivo compilado
sozinho fica no modo Swift 5**, a menos que se passe `-swift-version 6`, e a lição 15 passou. Um
pacote também pode escolher um modo por target com `swiftSettings: [.swiftLanguageMode(.v5)]`, que é
como um projeto grande passa para o Swift 6 um módulo de cada vez, e o `ApproachableConcurrency` que o
`init` escreveu na seção 02 é uma das **funcionalidades futuras**, regras isoladas de um modo futuro
ligadas mais cedo.

## O que o toolchain guarda

```
ana@vm:~/sw/l19/planner$ ls ~/.local/share/swift-6.4.2-RELEASE-ubuntu24.04/usr/bin | wc -l
60
ana@vm:~/sw/l19/planner$ du -sh .build ~/.cache/org.swift.swiftpm
112M	.build
6.8M	/home/ana/.cache/org.swift.swiftpm
```

O diretório `usr/bin` guarda 60 programas, e um punhado é o que você usa: `swift` e `swiftc`, os
drivers; `swift-build`, a quem o `swift build` entrega o trabalho; `lldb`, o depurador;
`sourcekit-lsp`, o servidor de linguagem que dá a um editor autocompletar e erros enquanto você
digita; `docc`, que gera documentação a partir de comentários; e `llvm-cov`, que a lição 18 usou. O
`clang` também está lá, porque um pacote Swift pode conter targets em C e o Swift chama C
diretamente.

Outros dois diretórios importam, e o `du` mediu os dois. O `.build`, 112 MB aqui, pertence ao projeto
e pode ser apagado a qualquer momento: ele é refeito, devagar uma vez. O `~/.cache/org.swift.swiftpm`
pertence à sua conta e guarda uma cópia de todo repositório que o SwiftPM já buscou, 6,8 MB até agora,
para que um segundo projeto que dependa do `swift-argument-parser` não o baixe de novo.

## Trocando de toolchain, e o swiftly

Um toolchain é um diretório, e a lição 1 pôs este no `PATH` à mão. Para experimentar outra versão, ou
um snapshot da próxima, os mesmos passos o desempacotam ao lado do primeiro e apontam o `PATH` para
ele. **O `swiftly` é a ferramenta do swift.org exatamente para isso**: baixa um toolchain, o verifica
e alterna entre os instalados com `swiftly use`, e um projeto pode dizer a versão que espera num
arquivo chamado `.swift-version`, que o `swiftly` então segue quando você trabalha dentro dele. O
swiftly não foi usado para gravar este curso, pelo motivo que a lição 1 deu: um arquivo fixado e uma
assinatura que você mesmo confere tornam cada versão das transcrições uma linha que dá para ler. Os
comandos dele estão na página de instalação do swift.org.

Num Mac, o toolchain chega dentro do Xcode, e o `xcode-select` escolhe de que Xcode vem o toolchain
que a linha de comando usa; a lição 20 diz o que mais um Mac acrescenta.
