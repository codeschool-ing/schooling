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
  ✘   1 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (6.1s)
  ✘   2 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (6.1s)
  ✓   3 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓   4 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.2s)
  ✓   5 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓   7 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓   8 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✘   6 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (6.1s)
  ✓   9 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  10 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  11 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  12 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  14 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  15 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✘  13 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (6.1s)
  ✓  17 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  18 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✘  16 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (6.1s)
  ✓  19 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  20 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  5 failed
  15 passed (34.1s)
```

**Quinze passaram e cinco falharam**, e as falhas são fáceis de achar: cada uma levou 6,1 s contra
cerca de 1,1 s, porque a verificação tentou de novo durante os seus cinco segundos contra uma lista
que nunca ia mudar. Com uma falha em quatro, uma única nova execução deixa o portão verde três
vezes em quatro.

## Mudar uma coisa

Os dois workers rodaram as vinte tentativas de duas em duas. As mesmas vinte, uma de cada vez:

```
ana@laptop:~/quitanda$ npx playwright test --config quarantine.config.js --repeat-each 20 --workers 1 | grep -E '^  [0-9]+ (failed|flaky|passed)'
  6 failed
  14 passed (1.2m)
```

**Seis falhas contra cinco: o número de workers quase não fez diferença.** Compare com o par da
seção das causas, que foi de nenhuma falha com um worker para três com dois. Esse contraste é o
diagnóstico. Nada neste teste alcança algo que outro teste toque, porque a busca não guarda estado,
então rodar duas tentativas ao mesmo tempo muda pouco. Uma taxa que salta com `--workers` diz
*compartilhamento*, e o valor recebido diz o que foi compartilhado: a contagem de 2 era a manga do
outro teste. Uma taxa que fica parada diz que a causa mora dentro do próprio teste e da sua página.

As outras coisas que vale mudar uma de cada vez são a velocidade da rede (o atraso com `page.route`
da aula 3), o navegador, a máquina e a ordem dos testes. Anote a contagem de cada execução, e não
só *continua instável*.

## O que as duas execuções fizeram de diferente

A mesma corrida, rodada pelo `race.mjs` da aula 3 a 145 ms por tecla, até uma execução terminar com uma
fruta e outra com mais. Foram precisas nove execuções:

```
ana@laptop:~/quitanda$ node race.mjs papaya 145
   62 ms  asked    "p"
  212 ms  asked    "pa"
  364 ms  asked    "pap"
  509 ms  asked    "papa"
  658 ms  asked    "papay"
  808 ms  asked    "papaya"
  812 ms  answered "papay"
  813 ms  answered "papa"
  816 ms  answered "papaya"
  816 ms    shows  1 found: Papaya  (aria-busy=true)
  819 ms    shows  1 found: Papaya  (aria-busy=true)
  819 ms    shows  1 found: Papaya  (aria-busy=true)
  820 ms  answered "pa"
  820 ms  answered "p"
  820 ms  answered "pap"
  823 ms    shows  2 found: Papaya, Passion fruit  (aria-busy=true)
  823 ms    shows  3 found: Papaya, Passion fruit, Pineapple  (aria-busy=true)
  823 ms    shows  1 found: Papaya  (aria-busy=false)
```

```
ana@laptop:~/quitanda$ node race.mjs papaya 145
   57 ms  asked    "p"
  206 ms  asked    "pa"
  358 ms  asked    "pap"
  506 ms  asked    "papa"
  654 ms  asked    "papay"
  803 ms  asked    "papaya"
  808 ms  answered "papaya"
  809 ms  answered "papay"
  810 ms  answered "pap"
  810 ms  answered "papa"
  811 ms    shows  1 found: Papaya  (aria-busy=true)
  814 ms  answered "p"
  814 ms    shows  1 found: Papaya  (aria-busy=true)
  815 ms  answered "pa"
  816 ms    shows  1 found: Papaya  (aria-busy=true)
  817 ms    shows  1 found: Papaya  (aria-busy=true)
  817 ms    shows  3 found: Papaya, Passion fruit, Pineapple  (aria-busy=true)
  817 ms    shows  2 found: Papaya, Passion fruit  (aria-busy=false)
```

As perguntas saíram com cerca de 150 ms entre si nas duas execuções, e **as seis respostas chegaram
com no máximo oito milissegundos de diferença**. Na primeira execução as respostas a `pa`, `p` e
`pap` chegaram todas em 820 ms e foram desenhadas nessa ordem: a lista passou a duas frutas, depois
três, e terminou na resposta a `pap`, que é só Papaya. Na segunda a resposta a `pa` chegou por
último, em 815 ms, e a lista ficou em duas frutas, Papaya e Passion fruit. Nenhuma das duas é o
quadro da aula 3, com respostas voltando na ordem inversa. Elas chegam amontoadas, e a que é
desenhada por último decide.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 372\" role=\"img\" aria-label=\"O mesmo teste, digitado a 145 milissegundos por tecla, desenhado em duas execuções. As seis perguntas saíram com cerca de 150 milissegundos entre si e as seis respostas chegaram com no máximo oito milissegundos de diferença. Na execução A as respostas a pa, p e pap chegaram todas em 820 ms e a resposta a pap foi desenhada por último, então a lista terminou com uma fruta e o teste passou. Na execução B a resposta a pa chegou por último, em 815 ms, e a lista terminou com duas frutas, então o teste falhou.\"><text x=\"20\" y=\"24\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">execução A: \"pa\", \"p\" e \"pap\" chegam juntas, \"pap\" é desenhada por último</text><text x=\"20\" y=\"50\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"p\"</text><path d=\"M150 46 L530 46\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"502\" cy=\"46\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"20\" y=\"68\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"pa\"</text><path d=\"M150 64 L530 64\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"502\" cy=\"64\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"20\" y=\"86\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"pap\"</text><path d=\"M150 82 L530 82\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"502\" cy=\"82\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"20\" y=\"104\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"papa\"</text><path d=\"M150 100 L530 100\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"348\" cy=\"100\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"20\" y=\"122\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"papay\"</text><path d=\"M150 118 L530 118\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"326\" cy=\"118\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"20\" y=\"140\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"papaya\"</text><path d=\"M150 136 L530 136\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"414\" cy=\"136\" r=\"5\" fill=\"var(--paper-dim)\"></circle><rect x=\"556\" y=\"82\" width=\"150\" height=\"40\" rx=\"3\" fill=\"var(--scan)\"></rect><text x=\"631\" y=\"98\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a lista termina em 1 found</text><text x=\"631\" y=\"114\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">passa</text><text x=\"20\" y=\"184\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">execução B: a resposta a \"pa\" chega por último</text><text x=\"20\" y=\"210\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"p\"</text><path d=\"M150 206 L530 206\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"370\" cy=\"206\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"20\" y=\"228\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"pa\"</text><path d=\"M150 224 L530 224\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"392\" cy=\"224\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"20\" y=\"246\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"pap\"</text><path d=\"M150 242 L530 242\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"282\" cy=\"242\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"20\" y=\"264\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"papa\"</text><path d=\"M150 260 L530 260\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"282\" cy=\"260\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"20\" y=\"282\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"papay\"</text><path d=\"M150 278 L530 278\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"260\" cy=\"278\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"20\" y=\"300\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"papaya\"</text><path d=\"M150 296 L530 296\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"238\" cy=\"296\" r=\"5\" fill=\"var(--paper-dim)\"></circle><rect x=\"556\" y=\"242\" width=\"150\" height=\"40\" rx=\"3\" fill=\"var(--scan)\"></rect><text x=\"631\" y=\"258\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a lista termina em 2 found</text><text x=\"631\" y=\"274\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">falha</text><path d=\"M150 324 L530 324\" stroke=\"var(--wire)\"></path><path d=\"M150 324 L150 329\" stroke=\"var(--wire)\"></path><text x=\"150\" y=\"342\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">804</text><path d=\"M238 324 L238 329\" stroke=\"var(--wire)\"></path><text x=\"238\" y=\"342\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">808</text><path d=\"M326 324 L326 329\" stroke=\"var(--wire)\"></path><text x=\"326\" y=\"342\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">812</text><path d=\"M414 324 L414 329\" stroke=\"var(--wire)\"></path><text x=\"414\" y=\"342\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">816</text><path d=\"M502 324 L502 329\" stroke=\"var(--wire)\"></path><text x=\"502\" y=\"342\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">820</text><text x=\"150\" y=\"362\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">milissegundos no relógio do race.mjs</text></svg>", "caption": "Duas execuções do mesmo teste, tiradas do race.mjs a 145 ms por tecla. Seis respostas chegam em oito milissegundos, e a que é desenhada por último decide o veredito."}
```

A figura é o diagnóstico inteiro: o teste não varia, a página não varia, e a ordem de seis respostas
que chegam quase no mesmo instante varia. Uma falha instável de tempo costuma ser uma corrida
como esta, entre eventos próximos o bastante para trocar de lugar.

## Guardar a evidência da tentativa que falhou

Uma contagem diz com que frequência; não diz como estava a página quando falhou. O Playwright
consegue gravar um **trace**, um arquivo com cada ação, cada requisição de rede e um retrato da
página em cada passo, e `--trace retain-on-failure` o guarda só para as tentativas que falharam.
Com um teste que falha uma vez em
quatro, é assim que você vê uma tentativa que falhou sem rodar de novo até pegar uma. A aula 16 trata de
ler um trace e as capturas de tela ao lado dele.
