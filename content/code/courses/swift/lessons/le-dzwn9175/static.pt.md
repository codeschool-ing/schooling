---
title: Um binário que não precisa de toolchain
version: 1
---

A aula 1 compilou o `hello` num arquivo de 17 KB e avisou que ele não iniciaria numa máquina sem o
toolchain. Todo executável gerado até aqui tem a mesma propriedade: **ele é ligado dinamicamente ao
runtime do Swift**, a `libswiftCore.so` e as vizinhas, e as encontra no diretório do toolchain cada
vez que inicia. Isso vai bem na máquina que o gerou, e é o formato errado para um servidor, uma
imagem de contêiner ou uma ferramenta que você entrega a outra pessoa.

A resposta no Linux é o **SDK estático de Linux**. Um Swift SDK é um pacote de bibliotecas e
configurações para compilar para um alvo diferente da máquina em que você está. Este tem como alvo
o próprio Linux, com tudo ligado dentro do executável: o runtime do Swift, a Foundation e a **musl**,
uma biblioteca C pequena escrita para ser ligada estaticamente, no lugar da `glibc` do Ubuntu. O
swift.org publica um por versão, ao lado do toolchain, com um checksum.

## Instalando o SDK

O programa é uma versão de linha de comando do total da semana, num pacote próprio chamado `week`:

```swift
// swift-tools-version: 6.2
// Package.swift
import PackageDescription

let package = Package(
    name: "week",
    targets: [
        .executableTarget(name: "week"),
    ]
)
```

```swift
// Sources/week/main.swift
let goal = 300
let minutes = CommandLine.arguments.dropFirst().compactMap { Int($0) }
let total = minutes.reduce(0, +)
print("\(total) of \(goal) minutes in \(minutes.count) sessions")
```

`CommandLine.arguments` é a lista de palavras com que o programa foi iniciado, primeiro o caminho
dele mesmo, então o `dropFirst()` pula esse e o `compactMap` guarda as palavras que são números, como
a aula 2 fez com `Int?`. O programa não importa nada, nem a Foundation.

O `swift sdk install` recebe a URL e o checksum que o swift.org lista para esta versão, baixa o
pacote, recusa-o se o checksum for diferente e o desempacota em `~/.swiftpm`. Enquanto baixa, ele
imprime uma linha a cada poucos por cento, e o `grep -v` descarta essas:

```
ana@vm:~/sw/l20/week$ swift sdk install https://download.swift.org/swift-6.4.2-release/static-sdk/swift-6.4.2-RELEASE/swift-6.4.2-RELEASE_static-linux-0.1.0.artifactbundle.tar.gz --checksum 3786b179936d9cc9e266dd506bd1654176358d7b25288e243359f4d17cc4dc5a | grep -v '%: Downloading'
Downloading a Swift SDK bundle archive from `https://download.swift.org/swift-6.4.2-release/static-sdk/swift-6.4.2-RELEASE/swift-6.4.2-RELEASE_static-linux-0.1.0.artifactbundle.tar.gz`...
Downloading
Swift SDK bundle archive successfully downloaded from `https://download.swift.org/swift-6.4.2-release/static-sdk/swift-6.4.2-RELEASE/swift-6.4.2-RELEASE_static-linux-0.1.0.artifactbundle.tar.gz`.
Verifying if checksum of the downloaded archive is valid...
Downloaded archive has a valid checksum.
Swift SDK bundle at `https://download.swift.org/swift-6.4.2-release/static-sdk/swift-6.4.2-RELEASE/swift-6.4.2-RELEASE_static-linux-0.1.0.artifactbundle.tar.gz` is assumed to be an archive, unpacking...
Swift SDK bundle at `https://download.swift.org/swift-6.4.2-release/static-sdk/swift-6.4.2-RELEASE/swift-6.4.2-RELEASE_static-linux-0.1.0.artifactbundle.tar.gz` successfully installed as swift-6.4.2-RELEASE_static-linux-0.1.0.artifactbundle.
ana@vm:~/sw/l20/week$ swift sdk list
swift-6.4.2-RELEASE_static-linux-0.1.0
```

O pacote tem cerca de 285 MB. **O checksum é a mesma conferência da assinatura da aula 1**, em outra
forma: um SHA-256 do arquivo, que o swift.org publica na página de instalação e na lista de versões
que a seção 02 leu. Um SDK estático tem de bater exatamente com o toolchain, 6.4.2 com 6.4.2, e é por
isso que a versão está no nome dele.

## O mesmo programa, ligado de dois jeitos

```
ana@vm:~/sw/l20/week$ swift build -c release 2>&1 | tail -1
Build complete! (2.38 secs)
ana@vm:~/sw/l20/week$ swift build -c release --swift-sdk x86_64-swift-linux-musl 2>&1 | tail -1
Build complete! (2.28 secs)
ana@vm:~/sw/l20/week$ ls -l .build/out/Products/*/week
-rwxr-xr-x 1 ana ana    41744 Oct 30 15:37 .build/out/Products/Release-linux-x86_64/week
-rwxr-xr-x 1 ana ana 39072128 Oct 30 15:37 .build/out/Products/Release-staticlinux-x86_64/week
```

**41.744 bytes contra 39.072.128.** O segundo build citou o SDK pelo triplo de alvo dele,
`x86_64-swift-linux-musl`, e todo o resto foi o mesmo comando. Os produtos caem em dois diretórios,
um por plataforma, e o estático é quase mil vezes maior, porque carrega tudo o que o pequeno pega
emprestado:

```
ana@vm:~/sw/l20/week$ file -b .build/out/Products/Release-linux-x86_64/week | cut -d, -f1-4
ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked
ana@vm:~/sw/l20/week$ file -b .build/out/Products/Release-staticlinux-x86_64/week | cut -d, -f1-4
ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked
ana@vm:~/sw/l20/week$ ldd .build/out/Products/Release-staticlinux-x86_64/week
	not a dynamic executable
ana@vm:~/sw/l20/week$ strip -o week-static .build/out/Products/Release-staticlinux-x86_64/week && ls -l week-static
-rwxr-xr-x 1 ana ana 7019888 Oct 30 15:37 week-static
```

O `file` diz isso em duas palavras, **dynamically linked** contra **statically linked**, e o `ldd`, que
lista as bibliotecas compartilhadas que um programa pede, não acha nenhuma para listar. A maior parte
dos 39 MB é informação de depuração, que o `strip` remove; o que sobra, cerca de 7 MB, é o programa,
o runtime do Swift e a biblioteca C sobre a qual ele roda.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l20-linking\" aria-label=\"Dois builds do mesmo programa. O ligado dinamicamente tem 41.744 bytes e pede o runtime do Swift no diretório usr/lib do toolchain toda vez que inicia, então numa máquina sem toolchain ele não inicia. O ligado estaticamente tem 39.072.128 bytes, cerca de 7 MB sem símbolos, e carrega dentro dele o seu código, o runtime do Swift e a biblioteca C musl, então roda numa máquina sem toolchain.\"><defs><marker id=\"l20-linking-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l20-linking-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l20-linking-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"230\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"135\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">week, ligado dinamicamente</text><text x=\"135\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">41.744 bytes</text><path d=\"M250 48 L318 48\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l20-linking-ah-wire)\"></path><rect x=\"320\" y=\"20\" width=\"200\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"420\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o runtime do Swift</text><text x=\"420\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no usr/lib do toolchain</text><text x=\"135\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pede por ele a cada partida</text><text x=\"620\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">sem toolchain: não inicia</text><rect x=\"20\" y=\"124\" width=\"500\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"270\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">week, ligado estaticamente</text><text x=\"270\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">39.072.128 bytes, 7 MB sem símbolos</text><rect x=\"40\" y=\"184\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">seu código</text><rect x=\"200\" y=\"184\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"270\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">runtime do Swift</text><rect x=\"360\" y=\"184\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"430\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">biblioteca C musl</text><text x=\"620\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">sem toolchain: roda</text></svg>", "caption": "Um binário estático carrega o que o dinâmico pega emprestado, e por isso é mil vezes maior e roda onde o Swift não está instalado."}
```

## Numa máquina sem Swift

A prova é um computador que nunca viu Swift. A máquina abaixo é o Ubuntu 24.04 da aula 1 antes de
qualquer instalação: sem toolchain, sem a linha do `apt`. Os dois binários foram copiados para o
diretório pessoal da Ana lá, como o `scp` os colocaria num servidor:

```
ana@vm:~$ which swift; ls ~
week-dynamic
week-static
ana@vm:~$ ./week-dynamic 45 30 60
./week-dynamic: error while loading shared libraries: libswiftCore.so: cannot open shared object file: No such file or directory
ana@vm:~$ ./week-static 45 30 60
135 of 300 minutes in 3 sessions
```

O `which swift` não imprime nada, porque não há Swift. O binário dinâmico falha antes da primeira
linha, com a mesma mensagem do **carregador dinâmico** que a seção 03 da aula 1 encontrou, citando a
`libswiftCore.so`. O estático roda e imprime a semana. **Copie um arquivo, e ele roda.** Esse é todo o
motivo de compilar assim: uma imagem de contêiner construída `FROM scratch` com um arquivo dentro, uma
ferramenta que um colega pode baixar, um servidor sem nada instalado.

O servidor da seção 04 compila do mesmo jeito, com a mesma opção:

```
ana@vm:~/sw/l20/server$ swift build -c release --swift-sdk x86_64-swift-linux-musl 2>&1 | tail -1
Build complete! (506.09 secs)
ana@vm:~/sw/l20/server$ ls -l .build/out/Products/Release-staticlinux-x86_64/PlannerServer
-rwxr-xr-x 1 ana ana 176852520 Oct 30 15:46 .build/out/Products/Release-staticlinux-x86_64/PlannerServer
```

De novo minutos de compilação, porque cada um dos vinte e quatro pacotes é compilado outra vez para
o novo alvo, e um binário de 177 MB antes do `strip`. Remover os símbolos é o passo a acrescentar
antes de colocá-lo numa imagem.

## O que o SDK estático não faz

**Ele compila para Linux e nada mais.** O binário roda em qualquer Linux x86-64, seja qual for a
distribuição, e em nenhum Mac, nenhum Windows e nenhum celular. Um servidor `aarch64` precisa do alvo
`aarch64-swift-linux-musl` do mesmo pacote. E ele não muda nada no código: um programa que precisa do
`FoundationNetworking` continua a importá-lo do jeito que a seção 03 mostrou, e o recebe
estaticamente.
