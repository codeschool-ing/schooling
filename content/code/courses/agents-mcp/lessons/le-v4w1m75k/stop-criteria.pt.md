---
title: Todos os jeitos de uma execução acabar
version: 2
---

Uma execução acaba por um entre poucos motivos, e o hospedeiro deveria saber qual. O `agent.py` distingue cinco, e cada um produz um resultado diferente:

| acaba porque | resultado | no `agent.py` |
|---|---|---|
| o modelo chamou `finish` | `answered`, com a resposta e suas fontes | o fim normal |
| o limite de passos foi atingido | `stopped`, com o motivo e uma passagem | `--max-steps` |
| o orçamento de tokens acabou | `stopped` | `--max-tokens` |
| o orçamento de tempo acabou | `stopped` | `--max-seconds` |
| o modelo respondeu sem chamar ferramenta nenhuma | `stopped`: `replied without calling finish` | uma resposta só de texto |

A guarda de laço da aula 3 acrescenta um sexto (a mesma chamada duas vezes), e um hospedeiro de produção acrescenta mais: um erro que o hospedeiro não consegue devolver ao modelo, um cliente que cancela, um operador que aperta parar.

## Por que uma ferramenta finish e não `end_turn`

As aulas 1 a 4 encerravam uma execução quando o modelo parava de pedir ferramentas, `stop_reason` diferente de `tool_use`, e tomavam o texto da resposta como a resposta. Isso funciona, e tem duas fraquezas. **Uma resposta sem chamada de ferramenta é ambígua**: pode ser uma resposta final, uma pergunta de volta ao cliente, ou um modelo que desistiu no meio do pensamento. E **uma resposta em texto não carrega estrutura**: nada de fontes, de confiança, de sinal de "passe isto a uma pessoa".

Uma ferramenta `finish` resolve as duas. A execução só acaba quando o modelo diz isso explicitamente, por uma chamada que o hospedeiro valida contra um esquema como qualquer outra: `answer` tem de ser uma string não vazia, `sources` uma lista. A primeira execução da seção 03 é essa conferência funcionando, numa resposta vazia. Uma resposta sem chamada nenhuma vira um resultado à parte, `stopped`, em vez de uma resposta por padrão. E o esquema pode ganhar campos de que o hospedeiro precisa, como `needs_human: true` para uma resposta de que o modelo não tem certeza, sem interpretar prosa.

## Um finish ao lado de outras chamadas

A execução de tokens da seção 04 acabou de um jeito que nenhuma das cinco linhas descreve bem: o modelo chamou duas ferramentas **e** `finish` numa só resposta. A resposta foi escrita antes de qualquer das ferramentas ter devolvido, então não podia se apoiar nelas, e não se apoiou; ela citou um livro que a loja não vende. O `agent.py` rodou as chamadas em ordem e retornou no `finish`, e a execução conta como `answered`. É a regra da aula 3 sobre ReAct em texto de novo, com outra cara: **uma resposta que chega junto com as ações de que depende foi escrita sem os resultados delas.** A correção é uma conferência no hospedeiro: uma resposta que chama `finish` e qualquer outra coisa recebe um erro para o `finish` (*"call finish on its own, after the results you need"*) e as outras chamadas rodam normalmente.

## Parar não é falhar

Dos cinco jeitos de acabar, quatro são `stopped`. É o desenho funcionando: **um limite que dispara é o hospedeiro fazendo o seu trabalho**, e o resultado da execução diz isso com clareza em vez de vestir um resultado parcial de resposta. O que a execução entrega quando para é o assunto da seção 06.
