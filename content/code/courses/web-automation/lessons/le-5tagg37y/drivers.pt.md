---
title: Drivers, versões e o Selenium Manager
version: 1
---

**Não existe um driver do Selenium.** Existe um driver por navegador, escrito por quem faz aquele
navegador, e a parte do Selenium é falar o padrão com o que você nomear. É no driver que mora o
conhecimento de um navegador em particular, e por isso quem o escreve é o fabricante:

| navegador | driver | escrito por | de onde vem |
|---|---|---|---|
| Chrome | `chromedriver` | Google, no projeto Chromium | os downloads do Chrome for Testing, um por versão do Chrome |
| Firefox | `geckodriver` | Mozilla | as versões dele no GitHub |
| Edge | `msedgedriver` | Microsoft | a página de download da Microsoft, um por versão do Edge |
| Safari | `safaridriver` | Apple | já vem no macOS; `safaridriver --enable` uma vez, como administrador |

O `forBrowser('chrome')` do teste é a única linha que escolhe. Troque por `'firefox'` e o mesmo
teste pede o `geckodriver`, que comanda o Firefox pelo canal próprio da Mozilla. **O Firefox e o
`geckodriver` não estão na máquina de onde vêm estas transcrições**, então nada nesta aula rodou
com eles; o Safari pede um Mac, e o Edge também não estava instalado.

## A versão tem de bater

Um driver é construído contra as entranhas do navegador, e navegadores se atualizam sozinhos. O
`chromedriver` e o `msedgedriver` saem junto com cada versão do navegador, e a regra que os
fabricantes dão é usar o driver cuja **versão principal**, o primeiro número, é a do navegador. O
`geckodriver` aceita uma faixa de versões do Firefox, que a documentação dele lista, e o
`safaridriver` é atualizado com o Safari, então não tem como ficar para trás.

**Esta é a falha que você encontra na manhã seguinte à atualização automática do Chrome.** Aqui o
teste da seção anterior roda com um `chromedriver` antigo, versão 139, achado primeiro no `PATH`,
contra o Chrome 141:

```
ana@laptop:~/quitanda$ node --test --test-reporter=spec selenium/shop.test.js
✖ adding a banana puts one item in the basket (339.211472ms)
ℹ tests 1
ℹ suites 0
ℹ pass 0
ℹ fail 1
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 536.84098

✖ failing tests:

test at selenium/shop.test.js:18:1
✖ adding a banana puts one item in the basket (339.211472ms)
  Error [SessionNotCreatedError]: session not created: This version of ChromeDriver only supports Chrome version 139
  Current browser version is 141.0.7390.37 with binary path /home/ana/bin/google-chrome
      at Object.throwDecodedError (/home/ana/quitanda/node_modules/selenium-webdriver/lib/error.js:523:15)
      at parseHttpResponse (/home/ana/quitanda/node_modules/selenium-webdriver/lib/http.js:527:13)
      at Executor.execute (/home/ana/quitanda/node_modules/selenium-webdriver/lib/http.js:459:28)
      at process.processTicksAndRejections (node:internal/process/task_queues:105:5) {
    remoteStacktrace: '#0 0x55f2353c108a <unknown>\n#1 0x55f234e60a70 <unknown>\n#2 0x55f234ea18f7 <unknown>\n#3 0x55f234ea07e5 <unknown>\n#4 0x55f234e9aad6 <unknown>\n#5 0x55f234e965a7 <unknown>\n#6 0x55f234ee693e <unknown>\n#7 0x55f234ee5f06 <unknown>\n#8 0x55f234ed81b3 <unknown>\n#9 0x55f234ea459b <unknown>\n#10 0x55f234ea5971 <unknown>\n#11 0x55f23538625b <unknown>\n#12 0x55f235389fa9 <unknown>\n#13 0x55f23536d339 <unknown>\n#14 0x55f23538ab58 <unknown>\n#15 0x55f235351c1f <unknown>\n#16 0x55f2353ae118 <unknown>\n#17 0x55f2353ae2f6 <unknown>\n#18 0x55f2353c0066 <unknown>\n#19 0x7f6fb829cb84 <unknown>\n#20 0x7f6fb8329ecc <unknown>\n'
  }
```

Leia as duas primeiras linhas do erro: o driver diz que Chrome ele suporta, qual encontrou e onde.
O conserto é um driver da versão certa, nunca uma mudança no teste. O mesmo comando com o driver
142, uma versão à frente do navegador, falhou do mesmo jeito, dizendo 142. Uma versão atrás foi mais
tolerante: o driver 140 abriu o Chrome 141 e escreveu isto no próprio registro enquanto abria:

```
[1791661619.997][WARNING]: This version of ChromeDriver has not been tested with Chrome version 141.
```

**Não construa nada em cima disso.** *Has not been tested* é o driver avisando que está chutando.

## O Selenium Manager

Até o Selenium 4.6, manter os drivers em dia com os navegadores era trabalho seu, e uma suíte de
testes quebrava numa terça-feira porque um navegador tinha se atualizado. O **Selenium Manager** faz
isso agora: o `build()` o chama antes de qualquer outra coisa, e ele responde com um driver e um
navegador. Você o rodou à mão na seção 02 com `--debug`, e a saída se lê em ordem:

- ele procura primeiro no `PATH`. `Found chromedriver ... in PATH` é a linha que importa na falha
  acima: um driver velho esquecido no `PATH` é usado mesmo quando não serve;
- ele pergunta a versão ao navegador, `--version`, e encontra `chrome 141`;
- ele consulta qual driver serve, no endereço da linha `Discovering versions`, e o baixa para
  `~/.cache/selenium` se ainda não estiver lá. A documentação dele diz que também consegue baixar
  um navegador, quando não há nenhum instalado.

As duas linhas `WARN` daquela transcrição são a máquina onde ele rodou sem internet. A sua busca a
lista e, na primeira vez, o driver. Mais uma linha merece atenção: `Sending stats to Plausible`
quer dizer que o Selenium Manager informa uso anônimo, o navegador e a versão do Selenium, ao
projeto Selenium. `--avoid-stats` desliga isso numa execução, e a documentação dele descreve a
configuração que desliga de vez.

**A resposta a uma versão que não bate costuma ser, portanto, apagar alguma coisa**: o driver velho
no `PATH`, para que o Selenium Manager baixe o certo. A aula 11 encontra ferramentas construídas
sobre os mesmos drivers, e a aula 17 roda o Chrome e o Firefox sem janela.
