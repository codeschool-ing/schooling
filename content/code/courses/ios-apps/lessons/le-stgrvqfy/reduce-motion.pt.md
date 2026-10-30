---
title: Reduzir Movimento, e as pessoas que a animação deixa mal
version: 1
---

**Para algumas pessoas, movimento numa tela causa tontura ou enjoo, e o iOS tem um ajuste que pede aos
apps que parem.** É o *Reduzir Movimento*, nos ajustes de Acessibilidade, e um app o lê pelo ambiente. A
documentação da Apple para `accessibilityReduceMotion` diz o que o ajuste pede: quando ele é verdadeiro,
a interface "deve evitar animações grandes, especialmente as que simulam a terceira dimensão". Ele não
pede ausência de resposta visual. Nada nesta seção foi executado; está escrito a partir dessa
documentação, como estava em 30 de outubro de 2026.

## Lendo o ajuste

```swift
// DayPicker.swift, the button honouring Reduce Motion
@Environment(\.accessibilityReduceMotion) private var reduceMotion

Button {
    withAnimation(reduceMotion ? nil : .spring) { selected = day }
} label: {
    // as in section 06
}
```

`withAnimation(nil)` é uma mudança sem animação: a cápsula aparece embaixo do novo dia num quadro só.
**O estado muda do mesmo jeito nos dois ramos**, e só o caminho da tela é diferente. Essa é a forma que
toda correção de Reduzir Movimento deve ter, porque um ramo que também mudasse *o que* acontece seria um
segundo comportamento a testar, e o que menos gente usa é o que quebra.

## O que o planner muda, e o que mantém

| animação | com Reduzir Movimento |
|---|---|
| a cápsula que desliza no seletor de dia (seção 06) | nenhuma: ela atravessa a tela, que é o caso de que o ajuste trata |
| a nota de "semana feita" subindo (seção 05) | um esmaecimento no lugar: `.opacity`, sem `.move` |
| a barra da semana se enchendo (seção 02) | mantida: ela cresce no lugar, é pequena, e diz ao estudante que o toque funcionou |
| uma sheet subindo para o `SessionForm` | a do próprio sistema, que segue o ajuste sozinha |

A transição da nota vira uma escolha feita num lugar só:

```swift
// WeekView.swift, the note's transition
.transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
```

**Tirar movimento não é tirar resposta.** Uma pessoa com Reduzir Movimento ligado ainda precisa ver que o
toque dela fez algo: a barra ainda se enche e a nota ainda aparece. O que sai é o deslocamento pela tela,
a mudança de escala e qualquer coisa que finja ser tridimensional.

## Conferindo

Num Mac, o simulador tem o ajuste onde um telefone o tem, no app Ajustes dele, em *Acessibilidade* e
*Movimento*, e a aula 19 trata das ferramentas que o Xcode acrescenta para conferir acessibilidade. Nada
disso foi executado para este curso: a tabela acima é uma decisão tomada a partir da documentação, e
conferir cada linha é trabalho para um Mac, ou um telefone, e um par de olhos.
