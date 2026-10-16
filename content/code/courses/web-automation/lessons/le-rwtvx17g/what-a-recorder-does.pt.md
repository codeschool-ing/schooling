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

%%FIG pipeline%%

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
