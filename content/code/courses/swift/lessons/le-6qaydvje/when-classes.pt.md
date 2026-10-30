---
title: Quando uma classe ainda é a ferramenta certa
version: 1
---

Nada disso torna as classes erradas. A aula 5 nomeou o que só uma classe tem: **identidade**, um
objeto que várias partes do programa compartilham e veem mudar. O erro da seção 02 foi usar herança
para descrever capacidades, não usar uma classe.

## Quando buscar uma classe

- **Algo é compartilhado de propósito.** Um objeto planner que a lista, a visão da semana e o código
  de sincronização leem e atualizam, em que a mudança feita por um precisa ser vista pelos outros. A
  aula 15 acrescenta que um objeto mutável compartilhado hoje costuma ser um ator.
- **Algo tem um tempo de vida.** Uma conexão, um arquivo aberto, um timer: um objeto que precisa ser
  fechado quando o último usuário o solta. O `deinit` da aula 11 só existe em classes.
- **Um framework lhe entrega uma classe base.** O `UIViewController` do UIKit é subclassificado por
  toda tela UIKit já escrita, e você não escolhe outra coisa. Isso é a plataforma da Apple e não roda
  neste curso; o `ios-apps` usa o SwiftUI, construído com structs e protocolos, e mostra onde o UIKit
  ainda aparece.

## final por padrão

Quando uma classe é a certa, herança geralmente não é. **Marcar uma classe como `final` diz que nada
pode subclassificá-la**, o compilador cobra isso de todos, e ele pode chamar os métodos da classe
diretamente, já que nenhuma sobrescrita pode existir:

```swift
// Final.swift
final class Planner {
    var owner: String
    init(owner: String) { self.owner = owner }
}

class SharedPlanner: Planner {}
```

```
ana@vm:~/sw/l10$ swiftc Final.swift -o final
Final.swift:7:7: error: inheritance from a final class 'Planner'
5 | }
6 | 
7 | class SharedPlanner: Planner {}
  |       `- error: inheritance from a final class 'Planner'
8 | 
```

O `final` é o padrão barato e tirá-lo depois é fácil, enquanto acrescentá-lo depois que outro código
subclassificou a classe não é. O `Planner` da aula 8 era `final` por esse motivo.

## Uma regra prática

| você precisa de | busque |
|---|---|
| uma capacidade que vários tipos compartilham | um protocolo, com uma extensão para o comportamento |
| um valor simples: uma sessão, um curso, uma semana | uma struct |
| uma coisa compartilhada, com identidade ou tempo de vida | uma `final class`, ou um ator da aula 15 |
| uma subclasse | só quando um framework pede uma |

A orientação da própria Apple para o Swift diz o mesmo em menos palavras: **use estruturas por padrão,
use protocolos para compartilhar comportamento, e use uma classe quando precisar de identidade ou de
interoperabilidade com Objective-C.**
