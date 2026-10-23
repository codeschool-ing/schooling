---
title: Que visão para que sala
version: 1
---

**A primeira decisão ao apresentar arquitetura é que visão mostrar, e quem decide isso é o que as
pessoas na sala decidem, não o que o arquiteto acha interessante.** A aula 1 disse que um diagrama
responde a uma pergunta. Uma apresentação é a mesma regra com uma plateia junto: a pergunta é dela,
então a visão tem de ser a que responde a ela.

## A semana depois da revisão

A revisão da aula 13 terminou numa sexta-feira. Na semana seguinte, Tainá teve de apresentá-la três
vezes:

| sala | quem | o que decidem | a visão que ela escolheu |
| --- | --- | --- | --- |
| **segunda, os diretores** | Celeste e os outros diretores | dinheiro, datas, o que a empresa arrisca no São João | o contexto de sistema da aula 3, com as 26 rodoviárias desenhadas como um elemento só e o segundo link marcado nele |
| **quarta, produto** | Otávio e os gerentes de produto | o que se constrói antes do pico, e o que espera | o contexto de novo, mais um diagrama dinâmico: a compra de um passageiro na manhã de maior movimento, numerada passo a passo |
| **quinta, engenharia** | os quarenta engenheiros | como as mudanças são construídas, e quem as constrói | o diagrama de containers, um diagrama de sequência de dois celulares enviando leituras de uma passagem, e a tabela de estados da aula 4 |

Nenhuma das três salas viu o diagrama que outra sala viu primeiro. Os diretores nunca viram um
container, e os engenheiros não precisaram que ninguém lhes explicasse o contexto. **Mostrar a visão
dos engenheiros aos diretores é o erro mais comum, e ele nasce do orgulho do arquiteto pelo desenho
detalhado**, que é aquele em que ele passou mais tempo.

## De onde vem a resposta

O curso já deu três maneiras de escolher:

- **Os níveis de zoom do C4** (aula 3): o contexto para qualquer pessoa, os containers para quem
  constrói ou opera o sistema, os componentes para o time dono de um container.
- **As linhas de Zachman** (aula 10): cada linha é uma plateia, do planejador no alto ao construtor
  embaixo. Uma linha diz o vocabulário, além do nível.
- **Os pontos de vista do ArchiMate** (aula 9): um ponto de vista é uma visão desenhada para a
  preocupação de um stakeholder, que é exatamente o problema de uma apresentação, já resolvido para
  um modelo.

As três concordam mais do que discordam. Quanto mais alto o nível das decisões do leitor, menos
caixas e menos tecnologia na página.

## Quando a sala é mista

Algumas salas têm um diretor e três engenheiros ao mesmo tempo. Dois hábitos ajudam:

- **Comece no nível mais alto de que alguém na sala precisa**, e desça um nível só na parte em que a
  decisão se apoia. Os engenheiros acompanham o contexto; o diretor não acompanha os containers.
- **Diga em voz alta para que nível você está indo**, *agora um nível abaixo, dentro do sistema de
  venda de passagens*, para que quem não precisa daquilo saiba que pode deixar passar.

Adaptar uma mensagem a uma plateia em geral, além dos diagramas, é a aula 3 de
`architect-communication`, mais adiante nesta trilha. Esta aula fica no que é próprio da
arquitetura: o modelo, suas visões e sua notação.
