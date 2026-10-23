---
title: Escolhendo uma ferramenta, e quando não usar nenhuma
version: 1
---

**As três ferramentas se sobrepõem menos do que parece.** O Mermaid é para diagramas que moram onde
as pessoas leem Markdown; o PlantUML é para UML precisa; o Structurizr é para modelos C4 em que
várias visões precisam concordar. A maioria das equipes acaba com duas delas.

| você precisa de | use | porque |
| --- | --- | --- |
| um fluxo ou uma máquina de estados num README | Mermaid | o GitHub e o GitLab desenham sem ferramenta nenhuma, ao lado do código |
| um diagrama de sequência com fragmentos, em UML exata | PlantUML | ele segue de perto a notação da aula 2 |
| um diagrama de classes, de componentes ou de implantação em UML | PlantUML | o Mermaid cobre alguns deles, com menos precisão |
| diagramas de contexto, de contêineres e de componentes que precisam concordar | Structurizr | um modelo, várias visões |
| um diagrama para uma apresentação à diretoria | uma ferramenta de desenho | o layout e a ênfase importam mais que os diffs, e ele não é mantido |

## Com o que o Carcará ficou

- **Structurizr** para o modelo C4 de passagens e embarque, no repositório de arquitetura, com as
  visões exportadas para Mermaid e renderizadas no pipeline;
- **Mermaid** dentro dos READMEs dos serviços, para o fluxo ou os dois fluxos que cada equipe quer ao
  lado do seu código;
- **PlantUML** para os diagramas de sequência nos documentos de design e nos registros de decisão,
  onde as pontas de seta importam;
- **uma ferramenta de desenho** para a apresentação trimestral à diretoria, desenhada do zero a cada
  vez a partir do modelo e não guardada, o que a aula 14 discute.

Por escrito, isso é um registro de decisão: ADR-0021, *Diagramas como texto, por tipo*.

## Quando o texto é a ferramenta errada

O texto perde onde o layout é a mensagem. Um diagrama feito para convencer, com uma posição pensada
para cada caixa e um caminho destacado, fica melhor desenhado à mão, e **melhor não guardado**: é um
slide, feito para uma reunião, e as regras da aula 11 sobre páginas mortas valem para ele no dia
seguinte. O teste da aula 1 continua decidindo: **quem lê, e que pergunta ele responde?** Se o leitor
é quem revisa um pull request, use texto. Se é uma diretoria decidindo um orçamento, use o que deixar
mais claro o único ponto.
