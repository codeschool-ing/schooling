---
title: Cenários, e os casos dentro deles
version: 1
---

As palavras *cenário* e *caso* costumam ser usadas como se fossem a mesma coisa, e numa conversa
apressada podem ser. Num conjunto de testes elas fazem trabalhos diferentes. **Um cenário de teste
é uma frase dizendo o que precisa ser testado; um caso de teste diz como**, com o estado, os dados,
os passos e o resultado. *Um membro reserva ingressos* é um cenário. O TC-BOOK-01 é um dos casos
que o testam.

## Por que escrever os cenários primeiro

Um cenário custa uma frase, e um caso custa dez minutos. Essa diferença é o motivo para escrever os
cenários primeiro. Uma lista de quinze cenários cabe em meia página, e a gerente do teatro a lê em
cinco minutos e responde a única pergunta que importa nessa fase: **está faltando alguma coisa?**
Fazer essa pergunta a cem casos prontos é tarde demais, porque o esforço já foi para o que estava
lá.

Cenários também vêm nas palavras do usuário, e não nas do testador. *Alguém reserva ingressos para
o espetáculo de hoje uma hora antes de começar* é um cenário que a gerente reconhece na hora, e a
gerente é quem sabe que isso acontece todo sábado. Ninguém precisa saber o que é uma pré-condição
para dizer que falta um cenário.

A norma de documentação de teste chama a etapa anterior ao caso de **condição de teste**, um item
ou evento que pode ser conferido por um ou mais casos. Muitos times dizem cenário para a mesma
coisa, e este curso também.

## Um cenário, vários casos

Um cenário vira tantos casos quantos forem os resultados diferentes que valem conferir. *Alguém
cria uma conta* vira pelo menos dois: um em que a conta é criada, e outro em que ela é recusada
porque o endereço de e-mail já pertence a alguém.

Esses dois tipos têm nome. **Um caso positivo** confere que a aplicação faz o que deve com uma
entrada que deve aceitar; às vezes é chamado de caminho feliz. **Um caso negativo** confere que a
aplicação recusa o que deve recusar, e recusa do jeito que os requisitos dizem. O R7 pede que o
boxoffice responda a uma entrada errada com uma frase dizendo o que está errado, então todo caso
negativo do boxoffice tem um resultado esperado com esse formato.

**Um caso negativo não é um caso que falha.** O TC-SIGNUP-02, escrito na seção 04, tenta criar uma conta
com um endereço de e-mail que já está em uso. O resultado esperado dele é uma recusa, então ele
passa quando o boxoffice recusa, e falha se o boxoffice criar uma segunda conta com o mesmo
endereço. A entrada é negativa; o veredito está tão em aberto quanto o de qualquer outro.

## Os cenários do R2 ao R4

Esta aula testa cadastro, confirmação e reserva, que são o R2, o R3 e o R4 da lista da aula 1.
Quatro cenários os cobrem, e a terceira coluna traz os casos que a seção 04 escreve:

| cenário | requisito | casos |
|---|---|---|
| SC-01 Alguém cria uma conta | R2 | TC-SIGNUP-01, TC-SIGNUP-02 |
| SC-02 Uma conta nova é confirmada pelo e-mail | R3 | TC-CONFIRM-01, TC-CONFIRM-02 |
| SC-03 Alguém com conta reserva ingressos | R4 | TC-BOOK-01, TC-BOOK-02 |
| SC-04 Um visitante novo se cadastra, confirma e reserva com preço de membro | R2, R3, R4, R5 | TC-SIGNUP-01, TC-CONFIRM-01, TC-BOOK-03 |

O SC-04 é um **cenário de ponta a ponta**: ele acompanha uma pessoa por várias funcionalidades, na
ordem em que ela as usaria. Na maior parte reaproveita casos que os outros cenários já exigem e
acrescenta um, o TC-BOOK-03, porque a reserva do visitante novo é o único lugar onde confirmar uma
conta muda um preço. Cenários de ponta a ponta encontram os defeitos que moram entre as
funcionalidades, onde cada uma funciona sozinha e a passagem de uma para outra não.

## O que esses quatro deixam de fora

Quatro cenários não testam o R2 ao R4 por completo, e uma lista que finge o contrário é a lacuna
contra a qual a aula 1 alertou. Três coisas ficam de fora desta aula de propósito.

**Que valores errados tentar.** Um nome de 41 caracteres, uma senha de 7, uma quantidade de 0 ou de
7 ou a palavra *two*: cada um é um caso negativo. Escolher quais dos infinitos valores errados
valem um caso é uma técnica à parte. A aula 4 é essa técnica.

**A segunda metade do R3.** Um link válido por 24 horas, e um link novo que faz o antigo parar de
funcionar, exigem tempo passando ou um segundo e-mail chegando. A aula 22 trata de testar e-mail,
e esses casos são escritos lá.

**O horário.** O R4 fecha as reservas uma hora antes do espetáculo. A seção 04 da aula 3 mostra por
que um caso que mexe com o relógio precisa dizer a que horas é executado.

Registrar as omissões é o que as transforma em decisões. Quando a gerente lê esta lista, ela vê que
nomes de 41 caracteres ainda não estão aqui, e por quê.
