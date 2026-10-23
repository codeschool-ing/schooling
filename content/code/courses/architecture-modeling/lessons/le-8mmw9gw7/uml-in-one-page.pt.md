---
title: A UML numa página
version: 1
---

**A UML, Unified Modeling Language, é um conjunto padronizado de tipos de diagrama para descrever
software, com um significado preciso para cada forma e cada ponta de seta.** Quem a mantém é o
Object Management Group (OMG); a versão atual, 2.5.1, saiu em 2017, e uma versão anterior também é
norma ISO. Ela define catorze tipos de diagrama. Esta aula precisa de cinco deles, e a aula 4 de
mais dois.

A UML nasceu nos anos 1990, quando três notações orientadas a objetos populares, as de Grady Booch,
James Rumbaugh e Ivar Jacobson, foram fundidas numa só. Essa história explica o tamanho dela: foi
feita para descrever tudo o que um projeto orientado a objetos pode conter, e a maioria dos times
usa uma parte pequena.

## Estrutura e comportamento

Os catorze tipos se dividem em duas famílias. **Diagramas de estrutura** mostram o que existe e como
se relaciona, sem levar o tempo em conta. **Diagramas de comportamento** mostram o que acontece:
quem faz o quê, em que ordem, e como algo muda de estado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l02-family\" aria-label=\"Os catorze tipos de diagrama da UML em duas famílias. Diagramas de estrutura: classes, componentes, implantação, objetos, pacotes, estrutura composta e perfil. Diagramas de comportamento: casos de uso, atividade, máquina de estados, e quatro diagramas de interação: sequência, comunicação, visão geral de interação e tempo. Em destaque, os cinco que esta aula desenha, classes, componentes, implantação, casos de uso e sequência, e os dois que a aula 4 desenha, atividade e máquina de estados.\"><text x=\"360.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">UML 2.5.1: catorze tipos de diagrama</text><rect x=\"20.0\" y=\"34.0\" width=\"300.0\" height=\"230.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"340.0\" y=\"34.0\" width=\"360.0\" height=\"230.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Estrutura</text><text x=\"520.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Comportamento</text><rect x=\"27.0\" y=\"68.0\" width=\"136.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"95.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Classes</text><rect x=\"177.0\" y=\"68.0\" width=\"136.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"245.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Componentes</text><rect x=\"27.0\" y=\"112.0\" width=\"136.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"95.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Implantação</text><rect x=\"177.0\" y=\"112.0\" width=\"136.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"245.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Objetos</text><rect x=\"27.0\" y=\"156.0\" width=\"136.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"95.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Pacotes</text><rect x=\"177.0\" y=\"156.0\" width=\"136.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"245.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Estrutura composta</text><rect x=\"27.0\" y=\"200.0\" width=\"136.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"95.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Perfil</text><rect x=\"352.0\" y=\"68.0\" width=\"156.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"430.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Casos de uso</text><rect x=\"352.0\" y=\"112.0\" width=\"156.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"430.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Atividade</text><rect x=\"352.0\" y=\"156.0\" width=\"156.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"430.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Máquina de estados</text><rect x=\"518.0\" y=\"66.0\" width=\"172.0\" height=\"186.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"604.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">Interação</text><rect x=\"526.0\" y=\"92.0\" width=\"156.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"604.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Sequência</text><rect x=\"526.0\" y=\"130.0\" width=\"156.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"604.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Comunicação</text><rect x=\"526.0\" y=\"168.0\" width=\"156.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"604.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Visão geral de interação</text><rect x=\"526.0\" y=\"206.0\" width=\"156.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"604.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Tempo</text><rect x=\"120.0\" y=\"278.0\" width=\"22.0\" height=\"12.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"150.0\" y=\"284.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">desenhados nesta aula</text><rect x=\"380.0\" y=\"278.0\" width=\"22.0\" height=\"12.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"410.0\" y=\"284.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">desenhados na aula 4</text></svg>", "caption": "Sete dos catorze fazem quase todo o trabalho em documentos de arquitetura. Os outros sete valem ser reconhecidos e raramente valem ser desenhados."}
```

Os cinco desenhados nesta aula são os cinco que aparecem o tempo todo em documentos de arquitetura.
Mais dois, o diagrama de atividades e o diagrama de máquina de estados, são o assunto da aula 4. Os
outros existem por bons motivos e são mais raros: um diagrama de objetos mostra as instâncias de um
momento, um diagrama de tempo mostra sinais contra um relógio, e um perfil estende a própria UML.

## Três jeitos de usar

Martin Fowler, em *UML Distilled*, separou três jeitos de usar a UML, e a maioria das discussões
sobre se vale a pena aprendê-la é gente falando de jeitos diferentes:

| | o que é | quem faz |
| --- | --- | --- |
| **UML como esboço** | diagramas parciais que comunicam uma ideia; corretos onde importa, soltos no resto | a maioria dos arquitetos, na maior parte do tempo |
| **UML como planta** | diagramas completos, detalhados o bastante para um programador construir a partir deles | times em ambientes regulados ou cheios de contratos |
| **UML como linguagem de programação** | modelos detalhados o bastante para gerar o programa | algumas ferramentas e domínios especializados |

**Este curso usa a UML como esboço.** Isso não quer dizer descuido: um esboço continua usando a
notação corretamente, porque um losango na ponta errada de uma linha diz o contrário do que se
queria, e quem conhece UML vai ler o que você desenhou, e não o que você quis dizer. Quer dizer que
você desenha só o que a pergunta precisa e deixa todo o resto de fora.

## Rigorosa em poucos lugares

A UML é tolerante com a disposição e muito rigorosa com algumas marcas. Quatro delas mudam o
sentido por completo e valem ser aprendidas antes de qualquer outra coisa:

- **pontas de seta**: um triângulo cheio, uma ponta aberta e um triângulo vazado são três coisas
  diferentes na UML, como mostram os diagramas de sequência e de classes desta aula;
- **estilo da linha**: linha contínua e linha tracejada são relações diferentes;
- **a ponta em que o símbolo fica**: um losango ou um triângulo diz qual lado é o todo, ou qual lado
  é o pai;
- **aspas angulares**: palavras entre `«aspas angulares»`, chamadas estereótipos ou palavras-chave,
  mudam o que uma forma significa, como `«include»` e `«device»` vão mudar.

O resto desta aula pega os cinco diagramas um de cada vez, cada um com a venda de passagens da
Carcará como exemplo, e mostra cada um desenhado certo e depois desenhado errado.
