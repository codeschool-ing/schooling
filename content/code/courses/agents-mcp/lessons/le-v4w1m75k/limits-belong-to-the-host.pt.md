---
title: Os limites pertencem ao hospedeiro
version: 1
---

Todo limite do `agent.py` é uma variável Python: `max_steps`, `max_tokens`, `max_seconds`. Nenhum deles é mencionado ao modelo, e nada do que o modelo escreve pode mudá-los. **Esta seção é sobre essa regra: um limite que o modelo vê é conselho; um limite que o modelo pode mudar não é limite.**

Três desenhos tentadores a quebram:

- **O limite no prompt.** "Você tem cinco passos; pare depois disso." O modelo pode contar, ou não; ele não tem noção confiável de quantos pedidos foram mandados, e uma conversa longa empurra a instrução para longe. Dizer ao modelo o orçamento dele pode ajudá-lo a planejar, como dica. Nunca substitui o contador do hospedeiro.
- **O limite como argumento de ferramenta.** Uma ferramenta `continue_working(extra_steps: 10)`, ou um esquema de plano com campo `max_steps`, deixa o modelo se dar mais espaço sempre que isso parecer útil, que é exatamente quando um modelo em laço acha que é.
- **O limite na conversa.** Um cliente que escreve "leve o tempo que precisar" não mudou o orçamento do hospedeiro, e um artigo de ajuda que diz "agentes podem rodar até 100 passos" também não. Texto que chega por mensagens e resultados de ferramenta é dado (aula 3), e um orçamento é configuração.

## Onde os números devem morar

Em código ou configuração que a implantação controla e o modelo nunca lê: uma constante, uma variável de ambiente, um ajuste por tipo de tarefa. Este repositório faz a mesma distinção para os próprios parâmetros. O `CLAUDE.md` pede que um valor com resposta certa more no código, onde um teste o segura, e que nada que enfraqueça uma proteção vire um botão que alguém gira para cima numa tarde inconveniente. O limite de passos de um agente é uma proteção exatamente desse tipo: às vezes aumentá-lo é certo, e isso deveria exigir uma mudança deliberada de uma pessoa, não uma frase numa conversa.

## O que o modelo pode saber

Dizer ao modelo quanto espaço ele tem é inofensivo e às vezes útil: "você pode fazer umas cinco chamadas de ferramenta" o ajuda a escolher menos buscas, mais amplas. A linha está entre **informar** o modelo sobre um limite e **delegar** o limite a ele. Informar muda como ele planeja; o contador no hospedeiro decide quando ele para.
