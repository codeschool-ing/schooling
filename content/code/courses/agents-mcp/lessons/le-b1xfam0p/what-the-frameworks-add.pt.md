---
title: O que os frameworks acrescentam
version: 1
---

O `minagent` tem o laço, as ferramentas, os limites, as guardas, o rastro e os testes. Os SDKs de agente das próximas três aulas têm tudo isso, com outros nomes, e uma lista de coisas que o `minagent` não tem. Saber o que é o quê é o motivo de tê-lo escrito.

| `minagent` | o que um SDK costuma acrescentar |
|---|---|
| `@tool` a partir de dicas de tipo | o mesmo, mais modelos Pydantic para argumentos aninhados e descrições geradas |
| um adaptador, o protocolo da Anthropic | adaptadores para muitos fornecedores, muitas vezes por uma interface comum |
| `Agent.run`, síncrono | execuções assíncronas, fluxo de tokens e eventos conforme acontecem |
| um rastro JSONL | rastreamento para um painel hospedado, spans por chamada de modelo e de ferramenta, exportação OpenTelemetry |
| a conversa vive por uma execução | **sessões**: histórico guardado entre execuções, em memória, num arquivo ou num banco |
| nenhuma passagem | passagens e agentes como ferramentas como objetos de primeira classe (aula 6) |
| um callback `confirm` para escritas | modos de permissão, ganchos antes e depois de cada ferramenta, fluxos de aprovação |
| nada | **guardrails**: verificações da entrada e da saída que rodam ao lado do agente e podem pará-lo |
| nada | clientes MCP embutidos, para que ferramentas venham de servidores MCP (aulas 11 a 16) |
| nada | ambientes hospedados: publicar o agente como serviço gerenciado |

## O que eles escondem

A mesma lista lida ao contrário: cada acréscimo é um lugar onde o laço faz algo que você não escreveu. Um SDK que repete uma chamada de ferramenta que falhou, compacta a conversa quando ela cresce ou resume turnos anteriores está tomando decisões sobre custo e correção em seu nome. **Nada disso está errado; tudo isso vale saber.** As perguntas a fazer a qualquer SDK, que as aulas 8 a 10 fazem a três:

- Onde está o laço, e consigo definir o limite de passos?
- Como a falha de uma ferramenta chega ao modelo: como resultado, ou como exceção?
- O que vai num rastro, e para onde ele vai? (Alguns SDKs mandam rastros ao fornecedor por padrão.)
- O que uma execução devolve quando para?
- Como ponho uma pessoa na frente de uma escrita?

Uma equipe que responde isso sobre o SDK dela está usando o SDK. Uma que não responde está sendo usada por ele, e vai descobrir no dia em que uma execução fizer algo que ninguém consegue explicar.
