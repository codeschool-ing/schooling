---
title: Quanto custa cada camada
version: 1
---

Um teste custa três coisas: **o tempo que leva, as vezes em que falha sem motivo e o trabalho de
mantê-lo verdadeiro** quando o produto muda por motivos que não são defeitos. As três crescem
conforme o teste roda mais do sistema, e esta seção mede cada uma nos três arquivos.

## Tempo, uma vez e vinte vezes

Uma execução de cada, cronometrada pelo shell, com a saída jogada fora para sobrar só o relógio:

```
ana@laptop:~/quitanda$ time node --test --test-reporter=tap unit/total.test.js > /dev/null

real	0m0.114s
user	0m0.102s
sys	0m0.021s
ana@laptop:~/quitanda$ time npx playwright test tests/basket-api.spec.js > /dev/null

real	0m2.521s
user	0m2.156s
sys	0m0.362s
ana@laptop:~/quitanda$ time npx playwright test tests/basket-ui.spec.js > /dev/null

real	0m2.647s
user	0m2.290s
sys	0m0.368s
```

A linha `real` é o que você espera diante do teclado: 0,114 s para o teste de unidade, 2,521 s e
2,647 s para os outros dois. **Numa execução avulsa, os dois arquivos do Playwright quase empatam**,
0,126 s de diferença, porque a maior parte de uma execução avulsa é o que os dois pagam antes de
qualquer teste começar: carregar o Playwright e subir a loja pelo `webServer`.

Vinte execuções os separam. O arquivo de unidade roda vinte vezes num laço do shell; os arquivos do
Playwright usam `--repeat-each 20`, num worker só porque os dois escrevem na cesta compartilhada:

```
ana@laptop:~/quitanda$ time for i in $(seq 20); do node --test --test-reporter=tap unit/total.test.js > /dev/null; done

real	0m2.164s
user	0m1.816s
sys	0m0.547s
ana@laptop:~/quitanda$ time npx playwright test tests/basket-api.spec.js --repeat-each 20 --workers 1 --reporter=dot

Running 20 tests using 1 worker
····················
  20 passed (16.3s)

real	0m17.531s
user	0m17.904s
sys	0m2.368s
ana@laptop:~/quitanda$ time npx playwright test tests/basket-ui.spec.js --repeat-each 20 --workers 1 --reporter=dot

Running 20 tests using 1 worker
····················
  20 passed (23.1s)

real	0m24.310s
user	0m22.908s
sys	0m4.574s
```

As quarenta execuções do Playwright passaram. Dividindo por vinte, uma execução custou 0,108 s na
camada de unidade, 0,877 s na de API e 1,215 s na do navegador. Vinte repetições não são vinte
testes num worker, porém, e isso importa aqui. O Playwright dá a cada repetição **um worker
próprio**, como o relatório JSON mostra:

```
ana@laptop:~/quitanda$ npx playwright test tests/basket-api.spec.js --repeat-each 3 --workers 1 --reporter=json > /tmp/run.json
ana@laptop:~/quitanda$ grep -o "\"workerIndex\": [0-9]*" /tmp/run.json
"workerIndex": 0
"workerIndex": 1
"workerIndex": 2
```

Então cada uma das vinte execuções subiu um processo de worker novo, assim como cada execução de
unidade subiu um Node novo. A comparação é justa entre as camadas, e é o preço de começar do zero,
que é o que rodar um arquivo de novo custa. Dentro de uma suíte longa o worker é reaproveitado, e o
número que cresce com a suíte é o tempo por teste, o que cada executor imprimiu na seção anterior:
bem menos de um milissegundo, 51 ms e 281 ms.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Os três arquivos de teste desenhados como uma pirâmide de três faixas. A faixa estreita do topo é a camada do navegador, um teste, 281 milissegundos por teste e 24,310 segundos para vinte execuções. A faixa do meio é a camada de API, um teste, 51 milissegundos por teste e 17,531 segundos para vinte execuções. A faixa larga da base é a camada de unidade, três testes, menos de um milissegundo cada e 2,164 segundos para vinte execuções.\"><path d=\"M200 30 L260 110 L140 110 Z\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M140 110 L260 110 L320 190 L80 190 Z\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></path><path d=\"M80 190 L320 190 L380 270 L20 270 Z\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><text x=\"200\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">1</text><text x=\"200\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">1</text><text x=\"200\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">3</text><path d=\"M240 81 L410 81\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"420\" y=\"72\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">navegador: um clique numa página real</text><text x=\"420\" y=\"91\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">281 ms</text><text x=\"560\" y=\"91\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">24.310 s</text><path d=\"M293 151 L410 151\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"420\" y=\"142\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">API: uma requisição, sem navegador</text><text x=\"420\" y=\"161\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">51 ms</text><text x=\"560\" y=\"161\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">17.531 s</text><path d=\"M353 231 L410 231\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"420\" y=\"222\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">unidade: uma chamada de função, sem servidor</text><text x=\"420\" y=\"241\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">menos de 1 ms</text><text x=\"560\" y=\"241\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">2.164 s</text><text x=\"20\" y=\"302\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o número em cada faixa é quantos testes ela tem; os tempos são as execuções desta aula</text><text x=\"420\" y=\"30\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um teste</text><text x=\"560\" y=\"30\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">vinte execuções</text></svg>", "caption": "A pirâmide com os números desta loja. Um comportamento, verificado três vezes: o teste de navegador custou mais de cinco vezes o teste de API por teste, e a camada de unidade verificou três casos em menos tempo do que qualquer um dos comandos do Playwright levou para terminar."}
```

## Por que lento importa

Um segundo a mais ou a menos parece nada, e para um teste é. **O custo de um teste é o tempo dele
multiplicado pelo número de vezes que ele roda**, e os dois números crescem. Pegue uma suíte de 300
verificações como estas, num worker, com os tempos por teste acima:

| as 300 verificações na | uma execução | 60 execuções por dia |
|---|---|---|
| camada do navegador, 281 ms cada | 300 × 0,281 = 84,3 s | 84,3 × 60 = 5.058 s, uns 84 minutos |
| camada de API, 51 ms cada | 300 × 0,051 = 15,3 s | 15,3 × 60 = 918 s, uns 15 minutos |
| camada de unidade, no máximo 1 ms cada | 300 × 0,001 = 0,3 s | 0,3 × 60 = 18 s |

Sessenta execuções são quatro pessoas rodando a suíte quinze vezes cada num dia de trabalho, o que é
uma equipe modesta fazendo o que você quer que ela faça: rodar os testes depois de cada mudança.
Workers em paralelo dividem a primeira coluna, e a aula 19 trata disso; eles dividem pelo número de
núcleos, não por mil.

Os minutos são a metade menor do custo. **Uma suíte que leva um minuto e meio roda menos vezes**,
então um defeito vive mais tempo entre ser escrito e ser visto, e esse intervalo é o custo em que a
aula 3 de `qa-fundamentals` põe preço. Uma suíte que responde em um terço de segundo roda a cada
salvamento sem ninguém precisar decidir isso.

## Instabilidade

As quarenta execuções do Playwright acima passaram, e isso prova menos do que parece. Um teste que
falha uma vez em cem, por motivos que nada têm a ver com a loja, passa vinte seguidas com
probabilidade 0,99 elevado a 20, cerca de 0,82: **quatro vezes em cinco você veria vinte limpas e
acreditaria.** A aula 11 tirou as esperas de um script do Puppeteer e obteve a cesta 0, 0, 0, 1, 1
em cinco execuções; a aula 14 trata de achar e conter testes assim.

O que as camadas mudam é quantas fontes desse tipo cada teste tem. O teste de unidade não tem rede,
servidor, temporizador nem renderização, então nada nele pode correr contra nada. O teste de API
acrescenta um servidor e HTTP. O teste de navegador acrescenta um navegador iniciando, uma página
carregando os scripts, um evento chegando a um botão e cada espera no meio, e cada um desses é um
lugar onde o tempo pode decidir o resultado.

## Manutenção

O terceiro custo chega quando o produto muda e nada está errado. Troque o texto do botão de
"Add to basket" para "Add to cart", uma mudança de palavras que nenhum cliente chamaria de defeito:

```sh
sed -i 's|<button type="button">Add to basket</button>|<button type="button">Add to cart</button>|' app/public/app.js
```

E rode os dois arquivos do Playwright:

```
ana@laptop:~/quitanda$ npx playwright test tests/basket-api.spec.js tests/basket-ui.spec.js --workers 1

Running 2 tests using 1 worker

  ✓  1 tests/basket-api.spec.js:4:1 › a banana in the basket costs 590 cents (46ms)
  ✘  2 tests/basket-ui.spec.js:3:1 › a banana in the basket shows R$ 5,90 (30.0s)


  1) tests/basket-ui.spec.js:3:1 › a banana in the basket shows R$ 5,90 ────────────────────────────

    Test timeout of 30000ms exceeded.

    Error: locator.click: Test timeout of 30000ms exceeded.
    Call log:
      - waiting for getByTestId('product-banana').getByRole('button', { name: 'Add to basket' })


      4 |   await request.post('/api/reset');
      5 |   await page.goto('/');
    > 6 |   await page.getByTestId('product-banana').getByRole('button', { name: 'Add to basket' }).click();
        |                                                                                           ^
      7 |   await expect(page.getByTestId('basket-count')).toHaveText('1');
      8 |   await expect(page.locator('.basket-total')).toHaveText('R$ 5,90');
      9 | });
        at /home/ana/quitanda/tests/basket-ui.spec.js:6:91

    Error Context: test-results/basket-ui-a-banana-in-the-basket-shows-R-5-90/error-context.md

  1 failed
    tests/basket-ui.spec.js:3:1 › a banana in the basket shows R$ 5,90 ─────────────────────────────
  1 passed (31.3s)
```

**O teste de navegador falhou numa loja que funciona**, e levou o tempo limite inteiro de 30
segundos para dizer isso, porque o Playwright ficou esperando aparecer um botão com o nome antigo. O
teste de API não sabe o que o botão diz. Todo teste de navegador que nomeia o botão paga essa mudança
uma vez, que é o argumento da aula 12 para guardar um localizador num page object só, e não em
cinquenta testes. Nada disso é motivo para não ter testes de navegador. É o motivo de cada um
precisar valer o que custa, e é para lá que vão as duas próximas seções. Recoloque o texto antes:

```sh
sed -i 's|<button type="button">Add to cart</button>|<button type="button">Add to basket</button>|' app/public/app.js
```
