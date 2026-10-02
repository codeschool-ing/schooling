---
title: Pedindo que ele confira
version: 1
---

Autoavaliação é o passo que devolve a resposta de um modelo para ele com uma pergunta: isto está
certo? Parece uma segunda opinião. **É a mesma opinião pedida duas vezes**, e o que ela consegue
acrescentar depende inteiramente do que muda entre a primeira leitura e a segunda.

O prompt de revisão do laboratório mostra ao modelo a mensagem do cliente e a resposta que ele deu,
e pede uma palavra de volta:

```
ana@lab:~/triage$ cat prompts/review.txt
You check answers given by a triage assistant for Folio, an online bookshop.

<message>
{{message}}
</message>

<answer>
{{answer}}
</answer>

Is the answer valid JSON with the right category? Reply OK, or WRONG and the reason.
```

Ele pergunta sobre o formato e a categoria, e não sobre a urgência, então aqui uma resposta conta
como errada quando falha em `json`, `fields`, `labels` ou `category`.

## O que o substituto faz com isso

Uma revisão precisa de uma regra, como tudo o que o substituto faz, e a regra dela está escrita ao
lado da função que a aplica:

```
ana@lab:~/triage$ grep -n -A5 "^def review" promptlab/standin.py
416:def review(message, answer):
417-    """Asked to check an answer, it re-reads the message the way it read it
418-    the first time. So it catches what it can SEE, a broken format, and a
419-    label that differs from what it would say itself, and it doubts an answer
420-    when its own two best labels were close. It cannot catch a mistake it
421-    would make again."""
```

Ele pontua a mensagem de novo com a mesma tabela de palavras-chave com que respondeu. Essa leitura
deixa de fora o que o prompt de triagem acrescentava, os exemplos e a ordem da lista, já que o
prompt de revisão não traz nenhum dos dois. Então ele diz WRONG em três casos: a resposta não é
JSON válido, o rótulo que ele mesmo põe em primeiro difere do da resposta, ou os dois melhores
rótulos dele estão próximos. Fora isso, diz OK.

Essa regra foi escolhida para se parecer com um relato honesto da autoavaliação. **Um revisor só
consegue marcar o que lhe parece errado**, e uma resposta que ele daria de novo não lhe parece
errada.

## Medindo uma verificação

O `pl selfcheck RUN` passa cada resposta de uma execução pelo `review.txt`, uma chamada a mais por
resposta, e compara cada veredito com o rótulo da pessoa: a resposta foi marcada, e estava mesmo
errada? É a mesma medição que a aula 13 fez de um modelo julgando duas respostas, com o mesmo ponto
de referência. **Uma verificação vale o quanto concorda com os rótulos que uma pessoa deu**, e a
próxima seção lê essa concordância numa tabela.
