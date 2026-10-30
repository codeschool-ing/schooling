---
title: Uma linguagem, muitos alvos
version: 1
---

A imagem comum é que o Swift é a linguagem do iPhone e roda onde rodam os aparelhos da Apple. **Foi
ali que começou, e hoje é um alvo entre vários.** O compilador é um projeto de código aberto, e cada
versão é publicada para os sistemas da Apple e para outros ao mesmo tempo, do mesmo fonte, com o
mesmo número de versão.

A máquina em que este curso foi gravado sabe dizer o que foi publicado para a própria versão dela. O
swift.org mantém a lista como um arquivo, e três comandos bastam para lê-la:

```
ana@vm:~/sw/l20$ swift --version
Swift version 6.4.2 (swift-6.4.2-RELEASE)
Target: x86_64-unknown-linux-gnu
ana@vm:~/sw/l20$ curl -s https://www.swift.org/api/v1/install/releases.json | python3 -c 'import json, sys; r = [x for x in json.load(sys.stdin) if x["name"] == "6.4.2"][0]; print("\n".join(p["name"] for p in r["platforms"]))'
Ubuntu 22.04
Ubuntu 24.04
Ubuntu 26.04
Debian 12
Debian 13
Fedora 41
Amazon Linux 2023
Red Hat Universal Base Image 9
Red Hat Universal Base Image 10
Windows 10
Static SDK
Wasm SDK
Android SDK
ana@vm:~/sw/l20$ swift sdk list
No Swift SDKs are currently installed.
```

O primeiro comando é a verificação da aula 1, igual depois de dezenove aulas. O segundo busca a
lista de versões e imprime as plataformas publicadas para a 6.4.2. O terceiro pergunta quais
**Swift SDKs** estão instalados, e a resposta é nenhum, por enquanto. Leia a lista do meio em três
grupos.

| grupo | o que é | neste curso |
|---|---|---|
| **Linux e Windows** | um toolchain completo para cada sistema citado: compilador, biblioteca padrão, Foundation, gerenciador de pacotes e executores de teste | Ubuntu 24.04, aulas 1 a 20 |
| **Static SDK, Wasm SDK, Android SDK** | não são toolchains, e sim pacotes que deixam um toolchain de Linux ou de Mac compilar para outro alvo | o SDK estático, seção 05 |
| **As plataformas da Apple** | fora da lista: iOS, iPadOS, macOS, watchOS, tvOS e visionOS recebem o Swift dentro do Xcode | descritas na seção 06, não rodadas |

## O que a lista diz e o que não diz

**Todas essas plataformas rodam a mesma linguagem**: o código das aulas 1 a 19 compila em todas.
O que muda entre elas são as bibliotecas acima da linguagem, assunto da seção 03, e o jeito como um
programa é empacotado e iniciado.

Dois alvos da lista merecem uma frase cada, porque são mais novos que a maior parte do material sobre
Swift. **WebAssembly** deixa o Swift compilar para o bytecode que os navegadores rodam, então o mesmo
código de modelo pode rodar numa página web. **Android** é publicado pelo swift.org como um SDK para
construir bibliotecas Android em Swift; não é um jeito de escrever as telas de um app Android, que
continuam em Kotlin, e este curso não compila para ele. Nenhum dos dois foi rodado neste curso.

Há também o **Embedded Swift**, um modo restrito do mesmo compilador para microcontroladores com
poucos kilobytes de memória, que deixa de fora as partes da linguagem que precisam de um runtime,
como os existenciais `any` da aula 9. É uma configuração do compilador e não uma entrada da lista, e
aparece aqui para a palavra não pegar você de surpresa.

## Onde o curso está

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 296\" role=\"img\" data-fig=\"l20-platforms\" aria-label=\"Um único fonte Swift compilado para três grupos de alvos. As plataformas da Apple recebem o Swift dentro do Xcode e podem importar SwiftUI e UIKit; essa coluna não foi rodada neste curso. Linux e Windows recebem um toolchain do swift.org com a Foundation de código aberto e sem frameworks da Apple; este curso rodou no Ubuntu 24.04. SDKs para outros alvos, o SDK estático de Linux, WebAssembly e Android, são pacotes com que um toolchain compila; a seção 05 roda o estático.\"><defs><marker id=\"l20-platforms-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l20-platforms-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l20-platforms-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"250\" y=\"14\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">um único fonte Swift</text><text x=\"360\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Sources/*.swift</text><path d=\"M360 54 L130 84\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l20-platforms-ah-wire)\"></path><rect x=\"20\" y=\"86\" width=\"220\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"130\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">As plataformas da Apple</text><text x=\"130\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o Swift dentro do Xcode</text><text x=\"130\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">iOS, macOS, watchOS</text><text x=\"130\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tvOS, visionOS</text><text x=\"130\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">SwiftUI e UIKit importáveis</text><text x=\"130\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">descrito, não rodado aqui</text><path d=\"M360 54 L360 84\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l20-platforms-ah-wire)\"></path><rect x=\"250\" y=\"86\" width=\"220\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Linux e Windows</text><text x=\"360\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">toolchain do swift.org</text><text x=\"360\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Foundation de código aberto</text><text x=\"360\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">sem frameworks da Apple</text><text x=\"360\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">este curso: Ubuntu 24.04</text><path d=\"M360 54 L590 84\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l20-platforms-ah-wire)\"></path><rect x=\"480\" y=\"86\" width=\"220\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"590\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">SDKs para outros alvos</text><text x=\"590\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Linux estático, com musl</text><text x=\"590\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">WebAssembly</text><text x=\"590\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">bibliotecas Android</text><text x=\"590\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a seção 05 roda o primeiro</text><text x=\"360\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a mesma linguagem em toda coluna</text></svg>", "caption": "A linguagem é a mesma em toda coluna. O que muda é o que dá para importar e do que um binário precisa para rodar.", "same": ["iOS, macOS, watchOS", "tvOS, visionOS", "WebAssembly"]}
```

**A linguagem é a mesma em toda coluna; a diferença é o que dá para importar e do que um binário
precisa para rodar.** Nos sistemas da Apple os frameworks da plataforma estão lá para importar, e o
SwiftUI é um deles. No Linux não estão, e a Foundation é a de código aberto. A seção 03 mostra essa
diferença na compilação, a seção 04 usa o Linux para aquilo em que ele é mais usado, um servidor, e
a seção 05 gera um programa que roda numa máquina Linux sem Swift instalado nenhum.
