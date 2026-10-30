---
title: O teclado, e o campo que ele cobre
version: 1
---

**O teclado ocupa até metade da tela de um iPhone, e um formulário tem de funcionar com ele no
caminho.** Três coisas dão errado com ele, e o SwiftUI tem uma resposta para cada: o teclado cobre o
campo em que se digita, ele não tem uma tecla para terminar, e ele não vai embora. Nada aqui foi
executado; está escrito a partir da documentação da Apple para os modificadores citados, como estava em
30 de outubro de 2026.

## O campo que ele cobre

O SwiftUI trata o teclado como parte da **área segura**, a região que o conteúdo é disposto para evitar,
ao lado da barra de status e do indicador de início. A documentação da Apple para `SafeAreaRegions` lista
`keyboard` como uma das regiões, "a extensão atual de qualquer teclado de software". Então quando o teclado sobe, o conteúdo do formulário ganha menos altura. Um `Form` rola, de modo que o
campo em que se digita pode ser trazido para cima do teclado. Que o SwiftUI faça isso com a linha
focada é um comportamento dele no iOS, e este curso não o viu rodar. É um dos motivos de o formulário do planner ser
um `Form` e não um `VStack` de campos: uma pilha simples mais alta que o espaço que sobra não rola, e os
campos de baixo ficam sob o teclado.

O contrário, um fundo que deve correr por baixo do teclado, é `.ignoresSafeArea(.keyboard)` nesse fundo,
e nada mais.

## Uma tecla para terminar

Um teclado completo tem uma tecla de retorno, e o `.onSubmit` roda quando ela é apertada; o
`.submitLabel` escolhe a palavra nela, `Done`, `Next`, `Go`. **O teclado numérico da seção 03 não tem
tecla de retorno nenhuma**, então quem digitou `45` não tem o que apertar. A resposta é uma barra de
ferramentas posta no teclado:

```swift
// SessionForm.swift, the keyboard's own toolbar
.toolbar {
    ToolbarItem(placement: .confirmationAction) {
        Button("Add", action: add)
    }
    ToolbarItemGroup(placement: .keyboard) {
        Spacer()
        Button("Done") { focused = nil }
    }
}
```

A documentação da Apple para `ToolbarItemPlacement.keyboard` diz que esses itens ficam acima do teclado
de software quando ele aparece, e no pé da tela quando há um teclado físico ligado. O `Spacer()` empurra
o `Done` para a borda final dessa barra. **`focused = nil` é a implementação inteira do `Done`**: o
`@FocusState` da seção 06 tira o foco de todos os campos, e sem nada para digitar o teclado vai embora.

## Ir embora ao rolar

Uma pessoa que quer ver o resto do formulário o arrasta, e o teclado também atrapalha isso. O
`.scrollDismissesKeyboard(_:)` decide o que uma rolagem faz com ele. A documentação da Apple para ele dá
o padrão: desde o iOS 16, conteúdo rolável fecha o teclado quando uma rolagem começa, exceto um
`TextEditor`, que o fecha de forma interativa, acompanhando o dedo. O planner fica com o padrão e não
escreve nada.

## A tela pronta

Juntando tudo, o `SessionForm` é o código da seção 06 com o `.toolbar` acima no lugar do dele. O
comportamento, todo ele vindo da documentação citada nesta aula e nenhum visto numa tela para o curso:

| a pessoa | o formulário |
|---|---|
| abre | a data é hoje, os minutos estão vazios, nenhuma mensagem aparece |
| digita `forty` e toca em Add | a linha dos minutos diz "Minutes are a whole number, like 45." e o foco fica no campo |
| corrige para `40` | a mensagem some na tecla seguinte |
| toca em Done | o teclado vai embora |
| toca em Add | `draft.session(…)` devolve uma sessão para o dia mostrado no seletor, e a sheet fecha |

Toda linha dessa tabela que trata do **que é aceito** é uma linha que os testes da seção 04 seguram. As
linhas sobre para onde vai o foco e quando o teclado se mexe são da tela, e os testes de interface da
aula 20 são onde elas são conferidas, num Mac.
