---
title: O que um Mac acrescenta
version: 1
---

Tudo neste curso rodou no Linux. **Esta seção é a exceção: ela descreve, a partir da documentação da
Apple, o que um Mac acrescenta, e nada disso foi rodado**, porque o curso foi gravado numa máquina sem
Mac e não há como rodar as ferramentas da Apple em outro lugar. Não há transcrição abaixo nem captura
de tela, de propósito.

## O mesmo toolchain, e mais em volta dele

Num Mac, o Swift chega com o **Xcode**, a IDE da Apple, ou com as **Command Line Tools**, menores. Os
dois põem `swift` e `swiftc` no `PATH`, e todo comando deste curso funciona lá como escrito:
`swift Hello.swift`, `swift build`, `swift test`, `swift package init`. As diferenças que você veria
são as que a lição 1 listou: caminhos, a linha de alvo do `swift --version`, que num Mac recente
começa com `arm64-apple-macosx` em vez de `x86_64-unknown-linux-gnu`, e a ausência da manobra do
`FoundationNetworking` da seção 03.

O que o Xcode acrescenta é tudo o que não é a linguagem:

| num Mac | o que faz | o mais próximo neste curso |
|---|---|---|
| **projetos do Xcode** | os targets, os schemes, o bundle identifier e o `Info.plist` de um app | um pacote, lição 19 |
| **o simulador do iOS** | roda um app de iPhone no Mac, num tamanho de aparelho escolhido | nenhum: ele só existe no macOS |
| **os previews do SwiftUI** | redesenham uma view no editor enquanto o código muda | nenhum; a lição 16 construiu os mecanismos que o SwiftUI usa |
| **o Instruments** | mede tempo, alocações e vazamentos num app rodando | a contagem com `deinit` da lição 11 |
| **o depurador do grafo de memória** | desenha os objetos vivos num app pausado e as referências entre eles | o ciclo da lição 11, achado por raciocínio |
| **assinatura e App Store** | certificados, perfis de provisionamento, TestFlight, revisão | nenhum |

## Por que o muro está lá

Não por causa do Swift. **O Xcode e os SDKs da Apple são licenciados para rodar em hardware da
Apple**, e o simulador e os frameworks que ele roda, UIKit e SwiftUI entre eles, fazem parte desse
SDK. Não existe build deles para Linux, e nenhum é prometido. É por isso que o curso depois deste no
caminho, o `ios-apps`, diz nos pré-requisitos que precisa de um Mac com Xcode desde a primeira lição,
e por isso este curso foi desenhado para terminar antes dele.

Duas coisas borram a linha sem apagá-la. Várias empresas alugam Macs remotos por hora, e a lição 20
do `react-native` e a lição 10 do `mobile-delivery` descrevem serviços de build hospedados que
compilam e assinam um app iOS sem um Mac na sala. Os dois ainda rodam o Xcode, no Mac de outra
pessoa. O que nenhum dos dois lhe dá é um simulador na sua própria tela para desenvolver, e é dessa
parte que o `ios-apps` depende.

## O que passa sem mudança

**Cada conceito destas vinte lições**, que é o motivo de tê-los aprendido primeiro. Os modelos de um
app de iPhone são structs e enums; as telas são views do SwiftUI, que são structs conformando a um
protocolo, montadas por um result builder e guardando estado em property wrappers; as chamadas de rede
são funções `async` que devolvem valores `Codable`; a interface roda no `@MainActor` da lição 15; e
os testes são o XCTest e o Swift Testing da lição 18. A seção 07 os relaciona um a um.
