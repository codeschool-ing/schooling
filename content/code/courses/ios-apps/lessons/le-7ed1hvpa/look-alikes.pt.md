---
title: Os modificadores que só parecem iguais
version: 1
---

**Vários pares de modificadores produzem a mesma imagem no caso simples e layouts diferentes no caso
seguinte.** Cada par é um par de embrulhos diferentes, e a regra da seção 02 separa os dois: pergunte o
que cada um é, e que tamanho informa.

| parece | é | a diferença que morde |
|---|---|---|
| `.overlay { … }` e um `ZStack` | um embrulho do tamanho da view que modifica, contra um contêiner do tamanho do maior filho | um selo num overlay nunca deixa o ícone maior; num `ZStack` um selo grande deixa |
| `.hidden()` e `if !visible { … }` | uma view que está lá e invisível, contra nenhuma view | a documentação da Apple para `hidden()` diz que uma view escondida fica na hierarquia e afeta o layout, então o espaço é mantido |
| `.opacity(0)` e `.hidden()` | os dois mantêm o espaço; a opacidade pode ser animada, e o `hidden()` não se desfaz por um valor | o `hidden()` esconde incondicionalmente; para mostrar e esconder, use opacidade ou um `if` |
| `.foregroundStyle(.red)` e `.tint(.red)` | a cor do conteúdo, contra a cor de destaque dos controles | o rótulo de um `Button` segue o tint; o texto segue o foreground style |
| `.cornerRadius(12)` e `.clipShape(.rect(cornerRadius: 12))` | um modificador mais antigo, contra o atual | a documentação da Apple marca `cornerRadius(_:antialiased:)` como descontinuado a partir do iOS 27.2, com a mensagem "Use `clipShape` or `fill` instead" |

**A linha do `overlay` é a que o planner usa.** A linha de curso vai ter um pontinho quando uma sessão
estiver atrasada, e ele não pode mexer o título nem um ponto quando aparece:

```swift
Image(systemName: "book")
    .overlay(alignment: .topTrailing) {
        Circle()
            .fill(.red)
            .frame(width: 8, height: 8)
    }
```

A documentação da Apple para `overlay(alignment:content:)` o descreve como pôr views em camadas na
frente desta, agrupadas num `ZStack` implícito posicionado pelo alinhamento. O overlay fica com o
tamanho da imagem que modifica, então o ponto fica no canto e o layout da linha não muda, com o ponto
ou sem ele.

## Por que o descontinuado ainda importa

Você vai ler `.cornerRadius(…)` em código mais antigo por anos, porque ele funcionava desde o primeiro
SwiftUI. Descontinuado quer dizer que o compilador avisa e o modificador ainda funciona; a mensagem da
Apple diz o que usar, e o `clipShape` aceita qualquer forma, o que o `cornerRadius` nunca aceitou.

Nada nesta seção foi executado para o curso. A tabela e a listagem foram escritas a partir da
documentação da Apple para cada modificador citado, lida em 30 de outubro de 2026.
