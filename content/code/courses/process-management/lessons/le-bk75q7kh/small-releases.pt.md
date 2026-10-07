---
title: Histórias, o jogo do planejamento e releases pequenos
version: 1
---

As práticas de planejamento do XP são mais antigas que quase tudo o que os times Scrum usam hoje, e várias foram adotadas tão amplamente que as pessoas esquecem de onde vieram. A **história de usuário** é uma delas.

## A história

Uma história é um pedaço pequeno de comportamento que um usuário valorizaria, escrito num cartão em uma ou duas frases: *uma recepcionista consegue mudar uma consulta para outro dia sem cancelá-la*. O cartão não é uma especificação. Ron Jeffries descreveu uma história como três coisas, os **três Cs**: o *cartão* (card), que é um lembrete; a *conversa* entre quem vai construir e quem quer, que é onde o detalhe é decidido; e a *confirmação*, os testes que dizem quando está pronta.

O modelo popular — *como recepcionista, quero mudar uma consulta, para que o paciente mantenha seu lugar na fila* — veio depois, de times da Connextra por volta de 2001. Ele é útil porque obriga alguém a dizer quem se beneficia e por quê. É prejudicial quando a frase vira o requisito inteiro e a conversa nunca acontece.

## O jogo do planejamento

O XP divide o planejamento entre dois grupos com conhecimentos diferentes. **O cliente decide o que tem valor e em que ordem**; os desenvolvedores **estimam quanto cada história custa** e dizem quanto cabe na próxima iteração. Nenhum dos dois pode tomar a decisão do outro. Um cliente que diz quanto tempo uma história deveria levar, ou um desenvolvedor que decide qual funcionalidade importa mais, está quebrando o jogo. A divisão do Scrum entre o Product Owner, que ordena o backlog, e os Desenvolvedores, que preveem o que cabe numa Sprint, é a mesma regra com nomes novos.

O XP também queria o cliente **presente** — um usuário de verdade ou alguém que fale por ele, sentado com o time e respondendo perguntas no mesmo dia. Poucos times conseguem isso ao pé da letra. O princípio sobrevive como teste de quanto tempo um desenvolvedor espera por uma resposta: horas é saudável, semanas é como um time acaba construindo o que adivinhou.

## Releases pequenos

O XP libera software funcionando para usuários reais com a frequência que o negócio conseguir absorver, o que em 1999 queria dizer muito mais vezes que os projetos em volta. Cada release é o ciclo de feedback mais externo da figura desta aula — o momento em que o time inteiro descobre se o produto serve para alguma coisa. Quanto mais tempo entre releases, mais o time constrói sobre suposições que ninguém conferiu.

A prática tem uma pré-condição fácil de não ver: **um release precisa ser barato**. Se liberar exige um fim de semana de passos manuais, ninguém vai fazer isso com frequência. É por isso que releases pequenos dependem da integração contínua da seção anterior, e por isso a aula 13 mede com que frequência um time faz deploy como um dos quatro números principais.

## Ritmo sustentável

A primeira edição chamava isso de *semana de 40 horas*; a segunda chama de *trabalho energizado*. A regra é que o time trabalha só as horas que consegue sustentar, e que hora extra duas semanas seguidas é sinal de que o plano está errado, não de que as pessoas devem trabalhar mais. Ela fica junto do planejamento porque hora extra é como um plano ruim se esconde: a data é cumprida, o custo é pago em defeitos e em pessoas saindo, e ninguém revisa a estimativa que causou tudo.
