---
title: Falhando, e o número que um pipeline lê
version: 1
---

**O código de saída do Newman é toda a interface entre uma execução e quem a iniciou.** Um programa
que termina com 0 deu certo, e qualquer outro número quer dizer que falhou, por uma convenção que todo
shell e todo pipeline obedecem. O Newman sai com 1 quando alguma asserção falha ou alguma requisição
não pôde ser mandada, e com 0 nos outros casos. A tabela bonita é para você; o número é para a
máquina.

## Vendo o número

`> /dev/null` joga fora o que a execução imprime, e `$?` é o código de saída do comando anterior:

```
ana@laptop:~/boxoffice$ npm run test:api > /dev/null; echo "exit code $?"
exit code 1
ana@laptop:~/boxoffice$ npm run test:api -- --folder orders > /dev/null; echo "exit code $?"
exit code 0
```

A coleção inteira sai com 1, porque **HEAD one show** falha. A pasta `orders` sozinha sai com 0,
porque todo teste dela passa. A segunda linha merece um momento: é assim que uma pasta de testes que
sabidamente passam pode barrar algo enquanto outra pasta carrega um defeito conhecido. Este curso
mantém uma execução só e a deixa falhar, porque esconder um defeito real do pipeline é exatamente o
que um pipeline existe para impedir.

**Uma execução sem testes sai com 0.** A coleção da lição 4 não tinha scripts, então todas as suas
requisições poderiam ter respondido `401` e a execução ainda teria contado zero falhas: nada
afirmava nada. Um pipeline verde diz só que os testes que existem passaram, e uma coleção sem testes
não tem nenhum.

## Parando na primeira falha

`--bail` encerra a execução na primeira falha em vez de terminá-la. A saída dele no terminal traz um
caractere que as transcrições do curso não conseguem mostrar, então esta execução grava o relatório
JSON da seção 05 no lugar, e o jq lista as requisições que de fato foram mandadas:

```
ana@laptop:~/boxoffice$ npm run test:api -- --bail --reporters json --reporter-json-export results/bail.json > /dev/null; echo "exit code $?"
exit code 1
ana@laptop:~/boxoffice$ jq -r '.run.executions[].item.name' results/bail.json
List shows
List shows
One show
HEAD one show
```

A execução parou depois de **HEAD one show**, a terceira requisição, e nunca chegou ao token nem aos
pedidos. `List shows` aparece duas vezes porque o script de pré-requisição da coleção mandou a
requisição de token de dentro dela. Parar cedo é útil quando a primeira falha torna o resto sem
sentido, como na seção 02 da lição 5, onde um token ausente transformou uma falha em dez. É errado
como hábito: uma execução que para cedo esconde toda falha depois da primeira, e a segunda pode ser a
que importa. **Deixe `--bail` fora do pipeline.**

## Lendo uma falha

Uma falha se lê do jeito que a lição 1 leu uma resposta: o que foi pedido, o que se esperava, o que
voltou. Para a que esta coleção sempre tem:

| parte | diz |
|---|---|
| `AssertionError` | uma asserção falhou, e não um script que quebrou |
| `HEAD answers like GET` | a afirmação, o nome do teste |
| `expected response to have status code 200 but got 405` | a evidência |
| `inside "shows / HEAD one show"` | onde: pasta, depois requisição |

Um `TypeError` ou um `JSONError` nessa primeira coluna quer dizer que o script quebrou antes de
conseguir julgar qualquer coisa, em geral porque a resposta não tinha a forma esperada. Esses merecem
ser lidos duas vezes: o teste não disse que a API estava errada, disse que o teste não conseguiu
saber.
