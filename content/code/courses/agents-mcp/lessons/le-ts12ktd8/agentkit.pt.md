---
title: AgentKit, a metade hospedada
version: 1
---

A OpenAI apresentou o **AgentKit** em outubro de 2025 como um conjunto de produtos hospedados para construir agentes na plataforma dela, com o **Agents SDK**, uma biblioteca Python de código aberto, por baixo. Os dois se confundem fácil porque dividem o vocabulário de agentes, e são coisas de tipos diferentes: um roda nos servidores da OpenAI e é usado por um navegador e uma API; o outro roda no seu programa.

Como a OpenAI os descreveu no lançamento, as peças hospedadas eram:

| peça | para que serve |
|---|---|
| **Agent Builder** | uma tela visual para desenhar um fluxo de agente como nós ligados (agentes, ferramentas, condições, guardrails), testá-lo com prévias e publicar versões; um fluxo pode ser exportado como código do Agents SDK |
| **ChatKit** | uma interface de chat embutível, para um produto pôr um agente diante dos usuários sem construir o front-end |
| **Connector Registry** | a lista, mantida por um administrador, das fontes de dados e servidores MCP a que os agentes de uma organização podem se conectar |
| acréscimos ao **Evals** | conjuntos de dados, avaliação de rastros inteiros e otimização de prompts, para medir um agente e não uma resposta solta |

**Nada disso pôde rodar neste curso.** O laboratório não alcança fornecedor nenhum (aula 1, seção 07), e esses produtos só existem na plataforma da OpenAI, atrás de uma conta e de uma fatura. Então esta seção os descreve e o resto da aula não volta a eles. Os produtos também mudam no ritmo da plataforma, não no da biblioteca: nomes, o que está em beta e o que está disponível para todos já mudaram desde o lançamento, e este curso não tem como dizer o que mudou depois de escrito. **Leia a documentação atual da OpenAI antes de confiar em qualquer detalhe da tabela.**

## O que se aproveita

O que não envelhece é a forma. Um construtor visual desenha o mesmo grafo que a aula 6 desenhou em código: um agente passa a vez a outro, um nó decide um caminho, um guardrail fica na frente de um passo. Um fluxo exportado de um construtor é código do Agents SDK, então a biblioteca é a parte que vale conhecer bem, e é a parte que roda aqui.

A troca entre os dois é a que a aula 7 discutiu para frameworks em geral. Um construtor hospedado começa rápido, é fácil de mostrar a quem não escreve código, e prende o agente à plataforma, aos preços e ao tratamento de dados de um fornecedor. A biblioteca mantém o laço no seu processo e no seu repositório, onde ele pode ser testado como o da aula 7, revisado num pull request e levado para outro lugar.
