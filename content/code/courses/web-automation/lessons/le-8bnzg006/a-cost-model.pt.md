---
title: Quanto um teste custa, e quanto vale
version: 1
---

**Um teste não sai de graça depois de escrito.** A imagem comum é que escrever é o custo e tudo o
que vem depois é lucro: ele roda para sempre, sem custo, e pega o que aparecer. Cada aula deste
curso mostrou um pedaço do contrário. O teste da aula 2 quebrou na primeira execução por causa de
um localizador, o driver da aula 8 deixou de combinar com o navegador, os testes da aula 14
ficaram vermelhos sem nada errado. Cada um desses é uma conta, e ela chega depois de o teste estar
escrito.

## O modelo

Uma verificação custa quatro coisas, e três delas se repetem:

- **escrevê-la**, uma vez;
- **mantê-la**: os minutos que alguém gasta com ela cada vez que a aplicação muda de um jeito que
  quebra o teste e não o produto;
- **executá-la**: os segundos dela, vezes o número de execuções;
- **alarmes falsos**: cada execução vermelha que no fim não era nada, vezes o tempo que leva para
  descobrir isso.

E ela vale uma coisa: os defeitos que pega, cada um valendo **o que esse defeito custaria se
escapasse, menos o que custa quando o teste o encontra**. Por que um defeito achado tarde custa
tanto mais que um achado cedo é a aula 3 de `qa-fundamentals`; aqui essa diferença é um número
que você põe na conta. Quais defeitos são prováveis o bastante para merecer uma verificação é a
aula 20 de `qa-fundamentals`, sobre priorização por risco.

```localised
custo por ano = escrita + mudanças × minutos por mudança + alarmes falsos × minutos cada
              + execuções × segundos por execução (tempo de máquina, numa coluna própria)
valor por ano = defeitos pegos × (minutos se escapar − minutos quando o teste o acha)
```

O tempo de máquina fica numa coluna própria de propósito. Um minuto de servidor de CI é mais
barato que um minuto de uma pessoa, e qualquer taxa que convertesse um no outro seria inventada.
Ele importa de outro jeito, que é quanto tempo alguém espera por uma resposta, e a seção sobre a
suíte como produto trata disso.

## Um experimento que você pode repetir

Dois testes deste curso, executados contra as mesmas cinco versões da loja: a verificação da
aula 7 de que nada rola para o lado, e a comparação da página inteira com uma captura de tela, da
aula 16. A primeira execução do teste de captura escreve a referência:

```
ana@laptop:~/quitanda$ npx playwright test --config evidence.config.js evidence/visual.spec.js | grep -E '✓|✘|^ +[0-9]+ pixels|snapshot doesn|^  [0-9]+ (passed|failed)'
  ✘  1 evidence/visual.spec.js:5:1 › the shop looks as it did (673ms)
    Error: A snapshot doesn't exist at /home/ana/quitanda/evidence/visual.spec.js-snapshots/shop-linux.png, writing actual.
  1 failed
```

Depois a loja como está, com o defeito da aula 7 dentro:

```
ana@laptop:~/quitanda$ npx playwright test --config evidence.config.js evidence/visual.spec.js | grep -E '✓|✘|^ +[0-9]+ pixels|snapshot doesn|^  [0-9]+ (passed|failed)'
  ✓  1 evidence/visual.spec.js:5:1 › the shop looks as it did (439ms)
  1 passed (1.6s)
ana@laptop:~/quitanda$ npx playwright test tests/responsive.spec.js -g sideways | grep -E '✓|✘|Expected to fail|^  [0-9]+ (passed|failed)'
  ✘  1 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 360 px (211ms)
  ✘  2 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 390 px (149ms)
  ✓  3 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 768 px (138ms)
  3 passed (1.9s)
```

Depois quatro edições do tipo que uma loja faz toda semana, cada uma desfeita antes da seguinte.
Duas são mudanças que alguém quis fazer, uma é um defeito, e uma é a correção que a aula 7 pediu. A
borda fica mais escura, em `app/public/style.css`:

```
ana@laptop:~/quitanda$ npx playwright test --config evidence.config.js evidence/visual.spec.js | grep -E '✓|✘|^ +[0-9]+ pixels|snapshot doesn|^  [0-9]+ (passed|failed)'
  ✘  1 evidence/visual.spec.js:5:1 › the shop looks as it did (960ms)
      4794 pixels (ratio 0.01 of all image pixels) are different.
  1 failed
ana@laptop:~/quitanda$ npx playwright test tests/responsive.spec.js -g sideways | grep -E '✓|✘|Expected to fail|^  [0-9]+ (passed|failed)'
  ✘  1 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 360 px (163ms)
  ✘  2 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 390 px (132ms)
  ✓  3 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 768 px (158ms)
  3 passed (1.8s)
```

A banana passa a custar R$ 6,20 em vez de R$ 5,90, em `app/store.js`:

```
ana@laptop:~/quitanda$ npx playwright test --config evidence.config.js evidence/visual.spec.js | grep -E '✓|✘|^ +[0-9]+ pixels|snapshot doesn|^  [0-9]+ (passed|failed)'
  ✘  1 evidence/visual.spec.js:5:1 › the shop looks as it did (1.1s)
      25 pixels (ratio 0.01 of all image pixels) are different.
  1 failed
ana@laptop:~/quitanda$ npx playwright test tests/responsive.spec.js -g sideways | grep -E '✓|✘|Expected to fail|^  [0-9]+ (passed|failed)'
  ✘  1 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 360 px (180ms)
  ✘  2 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 390 px (148ms)
  ✓  3 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 768 px (136ms)
  3 passed (1.8s)
```

Alguém escreve `color: #fff` em `.price`, e todo preço fica branco sobre um cartão branco. A página
continua com os preços, e o teste de fumaça da aula 1 roda também:

```
ana@laptop:~/quitanda$ npx playwright test --config evidence.config.js evidence/visual.spec.js | grep -E '✓|✘|^ +[0-9]+ pixels|snapshot doesn|^  [0-9]+ (passed|failed)'
  ✘  1 evidence/visual.spec.js:5:1 › the shop looks as it did (1.0s)
      1383 pixels (ratio 0.01 of all image pixels) are different.
  1 failed
ana@laptop:~/quitanda$ npx playwright test tests/responsive.spec.js -g sideways | grep -E '✓|✘|Expected to fail|^  [0-9]+ (passed|failed)'
  ✘  1 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 360 px (165ms)
  ✘  2 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 390 px (142ms)
  ✓  3 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 768 px (129ms)
  3 passed (1.7s)
ana@laptop:~/quitanda$ npx playwright test tests/smoke.spec.js | grep -E '✓|✘|^  [0-9]+ (passed|failed)'
  ✓  1 tests/smoke.spec.js:3:1 › the shop opens and lists its fruit (175ms)
  1 passed (1.4s)
```

E a correção: `white-space: nowrap; min-width: 24rem;` apagados de `.basket`:

```
ana@laptop:~/quitanda$ npx playwright test --config evidence.config.js evidence/visual.spec.js | grep -E '✓|✘|^ +[0-9]+ pixels|snapshot doesn|^  [0-9]+ (passed|failed)'
  ✓  1 evidence/visual.spec.js:5:1 › the shop looks as it did (451ms)
  1 passed (1.7s)
ana@laptop:~/quitanda$ npx playwright test tests/responsive.spec.js -g sideways | grep -E '✓|✘|Expected to fail|^  [0-9]+ (passed|failed)'
  ✓  1 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 360 px (158ms)
  ✓  2 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 390 px (152ms)
  ✓  3 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 768 px (161ms)
    Expected to fail, but passed.
    Expected to fail, but passed.
  2 failed
  1 passed (3.6s)
```

| a edição | era defeito? | captura de tela | rolagem lateral |
|---|---|---|---|
| nenhuma: o defeito da aula 7 | sim, em celulares | passou | falhou como declarado |
| borda mais escura | não | **falhou** | passou |
| preço novo | não | **falhou** | passou |
| preços brancos | sim | **falhou** | passou |
| a correção | não, um conserto | passou | **passou, e avisou** |

**Leia a tabela por coluna.** A verificação de rolagem lateral ficou vermelha uma vez, na única
coisa que ela pergunta, e é cega para todo o resto, inclusive os preços brancos, que o teste de
fumaça também deixou passar. A captura de tela ficou vermelha em toda edição que mexeu num pixel
na sua única largura, o defeito e as duas mudanças do mesmo jeito, e não enxerga o defeito da aula
7, porque tira a foto numa janela de 1280, o padrão do Playwright, onde a cesta cabe.

## Os dois testes no modelo

Os números abaixo são **suposições, ditas para você poder mudá-las**: uma suíte que roda 20 vezes
por dia útil em 250 dias, 5.000 execuções por ano; dez minutos para uma pessoa abrir uma execução
vermelha, olhar uma diferença e decidir; o visual da loja mudando uma vez por semana, 50 vezes por
ano; um defeito achado por um teste na revisão custando 15 minutos e um achado por um cliente
custando um dia de trabalho, 480. Os tempos de execução vêm das execuções acima: 211, 149 e 138 ms para as três larguras, e 439 ms para a captura de tela, na loja como está.

| | rolagem lateral (aula 7) | captura de tela (aula 16) |
|---|---|---|
| escrita | 15 min | 10 min |
| mudanças de visual que a quebram | 0 das 2 acima: 0 min | 2 de 2, então as 50: **50 × 10 = 500 min** |
| execuções, tempo de máquina | 0,50 s por execução: 2.490 s, 41 min | 0,44 s por execução: 2.195 s, 37 min |
| defeitos pegos por ano | suponha 1: 465 min | suponha 1: 465 min |
| **custo em pessoa : valor** | **15 : 465** | **510 : 465** |

**As duas custam quase o mesmo para rodar**, então não é no tempo de execução que diferem. A captura de
tela é o teste mais poderoso, e nesta loja ela **custa mais que o defeito que pega**, porque a
loja muda o visual mais vezes do que quebra. Isso diz algo sobre a loja e não sobre capturas de
tela: mude a suposição para uma mudança de visual por mês e o custo em pessoa vira
10 + 12 × 10 = 130, bem abaixo do valor. A verificação de rolagem lateral é barata por um motivo
que não depende das suposições. Ela faz uma pergunta que tem **uma resposta certa em cada
largura**, e nada inofensivo consegue deixá-la vermelha.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 380\" role=\"img\" aria-label=\"Um gráfico com o custo no eixo horizontal e o valor no vertical, ambos em minutos de pessoa por ano de 0 a 600, e uma diagonal tracejada onde o valor é igual ao custo. A verificação de rolagem lateral da aula 7 fica em custo 15 e valor 465, bem acima da diagonal. O teste de captura de tela com o visual mudando toda semana fica em custo 510 e valor 465, abaixo da diagonal. Uma seta o leva a custo 130, acima da diagonal, para um visual que muda uma vez por mês.\"><polygon points=\"90,320 680,40 90,40\" fill=\"var(--panel)\"></polygon><line x1=\"90\" y1=\"320\" x2=\"680\" y2=\"320\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"90\" y1=\"320\" x2=\"90\" y2=\"40\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"90\" y=\"338\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">0</text><text x=\"82\" y=\"324\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"end\">0</text><text x=\"287\" y=\"338\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">200</text><text x=\"82\" y=\"231\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"end\">200</text><text x=\"483\" y=\"338\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">400</text><text x=\"82\" y=\"137\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"end\">400</text><text x=\"680\" y=\"338\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">600</text><text x=\"82\" y=\"44\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"end\">600</text><line x1=\"90\" y1=\"320\" x2=\"680\" y2=\"40\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"></line><text x=\"414\" y=\"203\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\">valor = custo</text><text x=\"102\" y=\"180\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" text-anchor=\"start\">vale mais do que custa</text><text x=\"672\" y=\"306\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" text-anchor=\"end\">custa mais do que vale</text><text x=\"385\" y=\"360\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">custo, minutos de pessoa por ano</text><text x=\"22\" y=\"180\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\" text-anchor=\"middle\" transform=\"rotate(-90 22 180)\">valor, minutos de pessoa por ano</text><line x1=\"582\" y1=\"103\" x2=\"230\" y2=\"103\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></line><polygon points=\"226,103 238,98 238,108\" fill=\"var(--amber)\"></polygon><circle cx=\"105\" cy=\"103\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"115\" y=\"73\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" text-anchor=\"start\">rolagem lateral</text><text x=\"115\" y=\"88\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\">15 : 465</text><circle cx=\"218\" cy=\"103\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"226\" y=\"73\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" text-anchor=\"start\">captura, visual muda por mês</text><text x=\"226\" y=\"88\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\">130 : 465</text><circle cx=\"592\" cy=\"103\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"600\" y=\"129\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" text-anchor=\"end\">captura, visual muda por semana</text><text x=\"600\" y=\"144\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"end\">510 : 465</text></svg>", "caption": "Três pontos do modelo de custo, com as suposições desta seção. A verificação de rolagem lateral custa cerca de um trigésimo do que vale. A captura de tela custa mais do que vale enquanto o visual muda toda semana, e menos quando muda por mês: o teste não mudou, a loja mudou."}
```

## O que fazer com um teste caro

- **Estreite-o.** `expect(page.locator('.card').first()).toHaveScreenshot()` compara um cartão em
  vez da página, e uma edição em qualquer outro lugar da página deixa de deixá-lo vermelho.
- **Pergunte pelo fato em vez da imagem**, quando houver um. Os preços brancos são uma falha de
  contraste, e contraste tem resposta certa, que as aulas 12 a 15 de `non-functional-testing`
  testam.
- **Rode-o menos vezes**, à noite em vez de a cada push, para que seja um relatório que alguém lê
  e não uma porta diante da qual alguém espera.
- **Apague-o**, com o motivo anotado, que é o assunto de duas seções adiante.
