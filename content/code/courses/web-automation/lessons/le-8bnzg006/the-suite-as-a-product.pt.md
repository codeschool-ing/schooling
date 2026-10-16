---
title: A suíte como produto
version: 1
---

**Uma suíte de testes costuma ser tratada como um subproduto das funcionalidades**, uma pilha que
cresce um arquivo a cada entrega e da qual ninguém em particular cuida. Só que ela tem usuários:
todo mundo que espera por ela antes de fazer merge, e todo mundo que decide pela cor dela se uma
versão sai. Tudo o que tem usuários é um produto, e um produto sem responsável, sem orçamento e sem
um número que diga como ele vai piora devagar, de um jeito que ninguém percebe em nenhum dia
específico.

## Um responsável por arquivo

Quando um teste fica vermelho, **alguém tem de ser a pessoa que olha primeiro**, ou todo mundo
supõe que outro vai olhar. O arranjo mínimo que funciona é um nome por arquivo de teste, escrito
onde as ferramentas o veem: a quarentena da aula 14 escreveu um responsável na anotação, e o
arquivo de responsáveis por código de um serviço de repositórios faz o mesmo para uma pasta. Ser
dono de um teste não quer dizer escrever toda correção. Quer dizer responder, em um dia, se uma
execução vermelha é do produto, do teste ou da máquina.

## Um orçamento para o tempo de execução

As pessoas esperando são o custo, então **o tempo de execução tem um limite que alguém escolheu**, e
um teste que empurra a suíte para além dele tem de comprar o seu lugar acelerando outro, descendo
de camada ou rodando à noite. Não dá para segurar um limite que você não mede. O repórter JSON do
Playwright escreve a duração e o resultado de cada teste, e um script curto o transforma nos
poucos números que vale ler. Salve-o como `slowest.mjs`:

```javascript
import { readFileSync } from 'node:fs';

// Reads the report `--reporter=json` writes, and says where the time went.
const report = JSON.parse(readFileSync(process.argv[2], 'utf8'));
const tests = [];

function walk(suite) {
  for (const spec of suite.specs ?? []) {
    for (const test of spec.tests) {
      const ms = test.results.reduce((sum, result) => sum + result.duration, 0);
      tests.push({ file: spec.file, title: `${spec.file}:${spec.line} › ${spec.title}`, ms, test });
    }
  }
  for (const child of suite.suites ?? []) walk(child);
}
report.suites.forEach(walk);

const seconds = (ms) => (ms / 1000).toFixed(1).padStart(5) + ' s';
const { expected, unexpected, flaky, skipped, duration } = report.stats;
console.log(`${tests.length} tests, ${seconds(duration).trim()} from start to end`);
console.log(`as declared ${expected}, not as declared ${unexpected}, flaky ${flaky}, skipped ${skipped}`);

const byFile = new Map();
for (const t of tests) byFile.set(t.file, (byFile.get(t.file) ?? 0) + t.ms);
console.log('the five slowest files:');
for (const [file, ms] of [...byFile].sort((a, b) => b[1] - a[1]).slice(0, 5)) {
  console.log(`  ${seconds(ms)}  ${file}`);
}

// A test declared with test.fail() passes on ANY failure, so print the one
// it had: it should still be the defect its comment names.
const declared = tests.filter((t) => t.test.expectedStatus === 'failed');
const spent = declared.reduce((sum, t) => sum + t.ms, 0);
console.log(`declared to fail: ${declared.length} tests, ${seconds(spent).trim()}`);
for (const t of declared) {
  const error = t.test.results.at(-1)?.error?.message ?? 'no error recorded';
  const first = error.replace(/\x1b\[[0-9;]*m/g, '').split('\n')[0];
  console.log(`  ${t.title}\n      ${first}`);
}

for (const t of tests.filter((t) => t.test.status === 'unexpected' || t.test.status === 'flaky')) {
  console.log(`${t.test.status}: ${t.title}`);
}
```

A execução que mede a suíte usa **um worker só**, para que os testes que dividem a única cesta da
loja não mudem os resultados uns dos outros; a aula 19 trata de rodá-los separados. Rode a partir
da pasta do projeto:

```
ana@laptop:~/quitanda$ npx playwright test --workers 1 --reporter=json > report.json; echo "exit code $?"
exit code 0
ana@laptop:~/quitanda$ node slowest.mjs report.json
64 tests, 38.1 s from start to end
as declared 64, not as declared 0, flaky 0, skipped 0
the five slowest files:
    6.1 s  search.spec.js
    5.5 s  cache.spec.js
    3.1 s  waiting.spec.js
    3.1 s  toast.spec.js
    2.9 s  conditions.spec.js
declared to fail: 7 tests, 12.4 s
  cache.spec.js:13 › a returning customer sees the new offer
      Error: expect(locator).toContainText(expected) failed
  cache.spec.js:22 › the offer is checked with the server before it is reused
      Error: expect(received).toMatch(expected)
  conditions.spec.js:20 › waitForFunction: typed, the search settles on papaya
      Error: expect(received).toEqual(expected) // deep equality
  responsive.spec.js:45 › nothing scrolls sideways at 360 px
      Error: the page is wider than the window
  responsive.spec.js:45 › nothing scrolls sideways at 390 px
      Error: the page is wider than the window
  search.spec.js:13 › typed key by key, the list settles on papaya
      Error: expect(locator).toHaveText(expected) failed
  spa.spec.js:30 › the basket opens from its own address
      Error: expect(received).toBe(expected) // Object.is equality
```

Todos os 64 testes fizeram o que estavam declarados para fazer, em 38,1 segundos, e quatro
fatos dessa saída valem uma frase cada.

- **O arquivo mais lento é o `search.spec.js`**, com 6,1 segundos, e a maior parte vem de um
  teste: a falha declarada que espera os seus cinco segundos inteiros por uma lista que nunca
  assenta.
- **As sete falhas declaradas custam 12,4 segundos**, cerca de um terço da execução. Cada uma
  espera o tempo limite da sua expectativa, porque uma verificação que vai falhar não tem como
  saber antes. Documentar um defeito tem um preço em tempo de execução, e ele é pago em toda
  execução até o defeito ser corrigido.
- **Cada falha declarada imprime o próprio erro**, e cada um ainda nomeia o defeito que o
  comentário nomeia. É a conferência mensal que a seção anterior pediu.
- **Nada foi intermitente nesta execução**, que é uma só. Uma execução não mede uma taxa.

## A taxa de intermitência é um número

**O número a acompanhar é a fração de execuções que ficam vermelhas sem nada ter mudado.** É o que
uma pessoa sente: um desenvolvedor encontra uma execução vermelha, não um teste vermelho, e uma
suíte de 64 testes em que cada um falha uma vez a cada cem execuções fica vermelha em cerca de
metade delas. Rode a suíte cinco vezes como está, com o número padrão de workers do Playwright:

```
ana@laptop:~/quitanda$ for i in 1 2 3 4 5; do npx playwright test | grep -E '^  [0-9]+ (failed|flaky|passed)|^    tests/'; done
  3 failed
    tests/basket-data.spec.js:14:1 › a banana costs R$ 5,90 ────────────────────────────────────────
    tests/conditions.spec.js:30:1 › expect.poll: the server has the banana from /ssr ───────────────
    tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready ──────────────
  60 passed (28.2s)
  4 failed
    tests/basket-data.spec.js:14:1 › a banana costs R$ 5,90 ────────────────────────────────────────
    tests/conditions.spec.js:40:1 › toPass: the count and the total change together ────────────────
    tests/page-object.spec.js:8:1 › two fruit make two items ───────────────────────────────────────
    tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready ──────────────
  59 passed (31.8s)
  3 failed
    tests/basket-data.spec.js:14:1 › a banana costs R$ 5,90 ────────────────────────────────────────
    tests/page-object.spec.js:8:1 › two fruit make two items ───────────────────────────────────────
    tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready ──────────────
  60 passed (28.4s)
  1 failed
    tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready ──────────────
  63 passed (22.7s)
  4 failed
    tests/basket-data.spec.js:14:1 › a banana costs R$ 5,90 ────────────────────────────────────────
    tests/conditions.spec.js:40:1 › toPass: the count and the total change together ────────────────
    tests/page-object.spec.js:8:1 › two fruit make two items ───────────────────────────────────────
    tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready ──────────────
  59 passed (31.9s)
```

**As cinco execuções ficaram vermelhas**, com entre uma e quatro falhas cada. Os testes que falham mudam de uma execução para outra, e todos eles passaram na execução
com um worker, acima. Mais uma execução, cortada nos erros, mostra por quê:

```
ana@laptop:~/quitanda$ npx playwright test | grep -E 'using [0-9]+ workers|^  [0-9]+\) |Expected:|Received:'
Running 64 tests using 2 workers
  1) tests/basket-data.spec.js:14:1 › a banana costs R$ 5,90 ───────────────────────────────────────
    Expected: "1"
    Received: "2"
  2) tests/page-object.spec.js:8:1 › two fruit make two items ──────────────────────────────────────
    Expected: "1"
    Received: "2"
  3) tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready ─────────────
    Expected: "1"
    Received: "2"
```

**Dois workers, e a mesma expectativa quebrada três vezes: uma contagem que devia ser 1 e deu
2.** Cada um desses testes põe algo na cesta e depois conta, e com dois workers outro teste está
pondo coisas na mesma cesta no mesmo instante. É a única cesta da loja, compartilhada por todo
mundo, o assunto das aulas 15 e 19. Em cada uma, a causa está fora do teste que
falhou: no outro worker, e numa cesta que nenhum dos dois testes possui.

**É a suíte do próprio curso falhando, e isso não fica escondido.** Nenhuma opção aqui deixa essas
execuções verdes: uma nova tentativa transformaria uma cesta compartilhada num teste dado como
*flaky* e deixaria a causa no lugar, que é o aviso da aula 14. O arranjo honesto para este
projeto, até os testes serem donos dos próprios dados como a aula 15 os faz, é a decisão de
orçamento para a qual os números já apontam: um worker, em uns quarenta segundos, verde, e a taxa
de intermitência medida de novo a cada arquivo acrescentado.

## O que uma suíte informa sobre si mesma

Juntos, os números que uma suíte deveria saber dizer sobre si cabem numa linha, e cada um veio de
um comando desta seção:

| testes | tempo, um worker | falhas declaradas | a parte delas no tempo | execuções vermelhas em cinco, workers padrão |
|---|---|---|---|---|
| 64 | 38,1 s | 7 | 12,4 s | 5 |

Guardados num lugar onde a equipe olha, semana após semana, eles dizem se a suíte está melhorando
ou piorando antes de alguém precisar reclamar.
