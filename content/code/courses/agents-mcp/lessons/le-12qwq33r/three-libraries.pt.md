---
title: Três bibliotecas, lado a lado
version: 1
---

As aulas 8, 9 e 10 rodaram o mesmo agente, as mesmas ferramentas e o mesmo reembolso em três bibliotecas. Elas concordam no vocabulário (um agente é um modelo, instruções e ferramentas; uma execução é um laço; uma pessoa pode ser posta na frente de uma chamada) e divergem em quase todo padrão:

| | OpenAI Agents SDK (aula 8) | Claude Agent SDK (aula 9) | Google ADK (aula 10) |
|---|---|---|---|
| onde o laço roda | no seu processo | no CLI do Claude Code, um subprocesso | no seu processo |
| uma ferramenta é | uma função decorada | um `@tool` num servidor MCP no processo | uma função simples |
| o resultado vai como | texto, via `str()` | o texto que a ferramenta escreveu | um objeto JSON |
| uma ferramenta levanta erro | uma frase genérica de "tente de novo" | não testado na aula 9 | a execução termina, a menos que um callback responda |
| ferramentas embutidas oferecidas | nenhuma | as vinte do Claude Code, a menos que `tools=[]` | nenhuma |
| uma pessoa aprova | `needs_approval`, estado salvo e retomado | `can_use_tool`, enquanto a execução espera | `require_confirmation`, entre duas execuções |
| uma regra antes de qualquer pessoa | um guardrail, em volta do agente | um hook `PreToolUse` | um `before_tool_callback` |
| rastros por padrão | mandados aos servidores da OpenAI | não tratado aqui | não tratado aqui |

**Nenhum desses padrões está errado**, e cada um foi uma surpresa para alguém. A escolha entre as bibliotecas é sobretudo sobre o fornecedor que você já usa, já que cada uma é moldada em volta da API e das ferramentas do próprio fornecedor, e sobre quanto do laço você quer controlar. O que as três aulas têm em comum é o método: rodar a biblioteca contra algo que você consegue observar, ler o que ela mandou, e decidir cada padrão de propósito em vez de herdá-lo.

Esse método é também o motivo da aula 7. Cada linha da tabela é uma decisão que o `minagent` tomou numa linha que dá para ler, e saber onde cada decisão mora é o que torna legível a versão dela numa biblioteca.

As próximas seis aulas tratam de algo que as três bibliotecas já encontraram: as ferramentas da aula 9 eram um servidor MCP, o ADK recebe ferramentas MCP pelo `McpToolset`, e o SDK da OpenAI pelas classes `MCPServer`. O **MCP** é o protocolo que deixa um agente usar ferramentas que outra pessoa escreveu, e é onde as perguntas sobre quem pode chamar o quê, com que dados, deixam de ficar dentro de um programa só.
