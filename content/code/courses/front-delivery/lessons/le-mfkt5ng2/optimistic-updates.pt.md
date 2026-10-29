---
title: Atualizações otimistas, e como desfazê-las
version: 1
---

**Uma atualização otimista desenha o resultado de uma mudança antes de o servidor confirmá-la, e um
cliente que mantém o cache consegue desfazê-la quando o servidor recusa.** O planner da aula 9 já
desenhava primeiro e gravava depois, e quando a gravação falhava a tela ficava errada. Com o Apollo, o
`optimisticResponse` faz o próprio cache mudar na hora, numa camada separada, e o Apollo remove essa camada
quando a resposta de verdade chega: substituída pela resposta do servidor se a mutation funcionou,
descartada se ela falhou.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Uma linha do tempo de uma atualização otimista que falha. Apertar Mark done acrescenta na hora uma camada otimista ao cache, e a linha mostra done. A mutation chega ao proxy, que responde 502 porque o servidor caiu. O Apollo descarta a camada otimista, o cache responde como antes, e a linha volta a mostrar o botão.\"><line x1=\"40\" y1=\"100\" x2=\"690\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"690.0,100.0 682.6,103.1 682.6,96.9\" fill=\"var(--wire)\"></polygon><text x=\"690\" y=\"86\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tempo</text><rect x=\"30\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">clique</text><line x1=\"90\" y1=\"80\" x2=\"90\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"90\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Mark done</text><rect x=\"190\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"250\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">camada otimista</text><line x1=\"250\" y1=\"80\" x2=\"250\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"250\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">done: true</text><rect x=\"370\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"430\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o proxy responde</text><line x1=\"430\" y1=\"80\" x2=\"430\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"430\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">502</text><rect x=\"540\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">camada descartada</text><line x1=\"600\" y1=\"80\" x2=\"600\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"600\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">done: false</text><rect x=\"170\" y=\"140\" width=\"340\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"340\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">a linha mostra done</text><rect x=\"530\" y=\"140\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o botão voltou</text></svg>", "caption": "A resposta otimista fica numa camada própria, então uma recusa a remove e a verdade anterior do cache volta a aparecer."}
```

## Vendo falhar

Inicie os dois servidores de novo, o GraphQL e o `npm run dev` do planner, e abra o curso de JavaScript.
Depois pare o servidor GraphQL com Ctrl-C e aperte **Mark done** na sessão de 15 de outubro. A linha vira
*done* na hora. O terminal do Vite diz por que isso não pode durar:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.0 dev
> vite


  VITE v8.3.5  ready in 380 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
9:38:26 PM [vite] (client) [optimizer] scanning dependencies...
9:38:28 PM [vite] http proxy error: /graphql
Error: connect ECONNREFUSED 127.0.0.1:4000
    at TCPConnectWrap.afterConnect [as oncomplete] (node:net:1637:16)
```

O proxy não conseguiu chegar ao servidor e respondeu à página com um 502, e o Apollo transformou isso num
erro da mutation. **Um instante depois a linha está com o botão de volta**: o Apollo descartou a camada
otimista, o cache respondeu como antes do clique, e o `watchPlanner` desenhou isso. O console do navegador
tem a mensagem do planner, *Could not save*, com o `ServerError` do Apollo e o código de status.

Ninguém escreveu código para desfazer o clique. O `done` do próprio planner mudou a lista dele, e a
resposta do cache, desenhada depois, devolveu o que o servidor ainda guarda. **O cache é a verdade à qual
a tela volta.**

## O que a pessoa vê

Uma linha que volta atrás sem explicação é honesta, mas pouco amigável. Um app de verdade diz alguma coisa
quando desfaz uma mudança: um aviso curto perto da linha, *não foi salvo, tente de novo*. O planner só
registra o erro, e a aula 11 manda o que o console diz para um lugar onde alguém que cuida do planner vai
ver, que é a outra metade do mesmo problema.

## Quando não ser otimista

Uma atualização otimista acerta quando o servidor quase sempre concorda e a mudança é fácil de desfazer:
marcar uma sessão como feita, curtir um post. Ela erra quando falhar é comum ou quando desenhar sucesso
antes engana: um pagamento, uma reserva com vagas limitadas, qualquer coisa que mande um e-mail. Ali, uma
tela que espera o servidor e diz que está esperando é a correta.
