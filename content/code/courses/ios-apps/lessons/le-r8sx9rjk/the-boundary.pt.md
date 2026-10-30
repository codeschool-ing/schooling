---
title: O que precisa de um Mac, dito agora
version: 1
---

**Um app de iPhone é compilado com o Xcode, e o Xcode roda no macOS e em nenhum outro lugar.** A
licença da Apple para o Xcode e seus SDKs permite usá-los só em hardware da Apple, e o simulador de
iOS vem com o Xcode. O mesmo vale para o SwiftUI: o framework em que as telas são escritas vem dentro
dos SDKs de iOS e macOS e não tem versão para Linux nem para Windows. Colocar o app num iPhone de
verdade, e as aulas 21 e 22, pedem ainda uma assinatura paga do Apple Developer Program. Melhor saber
de tudo isso na aula 1 do que na aula 9.

**Mesmo assim, a maior parte deste curso pode ser praticada em qualquer computador.** As telas de um
app são uma camada fina sobre os seus dados e as suas regras, e esses são Swift puro. O Swift roda no
Linux, que é o assunto da aula 20 de `swift`, e toda aula aqui coloca a sua metade em Swift puro num
**pacote Swift**, que compila e testa do mesmo jeito no Linux e num Mac. O Xcode abre esse pacote sem
mudar nada, e o target do app o importa.

| aulas | o que você pratica em qualquer computador | o que precisa de um Mac com Xcode |
|---|---|---|
| 1 | o pacote do planner, os seus testes, a leitura de um `Info.plist` | o projeto Xcode, targets e schemes |
| 2 a 5 | a fase da cena como máquina de estados, result builders, um modelo do layout e dos modificadores | toda view SwiftUI, o canvas e o simulador |
| 6 a 10 | um `Binding` montado à mão, o próprio `@Observable`, identidade em listas, caminhos de navegação e deep links, validação de formulário | as telas que usam tudo isso |
| 11 | a aritmética de uma curva de tempo | toda animação |
| 12 | tudo: `URLSession`, decodificação, erros, cancelamento, contra um servidor na sua máquina | nada |
| 13 | muito pouco | o SwiftData, que só existe em sistemas da Apple |
| 14 e 15 | o repositório, os seus testes, um cache de imagens e as contas de memória | o `AsyncImage` e as views |
| 16 a 19 | a aritmética de agendamento e de gatilhos, payloads de notificação, arquivos de privacidade, razões de contraste | tarefas em segundo plano, notificações, pedidos de permissão e VoiceOver, num simulador ou num telefone |
| 20 | Swift Testing e XCTest, rodados pelo `swift test` | testes de interface e previews |
| 21 e 22 | um pedido de assinatura de certificado com `openssl` | assinatura, TestFlight e revisão da App Store, com assinatura paga |

**Sem um Mac você ainda faz todas as aulas.** As metades em SwiftUI viram material de leitura em vez
de prática: o que o código diz, o que a documentação da Apple diz que ele faz, e o que procurar quando
você tiver um Mac. **Essas partes vêm marcadas nas aulas como não executadas.** O curso foi gravado
num computador Linux, e nada do Xcode, do simulador, de um aparelho, de assinatura ou do App Store
Connect foi executado para ele. Cada transcrição que você vê saiu de um comando nessa máquina, e a
saída está colada como voltou; cada listagem SwiftUI é código escrito a partir da documentação da
Apple e aparece sem captura de tela e sem saída, porque nenhuma execução produziu uma.

É na documentação da própria Apple que essas partes se apoiam, e a Apple a muda todo ano. O curso foi
escrito contra a documentação como estava em 30 de outubro de 2026, quando a versão atual era o
**Xcode 27.1**, e contra APIs que o iOS 17 e posteriores oferecem, já que o pacote declara o iOS 17
como piso. Onde um Xcode mais novo tiver mudado um menu de lugar, a ideia da aula é a parte que fica.

## Sem um Mac, e querendo a metade do Mac também

A seção 03 lista as formas de ter o Xcode, e nenhuma é de graça. Duas valem ser conhecidas agora. Um
**iPad com o Swift Playgrounds**, que a Apple oferece sem custo na App Store, compila e roda apps
SwiftUI no próprio iPad, e é a única forma de rodar as telas deste curso sem um Mac; ele não é o
Xcode, e as aulas 1, 20 e 21 descrevem coisas que ele não tem. E um **Mac alugado num data center**,
por hora ou por mês, de várias empresas, é um Mac de verdade que você acessa por área de trabalho
remota. A aula 20 de `react-native` trata de uma terceira forma, que compila um app em Macs alugados
sem que você veja nenhum, e que não ajuda em nada a desenvolver contra um simulador.
