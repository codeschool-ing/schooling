---
title: Como o método dá errado
version: 1
---

Os quatro passos são simples de dizer e fáceis de pular. As formas de pular são poucas, e vale conhecê-las
pelo nome:

| o que acontece | por que custa | o passo que pula |
|---|---|---|
| consertar antes de ver o defeito | você pode consertar algo que não estava quebrado, e não o que estava | reproduzir |
| confiar no diagnóstico do usuário, "é a rede" | um palpite, por mais seguro, não é uma observação | reproduzir, isolar |
| mudar várias coisas de uma vez | o defeito vai embora e ninguém sabe qual mudança o levou | testar |
| uma checagem que muda alguma coisa | o resultado seguinte não quer mais dizer o que parece | isolar |
| declarar consertado da própria mesa | funciona para você e não para a pessoa | confirmar |
| fechar sem anotar a causa | o mesmo defeito é diagnosticado de novo do zero | confirmar |

**Um defeito que vai e volta** é o caso mais difícil, porque o passo 1 falha no dia em que você olha. O
método não muda; a evidência muda. Peça a hora de cada ocorrência, deixe rodando uma checagem que registre
quando falha, e compare o que estava diferente nesses momentos. A aula 3 dá as camadas a comparar, e a
aula 7 diz quando passar adiante.
