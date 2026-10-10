---
title: Foco que se vê, e foco que nada esconde
version: 1
---

**O indicador de foco é o ponteiro do mouse de quem usa teclado.** Sem ele, a pessoa aperta Tab e
tem que adivinhar onde está, e apertar Enter vira uma aposta. Os navegadores desenham um por
padrão, o contorno que você vê ao andar com Tab por qualquer página sem estilo, e o jeito mais
comum de perdê-lo é uma linha de CSS que alguém acrescentou porque o contorno parecia feio ao
clicar num botão com o mouse:

```css
*:focus { outline: none; }
```

É o defeito 3, e ele está em milhares de folhas de estilo de verdade.

## Três critérios sobre foco

| critério | nível | o que pede |
|---|---|---|
| **2.4.7 Foco visível** | AA | todo controle operado por teclado tem um indicador de foco visível |
| **2.4.11 Foco não encoberto (mínimo)** | AA, novo na 2.2 | o controle com foco não fica *totalmente* escondido por conteúdo que a própria página desenhou |
| **2.4.13 Aparência do foco** | AAA, novo na 2.2 | o indicador é grande o bastante, pelo menos do tamanho de um perímetro de 2 pixels CSS em volta do controle, e tem contraste de 3:1 entre os estados com e sem foco |

O 2.4.7 diz que o indicador existe. Não diz quão grande nem quão visível, e por isso o 2.4.13 foi
acrescentado, no AAA. Os 3:1 do *1.4.11 Contraste sem texto*, da aula 12, valem no AA para
qualquer indicador que a página desenhe no lugar do do navegador, já que um contorno que o olho
não separa do fundo não é grande coisa como indicador.

**O 2.4.11 é o que os testes perdem.** Um cabeçalho fixo, uma faixa de cookies presa no fim da
janela, um botão de chat flutuando num canto: cada um é desenhado por cima da página, e conforme o
usuário desce com Tab, o controle com foco rola para baixo dele. O contorno está lá, só que embaixo
de uma faixa. O teste é andar com Tab pela página inteira com todo elemento fixo à mostra, numa
janela pequena, que é onde isso acontece. A versão mínima é atendida enquanto alguma parte do
controle continuar visível; a versão AAA, o 2.4.12, pede que nada dele fique escondido.

## :focus e :focus-visible

O motivo de designers removerem o contorno é que o `:focus` também casa num clique de mouse, e um
contorno em volta de um botão que você acabou de clicar parece erro. **O `:focus-visible` é a
correção que o CSS ganhou exatamente para isso**: o navegador o aplica quando julga que um
indicador é útil, o que é sempre o caso para foco de teclado e em geral não para um clique de
mouse num botão.

```css
:focus-visible { outline: 3px solid #1a5fb4; outline-offset: 2px; }
```

Essa única regra, no lugar da que removia o contorno, satisfaz a designer e quem usa teclado ao
mesmo tempo. O `contrast.py` da aula 12 mede o azul contra a página branca:

```
ana@nft:~/a11y$ python3 contrast.py 1a5fb4 ffffff
#1a5fb4 on #ffffff: 6.29:1   AA text yes, AA large yes, AAA text no
```

O azul dá 6.29:1 contra o branco, com folga acima dos 3:1 de que um indicador precisa, e os 3
pixels e o afastamento o mantêm longe da borda do próprio controle.

## Links de pular

Toda página de um site de verdade começa com as mesmas coisas: um logo, a navegação, talvez uma
caixa de busca. Quem usa teclado as encontra em toda página, antes do conteúdo, toda vez. **O
2.4.1 Ignorar blocos**, nível A, pede um jeito de passar por blocos repetidos, e o mais comum é um
link de pular: o primeiro elemento focável da página, um link para o conteúdo principal.

```html
<a class="skip" href="#main">Skip to the booking form</a>
```

Ele costuma ficar escondido fora da tela até receber o foco, então quem usa mouse nunca o vê e
quem usa teclado o vê no primeiro Tab. Dois detalhes decidem se ele funciona. O alvo precisa de um
`id` para o qual o link aponte. E se o alvo não for focável por si, dê a ele `tabindex="-1"`, para
que seguir o link leve o **foco** até lá e não só a rolagem; senão, em alguns navegadores, o
próximo Tab recomeça do topo. Títulos e marcos como `<main>` e `<nav>` também atendem ao 2.4.1,
para quem usa leitor de tela, que consegue pular entre eles; o link de pular é o mesmo serviço
para quem enxerga a tela e usa o teclado.
