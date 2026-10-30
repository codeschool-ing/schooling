---
title: Três lugares onde um teste pode rodar
version: 1
---

**Um teste Android se define menos pelo que confere do que por onde roda**, e o lugar decide o custo.
As aulas 18 a 20 já escreveram testes de todos os tipos que este curso consegue rodar: um worker
respondendo de três jeitos, uma notificação lida de volta do sistema, uma permissão recusada duas
vezes. Esta aula dá nome aos tipos, escreve um de cada para a tela da semana do planner, e acrescenta
o único tipo que este curso não conseguiu rodar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l21-layers\" aria-label=\"Três tipos de teste lado a lado. JUnit puro, em src/test, roda na JVM do seu computador sem Android nenhum: confere lógica, como o total da semana. Robolectric, também em src/test, roda na mesma JVM com um substituto do Android: confere composables, notificações e permissões, e o Roborazzi salva capturas ali. Testes instrumentados, em src/androidTest, rodam num celular ou num emulador: conferem o sistema de verdade. Uma seta da esquerda para a direita diz: mais perto de um celular de verdade. Uma seta da direita para a esquerda diz: mais rápido, e roda em qualquer computador.\"><defs><marker id=\"l21-layers-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"16\" y=\"20\" width=\"216\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"124\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">JUnit puro</text><text x=\"124\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">src/test</text><text x=\"124\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a sua JVM, sem Android</text><text x=\"124\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lógica: o total da semana,</text><text x=\"124\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a tabela de ofertas</text><text x=\"124\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">roda aqui</text><rect x=\"252\" y=\"20\" width=\"216\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">Robolectric</text><text x=\"360\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">src/test</text><text x=\"360\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a sua JVM, um Android substituto</text><text x=\"360\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">composables, notificações,</text><text x=\"360\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">permissões, capturas</text><text x=\"360\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">roda aqui</text><rect x=\"488\" y=\"20\" width=\"216\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"596\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">instrumentado</text><text x=\"596\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">src/androidTest</text><text x=\"596\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um celular ou um emulador</text><text x=\"596\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o sistema de verdade: caixas,</text><text x=\"596\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a gaveta, uma GPU real</text><text x=\"596\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">não roda aqui</text><path d=\"M40 196 L680 196\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l21-layers-ah-wire)\"></path><text x=\"360\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mais perto de um celular de verdade</text><path d=\"M680 232 L40 232\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l21-layers-ah-wire)\"></path><text x=\"360\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mais rápido, e roda em qualquer computador</text></svg>", "caption": "Cada passo para a direita fica mais perto do que o estudante segura e mais longe do que um notebook roda. Este curso roda os dois primeiros em toda aula, e descreve o terceiro.", "same": ["Robolectric"]}
```

- **JUnit puro** roda na JVM do seu computador sem Android nenhum. Ele testa tudo o que é só Kotlin:
  o total da semana, a tabela de ofertas da aula 20, um cálculo de datas. Ele mora em `app/src/test`.
- **Robolectric** roda na mesma JVM, na mesma pasta, com um substituto do framework do Android. Ele
  testa composables, notificações, permissões e workers, e o Roborazzi salva capturas a partir dele.
  A maior parte das capturas deste curso veio de um.
- **Testes instrumentados** rodam num celular ou num emulador, a partir de `app/src/androidTest`.
  Eles testam o sistema de verdade, incluindo as partes que o Robolectric só imita. A seção 06
  escreve um e mostra o que aconteceu quando ele foi mandado rodar aqui.

## Quanto cada um custa

A diferença não é questão de opinião; está nos relatórios de teste. Depois que todos os testes da
aula foram escritos, o Gradle roda todos de novo com `--rerun`, e cada arquivo de resultado registra
quanto tempo cada teste levou:

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --rerun 2>&1 | grep -E '^BUILD|tests completed'
BUILD SUCCESSFUL in 21s
ana@vm:~/planner$ grep -ho 'testcase name="[^"]*" classname="[^"]*" time="[^"]*"' app/build/test-results/testDebugUnitTest/*.xml | sed -e 's/classname="com.example.planner.//'
testcase name="sundayBelongsToTheWeekThatEndsOnIt" data.WeekTest" time="0.002"
testcase name="theTotalCountsOnlyThisWeek" data.WeekTest" time="0.0"
testcase name="aWeekRunsMondayToSunday" data.WeekTest" time="0.0"
testcase name="tickingASessionMovesTheTotal" ui.WeekScreenTest" time="6.149"
testcase name="theWeek" ui.WeekShotTest" time="9.437"
```

Os três testes do `WeekTest` são JUnit puro, e cada um levou poucos milissegundos, ou nenhum que o
relatório conseguisse contar. Os testes no Robolectric levaram segundos cada, e **a maior parte disso
é iniciar o Android substituto**, que um teste puro nunca paga. Um teste instrumentado soma instalar
o app num aparelho e abri-lo ali, e é por isso que as equipes os mantêm poucos.

**A regra que sai disso é a de sempre: empurre cada conferência o mais para a esquerda possível.** Se
um cálculo pode ser testado sem Android, teste sem Android, e guarde os testes mais lentos para o que
só eles enxergam. A seção 07 volta a essa regra com os testes do próprio planner como exemplo.
