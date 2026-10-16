---
title: Quarentena, fora do portão e ainda rodando
version: 1
---

**Uma quarentena tira do portão um teste que se sabe instável, sem apagá-lo e sem calá-lo.** O
portão volta a querer dizer alguma coisa: vermelho é uma mudança que quebrou algo. O teste continua
rodando em outro lugar, onde as suas falhas são contadas em vez de obedecidas, e leva um nome, uma
data e um motivo que dizem quem o traz de volta e quando.

As três coisas que as pessoas fazem no lugar disso perdem, cada uma, alguma coisa. Apagar o teste
perde o defeito que ele estava achando. Pulá-lo faz com que ele pare de olhar, e nada diz quando
voltar a olhar. Repeti-lo, como a seção anterior mostrou, o mantém no portão e o esconde lá.

## Onde a quarentena fica

Há dois jeitos comuns de manter um teste fora do portão. O primeiro é uma **tag**: o teste fica no
seu arquivo, recebe o rótulo `@quarantine`, e o portão roda `npx playwright test --grep-invert
@quarantine`, enquanto um segundo job roda `npx playwright test --grep @quarantine`. O segundo é um
**lugar**: o teste vai para uma pasta que o portão nunca lê, com a sua própria configuração.

Este projeto usa o lugar, e o motivo é o próprio portão. Aqui o portão é o comando simples,
`npx playwright test`, e `npm test` é o mesmo comando. Uma tag só mantém o teste fora das execuções
que se lembram do `--grep-invert`. Todo job de CI novo, todo script e toda pessoa digitando o
comando têm de se lembrar dela, e o primeiro que esquecer põe o teste instável de volta no portão.
Uma pasta que a configuração do portão não lê não tem como ser esquecida. A tag também fica, no
próprio teste, porque marca o teste como em quarentena em todo relatório e deixa o `--grep
@quarantine` achá-lo onde quer que ele vá parar. Uma suíte grande, em que mudar um arquivo de lugar
o tiraria do meio dos vizinhos, pode escolher a tag com razão; aí ela precisa guardar a opção num
lugar compartilhado, e não em cada comando.

**Um teste em quarentena diz quem é o dono, até quando, e por quê.** O Playwright deixa um teste
declarar uma `annotation`, com um tipo e uma descrição, que o seu relatório HTML mostra ao lado do
teste, segundo a documentação. O comentário diz o resto: qual é o defeito e o que precisa ser
verdade para o teste voltar. Isto substitui o teste da seção de diagnóstico. Salve-o como
`quarantine/typing.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// QUARANTINED: lesson 3's search defect, at a speed where it shows only some
// of the time. The test is right and the page is wrong. It goes back into
// tests/ when search.js drops answers to questions the box no longer asks.
test('typed at 145 ms a key, the list settles on papaya', {
  tag: '@quarantine',
  annotation: {
    type: 'quarantine',
    description: 'owner: ana; review by 2026-11-10; reported as the search defect',
  },
}, async ({ page }) => {
  await page.goto('/search.html');
  await page.getByLabel('Fruit').pressSequentially('papaya', { delay: 145 });
  await expect(page.locator('#results')).toHaveAttribute('aria-busy', 'false');
  await expect(page.locator('#results li')).toHaveText(['Papaya']);
});
```

## O portão e o job da quarentena

O portão, como fica no fim desta aula:

```
ana@laptop:~/quitanda$ npx playwright test | grep -E '^  [0-9]+ (failed|flaky|passed)'
  1 failed
  50 passed (21.3s)
```

O job da quarentena, rodado como uma quarentena deve ser rodada, muitas vezes, para o resultado ser
uma taxa:

```
ana@laptop:~/quitanda$ npx playwright test --config quarantine.config.js --repeat-each 20 | grep -E '^  [0-9]+ (failed|flaky|passed)'
  8 failed
  12 passed (42.5s)
```

No CI os dois são jobs separados. O resultado do portão decide se uma mudança entra; o da quarentena
não decide nada e é lido pela contagem. A aula 5 de `testing-cicd` trata de montar esses jobs. O portão acima está vermelho, como esteve nas dez execuções da primeira seção: o teste do ssr
encontra uma cesta em que outro teste acabou de pôr algo. Pô-lo em quarentena seria a resposta
errada, porque o defeito está em como os testes dividem os dados, e não no teste nem na página, e a
aula 15 o corrige ali.

## skip, fixme e fail

O Playwright tem três anotações que parecem poder fazer o papel de uma quarentena, e cada uma diz
uma coisa diferente.

| | roda o teste? | o que diz |
|---|---|---|
| `test.skip()` | não | este teste não se aplica aqui, por exemplo num navegador em que não pode rodar |
| `test.fixme()` | não | este teste está quebrado, e alguém precisa corrigi-lo |
| `test.fail()` | sim | espera-se que este teste falhe; se passar, é informado como erro |

**`test.skip` e `test.fixme` impedem o teste de rodar**, então um teste pulado não tem como dizer se
o defeito continua lá. O `test.fixme` ao menos diz o motivo no nome, e nenhum dos dois tem data.

O `test.fail()` foi o que as aulas 3, 5 e 7 escolheram para um defeito conhecido que falha **toda
vez**, e para isso é a ferramenta certa: no dia em que o defeito é corrigido, o teste passa e o
relatório fica vermelho até alguém apagar a anotação. A fraqueza dele, vista na aula 3, é que
qualquer falha o satisfaz, então uma página que nem carregasse mais ainda contaria como a falha
esperada.

Para um teste instável ele é pior que fraco. Aqui está o teste em quarentena com `test.fail();`
acrescentado como primeira linha do corpo, vinte vezes:

```
ana@laptop:~/quitanda$ npx playwright test --config quarantine.config.js --repeat-each 20 | grep -E 'Expected to fail|^  [0-9]+ (failed|flaky|passed)' | sort | uniq -c
     13     Expected to fail, but passed.
      1   13 failed
      1   7 passed (38.6s)
```

**O defeito da busca apareceu em sete tentativas, e essas sete passaram. Nas outras treze ele não
apareceu, e cada uma foi informada como falha**: *Expected to fail, but passed.* Uma anotação que
diz *isto sempre falha* não consegue descrever um teste que falha às vezes; embrulhado nela, o
teste continua vermelho, agora nas execuções em que a página se comportou. É essa a lacuna que uma quarentena preenche.

## Uma quarentena precisa de uma saída

A plataforma em que você estuda põe em quarentena as suas próprias questões de prova,
automaticamente, quando as estatísticas dizem que o gabarito provavelmente está errado ou o
enunciado é ambíguo. Três das suas regras passam para testes quase palavra por palavra. Ela é
decidida **por um limite**, e não pelo humor de alguém no dia, o que para um teste quer dizer uma
contagem de flaky ao longo de várias execuções. Ela é **presa à versão**, então corrigir a questão é
a saída normal e ninguém precisa lembrar de liberar nada. E liberar uma questão à mão é uma exceção
que **precisa de um motivo**.

Para um teste, a saída é a correção e a volta para `tests/`, e a data na anotação é quando alguém
olha de novo se nenhuma das duas aconteceu. Uma quarentena sem dono e sem data é uma exclusão feita
devagar: o teste roda, ninguém o lê, e o defeito que ele achou fica.
