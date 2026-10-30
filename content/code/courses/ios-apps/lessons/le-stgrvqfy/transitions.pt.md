---
title: Transições, para views que chegam e saem
version: 1
---

**Uma transição é como uma view entra na tela ou sai dela, e ela só acontece quando a mudança é
animada.** A seção 03 terminou na regra: uma view que mantém a identidade é interpolada, e uma view que
começa ou deixa de existir é entregue a uma transição. A transição padrão é um esmaecimento. Nada aqui
foi executado; está escrito a partir da documentação da Apple para `transition(_:)` e `AnyTransition`,
como estava em 30 de outubro de 2026.

## O caso do planner

A tela da semana pode mostrar uma nota curta embaixo da barra quando o plano da semana está completo.
Ela está lá ou não está, então ela chega e sai:

```swift
// WeekView.swift, the note when the week is done
VStack(alignment: .leading, spacing: 12) {
    WeekBar(total: total)
    if total.planned > 0 && total.done == total.planned {
        Label("Every session this week is done", systemImage: "checkmark.seal")
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
.animation(.easeInOut, value: total.done == total.planned)
```

O `.transition` diz **como** o rótulo chega e sai: deslizando da borda de baixo e esmaecendo ao mesmo
tempo. Ele não diz nada sobre **quando** nem **com que velocidade**. Isso vem da animação da mudança que o
insere, aqui o `animation(_:value:)` na pilha, vigiando a única condição que põe o rótulo ali. **Uma
transição sem animação na transação não faz nada**: o rótulo aparece num quadro. Este é o motivo mais
comum de uma transição "não funcionar", e o remédio nunca está na linha do `.transition`.

## Montando uma a partir de peças

| transição | o que ela faz |
|---|---|
| `.opacity` | esmaece; a padrão |
| `.scale` | cresce a partir do nada, ou encolhe até ele |
| `.move(edge:)` | desliza para dentro a partir daquela borda e sai por ela |
| `.slide` | entra pela borda inicial, sai pela final |
| `a.combined(with: b)` | as duas ao mesmo tempo |
| `.asymmetric(insertion: a, removal: b)` | um jeito de entrar, outro de sair |

O `asymmetric` é o que parece desenhado em vez de padrão. Uma linha acrescentada a uma lista pode chegar
pelo topo, onde estão os olhos da pessoa depois de tocar em Add, e sair esmaecendo, porque fazer deslizar
algo que acabou de ser apagado chama atenção para uma coisa que já não importa.

## Linhas numa lista

Uma `List` anima as próprias linhas. Quando uma sessão é acrescentada ou removida dentro de um
`withAnimation`, a lista insere ou remove a linha com a animação dela, e as outras linhas se movem para
abrir espaço. A documentação da Apple não descreve uma transição que você prenda a uma linha para isso; a
lista decide. **O que a lista precisa de você é uma identidade estável**, o `id` em que a aula 8 insistiu:
uma lista avisada de que uma linha foi removida e outra inserida, quando uma sessão foi só editada, anima
uma remoção e uma inserção onde nada saiu.
