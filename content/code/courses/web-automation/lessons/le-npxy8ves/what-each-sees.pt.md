---
title: O que cada camada consegue ver
version: 1
---

Três execuções verdes dizem a mesma coisa três vezes, então não contam para que servem as camadas.
**Uma camada ganha o seu lugar pelo defeito que ela pega e as outras deixam passar**, e o jeito de
ver isso é pôr um defeito e olhar que testes ficam vermelhos. Cada mudança abaixo é feita com `sed`
para uma execução e desfeita logo depois, o que é teste de mutação feito à mão: quebrar o código de
propósito e ver se algum teste percebe.

## Um defeito que só o navegador vê

A página converte centavos em reais num lugar só, a função de `app/public/app.js` que desenha o
cabeçalho. Tire a divisão dela:

```sh
sed -i 's|money.format(basket.total / 100)|money.format(basket.total)|' app/public/app.js
```

O servidor continua respondendo `total: 590`, o que está certo. A página agora formata 590 como
reais. Rode os três arquivos:

```
ana@laptop:~/quitanda$ node --test --test-reporter=tap unit/total.test.js
TAP version 13
# Subtest: an empty basket costs nothing
ok 1 - an empty basket costs nothing
  ---
  duration_ms: 0.823823
  type: 'test'
  ...
# Subtest: one banana costs 590 cents
ok 2 - one banana costs 590 cents
  ---
  duration_ms: 0.187692
  type: 'test'
  ...
# Subtest: quantities multiply and lines add up
ok 3 - quantities multiply and lines add up
  ---
  duration_ms: 0.134308
  type: 'test'
  ...
1..3
# tests 3
# suites 0
# pass 3
# fail 0
# cancelled 0
# skipped 0
# todo 0
# duration_ms 69.284004
ana@laptop:~/quitanda$ npx playwright test tests/basket-api.spec.js tests/basket-ui.spec.js --workers 1

Running 2 tests using 1 worker

  ✓  1 tests/basket-api.spec.js:4:1 › a banana in the basket costs 590 cents (57ms)
  ✘  2 tests/basket-ui.spec.js:3:1 › a banana in the basket shows R$ 5,90 (5.2s)


  1) tests/basket-ui.spec.js:3:1 › a banana in the basket shows R$ 5,90 ────────────────────────────

    Error: expect(locator).toHaveText(expected) failed

    Locator:  locator('.basket-total')
    Expected: "R$ 5,90"
    Received: "R$ 590,00"
    Timeout:  5000ms

    Call log:
      - Expect "toHaveText" with timeout 5000ms
      - waiting for locator('.basket-total')
        9 × locator resolved to <span class="basket-total">R$ 590,00</span>
          - unexpected value "R$ 590,00"


       6 |   await page.getByTestId('product-banana').getByRole('button', { name: 'Add to basket' }).click();
       7 |   await expect(page.getByTestId('basket-count')).toHaveText('1');
    >  8 |   await expect(page.locator('.basket-total')).toHaveText('R$ 5,90');
         |                                               ^
       9 | });
      10 |
        at /home/ana/quitanda/tests/basket-ui.spec.js:8:47

    Error Context: test-results/basket-ui-a-banana-in-the-basket-shows-R-5-90/error-context.md

  1 failed
    tests/basket-ui.spec.js:3:1 › a banana in the basket shows R$ 5,90 ─────────────────────────────
  1 passed (6.6s)
```

O teste de unidade passou nos três casos, e o teste de API passou em 57 ms. O teste de navegador
falhou depois de 5,2 s, que são os cinco segundos que o `expect` passa tentando de novo um texto
antes de desistir, e a mensagem mostra os dois lados: esperado `R$ 5,90`, recebido `R$ 590,00`.

**Esse defeito mora na costura entre a página e o servidor**, o acordo de que o servidor fala em
centavos e a página divide. O teste de unidade não o vê, porque `total()` nunca esteve errada. O
teste de API não o vê, porque a API nunca esteve errada. Só o teste que lê o que a página desenha
consegue, e é o único dos três que roda o código da página. Recoloque a linha antes de seguir:

```sh
sed -i 's|money.format(basket.total)|money.format(basket.total / 100)|' app/public/app.js
```

## Um defeito que a camada de unidade crava barato

Agora quebre a aritmética. Em `app/store.js`, faça `total()` esquecer a quantidade:

```sh
sed -i 's|return sum + product.price \* line.qty;|return sum + product.price;|' app/store.js
```

```
ana@laptop:~/quitanda$ node --test --test-reporter=tap unit/total.test.js
TAP version 13
# Subtest: an empty basket costs nothing
ok 1 - an empty basket costs nothing
  ---
  duration_ms: 0.887472
  type: 'test'
  ...
# Subtest: one banana costs 590 cents
ok 2 - one banana costs 590 cents
  ---
  duration_ms: 0.320592
  type: 'test'
  ...
# Subtest: quantities multiply and lines add up
not ok 3 - quantities multiply and lines add up
  ---
  duration_ms: 0.87445
  type: 'test'
  location: '/home/ana/quitanda/unit/total.test.js:13:1'
  failureType: 'testCodeFailure'
  error: |-
    Expected values to be strictly equal:
    
    1880 !== 4350
    
  code: 'ERR_ASSERTION'
  name: 'AssertionError'
  expected: 4350
  actual: 1880
  operator: 'strictEqual'
  stack: |-
    TestContext.<anonymous> (file:///home/ana/quitanda/unit/total.test.js:15:10)
    Test.runInAsyncScope (node:async_hooks:214:14)
    Test.run (node:internal/test_runner/test:1047:25)
    Test.processPendingSubtests (node:internal/test_runner/test:744:18)
    Test.postRun (node:internal/test_runner/test:1173:19)
    Test.run (node:internal/test_runner/test:1101:12)
    async Test.processPendingSubtests (node:internal/test_runner/test:744:7)
  ...
1..3
# tests 3
# suites 0
# pass 2
# fail 1
# cancelled 0
# skipped 0
# todo 0
# duration_ms 78.745706
ana@laptop:~/quitanda$ npx playwright test tests/basket-api.spec.js tests/basket-ui.spec.js --workers 1

Running 2 tests using 1 worker

  ✓  1 tests/basket-api.spec.js:4:1 › a banana in the basket costs 590 cents (49ms)
  ✓  2 tests/basket-ui.spec.js:3:1 › a banana in the basket shows R$ 5,90 (213ms)

  2 passed (1.6s)
```

Agora quem falha é o teste de unidade. O terceiro caso esperava 4350 e recebeu 1880, que é uma
banana e uma goiaba, 590 + 1290, sem as quantidades. Os dois primeiros casos continuam passando,
porque uma quantidade de um esconde o defeito. Os testes de API e de navegador passaram, em 49 ms e
213 ms.

**O teste de navegador ficou verde numa loja que cobra errado.** Não é um teste ruim; ele comprou uma
banana, e com uma unidade de cada coisa o defeito não tem efeito. Para pegá-lo ali, o teste teria de
apertar o botão três vezes num cartão, duas em outro e ler o total, o que é mais passos, mais espera
e mais jeitos de falhar por motivos que não são a aritmética. O teste de API está na mesma situação:
precisaria de três requisições. O teste de unidade chegou lá escrevendo uma linha a mais, com outros
números. Desfaça a mudança:

```sh
sed -i 's|return sum + product.price;|return sum + product.price * line.qty;|' app/store.js
```

## Os dois juntos

| | unidade, `total()` | API, `/api/basket` | navegador, um clique |
|---|---|---|---|
| centavos desenhados como reais no cabeçalho | verde, não vê | verde, não vê | **vermelho**, e a mensagem nomeia os dois textos |
| quantidade esquecida em `total()` | **vermelho**, `1880 !== 4350` | verde, uma banana | verde, uma banana |
| para onde a falha aponta | a função e os números | a resposta da rota | um localizador, um texto, uma página |

Leia a última linha também. **Um teste de unidade vermelho nomeia a regra que quebrou**; um teste de
navegador vermelho nomeia o que um cliente notaria, e a causa pode estar em qualquer ponto entre a
aritmética do servidor e a formatação da página. Os dois são úteis, e úteis para coisas diferentes.
O primeiro diz o que consertar. O segundo diz que algo que um cliente toca está errado, o que nenhuma
quantidade de testes de unidade vai dizer.

Essa também é a resposta honesta para "qual camada é a melhor": nenhuma das três pegou os dois
defeitos. A próxima seção pergunta quanto cada uma custa para rodar, porque, se todas fossem de graça,
você simplesmente manteria as três em todo lugar.
