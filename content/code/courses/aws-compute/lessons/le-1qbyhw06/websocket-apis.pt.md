---
title: "WebSocket APIs: rotas, conexões e dois medidores"
version: 1
---

Uma REST API ou uma HTTP API responde; ela nunca fala primeiro. Um navegador que quer saber quando
o pedido 42 sai precisa perguntar de novo e de novo. **Uma WebSocket API mantém uma conexão aberta
por cliente e deixa qualquer um dos lados mandar uma mensagem a qualquer momento.** Quem segura as
conexões é o API Gateway, não o seu backend: uma função roda quando uma mensagem chega e manda uma
mensagem chamando um endereço que nomeia a conexão. Nada seu fica rodando entre uma mensagem e
outra.

## Rotas escolhidas pela mensagem

Uma WebSocket API tem rotas como uma HTTP API, mas uma mensagem não tem método nem caminho para
comparar. Então a **expressão de seleção de rota** aponta para dentro da mensagem. A mais comum lê
um campo do corpo JSON:

```
ana@laptop:~/aws$ aws apigatewayv2 create-api --name chat --protocol-type WEBSOCKET --route-selection-expression '$request.body.action' --query "{ApiId: ApiId, ApiEndpoint: ApiEndpoint, RouteSelectionExpression: RouteSelectionExpression}"
{
    "ApiId": "tnftvxnn",
    "ApiEndpoint": "https://tnftvxnn.execute-api.sa-east-1.amazonaws.com",
    "RouteSelectionExpression": "$request.body.action"
}
ana@laptop:~/aws$ WS=$(aws apigatewayv2 get-apis --query "Items[?Name==\`chat\`].ApiId" --output text)
ana@laptop:~/aws$ WINT=$(aws apigatewayv2 create-integration --api-id "$WS" --integration-type AWS_PROXY --integration-uri "$FN" --query IntegrationId --output text)
ana@laptop:~/aws$ for r in '$connect' '$disconnect' '$default' send; do aws apigatewayv2 create-route --api-id "$WS" --route-key "$r" --target "integrations/$WINT" --query RouteKey --output text; done
$connect
$disconnect
$default
send
ana@laptop:~/aws$ aws apigatewayv2 create-stage --api-id "$WS" --stage-name prod --query StageName --output text
prod
```

`$FN` é a função `orders` da seção anterior, reaproveitada só para ter algo para onde apontar; um
chat de verdade teria uma função própria. Na AWS o cliente se conecta a
`wss://tnftvxnn.execute-api.sa-east-1.amazonaws.com/prod`; o moto imprime a forma `https` do mesmo
endereço. As quatro rotas são as quatro maneiras de alcançar uma função:

- `$connect` roda uma vez, quando um cliente abre a conexão. É o lugar de verificar quem é o
  cliente, e uma função que responde a ela com qualquer coisa que não seja sucesso recusa a
  conexão.
- `$disconnect` roda uma vez, depois que a conexão fechou, de qualquer lado. É um aviso, não um
  pedido: o cliente já foi embora, e a AWS a documenta como melhor esforço.
- `send` roda para toda mensagem cujo corpo tem `"action": "send"`, porque é isso que a expressão
  de seleção lê.
- `$default` roda para toda mensagem que não casa com nenhuma outra rota, inclusive uma que nem é
  JSON.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 322\" role=\"img\" aria-label=\"Uma conexão WebSocket ao longo do tempo, em três raias: o cliente, o API Gateway e uma função. O cliente conecta e o API Gateway chama a rota $connect. Uma mensagem com action send vai para a rota send, e uma sem action vai para $default. A função chama post-to-connection e o API Gateway empurra a mensagem ao cliente. O cliente fecha e $disconnect roda. Embaixo, três mensagens marcadas, e uma barra da conexão ao fechamento para os minutos de conexão.\"><defs><marker id=\"ws-ah-p\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"ws-ah-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"16\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\" font-weight=\"600\">cliente</text><path d=\"M16 48 L704 48\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"16\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\" font-weight=\"600\">API Gateway</text><path d=\"M16 140 L704 140\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"16\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\" font-weight=\"600\">função</text><path d=\"M16 232 L704 232\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M110 52 L110 134\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ws-ah-p)\"></path><path d=\"M110 144 L110 226\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ws-ah-a)\"></path><text x=\"116\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">conecta</text><text x=\"116\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">$connect</text><path d=\"M230 52 L230 134\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ws-ah-p)\"></path><path d=\"M230 144 L230 226\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ws-ah-a)\"></path><text x=\"236\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">{&quot;action&quot;:&quot;send&quot;}</text><text x=\"236\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">send</text><path d=\"M360 52 L360 134\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ws-ah-p)\"></path><path d=\"M360 144 L360 226\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ws-ah-a)\"></path><text x=\"366\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">{&quot;text&quot;:&quot;hi&quot;}</text><text x=\"366\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">$default</text><path d=\"M480 228 L480 146\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ws-ah-a)\"></path><path d=\"M480 136 L480 54\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ws-ah-p)\"></path><text x=\"486\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">envio</text><text x=\"486\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">post-to-connection</text><path d=\"M610 52 L610 134\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ws-ah-p)\"></path><path d=\"M610 144 L610 226\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ws-ah-a)\"></path><text x=\"616\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">fecha</text><text x=\"616\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">$disconnect</text><circle cx=\"230\" cy=\"268\" r=\"4.5\" fill=\"var(--amber)\"></circle><circle cx=\"360\" cy=\"268\" r=\"4.5\" fill=\"var(--amber)\"></circle><circle cx=\"480\" cy=\"268\" r=\"4.5\" fill=\"var(--amber)\"></circle><text x=\"16\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mensagens, em qualquer sentido</text><rect x=\"110\" y=\"288\" width=\"500\" height=\"12\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"310\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">minutos de conexão, da conexão ao fechamento</text></svg>", "caption": "Uma conexão, cinco momentos. A rota é escolhida a cada mensagem pela expressão de seleção; o backend fala primeiro chamando o endereço da conexão. Os dois medidores correm: um conta as mensagens, o outro os minutos em que a conexão ficou aberta.", "same": ["API Gateway"]}
```

## Uma conexão tem um id, e o backend o usa

Toda conexão recebe um **connection id**, que chega em `requestContext.connectionId` de todo evento
que a função recebe. Uma função que quer alcançar um cliente mais tarde guarda esse id em algum
lugar, e uma tabela do DynamoDB é a escolha comum, e o apaga no `$disconnect`. Para mandar, o
backend envia para a conexão pela API Gateway Management API:

```
ana@laptop:~/aws$ aws apigatewaymanagementapi post-to-connection --connection-id L0SM9cOFvHcCIhw= --cli-binary-format raw-in-base64-out --data '{"text": "order 42 shipped"}'; echo "exit status $?"
exit status 0
ana@laptop:~/aws$ aws apigatewaymanagementapi get-connection --connection-id L0SM9cOFvHcCIhw= --query Identity
{
    "SourceIp": "192.168.0.1",
    "UserAgent": "Moto Mocks"
}
```

**Ninguém nunca abriu `L0SM9cOFvHcCIhw=`.** É um id inventado para o exemplo, e o moto aceitou a
mensagem e depois descreveu a conexão, inventando um endereço e um user agent para ela. A AWS
responde às duas chamadas com `GoneException`, status `410`, porque não existe essa conexão. Esse
`410` não é um caso raro em produção: é como um backend descobre que um cliente fechou a aba e o
aviso de `$disconnect` ainda não foi processado, então quem envia trata isso apagando o id
guardado e seguindo em frente. Na AWS o comando também precisa de
`--endpoint-url https://tnftvxnn.execute-api.sa-east-1.amazonaws.com/prod`, o endereço da própria
API com o stage; aqui o `AWS_ENDPOINT_URL` o manda para o moto.

Dois limites da documentação da AWS moldam todo cliente. Uma conexão dura **duas horas no máximo**,
e uma que não carrega nada por **dez minutos** é fechada por ociosidade. Um cliente que precisa
ficar conectado por um dia de trabalho, portanto, manda alguma coisa de vez em quando e reconecta
quando a conexão cai, e o backend guarda o id novo que vem com ela.

## Dois medidores

A tabela imprimiu os dois em 16 de outubro de 2026: **1,55 USD por milhão de mensagens** e
**0,388 USD por milhão de minutos de conexão**. As mensagens são contadas nos dois sentidos e em
passos de 32 KB, então uma mensagem de 70 KB conta como três. Os minutos correm enquanto uma conexão
estiver aberta, diga-se algo ou não.

A página de pedidos da Ana mantém 2.000 clientes conectados por 8 horas por dia em 22 dias úteis.
Os minutos são 2.000 × 8 × 60 × 22 = 21.120.000, ou seja, 21,12 milhões × 0,388 = 8,19 USD. Se uma
mudança de status chega a cada cliente uma vez a cada cinco minutos, são 96 mensagens por dia cada
um, e 2.000 × 96 × 22 = 4.224.000 mensagens, ou seja, 4,224 milhões × 1,55 = 6,55 USD. O mês custa
cerca de 14,74 USD.

A comparação que vale fazer é com polling. Para ver uma mudança em até cinco segundos sem
WebSocket, cada página perguntaria a uma HTTP API a cada cinco segundos: 5.760 requisições por dia
cada uma, então 2.000 × 5.760 × 22 = 253.440.000 requisições, e 253,44 milhões × 1,59 = 402,97 USD.
**O polling paga por toda pergunta; um WebSocket paga por toda resposta que tem algo dentro**, mais
uma cobrança pequena pelo tempo em que espera. A diferença some quando as atualizações são tão
frequentes quanto o polling teria sido, porque aí toda mensagem é paga de qualquer jeito.
