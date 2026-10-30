---
title: O projeto Xcode: targets e schemes
version: 1
---

**Um projeto Xcode é uma lista de coisas a compilar e das configurações com que compilar cada uma.**
Ele é um diretório, `Planner.xcodeproj`, que o Xcode lê e escreve; você o muda pelos editores do Xcode
e não à mão, e o versiona no git como qualquer outro código. Nada nesta seção foi executado para o
curso: ela foi escrita a partir da documentação da Apple sobre projetos, targets e schemes do Xcode,
como estava em 30 de outubro de 2026.

## Targets

Um **target** é um produto: um app, um framework, um conjunto de testes. Um projeto novo de app iOS
feito com o template *App* vem com três:

- `Planner`, o app. As configurações de build dele dizem qual iOS ele exige, em quais aparelhos roda,
  e o bundle identifier de que trata a seção 07;
- `PlannerTests`, testes unitários, compilados num bundle que roda dentro do app;
- `PlannerUITests`, testes de interface, que dirigem o app de fora como uma pessoa faria. A aula 20
  escreve os dois tipos.

**Cada target tem as suas próprias configurações de build**, e quase tudo o que você vai mudar neste
curso é uma configuração do target do app: o deployment target, o bundle identifier, a versão, o time
de assinatura na aula 21. Uma configuração pode ser dada no nível do projeto e herdada, ou
sobrescrita por target, e a aba *Build Settings* do Xcode mostra de qual nível veio cada valor.

## Schemes

Um target diz o que compilar. Um **scheme** diz o que fazer com ele: quais targets compilar, qual
rodar, quais testes rodar, e com qual **configuração de build**. Um projeto novo tem duas
configurações, `Debug` e `Release`. `Debug` compila rápido e guarda tudo de que um depurador precisa;
`Release` otimiza, e é o que um arquivo para a App Store usa, como mostra a aula 21.

É sobre o scheme que agem os comandos *Run*, *Test* e *Archive* do menu Product do Xcode, e o menu ao
lado do botão de parar escolhe tanto o scheme quanto o aparelho ou simulador em que rodar. Um projeto
com um target de app tem um scheme, com o nome dele, e isso é tudo de que este curso precisa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 364\" role=\"img\" data-fig=\"l01-project\" aria-label=\"Um projeto Xcode, Planner.xcodeproj, desenhado como uma caixa grande com três targets: o app Planner, PlannerTests e PlannerUITests. Abaixo deles, o scheme Planner, cujas ações Run, Test e Archive apontam para os targets. À direita, fora do projeto, o diretório planner: um pacote Swift cuja biblioteca PlannerCore é ligada ao target do app. O projeto é compilado pelo Xcode num Mac; o pacote, pelo swift em qualquer computador.\"><defs><marker id=\"l01-project-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l01-project-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l01-project-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l01-project-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"44\" width=\"430\" height=\"300\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"235\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Planner.xcodeproj</text><text x=\"235\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">targets: o que compilar</text><text x=\"235\" y=\"326\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">compilado pelo Xcode, num Mac</text><rect x=\"40\" y=\"94\" width=\"128\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"104\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Planner</text><text x=\"104\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o app</text><rect x=\"178\" y=\"94\" width=\"128\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"242\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">PlannerTests</text><text x=\"242\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">testes unitários</text><rect x=\"316\" y=\"94\" width=\"128\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"380\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">PlannerUITests</text><text x=\"380\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">testes de interface</text><rect x=\"40\" y=\"214\" width=\"394\" height=\"84\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"237\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">scheme Planner</text><text x=\"237\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o que fazer com os targets:</text><text x=\"237\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Run · Test · Archive, em Debug ou Release</text><path d=\"M104 214 L104 154\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-project-ah-amber)\"></path><path d=\"M242 214 L242 154\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-project-ah-amber)\"></path><path d=\"M380 214 L380 154\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-project-ah-amber)\"></path><rect x=\"500\" y=\"94\" width=\"200\" height=\"150\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"600\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">planner/</text><text x=\"600\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um pacote Swift</text><rect x=\"520\" y=\"148\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"600\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">PlannerCore</text><text x=\"600\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">compilado pelo swift,</text><text x=\"600\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">em qualquer computador</text><path d=\"M680 168 L708 168 L708 12 L104 12 L104 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-project-ah-phosphor)\"></path><text x=\"600\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">import PlannerCore</text></svg>", "caption": "Um target é um produto a compilar, e um scheme diz o que fazer com ele. O pacote fica ao lado do projeto, e só a sua biblioteca entra no app."}
```

## O pacote ao lado do projeto

O pacote do planner da seção 05 entra no projeto como um **pacote local**: no Xcode, *File*, depois
*Add Package Dependencies*, depois *Add Local*, e escolha o diretório `planner`. A biblioteca do
pacote, `PlannerCore`, aparece então entre os frameworks do target do app, e qualquer arquivo do app
pode dizer `import PlannerCore`. Edite um arquivo do pacote no Xcode e a próxima compilação do app o
pega; rode `swift test` no diretório do pacote e os mesmos arquivos são testados sem Xcode nenhum.

**Esse arranjo é o jeito de o curso ser honesto sobre o muro.** O que está no pacote é praticado e
capturado; o que está no target do app é descrito a partir da documentação da Apple. A aula 14 leva
mais do planner para o pacote, e a aula 20 o testa pelos dois lados.

O primeiro arquivo do target do app é o ponto de entrada. A aula 2 trata do que cada linha quer
dizer; aqui ele mostra que o app alcança o pacote:

```swift
// PlannerApp.swift
import SwiftUI
import PlannerCore

@main
struct PlannerApp: App {
    let plan = Plan(
        courses: [Course(id: "sql", title: "SQL Databases")],
        sessions: [StudySession(id: "s1", courseID: "sql", date: "2026-10-19", minutes: 50, done: true)]
    )

    var body: some Scene {
        WindowGroup {
            let total = plan.weekTotal(today: "2026-10-21")
            Text("\(total.done) of \(total.planned) minutes this week")
        }
    }
}
```

Não executado: não há Mac na gravação deste curso. Num Mac, o *Run* compila isto para o simulador que
você escolheu e o abre ali, e a documentação da Apple para o `Text` diz que ele desenha a string; a
string em si, `50 of 50 minutes this week`, é a aritmética do pacote, que a seção 05 testou.
