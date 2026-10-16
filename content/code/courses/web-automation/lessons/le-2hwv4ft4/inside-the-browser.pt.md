---
title: Dentro do navegador, com um processo ao lado
version: 1
---

**O Cypress roda o seu teste dentro do navegador, na mesma janela da aplicação que ele testa.** O
Selenium, na aula 8, trabalha do outro lado: o teste é um programa fora do navegador que manda
comandos a ele, um de cada vez, por meio de um driver. O Playwright, que este curso usa desde a
aula 1 e que a aula 10 trata a fundo, também fica do lado de fora. Quase tudo o que o Cypress tem de
bom, e quase tudo o que o limita, vem dessa única diferença de posição.

**Nada nesta aula que dependa do próprio Cypress foi executado.** O Cypress vem em duas partes: um
pacote npm e um programa separado, que o pacote baixa do servidor da própria Cypress ao ser
instalado. A máquina de onde vêm estas transcrições não alcança esse servidor. Por isso o pacote
foi instalado e o que ele imprime está capturado, e os arquivos de spec aparecem inteiros e foram
conferidos com as definições de tipos que o pacote traz. Nenhum deles foi executado, e nenhuma
execução, resultado, captura de tela ou tempo do Cypress aparece em parte alguma desta aula. Você
consegue instalar tudo; a próxima seção diz como.

## Dois lugares onde um teste pode ficar

A primeira imagem costuma ser a de que toda ferramenta de navegador faz o mesmo trabalho com outra
sintaxe: `cy.get` aqui, `page.locator` ali. **A sintaxe é a diferença pequena. Onde o código do
teste roda é a grande.**

**Do lado de fora**, o seu teste é um processo Node e o navegador é outro programa. Cada passo vira
uma mensagem. O Selenium a manda por HTTP ao chromedriver, que a repassa ao navegador; o Playwright
a manda direto ao protocolo de depuração do próprio navegador. A resposta volta pelo mesmo caminho.
O teste e a página não compartilham nada além dessas mensagens, então todo valor que o teste lê da
página, um texto ou uma contagem, é uma cópia feita no momento da pergunta.

**Do lado de dentro**, o Cypress inicia um navegador e carrega nele uma página própria, que a
documentação chama de executor (*runner*). O seu spec é empacotado e roda como script nessa página,
e a sua aplicação é carregada num frame ao lado. Junto do navegador, o Cypress mantém um processo
Node, o servidor do Cypress: ele inicia o navegador, lê os seus arquivos do disco e fica entre o
navegador e a rede, como proxy. Toda requisição que a aplicação faz passa por ele a caminho do
servidor a que se destinava, e é disso que a seção 05 desta aula se vale.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Dois arranjos lado a lado. À esquerda, rotulado Selenium e Playwright, o teste é um processo Node fora do navegador, que envia um comando e recebe uma resposta. À direita, rotulado Cypress, o navegador tem dois frames numa janela, o executor com o spec e a aplicação; ao lado do navegador, um servidor do Cypress, processo Node, o inicia, e toda requisição da aplicação passa por esse servidor a caminho da quitanda na porta 3000.\"><text x=\"20\" y=\"30\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">fora: Selenium, Playwright</text><rect x=\"20\" y=\"100\" width=\"125\" height=\"80\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"34\" y=\"130\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">seu teste</text><text x=\"34\" y=\"152\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um processo Node</text><path d=\"M150 125 L215 125\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M215 125 L206.0 120.0 L206.0 130.0 Z\" fill=\"var(--phosphor)\"></path><text x=\"182\" y=\"117\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">comando</text><path d=\"M215 158 L150 158\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M150 158 L159.0 163.0 L159.0 153.0 Z\" fill=\"var(--amber)\"></path><text x=\"182\" y=\"175\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">resposta</text><rect x=\"220\" y=\"100\" width=\"120\" height=\"80\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"234\" y=\"130\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">o navegador</text><text x=\"234\" y=\"152\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a página</text><text x=\"20\" y=\"215\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Uma mensagem para cada lado a cada passo; o que</text><text x=\"20\" y=\"232\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o teste lê da página chega como cópia.</text><path d=\"M355 20 L355 290\" stroke=\"var(--wire)\" stroke-dasharray=\"3 4\"></path><text x=\"372\" y=\"30\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">dentro: Cypress</text><rect x=\"370\" y=\"45\" width=\"330\" height=\"135\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"384\" y=\"66\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">o navegador</text><rect x=\"384\" y=\"78\" width=\"150\" height=\"74\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><text x=\"396\" y=\"102\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o executor</text><text x=\"396\" y=\"122\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">seu spec roda</text><text x=\"396\" y=\"138\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">aqui, como script</text><rect x=\"540\" y=\"78\" width=\"148\" height=\"74\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><text x=\"552\" y=\"102\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">um frame</text><text x=\"552\" y=\"122\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a aplicação</text><text x=\"535\" y=\"171\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">uma janela, um laço de eventos</text><rect x=\"370\" y=\"225\" width=\"190\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"384\" y=\"250\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">servidor do Cypress</text><text x=\"384\" y=\"270\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um processo Node</text><rect x=\"590\" y=\"225\" width=\"110\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"604\" y=\"250\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">quitanda</text><text x=\"604\" y=\"270\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">:3000</text><path d=\"M420 225 L420 185\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M420 185 L415.0 194.0 L425.0 194.0 Z\" fill=\"var(--phosphor)\"></path><text x=\"428\" y=\"207\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">inicia</text><path d=\"M612 185 L545 225\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M545 225 L555.3 224.7 L550.2 216.1 Z\" fill=\"var(--amber)\"></path><path d=\"M562 255 L586 255\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M586 255 L577.0 250.0 L577.0 260.0 Z\" fill=\"var(--amber)\"></path><text x=\"630\" y=\"207\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">requisições</text></svg>", "caption": "O mesmo clique de dois lugares. De fora, é uma mensagem; de dentro, é um script na página, e as requisições da página passam pelo Cypress na saída."}
```

## O que essa posição compra

- **A aplicação fica ao alcance.** Um teste pode pegar o `window` da página com `cy.window()`, ler
  o `localStorage` dela, chamar uma de suas funções ou trocar uma por outra com `cy.stub()`. Pode
  parar o relógio da página com `cy.clock()` e adiantá-lo à mão. Nada é copiado por um socket,
  porque não existe socket.
- **O teste vê a página entre um quadro e outro.** O spec e a aplicação compartilham um laço de
  eventos, então o Cypress verifica o DOM no mesmo navegador que o está mudando, e tenta a
  verificação de novo assim que ela falha. Repetir é o assunto da seção depois da próxima.
- **O executor é uma janela que se lê.** `npx cypress open` mostra os comandos de um teste numa
  lista ao lado da aplicação, e a documentação descreve voltar a qualquer comando para ver a página
  como ela estava naquele momento. Isso pede uma tela, e a máquina onde estas aulas foram gravadas
  não tem tela nem o binário do Cypress, então não há imagem disso aqui.

## O que ela custa

A mesma posição põe o seu teste sob as regras que o navegador aplica a todo script numa página. Um
script não pode ler o conteúdo de um frame vindo de outra origem, e um teste do Cypress é um script
numa página, então a regra vale para ele; o Playwright da aula 10, de fora, não está preso a ela. Um
script numa aba não conduz outra aba. E o navegador precisa ser um que o Cypress saiba iniciar e
onde saiba carregar o executor. A seção 06 trata de cada um desses pontos e mede o primeiro de
verdade.
