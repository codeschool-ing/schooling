---
title: A fase da cena: ativa, inativa, em segundo plano
version: 1
---

**O iOS diz a uma cena em qual de três fases ela está, e espera que o app reaja.** O SwiftUI expõe o
valor como `scenePhase` no ambiente, do tipo `ScenePhase`, e os três casos dele são o vocabulário
inteiro:

| fase | o que quer dizer, pela documentação da Apple para `ScenePhase` |
|---|---|
| `active` | a cena está em primeiro plano e interativa |
| `inactive` | a cena está em primeiro plano mas deve pausar o trabalho: um banner ou o seletor de apps está por cima |
| `background` | a cena não está visível; a documentação diz para esperar que o app seja encerrado logo depois |

A imagem errada é a de que um app roda até a pessoa fechá-lo. **No iOS uma pessoa quase nunca fecha
um app.** Ela vai para a tela inicial, e o app passa para o segundo plano; dali o iOS pode suspendê-lo,
e pode encerrar o processo para recuperar memória sem avisar antes. Quando a pessoa volta a um app que
foi encerrado, ele começa do nada. Então tudo o que vale guardar tem de ser escrito antes disso, e a
documentação da Apple sobre o ciclo de vida de um app diz o momento: salvar os dados ao sair do estado
ativo em primeiro plano.

## Lendo a fase

Qualquer view, ou o próprio `App`, lê a fase do ambiente e reage a uma mudança com `onChange(of:)`:

```swift
struct WeekView: View {
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Text("…")
            .onChange(of: scenePhase) { old, new in
                print("phase", old, "→", new)
            }
    }
}
```

**Onde ela é lida muda o que ela quer dizer.** A documentação da Apple é precisa aqui: lida dentro de
uma view, o valor é a fase da cena que contém aquela view; lida dentro do `App`, é um agregado de
todas as cenas do app, `active` se qualquer uma estiver ativa e `background` só quando todas
estiverem. Num iPhone com uma janela as duas coincidem. Num iPad com duas janelas do planner, uma em
segundo plano e outra na frente, uma view na primeira vê `background` e o `App` vê `active`.

O `onChange(of:)` entrega o valor antigo e o novo ao closure, que é a forma que o iOS 17 trouxe. A
documentação avisa que o closure pode rodar no main actor e não deve fazer trabalho demorado ali;
salvar o plano, na seção 07, é uma escrita curta.

## A ordem pela qual um telefone passa por elas

Ir para a tela inicial e voltar não são dois movimentos, são quatro: de ativa para inativa, de
inativa para segundo plano, e depois de segundo plano para inativa e de inativa para ativa. **Puxar
um banner por cima do app são dois movimentos que nunca chegam ao segundo plano**, e essa diferença é
todo o assunto da próxima seção, onde a decisão que reage a eles é escrita em Swift puro e testada.

Nada nesta seção foi executado para o curso. Ela foi escrita a partir da documentação da Apple para
`ScenePhase` e `onChange(of:initial:_:)`, lida em 30 de outubro de 2026, e a ordem dos movimentos é a
que a documentação da Apple sobre o ciclo de vida de um app descreve.
