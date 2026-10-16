---
title: Selenium em paralelo: o executor e as vagas do grid
version: 1
---

**O Selenium não tem workers próprios.** O `selenium-webdriver` é uma biblioteca: abre uma sessão e
manda comandos, e nunca decide o que roda quando. O paralelismo de uma suíte Selenium vem de dois
lugares configurados separadamente, e a equipe que acerta só um deles ganha menos do que esperava.

O primeiro é o **executor**. A aula 8 rodou o `selenium/shop.test.js` com o executor de testes do
próprio Node, `node --test`, que abre um processo filho por arquivo de teste e roda vários arquivos
ao mesmo tempo. A documentação dele chama de `--test-concurrency` a opção que diz quantos, e dentro
de um arquivo um `describe` ou um `test` com `{ concurrency: n }` deixa vários testes desse arquivo
rodarem juntos. Equipes de Java têm a mesma escolha no JUnit ou no TestNG, equipes de Python no
`-n` do pytest com o plugin `pytest-xdist`. Em todos os casos é o executor que abre vários testes, e
cada teste então pede um navegador.

O segundo é **de onde vêm os navegadores**. Um teste que monta o driver com o `chromedriver` da
mesma máquina abre o navegador ali, então os processadores e a memória do notebook são o limite,
exatamente como com os workers do Playwright. Um teste apontado para um grid com
`SELENIUM_REMOTE_URL`, como na aula 8, pede ao grid, e o grid tem **vagas**. O grid standalone da
aula 8 imprimiu a própria conta ao subir:

```
17:00:47.282 INFO [NodeOptions.getSessionFactories] - Detected 4 available processors
17:00:47.401 INFO [NodeOptions.report] - Adding Chrome for {"browserName": "chrome","platformName": "linux"} 4 times
```

Quatro processadores, quatro vagas de Chrome. A documentação dele aponta `--max-sessions` como a
opção que muda esse número. **Um pedido de quinta sessão não falha: espera na fila de sessões** até
uma vaga se liberar, e é para isso que serve a fila entre as partes do grid, na aula 8. Então um
executor ajustado para oito ao mesmo tempo, contra um grid de quatro vagas, roda quatro testes e
segura outros quatro na fila, e a execução leva mais ou menos o que levaria com quatro.

| | Playwright Test | Selenium |
|---|---|---|
| o que abre vários testes | os workers do executor | o executor que você escolheu: `node --test`, JUnit, TestNG, pytest |
| quantos | `--workers`, por padrão metade dos processadores | a opção do próprio executor |
| onde rodam os navegadores | dentro de cada worker, nesta máquina | nesta máquina, ou nos nós de um grid |
| o que limita os navegadores simultâneos | a máquina | a máquina, ou as vagas do grid |
| dividir entre máquinas | `--shard` | a divisão do próprio CI, ou mais nós atrás de um grid |

A cesta única da loja não liga para a coluna em que você está. Uma suíte Selenium rodando quatro de
cada vez contra uma loja colide exatamente como a do Playwright, e as respostas são as mesmas: o
jeito do executor de manter um grupo de arquivos junto, ou uma loja por teste, que só a aplicação
pode dar.

Nenhum dos comandos de Selenium citados aqui foi rodado para esta aula: o grid da aula 8 já mostrou
as vagas e a fila, e as execuções paralelas acima mostraram o que quatro navegadores ao mesmo tempo
fazem com uma loja.
