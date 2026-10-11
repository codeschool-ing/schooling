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
%%CAP trace-run%%
```

Nada na saída fala dele. Os rastros ficam em `test-results/`, uma pasta por teste, cada uma com o
nome do arquivo e do teste:

```
%%CAP trace-ls%%
```

## O que tem dentro

Um rastro é um arquivo zip, e qualquer ferramenta que lista um zip mostra o conteúdo. O dos dois
clientes:

```
%%CAP trace-unzip%%
```

Trinta e três arquivos, de quatro tipos:

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
%%CAP trace-network%%
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
%%CAP report-run%%
```

```
%%CAP report-ls%%
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
