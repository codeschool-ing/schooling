---
title: O que tudo isso pode perder
version: 1
---

O vídeo do laboratório foi construído para ter um ponto cego, e cada método desta aula teve o seu. Em vídeo real os pontos cegos não são plantados, então ajuda saber onde eles costumam estar.

**O que é mostrado e não dito.** O arquivo de verdade lista o que cada slide mostra e o que a narração diz por cima:

```
ana@lab:~/mm$ python -c "import json; s = json.load(open(\"media/truth/returns.json\"))[\"slides\"]; [print(x[\"slide\"], \"shown:\", x[\"shown\"], \"| said:\", x[\"said\"] or \"-\") for x in s if x[\"slide\"] in (3, 5, 7)]"
3 shown: ['( ) Damaged in transit', '( ) Wrong book sent', '( ) Changed my mind'] | said: Second, press Return this item and choose a reason from the list.
5 shown: ['Quote it if you call us'] | said: -
7 shown: ['Within 30 days of delivery', 'Damaged books: refunded in full', 'The label is valid for 7 days'] | said: Refunds go back to the card you paid with. A damaged book is refunded in full, shipping included.
```

O slide 3 mostra três motivos e a narração diz *choose a reason from the list*. O slide 7 mostra *The label is valid for 7 days*, e ninguém diz isso. O slide 5 não diz nada. Um processo que só ouve perde os três, e o mesmo acontece com qualquer cliente que não enxerga a tela, que é o assunto da aula 14: a informação que quem vê recebe de graça precisa ser posta em palavras para todos os outros.

**O que é dito e não mostrado.** *Refunds go back to the card you paid with* só está na fala. Um processo que só olha perde isso, e o mesmo acontece com quem não consegue ouvir.

**O que acontece entre as amostras.** Uma taxa fixa vê o mundo através de uma cerca, e qualquer coisa mais curta que o espaço entre as estacas pode passar sem ser vista. A detecção de cena fecha esse espaço para cortes e abre outro para mudanças graduais: um fade lento, uma panorâmica por uma estante, uma pessoa entrando no quadro. O padrão seguro para vídeo desconhecido são as duas, uma taxa fixa para cobertura e mudanças de cena para cortes, e a seção de custo da aula 13 é onde essa combinação ganha um orçamento.

**O que não está em fluxo nenhum.** Um vídeo pode carregar sentido na edição (uma tomada de reação, uma pausa), no movimento na tela (uma seta apontando para um botão), ou em coisas que um modelo lendo quadros não tem como saber (que esta é a política de devolução do ano passado). A saída honesta de um processo de vídeo diz o que ele olhou: *quadros em cada mudança de cena e a trilha inteira*, para que quem lê saiba o que ele não poderia ter visto.

## Para vídeo longo

Tudo acima cresce com a duração. Uma hora de vídeo são 3.600 quadros a um por segundo, 3.978.000 tokens em alto detalhe pela mesma regra de blocos, antes de uma palavra da trilha. Vídeo longo se trata em pedaços: transcreva tudo (áudio é barato, aula 13), detecte as cenas, guarde um quadro por cena em baixo detalhe, resuma cada pedaço e resuma os resumos, mantendo os tempos para que qualquer afirmação possa ser rastreada até um momento.
