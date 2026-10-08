---
title: O que a recuperação não conserta
version: 2
---

O RAG é vendido como a cura para um modelo que inventa coisas, e ele cura uma doença específica: o
modelo não ter o texto. Todos os outros jeitos de errar sobrevivem a ele, e alguns pioram, porque agora
a resposta errada chega com uma citação que a faz parecer conferida. Quatro deles importam desde o
primeiro dia, e as execuções desta própria aula mostram três.

## Um documento que não devia ter sido encontrado

```
ana@vm:~/rag$ python tiny_rag.py "Who pays for the return postage?"
[1] 0.798  returns-policy-2025 > Return postage
[2] 0.530  returns-policy > How to start a return
[3] 0.502  shipping-and-delivery > Damage in transit
According to [1], the customer pays for the return postage.
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

Para o prazo de devolução, o regulamento atual e o substituído foram os dois recuperados, por um fio de
diferença, e o modelo tirou a resposta do atual. Para o frete de devolução o regulamento substituído
ficou em primeiro e o modelo tirou a resposta dele. **Um gerador que recebe duas fontes que se
contradizem pode citar uma, citar as duas, ou misturá-las em algo que nenhuma diz, e nenhuma daquelas
duas escolhas foi uma decisão.** Nada no prompt dizia qual fonte vale, então nada podia decidir. A aula
7 mostra como um prompt diz a um gerador qual fonte ganha, e por que as datas têm de estar no prompt
para isso funcionar.

## A resposta estava lá, e a resposta gerada não a pegou

A recuperação pode pôr na frente do modelo a seção com a resposta e a resposta gerada ainda assim
citar a frase errada dela, ou responder uma pergunta um pouco ao lado da que foi feita. **A
recuperação acertou e a geração falhou.** Isso não aconteceu nas execuções desta aula, e é comum o
bastante para que um teste só da resposta final não baste: um teste assim culpa a busca pelo erro do
redator, ou o contrário. A aula 8 mede recuperação e geração em separado exatamente por isso.

## Resposta nenhuma

```
ana@vm:~/rag$ python tiny_rag.py "Can I place an order by phone?"
[1] 0.453  terms-of-sale > 2. Placing an order
[2] 0.453  shipping-and-delivery > Addresses
[3] 0.358  shipping-and-delivery > Pickup points
According to the provided sources, the answer is:

No, you cannot place an order by phone. The sources do not mention phone orders as a valid method of placing an order.

There is no explicit statement that prohibits phone orders, but the provided information focuses on online ordering through the website, and the process of placing an order is described in the context of online transactions.
```

Os documentos da Marginalia nunca falam de pedido por telefone, então a resposta certa é que eles não
dizem. **A busca mesmo assim devolveu três seções**: uma busca sempre devolve as suas três melhores,
sejam elas boas ou não, e aqui a melhor marcou 0,453. E o modelo, diante de três seções que não
respondem a pergunta, respondeu mesmo assim. A resposta dele é uma regra, *you cannot place an order
by phone*, que ninguém na Marginalia escreveu, e duas frases depois ele admite que nada proíbe isso. Um
cliente lê a primeira. A aula 6 dá à busca um jeito próprio de dizer que não achou nada bom, e a aula
7 transforma "as fontes não dizem" numa instrução contra a qual o modelo é testado.

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
