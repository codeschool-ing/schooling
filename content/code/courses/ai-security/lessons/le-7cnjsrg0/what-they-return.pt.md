---
title: O que um endpoint de moderação responde, e onde ele entra
version: 2
---

Um endpoint de moderação costuma ser imaginado como um sim ou não: você manda uma mensagem e ele diz
se ela é aceitável. **O que ele devolve é um score por categoria**, às vezes uma probabilidade entre
0 e 1, às vezes uma gravidade numa escala curta. Se uma mensagem é aceitável na sua plataforma é uma
decisão que o seu código toma a partir desses scores, com uma linha que você escolheu, e a linha é
onde está quase todo o trabalho desta aula.

Todo fornecedor dessa classe de produto responde mais ou menos nesse formato. O deste curso é um
substituto, o `moderation.py`, que a aula 5 lhe deu junto com o `guard moderate`, e **não é um modelo de
moderação**: é uma lista de palavras e expressões em inglês por categoria, cada uma com um peso que o
curso escolheu, combinadas num score que se comporta como um. O comentário no topo dele lista os erros
que ele comete de propósito. Ele responde assim:

```
ana@lab:~/guard$ guard moderate 'Shut up, you clown'
{"harassment": 0.84, "threat": 0.0, "spam": 0.0}
ana@lab:~/guard$ guard moderate 'Deliver tomorrow or you will regret it'
{"harassment": 0.0, "threat": 0.82, "spam": 0.0}
ana@lab:~/guard$ guard moderate 'Click here to claim your prize'
{"harassment": 0.0, "threat": 0.0, "spam": 0.84}
ana@lab:~/guard$ guard moderate 'He called me an idiot in the chat, can a moderator look?'
{"harassment": 0.9, "threat": 0.0, "spam": 0.0}
```

A última mensagem é a que vale guardar. Ela marca 0.9 para assédio, mais que o insulto do topo, e é
alguém pedindo ajuda. Uma lista de palavras não distingue um insulto do relato de um insulto. Um
classificador treinado acerta esse caso com muito mais frequência, e ainda erra alguns, em mensagens
que os seus usuários escrevem e ninguém testou.

## Três lugares para chamá-lo

Uma aplicação construída sobre um modelo tem três tipos de texto que valem ser enviados a um endpoint
de moderação, e cada um responde a um risco diferente:

| o que é verificado | quando | o risco a que responde |
|---|---|---|
| a mensagem do usuário, antes de o modelo vê-la | antes da chamada | abuso dirigido ao modelo, ou um pedido que a plataforma não atende |
| a resposta do modelo, antes de o usuário vê-la | depois da chamada | o modelo produzir algo que a plataforma não pode dizer |
| o que um usuário publica para outros | antes de ser mostrado | um usuário ferir outro, com a plataforma como meio |

Na Tarefa o fórum é o terceiro caso, e é o que esta aula mede. O segundo merece uma frase porque as
equipes o esquecem: **a saída do modelo é texto que a plataforma publica**, e um prompt de sistema que
diz *"nunca seja grosseiro"* é um pedido ao modelo, não uma garantia sobre o que ele escreve.

## As categorias são do fornecedor, a política é sua

As categorias de um fornecedor são feitas para muitos clientes ao mesmo tempo, e as regras da Tarefa
não vão bater exatamente com elas. A Tarefa proíbe passar um telefone para levar um trabalho para fora
da plataforma, o que nenhum produto de moderação tem como categoria; e pode tolerar uma linguagem
áspera entre dois freelancers discutindo kerning que um score geral de assédio marcaria. Então os
scores são entradas de uma política escrita na Tarefa, com um mapa de cada categoria para o que
acontece, e com as regras que o fornecedor não cobre aplicadas por outra coisa.

Os scores de duas categorias também não são comparáveis. Um 0.6 de spam e um 0.6 de ameaça vieram de
partes diferentes do classificador, treinadas com exemplos diferentes, e a linha certa de cada um é
achada separadamente. A próxima seção é como.
