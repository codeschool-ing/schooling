---
title: De um artigo a todo agente
version: 1
---

A aula 29 do `prompt-engineering` apresentou o ReAct como formato de prompt: o modelo escreve uma linha `Thought:`, depois uma linha `Action:` nomeando uma ferramenta, o programa acrescenta uma linha `Observation:` com o resultado da ferramenta, e o ciclo se repete até um `Answer:`. Esta aula parte desse formato e o roda como código. **O formato é a parte fácil; o que quebra é o encanamento em volta**, e é isso que as próximas sete seções desmontam.

## O que o artigo fez de fato

*ReAct: Synergizing Reasoning and Acting in Language Models* (Yao e colegas, 2022; publicado na ICLR 2023) testou a ideia em dois tipos de tarefa. Em responder perguntas e checar fatos (HotpotQA e FEVER), as únicas ferramentas do modelo eram três ações sobre a Wikipédia: `search[entity]`, `lookup[string]` e `finish[answer]`. Em tarefas interativas (ALFWorld, um jogo de texto de tarefas domésticas, e WebShop, uma loja online simulada), as ações eram movimentos no ambiente.

O resultado era sobre a combinação. Raciocinar sozinho, cadeia de pensamento sem ferramentas, inventava fatos que podia ter consultado. Agir sozinho, chamadas de ferramenta sem raciocínio escrito, perdia o rumo em tarefas longas. **Intercalar os dois deixava cada pensamento dizer o que faltava e cada observação corrigir o pensamento seguinte**, e deixava um rastro que uma pessoa conseguia ler para ver onde uma execução desandou.

## O que mudou desde então

O modelo do artigo não sabia nada de ferramentas; tudo acontecia em texto puro, e uma expressão regular achava as ações. Depois os fornecedores embutiram a chamada de ferramentas nas APIs: o pedido carrega definições de ferramentas em JSON Schema, e a resposta traz uma chamada estruturada em vez de uma linha `Action:` (a aula 4 é sobre esses esquemas). **O laço é o mesmo laço**; o que mudou é quem interpreta a ação. No ReAct em texto, a sua expressão regular faz isso, e ela pode ler errado. Com chamadas nativas, o fornecedor devolve os argumentos já em JSON, conferidos contra o esquema que o pedido declarou.

Então esta aula roda os dois. As seções 03 e 04 rodam o ReAct em texto, porque ele mostra cada peça às claras e uma falha que as chamadas nativas tornam mais rara. A seção 05 roda a mesma tarefa com chamadas nativas, que é como todo agente a partir da aula 7 é construído.
