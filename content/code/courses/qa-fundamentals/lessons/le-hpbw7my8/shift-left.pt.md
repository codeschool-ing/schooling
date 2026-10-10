---
title: Shift left, e o que ele não quer dizer
version: 1
---

**"Shift left" é o nome que o setor deu à conclusão desta aula.** Desenhe o ciclo de vida da esquerda para
a direita, requisitos primeiro e produção por último, e o teste tradicionalmente fica perto da ponta
direita. Deslocá-lo para a esquerda quer dizer fazer o trabalho de qualidade mais cedo: revisar
requisitos, testar enquanto o código é escrito, envolver quem testa desde a primeira conversa sobre uma
funcionalidade. A expressão foi cunhada por Larry Smith em 2001, e hoje está em quase todo anúncio de vaga
para a área.

É uma boa ideia, e costuma ser mal entendida de três jeitos.

## Não quer dizer testar menos no fim

Um time que desloca o teste para a esquerda ainda testa o produto pronto. O que muda é que menos defeitos
chegam até lá, então o teste do fim acha menos e leva menos tempo. Um time que "desloca para a esquerda"
tirando o teste final não deslocou nada; parou de detectar.

## Não quer dizer que quem testa faz tudo mais cedo

Deslocar para a esquerda leva o trabalho de qualidade para mais cedo para o **time todo**. O Rafael
escrevendo um teste antes de escrever a regra de preço é shift left. A Joana respondendo "maiores de 60,
ou a partir de 60?" antes de a sprint começar também é. A parte da Lia muitas vezes é fazer a pergunta,
não fazer o trabalho, e a aula 5 argumenta que quem testa e tenta fazer sozinho todo o trabalho de
qualidade vira o gargalo atrás do qual o resto do time espera.

## Não quer dizer que todo defeito pode ser achado cedo

Alguns defeitos só existem quando pessoas reais usam o sistema real. Quantos clientes compram na noite de
estreia de um sucesso, o que um celular lento numa conexão fraca faz com o mapa de assentos, que combinação
de descontos alguém de fato tenta: essas coisas se descobrem em produção ou não se descobrem. **Shift
right** é o nome da prática complementar: monitorar, observar o uso real, liberar para poucos clientes
antes de liberar para todos, e conseguir desfazer uma mudança rápido. Um defeito achado em produção sai
mais barato quando é achado na primeira hora do que na quinta semana, que é a mesma curva de novo,
desenhada depois da entrega.

## O trabalho cedo também não é de graça

As seções anteriores fazem achar defeito cedo parecer lucro puro. Não é. Revisar todo requisito custa o
tempo de quem revisa; um teste escrito antes do código custa tempo numa funcionalidade que pode ser
cancelada semana que vem. **A pergunta nunca é "dá para achar mais cedo?", que quase sempre é sim, e sim
"vale a pena achar mais cedo?"**, e as quatro coisas que crescem, da segunda seção, são como você responde.

Um defeito com pouca coisa construída em cima, que pouca gente encontraria, fácil de corrigir quando quer
que seja achado, pode ser pego tarde sem problema. Um requisito sobre o qual os próximos três meses de
trabalho vão ser construídos merece uma hora de três pessoas antes de alguém escrever uma linha. A aula 20
transforma esse julgamento num método para decidir o que testar primeiro.

## O que esta aula deixa com você

A curva é real na forma e pouco confiável nos números; argumente pelo mecanismo. Quatro coisas crescem
entre um erro e sua descoberta: o que se constrói em cima dele, quem topa com ele, quem ainda lembra dele e
por quantos passos uma correção passa. E o defeito mais barato é o parado numa frase, e é por isso que a
próxima aula é sobre como quem testa lê, pensa e duvida.
