---
title: O que testar, e o que a cobertura não diz
version: 1
---

**Teste as regras onde elas moram, no pacote, e deixe para os testes do app o que só o app faz.** Todo
teste desta aula até aqui está em `Tests/PlannerCoreTests/`, roda numa fração de segundo em qualquer
computador e confere uma regra que uma pessoa notaria quebrar: a soma da semana, a segunda-feira de um
dia, um erro que tem de chegar à tela. Os testes de interface da seção 06 conferem um punhado de fluxos
de ponta a ponta. As previews são para olhar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l20-where\" aria-label=\"Onde vive cada tipo de teste. À esquerda, o pacote Swift do planner, com os testes unitários em Swift Testing e XCTest, rodados pelo swift test em qualquer computador numa fração de segundo. À direita, o projeto Xcode num Mac, com os testes de interface, que abrem o app num simulador e levam segundos cada, e as previews, que são olhadas e não executadas. A seta do pacote para o app diz que o app importa as regras testadas.\"><defs><marker id=\"l20-where-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l20-where-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l20-where-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l20-where-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"320\" height=\"260\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">o pacote, qualquer computador</text><rect x=\"40\" y=\"66\" width=\"280\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Swift Testing</text><text x=\"180\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a semana, segundas, carga</text><rect x=\"40\" y=\"136\" width=\"280\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">XCTest</text><text x=\"180\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">os testes antigos, ao lado</text><rect x=\"40\" y=\"206\" width=\"280\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">swift test</text><text x=\"180\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">milissegundos, a cada mudança</text><rect x=\"400\" y=\"20\" width=\"300\" height=\"260\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"550\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">o app, num Mac (não executado aqui)</text><rect x=\"420\" y=\"66\" width=\"260\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"550\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">testes de interface (XCTest)</text><text x=\"550\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">poucos fluxos, segundos cada</text><rect x=\"420\" y=\"136\" width=\"260\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"550\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">#Preview</text><text x=\"550\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">olhadas, nunca falham</text><rect x=\"420\" y=\"206\" width=\"260\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"550\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">PlannerApp</text><text x=\"550\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">importa PlannerCore</text><path d=\"M340 233 L418 233\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l20-where-ah-phosphor)\"></path></svg>", "caption": "As regras são testadas onde moram, rápido e em qualquer lugar; o app fica com os poucos testes que só um app roda."}
```

## A cobertura, medida uma vez

O `swift test --enable-code-coverage` registra quais linhas do pacote os testes executaram, e o
`llvm-cov`, que vem com o toolchain, faz o relatório. O binário de teste no Linux é
`.build/debug/PlannerCoreTests.so`; num Mac é um bundle terminado em `.xctest`, e o
`swift test --show-codecov-path` imprime onde o SwiftPM grava o mesmo relatório em JSON:

```
ana@vm:~/l20$ swift test --enable-code-coverage > /dev/null 2>&1; echo $?
0
ana@vm:~/l20$ llvm-cov report .build/debug/PlannerCoreTests.so -instr-profile .build/debug/codecov/default.profdata -ignore-filename-regex Tests -show-region-summary=false -show-branch-summary=false
Filename                    Functions  Missed Functions  Executed       Lines      Missed Lines     Cover
---------------------------------------------------------------------------------------------------------
Days.swift                          4                 1    75.00%          18                 1    94.44%
Loading.swift                       1                 0   100.00%           4                 0   100.00%
Plan.swift                         12                 0   100.00%          40                 2    95.00%
---------------------------------------------------------------------------------------------------------
TOTAL                              17                 1    94.12%          62                 3    95.16%
ana@vm:~/l20$ llvm-cov show .build/debug/PlannerCoreTests.so -instr-profile .build/debug/codecov/default.profdata Sources/PlannerCore/Plan.swift | grep -E "^ +[0-9]+\| +0\|"
   51|      0|        sessions.append(session)
   52|      0|    }
```

**O número interessa menos que as duas linhas que ele aponta.** As linhas 51 e 52 do `Plan.swift` são o
fim do `add`: a sessão acrescentada, o caminho de sucesso. Todo teste que chama o `add` espera que ele
recuse, e nenhum teste acrescenta uma sessão válida e confere que ela está lá. O `week/main.swift` faz
isso, e um programa não é um teste. Isso é um teste que falta, com nome, e vale a pena escrevê-lo.

O que falta no `Days.swift` é do outro tipo. Pertence ao `preconditionFailure`, cuja mensagem é uma
closure que só roda para um dia que não é um dia, e testá-la seria um teste que trava de propósito. A
aula 10 confere o texto digitado antes de ele chegar lá, que é onde esse caso é testado.

**Então a cobertura é um mapa, não uma meta.** Uma linha que ninguém roda é uma pergunta: é um caso em
que ninguém pensou, ou um caso que não pode acontecer? Subir a porcentagem escrevendo testes que tocam
linhas sem afirmar nada não responde nenhuma das duas, e deixa o próximo mapa mais difícil de ler.

## A ordem em que escrevê-los

Quando um bug é encontrado, a primeira coisa escrita é o teste que falha por causa dele, e depois a
correção que o faz passar. O teste é a descrição do bug numa forma que não se esquece. O mesmo hábito
responde "o que testar agora?" num projeto com poucos testes: **o próximo bug**, e depois os casos ao
lado dele, do jeito que a seção 03 testou as fronteiras ao lado de uma semana.
