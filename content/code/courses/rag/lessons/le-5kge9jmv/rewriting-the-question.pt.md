---
title: Reescrevendo a pergunta
version: 2
---

Tudo até aqui usou a pergunta como o usuário a digitou. Muitas vezes esse é o elo mais fraco: a pergunta
é curta, se refere a algo dito antes, ou usa palavras que nenhum documento usa. **Reescrever a pergunta**
antes de buscar é mais barato que qualquer melhoria no índice, porque custa um passo por pergunta e não
muda nada do que foi guardado.

## Uma pergunta de continuação

Numa conversa, as pessoas fazem a segunda pergunta nos termos da primeira. Depois de *How many days do I
have to return a printed book?* vem *And for e-books?*, que só significa algo para quem leu a primeira.

```
ana@vm:~/rag$ python show.py vector "And for e-books?"
1    0.585  E-books and audiobooks > Where e-books can be read  | E-books open in the Marginalia app for phones an
2    0.574  E-books and audiobooks > Audiobooks  | Audiobooks are sold separately from e-books and 
3    0.563  E-books and audiobooks > Refunds for e-books  | An e-book that is faulty, for example with missi
4    0.548  E-books and audiobooks > Where e-books can be read  | You can use the same account on up to six device
5    0.540  E-books and audiobooks > Reading  | In the app, tap the middle of the page and choos
```

A busca fez o que pôde com as palavras que tinha: cinco pedaços sobre e-books, os aparelhos em que eles
abrem, audiolivros, leitura no aplicativo. Nenhum deles é a regra de reembolso, porque a pergunta nunca
disse que era sobre devolver alguma coisa. A mesma pergunta escrita por inteiro:

```
ana@vm:~/rag$ python show.py vector "How long do I have to return an e-book?"
1    0.794  Returns and refunds policy > E-books and audiobooks  | An e-book can be refunded within 14 days of purc
2    0.793  E-books and audiobooks > Refunds for e-books  | An e-book can be refunded within 14 days of purc
3    0.770  Returns policy > Returning a book  | You may return a printed book within 14 days of 
4    0.739  Returns policy > Damaged books  | If a book arrives damaged, send it back within 1
5    0.736  Returns and refunds policy > The return window  | You have 30 days from delivery to return a print
```

**Os dois pedaços com a regra de reembolso de e-book vêm em primeiro, com 0,794 e 0,793.** A reescrita aqui
foi feita pelo curso, à mão. Num sistema real é trabalho de um modelo de linguagem: dada a conversa até
aqui e a última mensagem, escrever a mensagem como uma pergunta que se sustente sozinha. É uma das
chamadas de modelo mais baratas de um pipeline, e a aula 13 constrói o histórico de conversa de que ela
precisa.

## Outras reescritas

- **Ampliar o vocabulário.** Clientes dizem *dinheiro de volta* e documentos dizem *reembolso*. Uma
  reescrita pode acrescentar as palavras do documento, ou uma lista de sinônimos mantida pela equipe pode.
- **Separar uma pergunta composta.** *Posso devolver um exemplar autografado e quanto tempo leva o
  reembolso?* são duas perguntas com duas respostas em duas seções. Buscar cada uma separadamente e juntar
  os resultados acha as duas; buscar uma vez acha a que dominar o vetor.
- **Várias formulações de uma vez.** Alguns pipelines geram três ou quatro versões da pergunta, buscam
  cada uma e fundem as listas com a mesma fusão por posição recíproca da seção anterior. Custa uma busca
  por formulação e ajuda mais quando as perguntas são curtas e vagas.
- **Uma resposta hipotética.** O método chamado HyDE faz um modelo escrever uma resposta plausível, sem
  fontes, e busca com ela em vez da pergunta, porque uma resposta se parece mais com um pedaço do que uma
  pergunta. Isso não foi rodado aqui; o risco fica claro pela aula 1, que mostrou o que um modelo escreve
  sem fontes, as regras de empréstimo de uma biblioteca para a pergunta de uma livraria.

Cada uma dessas é mensurável com o mesmo conjunto de teste de tudo nesta aula, e nenhuma deveria entrar
num pipeline sem medição: uma reescrita que ajuda perguntas vagas pode prejudicar as precisas, trocando o
identificador exato do usuário por uma paráfrase.
