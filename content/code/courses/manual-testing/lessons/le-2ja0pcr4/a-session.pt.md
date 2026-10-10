---
title: Uma sessão sobre pedidos
version: 1
---

Esta é a primeira sessão exploratória da Ana no boxoffice 1.1, feita com a missão da seção 03, com
as notas que ela tomou. **Faça junto**: reinicie a aplicação para os números de pedido baterem,
deixe o navegador e um segundo terminal abertos, e tente cada passo antes de ler o que ela encontrou.
As transcrições mostram as requisições com o curl, e todas menos uma são um botão ou um formulário
no navegador; a outra porta da seção 04 explica a exceção.

| | |
|---|---|
| missão | Explore a vida de um pedido, com toda ação a partir de todo estado, no navegador e com o curl, para descobrir o que a aplicação permite e diz que o R6 e o R7 não explicitam |
| testadora | Ana |
| versão | boxoffice 1.1, reiniciado no começo da sessão |
| tempo fixo | 60 minutos, uma sessão curta |
| heurísticas | Function e Time do SFDPOT; a outra porta |
| conhecido | o reembolso de um pedido usado (aula 5) |

## Function: toda ação a partir de todo estado

O R6 cita quatro estados que um pedido pode alcançar depois de reservado e quatro ações. O primeiro
movimento da Ana é o mais simples que a missão permite: reservar um pedido e apertar o botão que o R6
diz que ainda não deveria funcionar. Um pedido reservado não pode ser usado na porta, porque ninguém
pagou por ele.

@@fence@@

O R6 se sustenta em todas as linhas acima menos uma: usar é recusado enquanto o pedido está
reservado, pagar e usar funcionam em seguida, pagar e cancelar são recusados depois de usado, e o
reembolso de um pedido usado é aceito, que é o defeito que a aula 5 já relatou. A Ana escreve
*conhecido, visto de novo* ao lado dessa e segue.

O que as linhas acima dizem é outra história. **As recusas estão mal escritas**: *cannot be useed*,
*cannot be payed*. Nada no R6 ou no R7 fala de ortografia, e nenhum roteiro escrito a partir deles
teria olhado; foi a primeira coisa na tela. A nota dela: *mensagem de recusa = "cannot be " + ação +
"ed"? useed, payed, canceled. Conferir com um estado cujo nome eu conheço.*

Então ela tenta o único estado cujo nome a aplicação soletra para ela, cancelando um pedido novo e
depois tentando pagá-lo:

@@fence@@

*An order that is cancelled cannot be payed.* A mesma frase soletra o estado `cancelled`, com dois
l, e monta a palavra da ação a partir de `pay`. **É o mecanismo aparecendo**: os nomes dos estados
estão escritos por extenso, e as palavras das ações são feitas colando `ed` em qualquer ação que
chegue. A última requisição é a outra porta da seção 04: o navegador mostra quatro botões, mas o curl
manda qualquer palavra, e `dance` volta como *danceed*. Nenhum cliente vê essa. Ela é evidência para
o relatório, não um segundo defeito: prova que a frase é montada a partir de qualquer palavra que
chegue, o que diz ao Rui onde olhar e por que toda ação recusada é afetada, seja qual for o botão
que o cliente apertou.

A nota da Ana, escrita como constatação e não como palpite: *Defeito: a mensagem de toda ação
recusada diz `cannot be <action>ed`: useed, payed, canceled. O R7 pede uma frase dizendo o que está
errado; estas são frases, e duas delas não são inglês. Visto a partir de reservado, usado e
cancelado.*

## Time: o que acontece depois que o espetáculo começou

O T do SFDPOT é a letra que a maioria das sessões pula, e o R6 tem um horário: um pedido pago pode ser
reembolsado **antes de o espetáculo começar**. A Ana testou reembolsos às duas da tarde, oito horas
antes de The Seagull começar. A pergunta que a missão faz é o que acontece depois que ele começa.

O `BOXOFFICE_NOW` ajusta o relógio da aplicação, e a aula 1 disse para que ele serve. Escrito sem
fuso, ele é lido como a hora local da própria máquina, então o mesmo comando funciona em qualquer
lugar. A Ana para a aplicação e a sobe de novo às oito e meia da noite:

@@fence@@

@@fence@@

Está certo: o R4 fecha as reservas uma hora antes do espetáculo, e The Seagull começa às 20:00. Mas
isso deixa a Ana sem nada para reembolsar, porque um reinício esvazia a aplicação, e um pedido para
esta noite só pode ser feito antes das 19:00. **Um relógio parado não anda com um pedido na mão.**
Ela anota isso como obstáculo, *a aplicação não consegue mover o relógio enquanto guarda os pedidos*.
Depois monta a pergunta do jeito lento, no relógio real. À noite, sem `BOXOFFICE_NOW`, ela sobe o
boxoffice, reserva dois ingressos para The Seagull e paga.

@@fence@@

Depois deixa a aplicação rodando, cuida de outra coisa e volta depois que o espetáculo começou:

@@fence@@

**O reembolso é aceito às 20:01, um minuto depois do início de The Seagull**, quando o R6 só permite
reembolsos antes de o espetáculo começar. A nota dela: *Defeito: um pedido pago para S1 é
reembolsado depois que S1 começou (reservado e pago às 18:50, reembolsado às 20:01, relógio real).
R6: reembolso antes de o espetáculo começar.*

Para fazer o mesmo, você precisa de uma noite. Suba o boxoffice sem `BOXOFFICE_NOW` em algum momento
antes das 19:00, reserve e pague The Seagull, deixe a aplicação rodando e aperte Refund na página do
pedido depois das 20:00. A primeira parte, com o relógio parado às 20:30, leva um minuto a qualquer
hora do dia: pare a aplicação e suba-a com `BOXOFFICE_NOW=2026-10-10T20:30 python3 boxoffice.py`,
com a data que quiser, já que os espetáculos sempre são postos em volta da data que o relógio diz. No
Windows, defina a variável antes, `set BOXOFFICE_NOW=2026-10-10T20:30` no Prompt de Comando ou
`$env:BOXOFFICE_NOW="2026-10-10T20:30"` no PowerShell; nenhum dos dois foi rodado para este curso.

## O que a sessão deixa

| | |
|---|---|
| na missão | cerca de 45 minutos; os outros 15 foram para preparar a parte da noite |
| pares tentados | 9 dos 20 pares de ação e estado |
| defeitos | ações recusadas dizem `cannot be <action>ed`; um reembolso é aceito depois que o espetáculo começa |
| conhecido, visto de novo | o reembolso de um pedido usado |
| problemas | a aplicação não consegue mover o relógio enquanto guarda os pedidos |
| oportunidades | a contagem de lugares depois de um reembolso tardio; reservar exatamente às 18:59 e às 19:00 |

Nove de vinte pares é uma cobertura honesta e está escrita como tal: o bastante para ver o padrão das
mensagens, e não o bastante para dizer que todo par se comporta. A conversa final da seção 06 decide
o que acontece com os outros onze.
