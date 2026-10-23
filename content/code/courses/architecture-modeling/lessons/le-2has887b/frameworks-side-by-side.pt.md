---
title: Os frameworks clássicos lado a lado
version: 1
---

**Os frameworks das aulas 1 a 10 ficam mais fáceis de separar quando são alinhados pelo tipo de
coisa que cada um é, para que serve e em que escala trabalha.** Esta seção é a comparação que as
três últimas aulas vinham preparando.

| framework | tipo de coisa | escala | sua ideia central | aula |
| --- | --- | --- | --- | --- |
| **Zachman** | ontologia | empresa | seis perguntas para seis públicos; toda descrição tem uma célula | 10 |
| **TOGAF** | método, com framework de conteúdo | empresa | o ciclo ADM, da visão à mudança governada | 8 |
| **IAF** | taxonomia e abordagem | empresa e solução | por quê, o quê, como, com o quê, nessa ordem | 9 |
| **ArchiMate** | notação | empresa | uma linguagem tipada que cobre negócio, aplicação e tecnologia | 9 |
| **FEAF, DoDAF, NAF** | modelos de referência e pontos de vista | governo e defesa | descrições que muitas partes conseguem combinar | 9 |
| **4+1** | conjunto de pontos de vista | um sistema | quatro visões conferidas por cenários | 1 |
| **C4** | abstrações e diagramas | um sistema | quatro níveis de zoom com palavras fixas | 3 |
| **UML** | notação | um sistema | diagramas precisos de estrutura e comportamento | 2 |
| **arc42** | modelo de documentação | um sistema | doze seções que cobrem a arquitetura de um sistema | 11 |
| **ISO/IEC/IEEE 42010** | norma para descrições de arquitetura | qualquer uma | stakeholders, preocupações, pontos de vista e visões | 1 |

## Três perguntas que os separam

Quando aparece um framework novo, três perguntas o situam depressa:

1. **É um método, uma taxonomia, uma notação ou um modelo de documento?** A distinção da aula 9.
   Dois do mesmo tipo competem; dois de tipos diferentes costumam se combinar.
2. **Para que escala ele é?** Um framework corporativo aplicado a um serviço produz papelada; um
   framework de sistema aplicado a uma empresa deixa de fora a camada de negócio.
3. **Qual é a sua ideia?** Todo framework que durou tem uma. Se você não consegue dizê-la numa frase,
   ainda não entendeu o framework, e provavelmente nem quem o está recomendando.

## Eles concordam mais do que discordam

Alinhados, os frameworks repetem as mesmas poucas coisas com palavras próprias:

- **separar os públicos**: as linhas de Zachman, os stakeholders da 42010, os níveis do C4, as
  visões do 4+1;
- **separar o porquê do quê, do como e do com o quê**: de novo as linhas de Zachman, os níveis do
  IAF, os blocos de construção do TOGAF, o *o quê, não como* da aula 6;
- **ligar cada decisão ao seu motivo**: a ordem do IAF, a gestão de requisitos do TOGAF, os
  registros da aula 5 e a matriz da aula 6.

**Um arquiteto com esses três hábitos consegue trabalhar dentro de qualquer um desses frameworks em
uma semana.** Quem conhece o vocabulário dos frameworks sem os hábitos vai produzir os documentos e
perder o sentido, que é o resultado contra o qual as aulas 8 e 9 alertaram.
