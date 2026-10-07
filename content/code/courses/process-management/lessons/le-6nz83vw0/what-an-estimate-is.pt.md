---
title: Uma estimativa, uma meta e um compromisso
version: 1
---

"Quanto tempo vai levar?" parece uma pergunta. Em geral são três, e a maior parte do estrago que estimativas fazem vem de responder uma enquanto quem pergunta ouve outra. *Software Estimation*, de Steve McConnell (2006), as separa, e vale aprender a separação antes de qualquer técnica.

- Uma **estimativa** é uma previsão de quanto tempo algo vai levar ou quanto vai custar. É uma afirmação sobre o mundo, e pode estar certa ou errada.
- Uma **meta** é uma afirmação do que o negócio quer: *precisamos do agendamento online antes da renovação anual dos contratos das clínicas, em maio*. É um desejo, e pode ser razoável ou não.
- Um **compromisso** é uma promessa de entregar um trabalho definido até uma data, com um nível de qualidade.

A sequência que funciona é o negócio declarar uma meta, o time produzir uma estimativa, e as duas serem comparadas. Se a estimativa cabe na meta, o time pode se comprometer. Se não cabe, alguém muda o escopo, a data ou os recursos, e o time se compromete com o que sobrou. A sequência que falha é aquela em que a meta é rebatizada em silêncio de estimativa: *"a estimativa é maio, porque é quando precisamos"*. Nada no trabalho mudou; só a palavra.

## Por que as estimativas erram para um lado

Estimativas de trabalho de software não erram ao acaso. Elas erram **sobretudo para baixo**, e os motivos são bem documentados. Daniel Kahneman e Amos Tversky deram nome à **falácia do planejamento** em 1979: as pessoas estimam as próprias tarefas imaginando como o trabalho vai correr, e um plano imaginado não tem interrupção, doença, requisito mal entendido nem dependência que chega atrasada. Douglas Hofstadter pôs a experiência numa piada que também é lei: *sempre leva mais tempo do que você espera, mesmo quando você leva em conta a lei de Hofstadter*.

O remédio que funciona melhor não é se esforçar mais para imaginar. É **usar o que aconteceu da última vez**, que é o que a estimativa por analogia e a estimativa paramétrica, as próximas duas seções, fazem.

## Como é uma boa estimativa

Uma boa estimativa tem três partes: **uma faixa ou uma probabilidade**, não um número único; **as suposições** em que se apoia; e **quando foi feita**, porque o cone da incerteza da aula 1 diz que uma estimativa feita antes de os requisitos serem conhecidos é mais larga que uma feita depois. "Entre 18 e 26 dias úteis, com 85% de confiança, supondo que o ambiente de testes do provedor de pagamento esteja disponível desde a primeira semana, em 2 de março" é uma boa estimativa. "Três semanas" é um número que vai ser lembrado como promessa.
