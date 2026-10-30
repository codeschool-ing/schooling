---
title: Escolhendo o que roda, e o que um número diz
version: 1
---

O target de testes agora tem dez testes em dois frameworks, e eles terminam em bem menos de um
segundo. A suíte de um projeto real leva minutos, e enquanto você trabalha numa função quer os
testes dessa função, não todos. **O `swift test` sabe listar os testes, rodar um subconjunto, pular
um subconjunto e medir que linhas os testes alcançaram.**

## Listando

```
ana@vm:~/sw/l18/planner$ swift test list
Building for debugging...
[Using on-disk description]
Build complete! (1.01 secs)
PlannerCoreTests.WeekXCTests/testRemainingNeverGoesBelowZero
PlannerCoreTests.WeekXCTests/testTotalCountsOnlyDoneSessions
PlannerCoreTests.OfflineTests/aFailureHalfwayKeepsWhatWasSaved()
PlannerCoreTests.OfflineTests/anOfflineStoreStopsTheSync()
PlannerCoreTests.ProgressTests/progress(minutes:expected:)
PlannerCoreTests.SyncerTests/reportsEachSavedSession()
PlannerCoreTests.SyncerTests/savesOnlyDoneSessions()
PlannerCoreTests.WeekTests/firstSessionIsTheOneAdded()
PlannerCoreTests.WeekTests/progress()
PlannerCoreTests.WeekTests/total()
```

Uma linha por teste, como `módulo.Tipo/teste` para um teste dentro de um tipo e `módulo.teste` para
uma função solta. Os dois testes de XCTest vêm primeiro, nomeados do jeito do XCTest, e os do Swift
Testing vêm depois, com parênteses e rótulos de argumento. São esses nomes que o `--filter` e o
`--skip` comparam.

## Filtrando e pulando

As seções 04 a 06 usaram o `--filter` com o nome de uma suíte. **O argumento é uma expressão
regular**, comparada com esses nomes, então `--filter Syncer` roda todo teste cujo nome contém
`Syncer` e `--filter 'progress\('` roda os testes chamados `progress`, em qualquer tipo. O `--skip`
é o contrário, e os dois podem ser combinados:

```
ana@vm:~/sw/l18/planner$ swift test --skip Syncer 2>&1 | grep -v frontend | tail -4
✔ Suite "A week of study" passed after 0.001 seconds.
✔ Suite ProgressTests passed after 0.001 seconds.
✔ Suite OfflineTests passed after 0.001 seconds.
✔ Test run with 6 tests in 3 suites passed after 0.001 seconds.
```

O `tail -4` guarda as quatro últimas linhas. **Seis testes rodaram no Swift Testing**, os oito menos
os dois do `SyncerTests`, e os dois testes de XCTest rodaram também, na parte da saída que o `tail`
cortou, porque o `--skip` vale para os dois frameworks. Um teste que você pula é um teste que você
não está rodando; pular serve durante uma tarefa, e a suíte inteira roda antes de a mudança estar
pronta.

**O Swift Testing roda em paralelo por padrão; o XCTest roda um teste de cada vez**, a menos que se
passe `swift test --parallel`, que inicia vários processos de teste para ele. Uma suíte que passa em
ordem e falha em paralelo tem testes que compartilham algo, um arquivo, uma global ou uma linha de
banco, e a falha é informação real sobre o código mesmo quando é inconveniente.

## Cobertura, e o que ela não quer dizer

O `--enable-code-coverage` registra que linhas do código rodaram enquanto os testes rodavam, e o
`--show-codecov-path` diz para onde foi o resultado:

```
ana@vm:~/sw/l18/planner$ swift test --enable-code-coverage 2>&1 | grep -v frontend | tail -3
✔ Suite ProgressTests passed after 0.002 seconds.
✔ Suite "A week of study" passed after 0.001 seconds.
✔ Test run with 8 tests in 4 suites passed after 0.002 seconds.
ana@vm:~/sw/l18/planner$ swift test --show-codecov-path
/home/ana/sw/l18/planner/.build/out/Products/Debug-linux-x86_64/codecov/planner.json
```

O arquivo JSON é para ferramentas. O `llvm-cov` do toolchain lê os dados brutos ao lado dele e
imprime uma tabela; `-ignore-filename-regex=Tests` deixa de fora os arquivos de teste, e as quatro
opções `-show-…=false` tiram as colunas sobre ramos e regiões, de que esta aula não precisa:

```
ana@vm:~/sw/l18/planner$ llvm-cov report .build/debug/PlannerCoreTests.so -instr-profile=.build/debug/codecov/default.profdata -ignore-filename-regex=Tests -show-region-summary=false -show-branch-summary=false -show-instantiation-summary=false -show-mcdc-summary=false
Filename                    Functions  Missed Functions  Executed       Lines      Missed Lines     Cover
---------------------------------------------------------------------------------------------------------
Syncer.swift                        4                 0   100.00%          13                 0   100.00%
Week.swift                         10                 0   100.00%          18                 0   100.00%
---------------------------------------------------------------------------------------------------------
TOTAL                              14                 0   100.00%          31                 0   100.00%
```

**Toda linha do `Week.swift` e do `Syncer.swift` rodou.** Isso é um fato sobre as linhas, e nada
mais. O defeito do progresso da seção 03 estava numa linha que rodou em todo teste da seção 02 que
tocava o total de uma semana, e a cobertura a teria dado como coberta; o que o pegou foi um teste
que **afirmou** 15% e comparou. Um teste que chama `progress` e não confere nada sobe a porcentagem
exatamente tanto quanto um que confere a resposta certa.

Então leia a cobertura ao contrário: **uma linha que ninguém roda é uma linha sobre a qual nenhum
teste pode estar pegando nada**, e um número baixo num arquivo é uma lista de lugares para olhar. Um
número alto não é veredito, e acrescentar testes para subi-lo, em vez de para afirmar algo que o
código tem de fazer, produz testes que não afirmam nada.
