---
title: "PlantUML: UML, com precisão, a partir de texto"
version: 1
---

**PlantUML é uma sintaxe de texto que cobre todos os diagramas UML da aula 2, e mais, renderizada
por um único programa Java.** Onde o Mermaid é leve e aproximado, o PlantUML fica mais perto da
especificação UML: pontas de seta, estereótipos e fragmentos saem como a aula 2 os desenhou.

## Obtendo

O PlantUML é um arquivo `.jar`. Baixe a versão que esta aula usa do Maven Central, o repositório
público de bibliotecas Java, e confira que ele roda:

```
ana@vm:~/diagrams$ curl -sSLO https://repo1.maven.org/maven2/net/sourceforge/plantuml/plantuml/1.2026.9/plantuml-1.2026.9.jar
ana@vm:~/diagrams$ java -jar plantuml-1.2026.9.jar -version | head -1
PlantUML version 1.2026.9 / 18d0aae [2026-10-17 08:34:41 UTC]
```

## A compra, como sequência

Salve isto como `purchase.puml`. É a compra da aula 2, escrita como texto:

```
@startuml
participant App
participant API
participant Holds
database DB
participant Gateway
App -> API : POST /bookings
API -> Holds : hold seat 14, 10 min
Holds --> API : held
API -> DB : insert, pending payment
API --> App : 201 Created
App -> API : POST /payments
API -> Gateway : charge card
alt approved
  Gateway --> API : approved
  API -> DB : mark paid
  API --> App : ticket
else declined
  Gateway --> API : declined
  API ->> Holds : release seat
  API --> App : reason
end
@enduml
```

As setas seguem a notação da aula 2: `->` é uma mensagem síncrona com ponta cheia, `-->` uma
resposta tracejada, `->>` uma mensagem assíncrona com ponta aberta. `alt` e `else` abrem o
fragmento; `end` o fecha. Renderize como SVG:

```
ana@vm:~/diagrams$ java -jar plantuml-1.2026.9.jar -tsvg purchase.puml
ana@vm:~/diagrams$ ls -l purchase.svg
-rw-rw-r-- 1 ana ana 13716 Oct 23 02:06 purchase.svg
```

## Um diagrama no terminal

O PlantUML também consegue desenhar um diagrama de sequência como texto, o que é útil num terminal
ou num comentário de revisão de código. Este é só o primeiro pedido da compra. Salve isto como
`hold.puml`:

```
@startuml
participant App
participant API
participant Holds
App -> API : POST /bookings
API -> Holds : hold seat 14, 10 min
Holds --> API : held
API --> App : 201 Created
@enduml
```

```
ana@vm:~/diagrams$ java -jar plantuml-1.2026.9.jar -tutxt hold.puml
ana@vm:~/diagrams$ cat hold.utxt
┌───┐             ┌───┐                  ┌─────┐
│App│             │API│                  │Holds│
└─┬─┘             └─┬─┘                  └──┬──┘
  │ POST /bookings  │                       │
  │────────────────>│                       │
  │                 │                       │
  │                 │ hold seat 14, 10 min  │
  │                 │──────────────────────>│
  │                 │                       │
  │                 │         held          │
  │                 │< ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─│
  │                 │                       │
  │   201 Created   │                       │
  │< ─ ─ ─ ─ ─ ─ ─ ─│                       │
  │                 │                       │
┌─┴─┐             ┌─┴─┐                  ┌──┴──┐
│App│             │API│                  │Holds│
└───┘             └───┘                  └─────┘
```

O renderizador de texto é uma conveniência, não um substituto: ele lida bem com mensagens simples e
desenha mal fragmentos como `alt`, e é por isso que a compra completa acima foi renderizada como SVG.

## Verificando sem renderizar

`-syntax` pergunta ao PlantUML só se um arquivo é interpretado, lendo-o da entrada padrão. Quebre o
`hold.puml` dobrando a seta da segunda mensagem, `API -> -> Holds`, salve como `broken.puml` e
verifique os dois:

```
ana@vm:~/diagrams$ java -jar plantuml-1.2026.9.jar -syntax < hold.puml
SEQUENCE
(3 participants)
ana@vm:~/diagrams$ java -jar plantuml-1.2026.9.jar -syntax < broken.puml
ERROR
5
Syntax Error? (Assumed diagram type: sequence)
```

A primeira resposta dá o tipo de diagrama que ele encontrou e o que há nele; a segunda diz `ERROR`,
a linha, contada a partir da primeira linha depois de `@startuml`, e o que o PlantUML supôs que
estava lendo.

**Desenhe você mesmo.** Escreva em PlantUML o diagrama de classes do agregado de reserva da aula 2,
com a composição de Booking para Ticket e a associação navegável de Ticket para Trip, e renderize.
Confira que o losango cai na ponta de Booking. A versão usada aqui dispõe diagramas de classes
sozinha; versões mais antigas do PlantUML precisavam do Graphviz instalado para eles.
