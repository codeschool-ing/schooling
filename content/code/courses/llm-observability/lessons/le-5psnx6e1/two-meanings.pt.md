---
title: Dois sentidos de precisão e revocação
version: 1
---

**Precisão** e **revocação** (*precision* e *recall*) aparecem em dois lugares na avaliação de um
modelo, e querem dizer a mesma aritmética sobre coisas diferentes.

**Sobre uma busca.** Dos trechos que a busca devolveu, quantos pertencem à resposta: precisão. Dos
trechos que têm a resposta, quantos a busca devolveu: revocação. A aula 8 de `rag` mediu o segundo como
recall@k, com a posição do primeiro acerto como *mean reciprocal rank*, e esta aula não repete isso. Ela
acrescenta a versão que os frameworks de avaliação relatam com os nomes **context precision** e
**context recall**, duas seções adiante.

**Sobre um detector.** Qualquer coisa que marca respostas como ruins é um detector: uma regra da aula
8, um juiz da aula 9, um alerta da aula 16. Das respostas que ele marcou, quantas eram ruins: precisão.
Das respostas que eram ruins, quantas ele marcou: revocação. A aula 10 deu a este curso o seu primeiro
conjunto de respostas cuja qualidade se conhece, as sessenta com rótulos combinados, então agora dá
para dar nota a um detector.

Os dois sentidos têm a mesma forma: um conjunto escolhido, um conjunto que deveria ter sido escolhido,
e a interseção.

| | Escolhido | Deveria ter sido | Precisão | Revocação |
| --- | --- | --- | --- | --- |
| Uma busca | trechos devolvidos | trechos com a resposta | devolvidos que a têm | que a têm e foram devolvidos |
| Um detector | respostas marcadas | respostas ruins | marcadas que são ruins | ruins que foram marcadas |

**Cada número pode ficar perfeito arruinando o outro.** Uma busca que devolve todos os trechos tem
revocação 1 e precisão inútil; uma que devolve um único trecho certo tem precisão alta e perde o que
mais fosse preciso. Um detector que marca tudo pega toda resposta ruim; um que não marca nada nunca erra
sobre o que marcou, porque não há nada. É por isso que os dois são relatados juntos, e por isso que um
número só que combina os dois, como o **F1**, a média harmônica, esconde qual deles se mexeu.

O kappa da aula 10 era outra pergunta: dois conjuntos de rótulos concordam além do acaso? Um detector
pode ter um kappa respeitável e ainda assim perder o que importa, se a classe que ele perde for pequena.
Precisão e revocação dizem para que lado ele erra, e o lado para o qual ele erra é o que decide se ele
serve para um trabalho.
