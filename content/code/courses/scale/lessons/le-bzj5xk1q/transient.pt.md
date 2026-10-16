---
title: Falhas que passam
version: 1
---

A aula 9 terminou com a bilheteria respondendo `502` sempre que uma cobrança falhava. Muitas dessas
falhas nunca tiveram a ver com a cobrança. Uma conexão foi reiniciada porque uma cópia do payments
estava sendo trocada; um pedido caiu numa cópia no instante em que ela descartava carga; um pacote se
perdeu e o timeout acabou. Tentada de novo um momento depois, a mesma cobrança teria passado. Essas
são **falhas transitórias**, e num sistema de muitos serviços elas não são eventos raros: são uma
taxa de fundo que nunca chega a zero.

**Tentar de novo** (*retry*) transforma uma falha transitória num sucesso de que o comprador nunca
fica sabendo. É também um dos jeitos mais fáceis de piorar uma queda, e esta aula é sobre distinguir
os dois. Uma política de novas tentativas responde quatro perguntas:

1. **Quais falhas valem uma nova tentativa?** Um timeout ou um `503` bem pode dar certo na próxima.
   Um `400` não vai, nem um cartão recusado: a resposta seria a mesma.
2. **Quantas vezes?** Cada tentativa custa tempo a quem chama e trabalho a quem é chamado.
3. **Quanto esperar entre as tentativas?** Não zero: um serviço que falhou há um milissegundo
   dificilmente se recuperou um milissegundo depois. Seções 05 e 06.
4. **É seguro fazer o trabalho duas vezes?** Uma leitura é. Uma cobrança não é, a não ser que quem é
   chamado consiga saber que o segundo pedido é o primeiro de novo. Seções 07 e 08.

A última pergunta é a que mais importa e a que menos se faz. O timeout da aula 9 já mostrou o
problema: a bilheteria desistiu depois de um segundo e o payments seguiu cobrando o cartão. Uma nova
tentativa naquele momento o teria cobrado duas vezes.
