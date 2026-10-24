---
title: A pirâmide, e para que ela serve
version: 1
---

**Uma pirâmide de testes é um argumento sobre dinheiro: onde gastar o esforço de testar para que um
erro seja achado rápido e barato.** Os testes caros ficam para o que só eles conseguem achar. Não é
uma regra sobre quantos testes de cada tipo escrever, e quem a desenhou nunca disse que era.

Mike Cohn desenhou a primeira em 2009, em *Succeeding with Agile*. Embaixo fica uma base larga de
**testes unitários**, que conferem uma função ou classe sozinha e rodam em milissegundos. Acima deles
vem uma faixa mais estreita de **testes de integração**, que conferem que as peças funcionam juntas.
No topo fica uma ponta pequena de testes que conduzem a aplicação inteira pela interface, que ele
chamou de testes de UI e que hoje a maioria das pessoas chama de **testes de ponta a ponta**. A forma
diz do que ter mais.

## Por que a base é larga

Um teste vale o que ele pega menos o que ele custa, e o custo tem três partes. **Escrevê-lo.**
**Rodá-lo**: um teste unitário do `weekTotal` roda numa fração de milissegundo, e um teste que sobe um
navegador, abre uma página e clica leva perto de um segundo. **Acreditar nele**: quando um teste
unitário falha, ele aponta para uma função, e quando um teste de ponta a ponta falha, o defeito pode
estar em qualquer lugar entre o arquivo de dados e o CSS, ou no próprio tempo do teste. Uma falha que
leva uma hora para ser localizada custa mais que o teste que a achou.

Então, quanto mais embaixo um teste fica, mais deles você pode pagar, e mais perto cada um está da
linha que quebrou. Quanto mais em cima, mais do sistema real ele usa, e mais confiança um teste que
passa dá de que uma pessoa conseguiria mesmo fazer aquilo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l01-shapes\" aria-label=\"Duas formas lado a lado. À esquerda, a pirâmide de testes: uma base larga de testes unitários, uma faixa mais estreita de testes de integração acima dela e uma ponta pequena de testes de ponta a ponta. À direita, o troféu de testes: uma base fina de checagens estáticas, uma faixa pequena de testes unitários, uma faixa larga de testes de integração e um topo pequeno de testes de ponta a ponta. Uma seta ao lado diz que, quanto mais perto do topo, mais lento é o teste, mais custa mantê-lo e mais confiança ele dá de que o todo funciona; quanto mais perto da base, mais rápido, mais barato e mais perto da linha que quebrou.\"><defs><marker id=\"l01-shapes-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><polygon points=\"150.0,40 150.0,40 192.0,100 108.0,100\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></polygon><text x=\"150\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">ponta a ponta</text><polygon points=\"108.0,100 192.0,100 236.0,160 64.0,160\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></polygon><text x=\"150\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">integração</text><polygon points=\"64.0,160 236.0,160 280.0,220 20.0,220\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></polygon><text x=\"150\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">unitário</text><text x=\"150\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">a pirâmide</text><rect x=\"405.0\" y=\"40\" width=\"130\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"470\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ponta a ponta</text><rect x=\"365.0\" y=\"86\" width=\"210\" height=\"88\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"470\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">integração</text><rect x=\"415.0\" y=\"174\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"470\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">unitário</text><rect x=\"380.0\" y=\"214\" width=\"180\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"470\" y=\"229.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">estático</text><text x=\"470\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">o troféu</text><path d=\"M640 230 L640 50\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-shapes-ah-amber)\" marker-start=\"url(#l01-shapes-ah-amber)\"></path><text x=\"634\" y=\"22\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">mais lento, mais caro de manter,</text><text x=\"634\" y=\"34\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">mais confiança no todo</text><text x=\"634\" y=\"248\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">mais rápido, mais barato,</text><text x=\"634\" y=\"260\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">mais perto da linha quebrada</text></svg>", "caption": "A pirâmide de Cohn (2009) e o troféu de Dodds (2018) concordam no eixo e discordam sobre onde deve ficar a maioria dos testes. Num front-end, o meio largo do troféu é onde estão os defeitos que o usuário vê."}
```

## O front-end entorta a forma

Kent C. Dodds desenhou o **troféu de testes** em 2018 para aplicações como esta. Ele acrescenta uma
base que a pirâmide não tinha, as checagens **estáticas**, que acham erros sem executar nada: o
verificador de tipos lendo cada arquivo, um linter. E torna a faixa de integração a mais larga, por um
motivo próprio do front-end. A maior parte do que dá errado num app de navegador não está numa função
que soma números. Está entre as peças: um formulário que lê o campo errado, um botão ligado a nada, um
total que não se redesenha. Um teste unitário de cada peça passa com a tela quebrada, e um teste das
peças juntas, ainda rápido e ainda sem navegador de verdade, é o que vê.

As duas formas discordam das proporções e concordam com todo o resto: **teste cada coisa no nível mais
baixo que consegue vê-la falhar**, e suba só quando o nível de baixo não consegue.

## O que "integração" quer dizer aqui

A palavra quer dizer coisas diferentes para pessoas diferentes, e este curso a fixa. Um **teste de
componente** desenha uma parte da interface numa página simulada e a usa como uma pessoa usaria:
digita num campo, aperta um botão, lê o que aparece. Ele não precisa de servidor nem de navegador, e
roda em dezenas de milissegundos. Esse é o meio largo do troféu para um front-end, e as aulas 2 e 3
são sobre ele. Um teste de integração no sentido que uma pessoa de back-end dá à palavra, o app
conversando com um banco de dados ou um serviço de verdade, é assunto do back-end e não deste curso.
