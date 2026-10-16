---
title: Conflito com produto, e discordar e se comprometer
version: 1
---

O conflito mais frequente de uma gestora de engenharia é com produto: o que construir em seguida, quanto
tempo vai para manutenção, quanto risco é aceitável por uma data. **É um conflito saudável entre duas
preocupações legítimas**, e ele fica nocivo quando qualquer um dos lados trata a preocupação do outro
como obstáculo, e não como informação.

## A Helena e a lista de espera

A Helena, gerente de produto do Agenda, queria a funcionalidade de lista de espera da aula 4 estendida a
consultas em grupo, para uma grande rede de clínicas que o time de vendas estava perto de fechar. Pediu
em quatro semanas. O Diego disse que o código de agendamento precisava de um mês de refatoração antes de
qualquer outra coisa ser construída em cima dele, porque dois incidentes recentes tinham vindo dele.

Os dois tinham razão sobre a própria preocupação. A rede de clínicas era dinheiro de verdade. Os
incidentes eram risco de verdade. **Nenhuma das preocupações podia ser descartada, e nenhuma das pessoas
enxergava com clareza a da outra**, que é o estado habitual desse tipo de discordância.

## Tornar o trade-off visível

O primeiro movimento da Renata foi pôr as duas preocupações numa página, em números quando possível: a
receita que vendas esperava da rede, e o custo dos dois incidentes em horas e reclamações de clínicas,
com a estimativa do Diego da probabilidade de outro. Ela também trouxe um acordo que o Agenda tinha feito
com a Helena no trimestre anterior e escrito na página da aula 2: mais ou menos um quinto da capacidade
do time vai para manutenção e confiabilidade, decidida pelas pessoas engenheiras, sem precisar ser
defendida a cada vez.

Com as duas na página, a conversa mudou. A Helena conseguiu ver que a refatoração não era preferência de
engenheiro, mas um risco para as mesmas clínicas a que ela estava vendendo. O Diego conseguiu ver que a
rede não era capricho. Combinaram uma versão: a refatoração do único módulo que as consultas em grupo
iam tocar, duas semanas, depois a funcionalidade, mais quatro. A Helena disse a vendas seis semanas em
vez de quatro.

## Discordar e se comprometer

Às vezes o trade-off está visível e as pessoas continuam discordando. Um dos princípios de liderança da
Amazon diz isso em poucas palavras, discordar e se comprometer: defenda a sua posição por inteiro enquanto
a decisão está aberta e, uma vez tomada, comprometa-se com ela por inteiro, mesmo que ainda ache que está
errada. A ideia é mais antiga que a Amazon; Andy Grove descreveu algo parecido na Intel.

A segunda metade é a parte difícil. **Se comprometer não é dizer sim na reunião e depois trabalhar devagar,
levantar objeções a cada passo ou contar ao time que foi uma decisão ruim.** Isso é sabotagem passiva, e é
pior que discordância aberta porque ninguém consegue tratá-la.

Neste caso o Diego continuava achando que o código de agendamento inteiro precisava de refatoração, não
um módulo, e disse isso com clareza na reunião. Uma vez tomada a decisão, ele planejou as duas semanas de
modo que o módulo ficasse melhor do que ele tinha pedido, e não mencionou a refatoração maior de novo até
o planejamento do trimestre seguinte, onde defendeu a posição dele do jeito certo. É assim que se
comprometer se parece.

## Quando a gestora discorda da decisão

O mesmo vale para a gestora. Se a Helena e o Otávio tivessem decidido por quatro semanas e nenhuma
refatoração, contra o conselho da Renata, o trabalho dela seria garantir que o risco ficasse escrito, e
depois entregar a decisão como sendo do time, do jeito que a aula 7 descreveu um "não" vindo de cima.
**Uma gestora que diz ao time "eu argumentei contra isso" transforma toda decisão de cima em algo a que o
time pode resistir**, e a aula 24 trata de por que essa posição, no meio, é tão difícil de sustentar.
