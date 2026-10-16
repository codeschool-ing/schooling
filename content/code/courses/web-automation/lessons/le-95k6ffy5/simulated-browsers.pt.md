---
title: Um navegador sem tela
version: 1
---

Todo teste deste curso até aqui rodou no Chromium sem janela. Isso faz "headless" soar como o nome
de um tipo mais barato de navegador, e **não é**. O Chromium headless é o navegador inteiro: ele
calcula o layout da página, pinta tudo na memória, e as capturas de tela da aula 16 são retratos
dessa memória. Um **navegador simulado** é outra coisa. É uma biblioteca, escrita do zero, que faz
a primeira metade do trabalho de um navegador e nada da segunda.

## O que um navegador faz com uma página

Quando o Chromium abre a loja, o trabalho vem numa ordem fixa. Ele busca os bytes, analisa o HTML
e monta a árvore de elementos que a aula 2 percorreu, e roda o `app.js` sobre essa árvore. Casa as
regras do `style.css` com cada elemento e depois calcula onde cada caixa fica e qual o tamanho
dela: esse passo é o **layout**. Aí pinta os pixels e compõe as camadas na tela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 212\" role=\"img\" aria-label=\"Sete etapas da esquerda para a direita: buscar os bytes, analisar o HTML num DOM, rodar scripts sobre ele, casar regras de CSS, layout, pintar, compor na tela. Um navegador simulado guarda as quatro primeiras; só um navegador de verdade faz layout, pintura e composição. Um script que pergunta o scrollWidth precisa de layout: o Chromium com 360 pixels de largura responde 400 para a loja, e o jsdom responde 0 para a mesma página.\"><rect x=\"16\" y=\"70\" width=\"92\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"62.0\" y=\"91\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">buscar</text><text x=\"62.0\" y=\"107\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">os bytes</text><rect x=\"122\" y=\"70\" width=\"92\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"168.0\" y=\"91\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">analisar HTML</text><text x=\"168.0\" y=\"107\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">num DOM</text><path d=\"M109 95.0 L119 95.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M115 91.0 L120 95.0 L115 99.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><rect x=\"228\" y=\"70\" width=\"92\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"274.0\" y=\"91\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">rodar scripts</text><text x=\"274.0\" y=\"107\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sobre ele</text><path d=\"M215 95.0 L225 95.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M221 91.0 L226 95.0 L221 99.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><rect x=\"334\" y=\"70\" width=\"92\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"380.0\" y=\"91\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">casar regras</text><text x=\"380.0\" y=\"107\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">de CSS</text><path d=\"M321 95.0 L331 95.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M327 91.0 L332 95.0 L327 99.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><rect x=\"440\" y=\"70\" width=\"92\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-dasharray=\"5 4\"></rect><text x=\"486.0\" y=\"91\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">layout</text><text x=\"486.0\" y=\"107\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tamanhos, lugares</text><path d=\"M427 95.0 L437 95.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M433 91.0 L438 95.0 L433 99.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><rect x=\"546\" y=\"70\" width=\"92\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-dasharray=\"5 4\"></rect><text x=\"592.0\" y=\"91\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pintar</text><text x=\"592.0\" y=\"107\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pixels</text><path d=\"M533 95.0 L543 95.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M539 91.0 L544 95.0 L539 99.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><rect x=\"652\" y=\"70\" width=\"92\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-dasharray=\"5 4\"></rect><text x=\"698.0\" y=\"91\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">compor</text><text x=\"698.0\" y=\"107\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">na tela</text><path d=\"M639 95.0 L649 95.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M645 91.0 L650 95.0 L645 99.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M16 52 L16 44 L426 44 L426 52\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><text x=\"221.0\" y=\"34\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">o navegador simulado guarda</text><path d=\"M440 52 L440 44 L744 44 L744 52\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"592.0\" y=\"34\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">só o navegador de verdade</text><path d=\"M274.0 120 L274.0 154 L486.0 154 L486.0 124\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M482.0 129 L486.0 123 L490.0 129\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><text x=\"380.0\" y=\"148\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">scrollWidth?</text><text x=\"486.0\" y=\"176\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Chromium, 360 px de largura: 400</text><text x=\"486.0\" y=\"194\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">jsdom, a mesma página: 0</text></svg>", "caption": "O que um navegador faz com uma página, e onde um simulado para. O casamento das regras de CSS é parcial: o jsdom sabia que a cesta tem min-width de 384px, e não sabia dizer que largura isso dava a coisa nenhuma.", "same": ["layout", "pixels"]}
```

**Um navegador simulado guarda os quatro primeiros passos e larga os três últimos.** Tem um
analisador de HTML, um DOM, um motor de JavaScript para rodar os scripts da página e parte da
cascata de CSS. Não tem layout, então não sabe dizer onde nada está nem qual a largura de nada. Não
pinta, então ninguém consegue olhar para ele. E como nada está numa tela, um clique é uma chamada
de função num elemento, sem ponteiro e sem a pergunta de onde o ponteiro teria caído.

**O que ele ganha com isso é um navegador que mora dentro do seu programa.** Nenhum processo
separado para iniciar, nenhum protocolo entre o seu código e a página, nenhum driver. O
`document.querySelector` do seu teste é o mesmo objeto que o script da própria página segura. Foi
por isso que navegadores simulados foram o caminho rápido durante anos. Antes de o Chrome 59 trazer
o modo headless, em 2017, conduzir um navegador de verdade num servidor de build pedia uma tela
virtual ou uma versão especial de um motor.

## Os três que esta aula encontra

| | linguagem | o JavaScript roda em | versão usada aqui |
|---|---|---|---|
| Zombie.js | Node | jsdom 11.12.0, que o Zombie fixa | 6.1.4, de 2018: a última |
| HtmlUnit | Java | um fork próprio do Mozilla Rhino | 5.6.0, atual |
| jsdom | Node | o próprio V8 do Node, num contexto separado | 30.1.2 |

Não são três concorrentes do mesmo porte. **O Zombie é uma API em cima do jsdom**, dos anos em que
as ferramentas de teste do Node queriam um navegador inteiro dentro de um callback. A última versão
dele tem oito anos, e a próxima seção mostra o que isso quer dizer para uma página escrita hoje.
**O HtmlUnit é o de Java**, ainda lançado, e o que o Selenium consegue conduzir por um driver
próprio. **O jsdom é o DOM em si**, sem o navegador em volta, e é o que a maioria dos
desenvolvedores JavaScript roda sem saber: é o que um teste do Jest recebe quando o ambiente dele é
`jsdom`.

## O que a palavra "navegador" promete aqui

Nenhum dos três é um quarto navegador ao lado do Chrome, do Firefox e do Safari. Cada um implementa
os padrões para os quais os autores tiveram tempo. O HtmlUnit os roda num motor de JavaScript que
nenhum navegador de usuário usa, e o jsdom no V8 que vier com o Node que você instalou. **Uma página pode passar num deles e falhar em todos os navegadores de
verdade**, e o contrário também. A aula 10 roda uma suíte no Chromium, no Firefox e no WebKit
porque três motores de verdade tratam a mesma página de jeitos um pouco diferentes; um simulado é
um quarto motor que nenhum dos seus usuários tem.

Então a pergunta que esta aula repete não é "é rápido?". É: **o que a verificação que eu escrevi
olhou de fato?** Para o HTML que um servidor manda, e para código que só lê e escreve na árvore, a
resposta é a mesma num navegador simulado e num de verdade. Para tudo o que depende de onde uma
caixa foi parar, não existe resposta, e as próximas seções medem como isso aparece.
