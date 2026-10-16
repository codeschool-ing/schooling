---
title: Apagar um teste, e os defeitos que a suíte documenta
version: 1
---

**Um teste que não falha há um ano não é, só por isso, inútil.** Ele pode guardar algo que nunca
quebrou justamente por estar guardado, ou algo que custaria muito na única vez em que quebrasse. O
que torna um teste inútil é que **ele não consegue falhar**. A aula 7 mostrou o formato:
`toBeHidden()` sozinho passa num botão que foi renomeado ou apagado, porque um localizador que não
acha nada conta como escondido. Então a pergunta a fazer a um teste quieto não é há quanto tempo
ele está verde. É se ele ficaria vermelho caso o que guarda quebrasse, e o jeito de descobrir é
quebrar isso de propósito e rodá-lo, como o experimento de duas seções atrás fez com quatro
edições.

## Os testes que vale apagar

- **Um teste que não consegue falhar**, descoberto desse jeito. Corrija-o para que consiga, ou
  apague-o.
- **Um teste que verifica o que outro já verifica**, na mesma camada ou numa mais barata. A segunda
  cópia dobra a manutenção e não pega nada que a primeira não pegue. A aula 21 trata de descer uma
  verificação de camada; depois que ela desceu, a cópia do navegador pode sair.
- **Um teste intermitente que ninguém vai corrigir.** A aula 14 trata do que ele faz: uma suíte
  vermelha sem motivo ensina todo mundo a rodá-la de novo, e a execução vermelha por um motivo real
  também é rodada de novo. Um teste assim é pior que nenhum, porque nenhum teste ao menos deixa o
  vermelho querendo dizer vermelho. A quarentena da aula 14 leva um responsável e uma data
  exatamente por isso, e um teste ainda lá depois da data entra nesta lista.
- **Um teste de uma funcionalidade que já não existe.** Ele passa, ou falha, sobre nada.

**Apague com um motivo, e escreva o motivo onde a próxima pessoa vai olhar**: no commit que o
remove, diga o que o teste verificava, por que sai, e o que cobre esse risco agora, mesmo quando a
resposta for *nada, de propósito*. O histórico do repositório guarda o código; só você guarda o
motivo, e uma remoção com motivo é uma decisão que alguém pode contestar depois.

## Os defeitos que esta suíte documenta

As aulas 3, 4, 5, 7 e 13 usaram `test.fail()` para manter no projeto um teste de um defeito
conhecido. Aqui está o projeto no fim do curso, e cada lugar onde ele faz isso:

```
ana@laptop:~/quitanda$ ls tests
banana.spec.js
basket-api.spec.js
basket-data.spec.js
basket-ui.spec.js
cache.spec.js
conditions.spec.js
contexts.spec.js
deals.spec.js
fixtures.js
headless.spec.js
locators.spec.js
names.spec.js
no-script.spec.js
offline.spec.js
page-object-card.spec.js
page-object.spec.js
responsive.spec.js
search.spec.js
setup-cost.spec.js
signup.spec.js
sleeps.spec.js
smoke.spec.js
spa.spec.js
ssr-html.spec.js
ssr.spec.js
targets.spec.js
toast.spec.js
two-fruit.spec.js
waiting.spec.js
ana@laptop:~/quitanda$ ls tests/*.spec.js | wc -l
28
```

```
ana@laptop:~/quitanda$ grep -rn "test.fail(" tests | wc -l
6
ana@laptop:~/quitanda$ grep -rn "test.fail(" tests
tests/search.spec.js:16:  test.fail();
tests/spa.spec.js:31:  test.fail(true, 'known defect: the server has no fallback for /spa/basket');
tests/conditions.spec.js:23:  test.fail();
tests/cache.spec.js:14:  test.fail(true, 'known flaw: GET /api/offer may be kept for ten minutes');
tests/cache.spec.js:23:  test.fail(true, 'known flaw: GET /api/offer may be kept for ten minutes');
tests/responsive.spec.js:46:    test.fail(overflows.includes(width), 'known defect: .basket is wider than a phone');
```

28 arquivos e 6 linhas. A execução da suíte na próxima seção conta **7
testes declarados para falhar**, porque a linha da aula 7 está dentro de um laço e cobre duas
larguras. Cada um deles é uma promessa de fazer algo no dia em que a loja for corrigida, e a
promessa é diferente para cada um:

| linha | o defeito | no dia da correção |
|---|---|---|
| `search.spec.js:16` (aula 3) | a resposta a *p* chega por último e substitui a lista | o Playwright informa *Expected to fail, but passed*; apague a linha |
| `conditions.spec.js:23` (aula 13) | o mesmo defeito, esperado com `waitForFunction` | o mesmo dia, o mesmo vermelho; depois **fique com um dos dois** |
| `spa.spec.js:31` (aula 5) | `/spa/basket` não tem rota de reserva no servidor | apague a marcação; o teste passa a guardar a rota de reserva |
| `cache.spec.js:14` e `:23` (aula 4) | a oferta é enviada com `max-age=600` | se a correção for `no-cache`, os dois passam no mesmo dia e as duas marcações saem |
| `responsive.spec.js:46` (aula 7) | `.basket` é mais larga que um celular | tire 360 e 390 de `overflows`; o experimento desta aula viu esse dia |

**A segunda linha é a que pede julgamento.** A aula 13 escreveu o seu teste para mostrar uma
condição sua, e faz isso bem; como verificação de regressão, ele vigia o mesmo defeito que o da
aula 3, pela mesma página, no mesmo navegador. No dia em que a busca for corrigida, os dois ficam
vermelhos juntos, as duas marcações saem, e a suíte fica com dois testes para um comportamento.
Fique com aquele cuja mensagem de falha diria mais a um desenvolvedor, e apague o outro com esse
motivo no commit.

**E a quarta linha esconde um teste que não está marcado.** O `cache.spec.js` também tem *routing
hides the flaw*, que passa porque o roteamento desliga o cache do navegador. Ele documenta uma
armadilha da ferramenta, não um defeito da loja, então não muda quando a loja for corrigida. Fica
enquanto alguém puder acrescentar `page.route` a um teste de cache e acreditar no resultado.

## Uma marcação que continua passando pelo motivo errado

O `test.fail()` tem a fraqueza que as aulas 3 e 7 nomearam: aceita qualquer falha. Um teste
declarado para falhar no defeito da busca, que um dia falha porque a página nem carrega mais,
continua sendo dado como aprovado, e o defeito que ele vigiava poderia ser corrigido sem ninguém
ficar sabendo. Por isso o script da próxima seção imprime, para cada falha declarada, a primeira
linha do erro que ela teve de fato. Uma lista de sete é curta o bastante para ler uma vez por mês,
e **cada linha ainda deve nomear o defeito que o comentário dela nomeia**.
