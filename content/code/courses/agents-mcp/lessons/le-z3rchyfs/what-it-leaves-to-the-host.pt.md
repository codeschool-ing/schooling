---
title: O que ele deixa para o hospedeiro
version: 1
---

O servidor descreveu o `get_order` uma vez. Tudo o que veio depois, os três hospedeiros decidiram de jeitos diferentes, e o protocolo deixou:

- **O nome que o modelo vê.** O hospedeiro do Claude renomeou a ferramenta para `mcp__shop__get_order`; os hospedeiros da OpenAI e do Google passaram `get_order` adiante. O prefixo faz com que dois servidores que oferecem um `get_order` não se confundam; passar o nome adiante o mantém curto. De um jeito ou de outro, a escolha é do hospedeiro.
- **O rigor do esquema.** O hospedeiro da OpenAI mandou `"strict": false` para esta ferramenta, enquanto as ferramentas de função da aula 8 foram com `"strict": true`.
- **Com que frequência a lista é buscada.** O cliente do hospedeiro da OpenAI pediu a lista de ferramentas duas vezes numa execução:

```
ana@lab:~/agents$ python -c 'import json; [print(json.loads(l)["method"]) for l in open("openai.in.jsonl")]' | sort | uniq -c
      1 server/discover
      1 tools/call
      2 tools/list
```

  uma vez antes de cada pedido ao modelo, para que um servidor cujas ferramentas mudaram entre turnos fosse notado. O SDK da OpenAI tem a opção `cache_tools_list` para buscá-la uma vez só; a revisão 2026-07-28 acrescenta `ttlMs` aos resultados de lista para que um servidor diga por quanto tempo a resposta continua válida.
- **Quanto a descrição é confiável.** O hospedeiro do Google embrulhou a descrição do servidor entre `<<<BEGIN_UNTRUSTED_TOOL_DESCRIPTION>>>` e `<<<END_UNTRUSTED_TOOL_DESCRIPTION>>>` antes de o modelo vê-la, como mostra a captura da seção 02. Os outros dois a passaram como estava escrita.

Este último merece uma frase só dele. **A descrição de uma ferramenta é texto escrito por quem escreveu o servidor, e o modelo a lê como orientação.** Um servidor que o hospedeiro não escreveu pode dizer qualquer coisa numa descrição, inclusive coisas dirigidas ao modelo e não a uma pessoa lendo a lista. O ADK marca o texto como não confiável; marcar não faz o modelo ignorá-lo, mas diz ao modelo de quem são aquelas palavras. A aula 17 trata disso como um risco a testar, contra o próprio laboratório deste curso, e a defesa é do hospedeiro: a que servidores ele se conecta, que ferramentas expõe, e o que pergunta a uma pessoa antes de uma chamada.

E acima de tudo isso ficam as decisões em que o MCP nem toca: **que modelo**, **o laço**, **que chamadas precisam de uma pessoa**, **o que o agente pode fazer com um resultado**. Um servidor não pode dar permissão a si mesmo. Um hospedeiro que se conecta a um servidor e deixa o modelo chamar toda ferramenta sem olhar tomou uma decisão; só não a tomou de propósito.
