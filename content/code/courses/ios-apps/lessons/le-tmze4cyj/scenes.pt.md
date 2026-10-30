---
title: Cenas: uma janela, e as views dentro dela
version: 1
---

**Uma cena é um pedaço da interface cuja vida o sistema administra.** Num iPhone o app quase sempre
tem uma, e ela ocupa a tela. Num iPad a mesma declaração pode produzir várias ao mesmo tempo: duas
janelas do planner lado a lado, cada uma mostrando um curso. A documentação da Apple para `Scene` diz
assim: uma cena é um contêiner para uma hierarquia de views, e o sistema decide quando e como
apresentá-la.

O planner declara um tipo de cena, um `WindowGroup`:

```swift
WindowGroup {
    CourseListView()
}
```

**Um `WindowGroup` é um modelo, não uma janela.** As views no closure dele são o que cada janela que
ele cria vai conter. Num iPhone há uma janela dessas. No iPadOS, diz a documentação da Apple, uma
pessoa pode abrir mais de uma janela do grupo, desde que o `Info.plist` do app ponha
`UIApplicationSupportsMultipleScenes` em `true` no manifesto de cenas. **Cada janela guarda o seu
próprio estado**: a documentação é explícita em que o SwiftUI aloca armazenamento novo para as
variáveis `@State` de cada janela que cria.

Essa frase decide onde os dados do planner podem morar. Se o plano fosse `@State` dentro de
`CourseListView`, duas janelas de iPad teriam dois planos, e uma sessão acrescentada numa não
apareceria na outra. A aula 7 põe o plano num modelo criado uma vez, no `App`, para que toda janela
leia o mesmo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l02-scenes\" aria-label=\"O valor PlannerApp no topo declara um WindowGroup. Num iPhone o grupo faz uma janela; num iPad faz duas janelas lado a lado. Cada janela tem o seu CourseListView com o seu próprio estado, então duas janelas com @State teriam dois planos separados.\"><defs><marker id=\"l02-scenes-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l02-scenes-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l02-scenes-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l02-scenes-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"260\" y=\"16\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">PlannerApp</text><rect x=\"260\" y=\"84\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">WindowGroup</text><path d=\"M360 56 L360 82\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-scenes-ah-wire)\"></path><text x=\"150\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um modelo</text><rect x=\"30\" y=\"160\" width=\"180\" height=\"110\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">iPhone: uma janela</text><rect x=\"50\" y=\"196\" width=\"140\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">CourseListView</text><text x=\"120\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o seu @State</text><rect x=\"290\" y=\"160\" width=\"400\" height=\"110\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"490\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">iPad: duas janelas do mesmo grupo</text><rect x=\"310\" y=\"196\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"395\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">CourseListView</text><text x=\"395\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o seu @State</text><rect x=\"500\" y=\"196\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"585\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">CourseListView</text><text x=\"585\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o seu @State</text><path d=\"M330 124 L125 158\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-scenes-ah-amber)\"></path><path d=\"M380 124 L395 158\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-scenes-ah-amber)\"></path><path d=\"M420 124 L580 158\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-scenes-ah-amber)\"></path></svg>", "caption": "Uma declaração, tantas janelas quanto a plataforma permitir, e um @State separado em cada uma."}
```

## Os outros tipos de cena

O SwiftUI oferece mais tipos de cena do que o planner precisa, e saber que existem explica parte do
que você vai ler em outros apps:

- `DocumentGroup` abre e salva documentos, uma janela por arquivo, para um app feito em torno de
  arquivos;
- `Settings` é uma cena do macOS para a janela de ajustes;
- `Window` declara uma janela única, de novo quase sempre no macOS.

Nenhum deles muda o que este curso constrói. **Um `WindowGroup` é o `body` inteiro do planner**, e
todo o resto do curso acontece nas views dentro dele. Nada nesta seção foi executado; ela foi escrita
a partir da documentação da Apple para `Scene` e `WindowGroup`, lida em 30 de outubro de 2026.
