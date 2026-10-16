---
title: Rastros e o relatório HTML
version: 1
---

Uma falha no terminal são poucas linhas: a asserção, o valor que ela recebeu, um registro de
chamadas. Isso costuma bastar no seu computador, onde você pode rodar o teste de novo e olhar.
**Num servidor de build ninguém olha**, e a execução que falhou já acabou quando alguém lê a
mensagem. O **rastro** (trace) é a resposta do Playwright: um arquivo gravado durante a execução que
guarda cada ação do teste, como a página estava antes e depois de cada uma, cada requisição e
resposta, e o console. A aula 16 usa rastros para diagnosticar falhas reais; esta seção mostra o
que é um.

## Gravando um

`--trace on` grava um rastro para cada teste da execução:

```
ana@laptop:~/quitanda$ npx playwright test tests/contexts.spec.js --trace on

Running 4 tests using 1 worker

Ana's page reads ana
Bia's page reads null
  ✓  1 tests/contexts.spec.js:8:1 › two contexts share nothing in the browser (534ms)
cookies: Ana [], Bia []
Ana's total after Bia's mango: R$ 10,40
  ✓  2 tests/contexts.spec.js:31:1 › two shoppers, one basket: the shop's flaw (615ms)
  ✓  3 tests/contexts.spec.js:57:1 › the page fixture: storage written in one test (151ms)
  ✓  4 tests/contexts.spec.js:63:1 › the next test in the same browser starts without it (165ms)

  4 passed (3.0s)
```

Nada na saída fala dele. Os rastros ficam em `test-results/`, uma pasta por teste, cada uma com o
nome do arquivo e do teste:

```
ana@laptop:~/quitanda$ ls test-results
contexts-the-next-test-in-the-same-browser-starts-without-it
contexts-the-page-fixture-storage-written-in-one-test
contexts-two-contexts-share-nothing-in-the-browser
contexts-two-shoppers-one-basket-the-shop-s-flaw
```

## O que tem dentro

Um rastro é um arquivo zip, e qualquer ferramenta que lista um zip mostra o conteúdo. O dos dois
clientes:

```
ana@laptop:~/quitanda$ unzip -l test-results/contexts-two-shoppers-*/trace.zip
Archive:  test-results/contexts-two-shoppers-one-basket-the-shop-s-flaw/trace.zip
  Length      Date    Time    Name
---------  ---------- -----   ----
     2524  2026-10-15 21:50   resources/src@6ce6e52f7b3ff0cadddbf49cff84b497dd93146a.txt
    10478  2026-10-15 21:50   test.trace
     1950  2026-10-15 21:50   2-trace.trace
     1153  2026-10-15 21:50   2-trace.network
       14  2026-10-15 21:50   resources/e7e8acd9614309b836bf29744b10316e7e9ae74c.json
      455  2026-10-15 21:50   2-trace.stacks
    12334  2026-10-15 21:50   1-trace.trace
    11743  2026-10-15 21:50   1-trace.network
     2459  2026-10-15 21:50   resources/page@5c43eac8d15b790ac05241bed803b305-1792111821187.jpeg
     9481  2026-10-15 21:50   resources/page@5c43eac8d15b790ac05241bed803b305-1792111821419.jpeg
    33113  2026-10-15 21:50   resources/page@5c43eac8d15b790ac05241bed803b305-1792111821439.jpeg
    33130  2026-10-15 21:50   resources/page@5c43eac8d15b790ac05241bed803b305-1792111821448.jpeg
    33655  2026-10-15 21:50   resources/page@5c43eac8d15b790ac05241bed803b305-1792111821565.jpeg
      777  2026-10-15 21:50   resources/1ce73c06221cd554cd0d9b5e41880a93864b7397.html
     1240  2026-10-15 21:50   resources/39dfe74803f515f71990df1b2934669d13b07de7.css
      479  2026-10-15 21:50   resources/1c9a406b53395251437640846f6d28fb68008123.json
       47  2026-10-15 21:50   resources/6e6f9bda0f8670a0c478f30e68530a696865f42f.json
       14  2026-10-15 21:50   resources/a7f393e2fef8da8622e971e616554e89ac8ecb76.json
       71  2026-10-15 21:50   resources/ee0f2e8073ce999113f321888e8e5cdc95ea7ae2.json
      376  2026-10-15 21:50   1-trace.stacks
    21213  2026-10-15 21:50   0-trace.trace
    21134  2026-10-15 21:50   0-trace.network
     2459  2026-10-15 21:50   resources/page@96dd63ff4c62a7233623aa8b8f6a15c7-1792111821155.jpeg
     9481  2026-10-15 21:50   resources/page@96dd63ff4c62a7233623aa8b8f6a15c7-1792111821230.jpeg
    33113  2026-10-15 21:50   resources/page@96dd63ff4c62a7233623aa8b8f6a15c7-1792111821261.jpeg
    33113  2026-10-15 21:50   resources/page@96dd63ff4c62a7233623aa8b8f6a15c7-1792111821271.jpeg
    33509  2026-10-15 21:50   resources/page@96dd63ff4c62a7233623aa8b8f6a15c7-1792111821362.jpeg
    33190  2026-10-15 21:50   resources/page@96dd63ff4c62a7233623aa8b8f6a15c7-1792111821589.jpeg
       22  2026-10-15 21:50   resources/e08a78924b70868ee32e65ed1f50e8617a496356.json
       15  2026-10-15 21:50   resources/ecd48961d64df9c15fe3c56d69856ba51244c7f6.json
      377  2026-10-15 21:50   0-trace.stacks
---------                     -------
   343119                     31 files
```

Trinta e um arquivos nesta execução, de quatro tipos:

- **`test.trace`** é o teste como o executor o viu: cada passo, os hooks, e onde no código-fonte
  cada um foi chamado. O código-fonte do próprio teste está em `resources/src@….txt`, para que o
  viewer mostre a linha que rodou;
- **um arquivo `trace` e um `network` numerados para cada contexto**, com as ações e as
  requisições que aquele contexto fez;
- **capturas de tela `.jpeg`**, com o nome da página de onde vieram e tiradas conforme o teste
  agia, e é assim que o viewer mostra a página a cada passo;
- **recursos `.html`, `.css` e `.json`**: os corpos das respostas, para que o viewer reconstrua a
  página como ela estava, e não como a loja a serve hoje.

Há três contextos numerados num teste que criou dois. Os arquivos de rede dizem quem é quem:

```
ana@laptop:~/quitanda$ unzip -p test-results/contexts-two-shoppers-*/trace.zip 0-trace.network | grep -o '"url":"[^"]*"' | sort | uniq -c
      2 "url":"http://localhost:3000/"
      3 "url":"http://localhost:3000/api/basket"
      2 "url":"http://localhost:3000/api/products"
      2 "url":"http://localhost:3000/app.js"
      2 "url":"http://localhost:3000/style.css"
ana@laptop:~/quitanda$ unzip -p test-results/contexts-two-shoppers-*/trace.zip 1-trace.network | grep -o '"url":"[^"]*"' | sort | uniq -c
      1 "url":"http://localhost:3000/"
      2 "url":"http://localhost:3000/api/basket"
      1 "url":"http://localhost:3000/api/products"
      1 "url":"http://localhost:3000/app.js"
      1 "url":"http://localhost:3000/style.css"
ana@laptop:~/quitanda$ unzip -p test-results/contexts-two-shoppers-*/trace.zip 2-trace.network | grep -o '"url":"[^"]*"' | sort | uniq -c
      1 "url":"http://localhost:3000/api/reset"
```

`0-` é a Ana: a página duas vezes, porque ela recarregou, e a cesta três vezes, uma em cada carga
e uma pela banana. `2-` tem uma requisição só, o reset do `beforeEach`, porque a fixture `request`
é um contexto de requisições próprio, sem página nenhuma. `1-` é a Bia: uma carga e a manga dela.

**Um rastro é um registro da execução**, e diz o que aconteceu sem ninguém rodar o teste de novo.
Ele também guarda o que as páginas mostraram e o que as requisições carregaram, o que, numa
aplicação com contas reais, significa dados que você não colaria numa issue pública.

## Abrindo um

O rastro foi feito para ser lido no **trace viewer** do Playwright:

```sh
npx playwright show-trace test-results/contexts-two-shoppers-one-basket-the-shop-s-flaw/trace.zip
```

Ele abre uma janela com a linha do tempo do teste no alto, a lista de ações na lateral e, para a
ação que você escolher, a página como estava naquele momento, com os painéis de rede e de console
da aula 1 ao lado. **O viewer não foi executado para este curso**: ele precisa de uma tela, e a
máquina em que estas aulas foram gravadas não tem. A documentação do Playwright também indica o
`trace.playwright.dev`, uma página que abre, dentro do seu próprio navegador, um arquivo de rastro
que você solta nela.

Gravar todos os testes custa espaço em disco e algum tempo, então é raro uma equipe deixar
`--trace on` numa configuração. A documentação do Playwright sugere `trace: 'on-first-retry'` dentro
de `use`, que grava só quando um teste que falhou é repetido, e `'retain-on-failure'` guarda o
rastro só dos testes que falharam. A aula 16 escolhe entre eles.

## O relatório HTML

O reporter `list` que este curso usa imprime uma linha por teste. O **reporter HTML** escreve um
site inteiro: cada teste, os passos, os erros e um link para o rastro quando há um. Reporters podem
ser combinados, então `--reporter=list,html` mantém as linhas no terminal e também escreve o site:

```
ana@laptop:~/quitanda$ npx playwright test tests/smoke.spec.js --reporter=list,html

Running 1 test using 1 worker

  ✓  1 tests/smoke.spec.js:3:1 › the shop opens and lists its fruit (158ms)

  1 passed (1.5s)

To open last HTML report run:

  npx playwright show-report
```

```
ana@laptop:~/quitanda$ ls playwright-report
index.html
```

O `playwright-report/index.html` é o relatório, e é uma página única que pode ser publicada como
artefato do build. `npx playwright show-report`, o comando que a execução sugere, serve essa pasta e
a abre numa janela de navegador; **ele também não foi executado aqui**, pelo mesmo motivo do viewer.
A documentação diz que, numa execução com falhas, o reporter HTML abre o relatório sozinho, a não ser
que a opção `open` dele esteja como `'never'` numa configuração.

## Codegen e o inspetor

Mais duas ferramentas vêm com o Playwright, e as duas precisam de uma tela.
`npx playwright codegen localhost:3000` abre a loja numa janela e escreve código de teste conforme
você clica; a aula 20 trata de gravadores como ele, e de por que o código escrito à mão vence.
`npx playwright test --debug` roda um teste passo a passo no **inspetor**, com o navegador na tela e
um botão para avançar cada ação. Nenhuma das duas foi executada para este curso.
