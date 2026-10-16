---
title: O que o curso cobriu, e o que vem depois
version: 1
---

O curso começou pelas ferramentas de desenvolvedor do navegador e por uma loja com defeitos, e
termina com um projeto de algumas dezenas de testes que você escreveu, executou e, em alguns
pontos, decidiu não manter. **O curso nunca foi sobre uma ferramenta.** Selenium, Cypress e
Playwright tiveram cada um a sua aula, e cada um terá mudado quando você ler isto; o que
continua valendo é saber o que o navegador está fazendo enquanto o teste espera, e se uma
verificação vale o que custa.

## O curso, aula por aula

| | aula | o que ficou com você |
|---|---|---|
| 1 | Ferramentas de desenvolvedor do navegador | a loja, o laboratório e uma página lida em três painéis |
| 2 | DOM, seletores CSS e XPath | um localizador que sobrevive a um recarregamento, e por que um id copiado não sobreviveu |
| 3 | Ajax e carregamento assíncrono | esperar pela coisa certa, e uma corrida relatada como defeito |
| 4 | O cache do navegador | uma oferta velha, e um contexto novo para cada visitante |
| 5 | Página única, PWA e JAMStack | um link direto que dá 404, e um service worker que serve a casca antiga |
| 6 | Renderização no cliente e no servidor | um clique que chega antes do script, e a camada certa para testá-lo |
| 7 | Layout responsivo e adaptativo | a verificação de rolagem lateral, e o que um descritor não consegue fingir |
| 8 | Selenium WebDriver | o protocolo por baixo de todo driver, e uma grade |
| 9 | Cypress | um teste rodando dentro da página, e onde isso para |
| 10 | Playwright | navegadores, contextos e um rastro |
| 11 | As outras ferramentas | Puppeteer, WebdriverIO, Nightwatch, Jest, Jasmine, Robot e QA Wolf, cada um no seu lugar |
| 12 | O padrão Page Object | um lugar para cada localizador, e quando a abstração passa do ponto |
| 13 | Esperas explícitas e implícitas | uma condição sua, escrita para ser esperada |
| 14 | Testes intermitentes | uma causa encontrada em vez de escondida por novas tentativas, e uma quarentena |
| 15 | Dados de teste | um teste dono dos próprios dados, que limpa o que fez |
| 16 | Captura de tela, vídeo e rastro | a evidência que um teste que falha deixa para trás |
| 17 | Execução headless | o navegador sem janela, e o que muda sem ela |
| 18 | Zombie.js e HtmlUnit | navegadores que não são navegadores, e o que eles não veem |
| 19 | Execução em paralelo | uma suíte dividida entre workers, e o que eles compartilham |
| 20 | Gravadores | um teste gravado ao lado de um escrito |
| 21 | A pirâmide de testes | a camada a que cada verificação pertence |
| 22 | O que não automatizar | o custo de um teste, posto contra o valor dele |

## O que vem depois

**`api-mobile-automation` é o próximo curso da trilha qa.** Ele desce uma camada, até a API:
métodos HTTP, códigos de status e cabeçalhos para quem testa, o contrato que uma API REST promete
e a autenticação, antes de passar ao mobile. Muito do que este curso verificou pela página, como
o total da cesta ou a recusa de um nome já usado, sai mais barato lá, como a aula 21 defendeu.
Tudo o que você aprendeu sobre isolamento e limpeza na aula 15 vale sem mudança.

**`non-functional-testing` se apoia neste.** Ele pressupõe a base de automação que você tem
agora, e a usa para o que este curso apontou várias vezes e deixou de lado: quão rápida é a
página (`non-functional-testing` aula 10, desempenho de front-end) e se todo mundo consegue
usá-la (aulas 12 a 15, acessibilidade). A verificação de contraste que teria pego os preços
brancos do experimento desta aula é o assunto daquele curso.

E `testing-cicd` é onde a suíte que você montou deixa de rodar no seu computador. A aula 1 de lá
é de novo sobre as camadas, do ponto de vista do pipeline, e a aula 5 é integração contínua, onde
o tempo de execução e a taxa de intermitência da seção anterior viram o orçamento de alguém todo
dia.

## O projeto que fica com você

`~/quitanda` é seu. É pequeno o bastante para ler numa tarde e cada defeito nele está marcado, o
que o torna um bom lugar para experimentar uma ferramenta antes de confiar nela no trabalho: uma
versão nova do Playwright, um repórter, um jeito de dividir a suíte. Corrija um defeito e veja
quais testes percebem. Se a resposta surpreender você, você aprendeu algo sobre esses testes que
nenhuma aula contou.
