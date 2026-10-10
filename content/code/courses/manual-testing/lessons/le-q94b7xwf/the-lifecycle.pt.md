---
title: O ciclo de vida de um defeito
version: 1
---

Um relato de defeito costuma ser imaginado como um chamado com dois estados, aberto e fechado, e a
parte de quem testa como o momento em que ele é aberto. **Um relato passa por um punhado de
estados, e quem testa é quem o move nas duas pontas**: para dentro no começo, ao registrá-lo, e
para fora no fim, ao confirmar a correção. No meio, outras pessoas o movem, e cada movimento
responde a uma pergunta. Um time que concorda sobre os estados olha para qualquer relato e sabe de
quem é a vez.

Cada ferramenta dá aos estados nomes próprios, e a aula 17 mostra quatro delas. Os nomes abaixo
são comuns; o que importa são as perguntas, porque essas são as mesmas em todo lugar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" data-fig=\"l16-lifecycle\" aria-label=\"Um diagrama de estados de um relato de defeito. Novo leva a triado, também chamado aberto, depois a em andamento, depois a corrigido. Um build entregue move corrigido para pronto para reteste. De pronto para reteste, um reteste que passa leva a verificado e depois a fechado; um reteste que falha leva a reaberto, que volta para em andamento. De triado, três saídas deixam o caminho: duplicado, rejeitado e adiado. Quem testa coloca o relato em novo, e o tira de pronto para reteste nas duas direções.\"><defs><marker id=\"mt-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"mt-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"140.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">novo</text><rect x=\"190.0\" y=\"40.0\" width=\"140.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">triado (aberto)</text><rect x=\"360.0\" y=\"40.0\" width=\"140.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"430.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">em andamento</text><rect x=\"540.0\" y=\"40.0\" width=\"140.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">corrigido</text><rect x=\"540.0\" y=\"140.0\" width=\"140.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"159.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">pronto para reteste</text><rect x=\"360.0\" y=\"140.0\" width=\"140.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"430.0\" y=\"159.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">reaberto</text><rect x=\"540.0\" y=\"240.0\" width=\"140.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"259.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">verificado</text><rect x=\"360.0\" y=\"240.0\" width=\"140.0\" height=\"38.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"430.0\" y=\"259.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">fechado</text><path d=\"M90.0 14.0 L90.0 40.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#mt-ah-amber)\"></path><path d=\"M160.0 59.0 L190.0 59.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M330.0 59.0 L360.0 59.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M500.0 59.0 L540.0 59.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M610.0 78.0 L610.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><text x=\"618.0\" y=\"109.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">build entregue</text><path d=\"M610.0 178.0 L610.0 240.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#mt-ah-amber)\"></path><text x=\"618.0\" y=\"209.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">reteste passa</text><path d=\"M540.0 159.0 L500.0 159.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#mt-ah-amber)\"></path><text x=\"520.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">reteste falha</text><path d=\"M430.0 140.0 L430.0 78.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M540.0 259.0 L500.0 259.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M205.0 78.0 L205.0 247.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M205.0 137.0 L222.0 137.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#mt-ah-paper-dim)\"></path><rect x=\"224.0\" y=\"120.0\" width=\"106.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"277.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">duplicado</text><path d=\"M205.0 192.0 L222.0 192.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#mt-ah-paper-dim)\"></path><rect x=\"224.0\" y=\"175.0\" width=\"106.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"277.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">rejeitado</text><path d=\"M205.0 247.0 L222.0 247.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#mt-ah-paper-dim)\"></path><rect x=\"224.0\" y=\"230.0\" width=\"106.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"277.0\" y=\"247.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">adiado</text><text x=\"20.0\" y=\"120.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">saídas na triagem</text><path d=\"M20.0 236.0 L48.0 236.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"56.0\" y=\"236.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">movido por quem testa</text><path d=\"M20.0 258.0 L48.0 258.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"56.0\" y=\"258.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">movido por outros</text></svg>", "caption": "Os estados por que passa um relato de defeito, e os movimentos entre eles. Os movimentos de quem testa têm uma cor própria: abrir o relato e decidir o reteste."}
```

## O caminho principal

**Novo.** O relato existe e ninguém além de quem escreveu o leu. A pergunta que espera é *isto é
real, e importa?*, e ninguém deveria estar trabalhando nele ainda.

**Triado**, muitas vezes chamado de **aberto**. Alguém o leu, concordou que é um defeito, confirmou
ou corrigiu a severidade, definiu uma prioridade e, em geral, deu nome a quem vai corrigir. A seção
03 desta aula é a reunião onde isso acontece.

**Em andamento.** Um desenvolvedor o pegou. Este estado existe para que duas pessoas não corrijam o
mesmo defeito, e para que um relato que ninguém tocou em um mês apareça exatamente como isso.

**Corrigido.** O desenvolvedor mudou o código e acredita que o defeito sumiu. Acredita é a palavra:
ele testou a mudança, mas na própria máquina, contra a própria leitura do relato.

**Pronto para reteste.** Um build com a correção chegou ao ambiente de teste. Uma correção que só
existe na máquina do desenvolvedor não pode ser retestada, por isso este é um estado à parte e não
um pedaço de *corrigido*: ele diz que quem testa pode começar.

**Verificado**, depois **fechado.** Quem testa rodou a reprodução do relato no build novo, viu o
resultado esperado e rodou as verificações vizinhas que uma correção pode ter perturbado. Alguns
times fecham assim que a correção é verificada; outros a deixam verificada até a versão sair e
fecham tudo junto.

O boxoffice já percorreu o caminho inteiro com um defeito. A aula 4 descobriu que seis ingressos
eram recusados, embora o R4 permita de 1 a 6: isso era *novo*. O Rui mudou a regra, a mudança
entrou na versão 1.1, e a aula 9 a conferiu no build novo. Essa conferência é o reteste, e numa
1.1 recém-iniciada ela fica assim:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=6' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1001 reserved.</p>
```

Seis ingressos viram um pedido, o resultado esperado do relato original, então o defeito está
verificado.

## O caminho de volta: reaberto

Quando o reteste falha, o relato volta, e **reaberto** diz isso. É o mesmo defeito, com o histórico
junto, e o desenvolvedor vê o que tentou e por que não segurou. Abrir um relato novo no lugar
perderia esse histórico e faria o defeito parecer mais novo do que é.

**Um reteste que falha não é o mesmo que uma correção que quebrou outra coisa**, e a diferença
decide qual dos dois você faz. A versão 1.1 também corrigiu o desconto de membro da aula 5, e a
rodada de regressão da aula 10 descobriu que a mesma edição fez estudantes deixarem de pagar
metade. O defeito da aula 5, um membro que reserva cinco ou mais levando 25%, está corrigido: na 1.1 esse
membro leva 15%, como diz o R5. O preço de estudante é uma falha nova, de outra regra, introduzida
pela correção. Então o defeito da aula 5 está verificado e continua fechado, e o preço de estudante é um
relato novo que aponta a mudança da versão 1.1 como causa. Reabrir o defeito da aula 5 por causa dele
deixaria o registro dizendo que o desconto de membro continua quebrado, o que é falso.

## As saídas: três finais que não são correção

Alguns relatos deixam o caminho na triagem, e cada saída é uma decisão com um motivo escrito nela.

**Duplicado**: o defeito já foi relatado. O relato novo é fechado e ligado ao antigo, e o que ele
tiver de útil, uma reprodução melhor ou outro ambiente, é copiado para lá.

**Rejeitado**: não é um defeito. Na maioria das vezes o programa faz o que o requisito diz e quem
relatou leu o requisito de outro jeito; às vezes ninguém consegue reproduzir. A seção 04 desta aula
trata dessas duas saídas.

**Adiado**: é um defeito, e o time decidiu não corrigi-lo nesta versão. Ele fica na ferramenta com
a sua severidade e volta na próxima triagem que planeja uma versão. Adiar é honesto de um jeito que
deixar um relato parado em *novo* por seis meses não é: o primeiro é uma decisão da qual alguém pode
discordar, o segundo é uma decisão que ninguém tomou.

## Quem move o quê

As cores da figura carregam a regra que vale guardar: **quem testa põe o relato no ciclo e o tira
dele, e ninguém mais fecha um defeito no lugar de quem testa.** Um desenvolvedor que marca a
própria correção como *fechada* pulou a única conferência que não depende da leitura dele do
relato. Quando falta gente no time, o estado que some primeiro é *pronto para reteste*, e os
defeitos que voltam dos clientes são os que passaram direto por ele.
