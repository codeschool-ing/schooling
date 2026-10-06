---
title: O que a biblioteca cliente fez
version: 1
---

O `mcp_host.py` decidiu a política dele; o `Client` do SDK `mcp` cuidou do protocolo. Vale saber o que é de quem, porque cada um é um lugar onde um defeito pode se esconder.

**O que o `Client` fez sem ninguém pedir:**

- **Escolheu a revisão.** O modo padrão dele, `auto`, sonda o `server/discover` primeiro e cai para o handshake `initialize` num servidor legado, que é o que o hospedeiro da OpenAI da aula 11 mostrou no fio.
- **Rodou o laço de várias idas e voltas.** Quando o `refunds` respondeu `input_required`, o `call_tool` chamou o `server_asks`, repetiu com a resposta e o `requestState` selado, e devolveu o resultado final. Ele para depois de um número fixo de rodadas (`input_required_max_rounds`), então um servidor que continuasse perguntando não prenderia a chamada para sempre.
- **Guardou listas em cache.** Ele respeita as dicas `ttlMs` e `cacheScope` dos servidores; com `ttlMs: 0`, como estes servidores mandam, nada é reaproveitado.

**O que ele declarou, por causa do que o hospedeiro lhe deu:** `elicitation`, já que o `server_asks` existe. Ele não declarou **sampling**, porque o hospedeiro não lhe deu `sampling_callback`: um servidor conectado a este hospedeiro não consegue pedir ao modelo do hospedeiro que escreva texto. É uma escolha com motivo. Sampling deixa um servidor gastar o modelo do hospedeiro com os próprios prompts, e está obsoleto na revisão 2026-07-28; um hospedeiro que não precisa dele não deve oferecê-lo.

**O que o hospedeiro ainda teve de escrever:** tudo da tabela da aula 12. Que variáveis um servidor herda, como as ferramentas são nomeadas, o que o modelo fica sabendo sobre a origem de uma ferramenta, que chamadas precisam de uma pessoa, que recursos o modelo pode levar a serem lidos, e o que fica registrado. Nada disso está no protocolo, e nada disso estava na biblioteca.
