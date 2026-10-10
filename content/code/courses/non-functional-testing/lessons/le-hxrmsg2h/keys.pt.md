---
title: Operando uma página com o teclado
version: 1
---

Muita gente nunca toca num mouse. Algumas pessoas não conseguem segurá-lo com firmeza, ou de jeito
nenhum; algumas são cegas e usam leitor de tela, que é comandado pelo teclado; algumas usam um
acionador, uma ponteira de boca ou controle por voz, e tudo isso chega ao navegador como teclas. E
muita gente que digita rápido simplesmente prefere. **O 2.1.1 Teclado da WCAG, nível A, diz que
toda função da página pode ser operada por um teclado**, sem exigir tempo entre as teclas. É o
critério em que o `book.html` reprova pior, e a aula 13 mostrou que nenhuma ferramenta o relatou.

## As teclas que um testador usa

Testar com o teclado não pede software nenhum, só o hábito de deixar o mouse fora de alcance.
Estas são as teclas, e o que se espera de cada uma numa página web comum:

| tecla | o que faz |
|---|---|
| **Tab** | leva o foco ao próximo controle: link, botão, campo, qualquer coisa focável |
| **Shift+Tab** | leva de volta ao anterior |
| **Enter** | segue um link, aperta um botão, envia o formulário de dentro de um campo de texto |
| **Espaço** | aperta um botão, marca uma caixa de seleção, abre um select na maioria dos navegadores |
| **setas** | movem *dentro* de um controle: entre os botões de rádio de um grupo, as opções de um select, as abas de uma lista de abas, as células de uma grade |
| **Esc** | fecha o que foi aberto por cima da página: um menu, um diálogo, uma lista de sugestões |
| **Home, End** | pulam para as pontas de uma lista ou de um campo |

Dois pontos dessa tabela pegam as pessoas. **Tab não serve para andar dentro de um widget.** Um
grupo de botões de rádio é uma parada só na ordem de tabulação, e as setas escolhem dentro dele;
um widget próprio que põe cada opção na ordem de tabulação obriga o usuário a apertar Tab vinte
vezes para passar por ele. E **Enter e Espaço não são intercambiáveis**: um link responde a Enter e
não a Espaço, um botão responde aos dois. Uma `<div>` com cara de botão não responde a nenhum, a
menos que alguém escreva o código para as duas teclas, e esse é o motivo de usar um `<button>`.

## Ordem do foco é ordem de leitura

**O 2.4.3 Ordem do foco**, nível A, pede que a ordem em que o Tab percorre a página preserve o
sentido dela: grosso modo, que siga a ordem em que uma pessoa lê a página e preenche o formulário.
O navegador monta a ordem de tabulação a partir da ordem dos elementos no HTML, então uma página
cuja marcação está em ordem de leitura ganha uma ordem de tabulação sensata de graça. Duas coisas
a quebram.

- **Um `tabindex` positivo.** `tabindex="0"` põe um elemento na ordem normal, e `tabindex="-1"` o
  torna focável por script mas não pelo Tab; os dois são úteis. Qualquer valor acima de zero põe o
  elemento **na frente de tudo o mais na página**, em ordem numérica, antes de o navegador começar
  pelos elementos na ordem do documento. Um único `tabindex="1"` reordena a página inteira em volta
  dele, e esse é o defeito 6.
- **CSS que move coisas.** O `order` do flexbox, o posicionamento do grid e o posicionamento
  absoluto mudam onde um elemento é desenhado sem mudar onde ele está na marcação, então o foco
  pula pela tela numa ordem que não bate com nada que o usuário vê. O *1.3.2 Sequência com
  significado* da WCAG cobre a metade de leitura do mesmo problema.

## Armadilhas de foco

**O 2.1.2 Sem bloqueio do teclado**, nível A, diz que, se o teclado consegue levar o foco para
dentro de algo, consegue tirá-lo de lá. Uma armadilha é uma região em que o foco entra e não
consegue sair: um player de vídeo ou um mapa embutido que engole o Tab, um editor de texto rico em
que o Tab insere uma tabulação e nada diz como escapar. Para quem usa mouse ela é invisível. Para
quem usa teclado é o fim da página; o único jeito de sair é recarregar.

Um diálogo modal é o caso que parece armadilha e não é. Enquanto ele está aberto, o foco **deve**
ficar dentro dele, indo do último controle para o primeiro, porque a página atrás está inerte. O
que o torna legítimo é que o Esc, ou um botão de fechar dentro dele, o encerra e devolve o foco ao
controle que o abriu. Um diálogo que prende o foco e não oferece saída é uma armadilha; um diálogo
que deixa o foco escapar para a página atrás dele é outro defeito.

## Uma passada manual, em cinco minutos

Antes de um script, o teste em si, que qualquer pessoa roda em qualquer página:

1. Clique na barra de endereço do navegador e aperte Tab uma vez. O primeiro elemento da página
   deve receber o foco, e você deve conseguir **ver** qual é.
2. Continue apertando Tab. Confira se a ordem segue a página, se nada é pulado e se o foco nunca
   some.
3. Em cada controle, acione-o: Enter em links e botões, Espaço em botões e caixas, setas em selects
   e grupos, Esc em tudo que abriu.
4. Complete a tarefa para a qual a página existe. No `book.html`, é reservar um assento.
5. Volte por toda a página com Shift+Tab, para conferir a ordem inversa também.

O passo 4 é o que falha no `book.html`, e a próxima seção mostra a falha, numa transcrição.
