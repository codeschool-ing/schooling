---
title: Uma frase com apoio ainda pode ser a resposta errada
version: 2
---

A verificação de citação responde a uma pergunta: esta frase está na fonte que cita? Ela não responde à
pergunta que o cliente fez. As duas coisas se separam nos dois sentidos, e esta aula já viu um deles:
na resposta do reembolso, a única frase que o verificador aprovou como citada literalmente é
verdadeira, citada para a fonte certa, e não é a resposta. O reembolso leva três dias úteis, e nenhuma
frase da resposta diz isso.

O outro sentido é a pergunta do exemplar autografado:

```
ana@vm:~/rag$ python answer.py "Can I return a signed copy?"
According to source [2], personalised copies and copies signed by the author cannot be returned, unless they arrive damaged or faulty.
  [2] Returns and refunds policy > Items that cannot be returned, updated 2026-02-02
ana@vm:~/rag$ python -c "from answer import sources_for; [print(round(s[\"score\"], 3), s[\"path\"]) for s in sources_for(\"Can I return a signed copy?\")]"
0.522 Returns and refunds policy > Damaged, faulty and wrong items
0.517 Returns and refunds policy > Items that cannot be returned
0.515 Returns and refunds policy > Damaged, faulty and wrong items
ana@vm:~/rag$ python check_reply.py "Can I return a signed copy?"
According to [2], personalised copies and copies signed by the author cannot be returned, unless they arrive damaged or faulty.
  unsupported (0.56) [2] Personalised copies and copies signed by the author cannot b
```

**A resposta está certa, e o verificador a chama de sem apoio.** A fonte que responde, *Items that
cannot be returned*, veio em segundo com 0,517, e o modelo achou a resposta nela. A política escreve
isso como uma lista, *the following cannot be returned unless they arrive damaged or faulty:* e depois
*personalised copies and copies signed by the author;* como um item. O modelo transformou a lista
numa frase só. O verificador divide a fonte nos pontos finais, então a lista inteira é um trecho
único e longo, e uma frase feita de dois pedaços dela marca 0,56 contra ele.

(As duas execuções aqui também escreveram a resposta de jeitos diferentes: *According to source [2]*
na primeira, *According to [2]* na segunda. Mesmo programa, mesma pergunta, temperatura 0. A primeira
requisição depois de o modelo carregar é a que costuma diferir.)

**Cada componente fez seu trabalho pela própria régua, e os vereditos continuam errados nos dois
sentidos.** A busca devolveu o pedaço certo entre os três primeiros. O modelo respondeu certo à pergunta
do exemplar autografado e errado à do reembolso. O verificador aprovou a resposta errada e reprovou a
certa. Nada no pipeline até aqui consegue dizer qual resposta responde à pergunta.

## Três propriedades, três verificações

Ajuda manter três perguntas separadas, porque cada uma pede um teste diferente:

| pergunta | propriedade | conferida por |
| --- | --- | --- |
| a busca achou o trecho que responde? | recuperação | o texto da resposta nos pedaços recuperados, como a aula 4 mediu |
| cada frase vem da sua fonte? | fidelidade | o `verify.py`, nesta aula |
| a resposta responde à pergunta? | correção | comparar a resposta com uma resposta conhecida, aula 8 |

A resposta do reembolso passa na primeira e na segunda, para a frase que citou, e falha na terceira. A
do exemplar autografado passa na primeira e na terceira e falha na segunda, que aqui é erro do
verificador e não do modelo. E a execução do prazo de devolução na aula 1 pôs o regulamento substituído
de 2025 em segundo entre as fontes, uma falha do primeiro tipo, que o filtro de status agora barra. **Um
pipeline medido numa propriedade pode parecer saudável enquanto falha nas outras duas**, e é por isso que
a aula 8 mede as três em toda pergunta.

## O que o verificador não enxerga

Um verificador que compara frases enxerga palavras, não sentido. Ele não sabe que um item de lista e uma
frase dizem a mesma coisa, e não sabe que uma citação verdadeira deixou de fora o fato que foi
perguntado. A versão do modelo para a segunda falha é a perigosa, porque nada a sinaliza: ele responde a
uma pergunta ligeiramente diferente da feita, ou responde o caso geral quando o cliente descreveu uma
exceção, e cita uma fonte que apoia o que ele disse. Só um teste com respostas conhecidas pega essas, e
só nas perguntas que alguém pensou em escrever.
