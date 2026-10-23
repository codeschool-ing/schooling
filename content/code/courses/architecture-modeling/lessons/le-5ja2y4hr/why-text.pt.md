---
title: Por que escrever um diagrama como texto
version: 1
---

**Um diagrama escrito como texto é um arquivo-fonte que um programa transforma em imagem.** A fonte
pode ficar no repositório, ser revisada num pull request, ser comparada entre versões e ser
verificada por um build, que são exatamente as coisas que, segundo a aula 11, mantêm a documentação
viva e que o arquivo de uma ferramenta de desenho não faz bem.

## O que o texto dá

- **Um diff que dá para ler.** Quando alguém acrescenta o serviço de sincronização de embarque a um
  diagrama de contêineres desenhado numa ferramenta de diagramas, o pull request mostra que um
  arquivo binário mudou. Escrito como texto, ele mostra uma linha nova para o contêiner e uma para
  cada relação, que quem revisa consegue ler e questionar.
- **Um lugar só para o diagrama e o código.** A fonte fica em `docs/`, ao lado do código que
  descreve, muda no mesmo pull request e vem junto no checkout da versão que descreve.
- **Verificações.** Um build pode renderizar todos os diagramas e falhar quando um deles não é
  interpretado, como faz a seção desta aula sobre o pipeline. O arquivo de uma ferramenta de desenho
  quebra em silêncio.
- **Geração.** Texto pode ser produzido por um programa: uma lista de contêineres lida da
  configuração de implantação, a documentação de referência da aula 11 mantida verdadeira por ser
  gerada.

## O que custa

- **Menos controle sobre o layout.** A ferramenta posiciona as caixas. Na maior parte das vezes o
  resultado é bom o bastante; às vezes não é, e ajustar um layout automático é mais lento do que
  arrastar uma caixa.
- **Uma notação para aprender por ferramenta.** Cada ferramenta tem a sua sintaxe, e a pergunta da
  aula 1, *o leitor consegue ler?*, agora ganha uma irmã: *o autor consegue escrever?*
- **Uma ferramenta para instalar e manter numa versão.** Um diagrama que renderizava com uma versão
  pode sair diferente, ou falhar, na seguinte. É por isso que esta aula fixa cada versão.

## Três ferramentas, três ideias

| ferramenta | a ideia dela | no que ela é melhor |
| --- | --- | --- |
| **Mermaid** | uma sintaxe leve para diagramas comuns, desenhada no navegador | fluxos, sequências e estados num README; o GitHub e o GitLab desenham no próprio texto |
| **PlantUML** | uma sintaxe de texto completa para UML e mais | todos os diagramas UML da aula 2, com notação precisa |
| **Structurizr** | um **modelo** escrito uma vez, com **visões** derivadas dele | diagramas C4 que não podem discordar entre si |

A terceira é uma coisa de outro tipo. Mermaid e PlantUML descrevem **um diagrama por arquivo**: se a
API de passagens aparece em três diagramas, ela é escrita três vezes, e as três podem se afastar uma
da outra. O Structurizr descreve **o sistema uma vez** e pede visões dele, que é o ponto de vista e a
visão da aula 1, e o *um modelo, muitos diagramas* da aula 3, transformados em ferramenta.
