---
title: Reproduzir, e depois mudar uma coisa
version: 1
---

**Diagnosticar um teste instável começa por fazê-lo falhar de propósito, vezes suficientes para
contar.** O primeiro movimento errado é ler com muita atenção a única execução vermelha e
adivinhar. Uma execução é uma amostra de um; uma causa adivinhada a partir dela é uma história. O
movimento certo é rodar o teste muitas vezes, medir a taxa, e então mudar uma coisa de cada vez e
ver se a taxa se mexe.

## Um teste certo e às vezes vermelho

A aula 3 calculou quando o defeito da busca aparece: uma tecla a cada *k* milissegundos põe a
resposta da *n*-ésima pergunta em *k*×(*n*−1) + 900 − 150×*n* depois da primeira tecla. Abaixo de
150 ms por tecla as respostas voltam na ordem inversa, e a lista termina errada; acima disso voltam
em ordem. Em exatamente 150 ms, todas as respostas são esperadas no mesmo instante, cerca de 750 ms
depois da primeira tecla, e qual chega por último depende do que mais a máquina estiver fazendo.
Uma pessoa que digita rápido não está longe disso.

O teste abaixo digita `papaya` a 145 ms por tecla, que nesta máquina é onde o veredito se divide. É
um bom teste: espera a página dizer que terminou e então verifica a única coisa que um cliente
verificaria. É também um teste que você não deve pôr em `tests/` enquanto descobre o que ele faz.
Tudo em `tests/` é o portão da primeira seção, e um teste de que você já desconfia faria de cada
execução do portão um cara ou coroa. Então ele vai para uma pasta só sua, com uma configuração
que lê apenas essa pasta e tira todo o resto da configuração do projeto. Salve-a como
`quarantine.config.js`:

```javascript
// The quarantine: tests known to be flaky, run apart from the gate.
// Everything else comes from the project's own configuration.
import { defineConfig } from '@playwright/test';
import base from './playwright.config.js';

export default defineConfig({
  ...base,
  testDir: 'quarantine',
});
```

E o teste. Salve-o como `quarantine/typing.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// Lesson 3's search, typed just under the speed at which its defect stops
// showing. Whether it shows is decided by a few milliseconds.
test('typed at 145 ms a key, the list settles on papaya', async ({ page }) => {
  await page.goto('/search.html');
  await page.getByLabel('Fruit').pressSequentially('papaya', { delay: 145 });
  await expect(page.locator('#results')).toHaveAttribute('aria-busy', 'false');
  await expect(page.locator('#results li')).toHaveText(['Papaya']);
});
```

## Rodar muitas vezes

`--repeat-each 20` roda cada teste vinte vezes de uma vez. O `grep` guarda a linha que o Playwright
imprime para cada tentativa e o resumo:

```
ana@laptop:~/quitanda$ npx playwright test --config quarantine.config.js --repeat-each 20 | grep -E '✓|✘|^  [0-9]+ (failed|flaky|passed)'
  ✓   1 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓   3 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓   4 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✘   2 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (6.1s)
  ✓   5 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓   6 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓   7 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓   8 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓   9 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  10 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  11 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  12 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  13 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  14 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  15 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  16 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  17 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  18 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  19 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  20 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  1 failed
  19 passed (23.9s)
```

**Dezenove passaram e uma falhou**, e a falha é fácil de achar: levou 6,1 s contra 1,1 s, porque a
verificação tentou de novo durante os seus cinco segundos contra uma lista que nunca ia mudar. Uma
falha em vinte é exatamente a taxa que sobrevive a uma nova execução e chega ao portão.

## Mudar uma coisa

Os dois workers rodaram as vinte tentativas de duas em duas. As mesmas vinte, uma de cada vez:

```
ana@laptop:~/quitanda$ npx playwright test --config quarantine.config.js --repeat-each 20 --workers 1 | grep -E '^  [0-9]+ (failed|flaky|passed)'
  8 failed
  12 passed (1.3m)
```

**Oito falhas desta vez, contra uma.** Vale ler isso com cuidado, porque a cesta compartilhada da
seção anterior também mudou de veredito com `--workers`, e aqui a causa é outra. Nada neste teste
alcança algo que outro teste toque: a busca não guarda estado. O que mudou foi a carga da máquina, e
com ela o ritmo em que seis requisições e seis respostas foram tratadas; como exatamente isso as
moveu, estas duas execuções não mostram. Uma taxa que se mexe com o número de workers diz *tempo ou
compartilhamento*; o que diz *compartilhamento* é um valor recebido que é trabalho de outro teste,
como a contagem de 2 na falha da cesta.

As outras coisas que vale mudar uma de cada vez são a velocidade da rede (o atraso com `page.route`
da aula 3), o navegador, a máquina e a ordem dos testes. Anote a contagem de cada execução, e não
só *continua instável*.

## O que as duas execuções fizeram de diferente

A mesma corrida, rodada pelo `race.mjs` da aula 3 a 145 ms por tecla, até uma execução terminar com
uma fruta e outra com três. Foram precisas duas execuções:

```
ana@laptop:~/quitanda$ node race.mjs papaya 145
   62 ms  asked    "p"
  211 ms  asked    "pa"
  362 ms  asked    "pap"
  511 ms  asked    "papa"
  661 ms  asked    "papay"
  819 ms  asked    "papaya"
  820 ms  answered "pa"
  820 ms  answered "p"
  821 ms  answered "papa"
  821 ms  answered "pap"
  823 ms    shows  2 found: Papaya, Passion fruit  (aria-busy=true)
  828 ms  answered "papay"
  829 ms  answered "papaya"
  829 ms    shows  3 found: Papaya, Passion fruit, Pineapple  (aria-busy=true)
  829 ms    shows  1 found: Papaya  (aria-busy=true)
  830 ms    shows  1 found: Papaya  (aria-busy=true)
  831 ms    shows  1 found: Papaya  (aria-busy=true)
  831 ms    shows  1 found: Papaya  (aria-busy=false)
```

```
ana@laptop:~/quitanda$ node race.mjs papaya 145
   72 ms  asked    "p"
  220 ms  asked    "pa"
  369 ms  asked    "pap"
  518 ms  asked    "papa"
  669 ms  asked    "papay"
  818 ms  asked    "papaya"
  824 ms  answered "papa"
  825 ms  answered "papay"
  825 ms  answered "papaya"
  826 ms  answered "pap"
  826 ms  answered "pa"
  828 ms    shows  1 found: Papaya  (aria-busy=true)
  829 ms    shows  1 found: Papaya  (aria-busy=true)
  832 ms    shows  1 found: Papaya  (aria-busy=true)
  832 ms  answered "p"
  833 ms    shows  1 found: Papaya  (aria-busy=true)
  833 ms    shows  2 found: Papaya, Passion fruit  (aria-busy=true)
  833 ms    shows  3 found: Papaya, Passion fruit, Pineapple  (aria-busy=false)
```

As perguntas saíram com cerca de 150 ms entre si nas duas execuções, e **as seis respostas chegaram
com no máximo uns doze milissegundos de diferença**. Na primeira execução as respostas a `papay` e
`papaya` chegaram por último e a lista terminou em Papaya; no caminho ela mostrou três frutas por
um instante, que nenhuma verificação viu. Na segunda a resposta a `p` chegou por último, em 832 ms,
e a lista ficou nas três.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 372\" role=\"img\" aria-label=\"O mesmo teste, digitado a 145 milissegundos por tecla, desenhado em duas execuções. As seis perguntas saíram com cerca de 150 milissegundos entre si e as seis respostas chegaram com no máximo uns doze milissegundos de diferença, entre 820 e 832 ms. Na execução A as respostas a papay e papaya chegaram por último, em 828 e 829 ms, e a lista terminou com uma fruta: o teste passou. Na execução B a resposta a p chegou por último, em 832 ms, e a lista terminou com três frutas: o teste falhou.\"><text x=\"20\" y=\"24\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">execução A: a resposta a \"papaya\" chega por último</text><text x=\"20\" y=\"50\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"p\"</text><path d=\"M150 46 L530 46\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"238\" cy=\"46\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"20\" y=\"68\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"pa\"</text><path d=\"M150 64 L530 64\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"238\" cy=\"64\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"20\" y=\"86\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"pap\"</text><path d=\"M150 82 L530 82\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"260\" cy=\"82\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"20\" y=\"104\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"papa\"</text><path d=\"M150 100 L530 100\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"260\" cy=\"100\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"20\" y=\"122\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"papay\"</text><path d=\"M150 118 L530 118\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"414\" cy=\"118\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"20\" y=\"140\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"papaya\"</text><path d=\"M150 136 L530 136\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"436\" cy=\"136\" r=\"5\" fill=\"var(--phosphor)\"></circle><rect x=\"556\" y=\"82\" width=\"150\" height=\"40\" rx=\"3\" fill=\"var(--scan)\"></rect><text x=\"631\" y=\"98\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a lista termina em 1 found</text><text x=\"631\" y=\"114\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">passa</text><text x=\"20\" y=\"184\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">execução B: a resposta a \"p\" chega por último</text><text x=\"20\" y=\"210\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"p\"</text><path d=\"M150 206 L530 206\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"502\" cy=\"206\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"20\" y=\"228\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"pa\"</text><path d=\"M150 224 L530 224\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"370\" cy=\"224\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"20\" y=\"246\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"pap\"</text><path d=\"M150 242 L530 242\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"370\" cy=\"242\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"20\" y=\"264\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"papa\"</text><path d=\"M150 260 L530 260\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"326\" cy=\"260\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"20\" y=\"282\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"papay\"</text><path d=\"M150 278 L530 278\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"348\" cy=\"278\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"20\" y=\"300\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"papaya\"</text><path d=\"M150 296 L530 296\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"348\" cy=\"296\" r=\"5\" fill=\"var(--paper-dim)\"></circle><rect x=\"556\" y=\"242\" width=\"150\" height=\"40\" rx=\"3\" fill=\"var(--scan)\"></rect><text x=\"631\" y=\"258\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a lista termina em 3 found</text><text x=\"631\" y=\"274\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">falha</text><path d=\"M150 324 L530 324\" stroke=\"var(--wire)\"></path><path d=\"M150 324 L150 329\" stroke=\"var(--wire)\"></path><text x=\"150\" y=\"342\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">816</text><path d=\"M238 324 L238 329\" stroke=\"var(--wire)\"></path><text x=\"238\" y=\"342\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">820</text><path d=\"M326 324 L326 329\" stroke=\"var(--wire)\"></path><text x=\"326\" y=\"342\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">824</text><path d=\"M414 324 L414 329\" stroke=\"var(--wire)\"></path><text x=\"414\" y=\"342\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">828</text><path d=\"M502 324 L502 329\" stroke=\"var(--wire)\"></path><text x=\"502\" y=\"342\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">832</text><text x=\"150\" y=\"362\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">milissegundos no relógio do race.mjs</text></svg>", "caption": "Duas execuções do mesmo teste, tiradas do race.mjs a 145 ms por tecla. Seis respostas chegam em doze milissegundos, e a que chega por último decide o veredito."}
```

A figura é o diagnóstico inteiro: o teste não varia, a página não varia, e a ordem de seis respostas
que chegam quase no mesmo instante varia. Um teste que falha uma vez em vinte costuma ser uma
corrida como esta, entre dois eventos próximos o bastante para trocar de lugar.

## Guardar a evidência da tentativa que falhou

Uma contagem diz com que frequência; não diz como estava a página quando falhou. O Playwright
consegue gravar um **trace**, um arquivo com cada ação, cada requisição de rede e um retrato da
página em cada passo, e `--trace retain-on-failure` o guarda só para as tentativas que falharam.
Com um teste que falha uma vez em vinte, é assim que você chega a ver essa uma. A aula 16 trata de
ler um trace e as capturas de tela ao lado dele.
