---
title: Uma frase com apoio ainda pode ser a resposta errada
version: 1
---

A verificação de citação responde a uma pergunta: esta frase está na fonte que cita? Ela não responde à
pergunta que o cliente fez. As duas coisas se separam mais vezes do que se espera, e a pergunta do
exemplar autografado mostra isso numa execução.

```
ana@lab:~/rag$ python answer.py "Can I return a signed copy?"
We replace damaged books at no cost and you do not need to send the damaged copy back. [1]
  [1] Returns and refunds policy > Damaged, faulty and wrong items, updated 2026-02-02
ana@lab:~/rag$ python -c "from answer import sources_for; [print(round(s[\"score\"], 3), s[\"path\"]) for s in sources_for(\"Can I return a signed copy?\")]"
0.522 Returns and refunds policy > Damaged, faulty and wrong items
0.517 Returns and refunds policy > Items that cannot be returned
0.515 Returns and refunds policy > Damaged, faulty and wrong items
ana@lab:~/rag$ python check_reply.py "Can I return a signed copy?"
We replace damaged books at no cost and you do not need to send the damaged copy back. [1]
  quoted             [1] We replace damaged books at no cost and you do not need to s
```

**A resposta é sobre livros danificados, a verificação diz que está citada, e o cliente continua sem
saber se um exemplar autografado pode ser devolvido.** A fonte que responde foi recuperada: *Items that
cannot be returned*, em segundo com 0,517, com *copies signed by the author* na lista. O extract-1
escolheu uma frase da primeira fonte, porque para o MiniLM *send the damaged copy back* fica mais perto de
*return a signed copy* do que um item de lista terminado em ponto e vírgula.

Cada componente fez seu trabalho pela própria régua. A busca devolveu o pedaço certo entre os três
primeiros. O gerador citou fielmente. O verificador confirmou a citação. **A resposta continua errada**, e
nada no pipeline até aqui consegue ver isso.

## Três propriedades, três verificações

Ajuda manter três perguntas separadas, porque cada uma pede um teste diferente:

| pergunta | propriedade | conferida por |
| --- | --- | --- |
| a busca achou o trecho que responde? | recuperação | o texto da resposta nos pedaços recuperados, como a aula 4 mediu |
| cada frase vem da sua fonte? | fidelidade | o `verify.py`, nesta aula |
| a resposta responde à pergunta? | correção | comparar a resposta com uma resposta conhecida, aula 8 |

A execução do exemplar autografado passa nas duas primeiras e falha na terceira. A execução da entrega
expressa na aula 1 falhou na terceira com a seção certa recuperada, e as execuções do regulamento de 2025
falharam na primeira recuperando o documento errado. **Um pipeline medido numa propriedade pode parecer
saudável enquanto falha nas outras duas**, e é por isso que a aula 8 mede as três em toda pergunta.

## Por que modelos reais falham nisso de outro jeito

Um modelo real lê a lista de fontes inteira como linguagem e teria muita chance de responder esta
corretamente: o item da lista diz que exemplares autografados não podem ser devolvidos, e modelos leem
listas bem. A versão dele desta falha é mais sutil. Ele responde a uma pergunta ligeiramente diferente da
feita, ou responde o caso geral quando o cliente descreveu uma exceção, e cita uma fonte que apoia o que
ele disse. A verificação acima também deixa esses passarem. Só um teste com respostas conhecidas os pega,
e só nas perguntas que alguém pensou em escrever.
