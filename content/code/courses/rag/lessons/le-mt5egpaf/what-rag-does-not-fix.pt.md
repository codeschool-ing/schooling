---
title: O que a recuperação não conserta
version: 1
---

O RAG é vendido como a cura para um modelo que inventa coisas, e ele cura uma doença específica: o
modelo não ter o texto. Todos os outros jeitos de errar sobrevivem a ele, e alguns pioram, porque agora
a resposta errada chega com uma citação que a faz parecer conferida. As execuções desta própria aula já
mostraram quatro deles.

## Um documento que não devia ter sido encontrado

```
ana@lab:~/rag$ python tiny_rag.py "Who pays for the return postage?"
[1] 0.798  returns-policy-2025 > Return postage
[2] 0.530  returns-policy > How to start a return
[3] 0.502  shipping-and-delivery > Damage in transit
Return postage is paid by the customer. [1]
```

A pergunta é sobre as regras de hoje e a resposta é a de 2025: **o frete de devolução é grátis desde
fevereiro de 2026.** A busca não errou pela própria régua. A seção de 2025 se chama *Return postage* e
não fala de outra coisa, então sua similaridade com a pergunta, 0,798, vence a de *How to start a
return* do regulamento atual, 0,530, onde "Returns are free" é uma frase entre muitas.

O índice guarda o que quer que tenha sido posto nele, e não faz ideia de quais documentos estão em
vigor. Apagar o regulamento antigo é uma solução, e mantê-lo marcado como substituído é outra, porque
um atendente às vezes precisa saber o que foi prometido a um cliente em 2025. A aula 5 guarda o status
ao lado de cada pedaço, e a aula 14 faz a busca respeitá-lo.

## Duas fontes que discordam

A pergunta do prazo de devolução, na seção anterior, recebeu trinta dias de `[1]` e catorze dias de
`[2]`, numa resposta só. **Um gerador que recebe duas fontes contraditórias pode citar as duas,
escolher uma ao acaso, ou tirar uma média que nenhuma das duas diz.** O extract-1 cita as duas porque
sua regra copia as frases mais parecidas, digam elas o que disserem. A aula 7 mostra como um prompt diz
a um gerador qual fonte prevalece, e por que as datas têm de estar no prompt para isso funcionar.

## A resposta estava lá, e a resposta gerada não a pegou

A pergunta da expressa recuperou a seção com o preço e respondeu com uma frase sobre a expressa nunca
ser grátis. **A recuperação acertou e a geração errou.** Com um modelo real o mecanismo é outro, e as
chances também, mas a categoria é a mesma: o contexto tinha a resposta e o texto gerado não a usou. É a
falha que as pessoas mais culpam na busca, e um teste que só confere a resposta final não consegue
separar uma coisa da outra. A aula 8 mede recuperação e geração em separado exatamente por isso.

## Resposta nenhuma

```
ana@lab:~/rag$ python tiny_rag.py "Can I place an order by phone?"
[1] 0.453  shipping-and-delivery > Addresses
[2] 0.453  terms-of-sale > 2. Placing an order
[3] 0.358  shipping-and-delivery > Pickup points
The sources do not say.
```

Os documentos da Marginalia nunca falam de pedido por telefone, então esta é a resposta certa. Mas
repare que **a busca ainda devolveu três seções**: uma busca sempre devolve as três primeiras, prestem
elas ou não, e aqui a melhor marcou 0,453. A recusa veio do limiar do próprio extract-1, não da
recuperação. Um modelo real com essas três seções na frente poderia muito bem escrever alguma coisa
sobre pedidos assim mesmo. A aula 6 dá à busca seu próprio jeito de dizer que não achou nada bom, e a
aula 7 transforma "as fontes não dizem" numa instrução em vez de um acaso.

## E o que ela não alcança

Algumas perguntas não têm trecho que as responda, porque a resposta não está escrita em lugar nenhum e
tem de ser calculada. *Quantos dos nossos documentos falam de um limite de catorze dias?* *Qual
política mudou mais este ano?* *O que todas as nossas regras de devolução têm em comum?* Um sistema de
recuperação encontra alguns trechos; ele não lê o corpus inteiro. Perguntas sobre tudo, ou sobre
contagens e totais, pertencem a uma consulta ao banco de dados ou a um processamento em lote, e a aula 2
traça essa fronteira com exemplos.

O RAG também não faz um modelo raciocinar melhor. Com os trechos certos, um modelo que lê mal uma
tabela lê mal no prompt como leria em qualquer lugar. O que a recuperação garante é mais estreito e
ainda vale a pena: **o modelo lê o texto de que precisa, e quem lê a resposta consegue ver que texto
foi esse.**
