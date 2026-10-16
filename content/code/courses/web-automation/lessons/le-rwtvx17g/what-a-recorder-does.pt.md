---
title: O que um gravador anota
version: 1
---

Um gravador observa você usar uma página e anota o que você fez, como uma lista de passos que uma
máquina consegue repetir. **A crença comum é que a lista é um teste. Ela é a transcrição de uma
visita**: em que você clicou, em que ordem, na página como ela estava naquele momento. Um teste é
uma afirmação sobre a loja que precisa valer em toda visita, e esta aula é sobre a distância entre
as duas coisas.

## Três movimentos, em todo gravador

Todo gravador desta aula faz as mesmas três coisas, custe o que custar e rode onde rodar.

- **Ele escuta.** Um script que o gravador põe na página ouve cada clique, cada tecla e cada
  mudança de campo, os mesmos eventos a que a aula 11 de `javascript` liga ouvintes.
- **Ele dá nome ao elemento.** "Um clique" não serve para nada até dizer em quê, então o gravador
  roda um **construtor de localizadores**: uma lista ordenada de jeitos de nomear um elemento, de um
  atributo de teste ou um `id` até uma posição na árvore. Ele fica com o primeiro nome que acha
  aquele elemento e nenhum outro.
- **Ele salva um passo.** Um comando, o alvo que o construtor escolheu e um valor quando houver,
  como o texto digitado num campo.

Reproduzir é a mesma lista lida ao contrário: achar o alvo, fazer o comando, ir para a linha
seguinte.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 318\" role=\"img\" aria-label=\"Quatro caixas em fila. A página: um clique no botão da banana, que é um evento e nada mais. O script do gravador escuta dentro da página e ouve o clique neste elemento, neste momento. O construtor de localizadores tenta nomes em ordem, atributo de teste, id, name, caminho CSS, XPath por posição, e fica com o primeiro que for único. O passo salvo: command click, target css=#card-4821 &gt; button, value vazio, uma linha do arquivo. Uma seta tracejada volta do passo salvo para a página: a reprodução acha o alvo, faz o comando e vai para a próxima linha. Embaixo, uma caixa tracejada lista o que nunca é um evento e por isso nunca está na gravação: a cesta vazia, o que você esperou, o que você conferiu, e o porquê.\"><rect x=\"10\" y=\"40\" width=\"170\" height=\"150\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"95.0\" y=\"62\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">a página</text><text x=\"95.0\" y=\"88\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um clique no botão</text><text x=\"95.0\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">da banana</text><text x=\"95.0\" y=\"124\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\"></text><text x=\"95.0\" y=\"142\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um evento, nada mais</text><path d=\"M180 115.0 L196 115.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M196 115.0 L189.6 117.7 L189.6 112.3 Z\" fill=\"var(--wire)\"></path><rect x=\"198\" y=\"40\" width=\"170\" height=\"150\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"283.0\" y=\"62\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">o script do gravador</text><text x=\"283.0\" y=\"88\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">escuta dentro da página</text><text x=\"283.0\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ouve: clique</text><text x=\"283.0\" y=\"124\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">neste elemento</text><text x=\"283.0\" y=\"142\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">neste momento</text><path d=\"M368 115.0 L384 115.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M384 115.0 L377.6 117.7 L377.6 112.3 Z\" fill=\"var(--wire)\"></path><rect x=\"386\" y=\"40\" width=\"170\" height=\"150\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"471.0\" y=\"62\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">construtor de localizadores</text><text x=\"471.0\" y=\"88\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tenta nomes em ordem:</text><text x=\"471.0\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">atributo de teste, id,</text><text x=\"471.0\" y=\"124\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">name, caminho CSS,</text><text x=\"471.0\" y=\"142\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">XPath por posição;</text><text x=\"471.0\" y=\"160\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">fica com o primeiro único</text><path d=\"M556 115.0 L572 115.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M572 115.0 L565.6 117.7 L565.6 112.3 Z\" fill=\"var(--wire)\"></path><rect x=\"574\" y=\"40\" width=\"170\" height=\"150\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"659.0\" y=\"62\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">o passo salvo</text><text x=\"659.0\" y=\"88\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">command: click</text><text x=\"659.0\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">target:</text><text x=\"659.0\" y=\"124\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">css=#card-4821 &gt; button</text><text x=\"659.0\" y=\"142\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">value: (empty)</text><text x=\"659.0\" y=\"160\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">uma linha do arquivo</text><path d=\"M665 190 L665 218 L95 218 L95 194\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M95 200 L95 192\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M95 192 L97.7 198.4 L92.3 198.4 Z\" fill=\"var(--wire)\"></path><text x=\"380\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">reprodução: acha o alvo, faz o comando, próxima linha</text><rect x=\"10\" y=\"238\" width=\"740\" height=\"70\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-dasharray=\"5 4\"></rect><text x=\"380\" y=\"260\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">nunca é um evento, então nunca está na gravação</text><text x=\"102.5\" y=\"286\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a cesta vazia</text><text x=\"287.5\" y=\"286\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o que você esperou</text><text x=\"472.5\" y=\"286\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o que você conferiu</text><text x=\"657.5\" y=\"286\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">por quê</text></svg>", "caption": "Um gravador em três movimentos. Tudo o que ele salva passa pelo construtor de localizadores, e tudo o que importa a um teste sem passar pelo mouse fica abaixo da linha."}
```

**O ponto fraco é o movimento do meio.** O construtor escolhe um nome numa página, num momento, por
regras escritas para todas as páginas do mundo. A aula 2 mostrou quanto isso custa nesta loja: o
próprio erro de modo estrito do Playwright ofereceu `#card-NNNN > button` como jeito de achar um
botão, e o número ali é sorteado de novo toda vez que a loja carrega. Um gravador encontra a mesma
página, e as duas próximas seções mostram, pelo código-fonte, quando ele escolhe um nome assim e
quando não escolhe.

## O que não deixa evento

Tudo o que você fez sem o mouse e sem o teclado falta na gravação, e quatro dessas coisas são o que
transforma uma verificação num teste.

1. **O estado de onde você partiu.** Você abriu uma loja com a cesta vazia. Nada na gravação diz que
   ela precisa estar vazia, porque esvaziá-la nunca foi um clique. Esse é o assunto da aula 15, e a
   terceira seção desta aula esbarra nele.
2. **O que você esperou.** Você viu a contagem mudar antes de clicar de novo; seus olhos fizeram a
   espera. Uma gravação ou reproduz tão rápido quanto a ferramenta consegue, ou carrega uma pausa
   fixa que alguém acrescentou depois que a primeira reprodução deu errado. A aula 3 mediu o que
   uma pausa fixa compra: dormir um segundo ainda leu uma resposta velha.
3. **O que você estava conferindo.** Um gravador só salva uma asserção quando você pede uma, num
   menu, sobre o elemento que você aponta, com o texto que aquele elemento tinha naquele momento.
4. **Por quê.** "Duas frutas dão dois itens" é a razão do teste. A gravação não tem lugar para
   isso, então guarda uma lista de cliques e um nome de teste como `test`.

**Nada disso torna um gravador inútil.** Torna-o um jeito rápido de produzir um primeiro rascunho,
e a última seção desta aula diz quando um rascunho é tudo de que você precisa.

## Onde um gravador fica

A aula 11 desenhou o teste de navegador em camadas: um executor, uma biblioteca, um protocolo e um
navegador. Um gravador escreve para uma dessas bibliotecas. As gravações do Selenium IDE são
reproduzidas pelo `selenium-webdriver`, que fala WebDriver, o protocolo da aula 8; o gravador do
Playwright escreve código Playwright. O BugBug e o Ghost Inspector guardam a gravação no serviço
deles e a reproduzem nos navegadores deles, então as camadas são deles e você só vê o resultado.

Isso deixa a comparação desta aula justa num sentido e não no outro. O que a gravação **diz** pode
ser lido e rodado aqui, porque os dois formatos são abertos. Como o serviço de um fornecedor **se
comporta** só pode ser lido em algum lugar, e a seção sobre esses dois diz isso.
