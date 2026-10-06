---
title: O que roda, e quando
version: 1
---

As aulas 13 e 14 montaram dois tipos de verificação: a integridade do próprio conjunto, e a comparação
de uma candidata com a produção. Rodadas à mão, cada uma depende de alguém lembrar de rodá-la, no dia em
que importa, que é o dia em que alguém está com pressa. Ligá-las à **integração contínua** faz com que
rodem em toda mudança que possa precisar delas, e faz uma falha parar o merge em vez de aparecer numa
mensagem que ninguém lê.

Nem tudo deve rodar em todo commit, porque as verificações custam quantias muito diferentes:

| Camada | O que roda | Chama modelo? | Quando |
| --- | --- | --- | --- |
| o conjunto | ids, hash do manifesto, fatos nas seções gold, documentos nas versões fixadas, dados pessoais | não | toda mudança no conjunto, nos documentos ou nos testes |
| a regressão | produção e candidata respondem ao conjunto; casos quebrados, verificações novas falhando, orçamentos | sim, duas vezes por caso | toda mudança que possa alterar uma resposta |
| as lentas | divisão reservada, métricas avaliadas por juiz, uma olhada nas respostas que mudaram | sim, mais | antes de um lançamento, ou toda noite |

**A primeira camada não custa nada e nunca deve ser pulada.** É o `check_set.py` da aula 13 em forma de
testes, e ela falha em segundos quando alguém faz commit de um conjunto que não bate com o manifesto, ou
de um caso com o nome de um cliente.

**A segunda camada custa dinheiro a cada execução.** Na aula 14 o conjunto inteiro custou menos de cinco
centavos de dólar para responder, nos preços do laboratório, para a candidata mais cara. O dobro disso
por pull request é barato perto de uma versão que quebra cinco perguntas, e ainda assim é uma conta: o
gatilho tem de ser as mudanças que podem alterar uma resposta, não toda edição num README.

**A terceira camada é onde as pessoas entram**: a divisão reservada roda quando uma candidata está pronta,
e as respostas que mudaram são lidas, como a aula 14 pediu. Um pipeline pode agendar isso; não pode fazer
a leitura.

O resto desta aula monta as duas primeiras camadas como testes de pytest, roda-as nas candidatas da aula
14, e mostra o workflow que as roda num pull request.
