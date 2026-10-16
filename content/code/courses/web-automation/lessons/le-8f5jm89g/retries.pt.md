---
title: O que uma nova tentativa compra, e o que esconde
version: 1
---

**Uma nova tentativa roda de novo um teste que falhou, e se uma tentativa seguinte passar, a
execução segue em frente.** É só isso que ela faz. Não deixa o teste certo nem deixa a página certa.
O que ela muda é o veredito que a suíte informa, e é por isso que precisa ser usada com o relatório
à vista.

O Playwright aceita `--retries N` na linha de comando, ou `retries` numa configuração. Um teste que
falha é rodado de novo, até N vezes a mais. Um que falha e depois passa não é contado como aprovado:
o Playwright o põe num terceiro veredito, **flaky** (instável), e imprime essa contagem no resumo.

## No teste em quarentena

O teste da seção de diagnóstico, vinte vezes, com até duas novas tentativas cada:

```
ana@laptop:~/quitanda$ npx playwright test --config quarantine.config.js --repeat-each 20 --retries 2 | grep -E '^  [0-9]+ (failed|flaky|passed)'
  1 failed
  7 flaky
  12 passed (1.1m)
```

Doze tentativas passaram de primeira. **Sete falharam e depois passaram numa nova tentativa, e
são as 7 flaky.** Uma falhou três vezes seguidas e continua sendo uma falha. Uma nova tentativa
baixa a taxa que o leitor vê e não a leva a zero: oito tentativas em vinte deram com o defeito, e
só uma delas é contada como falha.

## No par do portão

O par da cesta compartilhada da seção das causas, com dois workers e duas novas tentativas:

```
ana@laptop:~/quitanda$ npx playwright test tests/ssr.spec.js tests/waiting.spec.js --repeat-each 10 --retries 2 > /tmp/run.log; echo "exit code $?"
exit code 0
ana@laptop:~/quitanda$ grep -E '^  [0-9]+ (failed|flaky|passed)' /tmp/run.log
  5 flaky
  15 passed (53.8s)
```

O código de saída é o número que um job de CI lê: 0 quer dizer portão aberto, qualquer outro quer
dizer portão fechado. **Com novas tentativas, cinco tentativas que falharam na cesta compartilhada
viraram 5 flaky e um código de saída 0.** O defeito da suíte, a cesta compartilhada, continua lá, e o
único rastro dele é uma linha do resumo. Ninguém lê essa linha num build verde.

É isso que uma nova tentativa esconde. Sem relatório, ela transforma *este teste falha uma vez em
quatro* em *este teste passa*, que é o mesmo gesto da pessoa apertando o botão de novo, feito pela
máquina e feito toda vez.

## Tornar a instabilidade visível

Novas tentativas se justificam numa situação: a equipe decidiu manter o portão aberto enquanto
corrige algo, e tem um lugar onde olhar que diz quantas vezes elas foram necessárias. A contagem de
flaky do resumo é esse lugar, e dá para pedir ao Playwright que a trate como falha:

```
ana@laptop:~/quitanda$ npx playwright test tests/ssr.spec.js tests/waiting.spec.js --repeat-each 10 --retries 2 --fail-on-flaky-tests > /tmp/run.log; echo "exit code $?"
exit code 1
ana@laptop:~/quitanda$ grep -E '^  [0-9]+ (failed|flaky|passed)' /tmp/run.log
  5 flaky
  15 passed (53.9s)
```

`--fail-on-flaky-tests` mantém as novas tentativas, de modo que o relatório ainda diz se um teste
passou numa segunda tentativa, e **fecha o portão mesmo assim**. De novo cinco tentativas foram
flaky, e desta vez o código de saída foi 1. Uma suíte com novas tentativas e essa opção não fica instável sem que
alguém veja.

Daí saem três hábitos:

- **Conte os resultados flaky ao longo do tempo**, por teste, como o resumo os conta por execução.
  Um teste instável uma vez por mês e um instável todo dia pedem respostas diferentes, e só uma
  contagem os separa.
- **Nunca aumente as novas tentativas para fazer uma execução passar.** Se duas não bastam, a
  terceira é a mesma moeda jogada de novo.
- **Guarde a tentativa que falhou.** O trace da seção de diagnóstico, gravado na nova tentativa ou
  na falha, é a evidência do que deu errado; uma nova tentativa que passou só não jogou nada fora se
  esse trace foi guardado.

Um teste que continua aparecendo na contagem de flaky precisa sair do portão até ser corrigido. A
próxima seção mostra como.
