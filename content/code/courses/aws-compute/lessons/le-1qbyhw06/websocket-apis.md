---
title: "WebSocket APIs: routes, connections and two meters"
version: 1
---

A REST or HTTP API answers; it never speaks first. A browser that wants to know when order 42
ships has to ask again and again. **A WebSocket API keeps one connection open per client and lets
either side send a message at any moment.** API Gateway holds the connections, so your backend
does not: a function runs when a message arrives and sends a message by calling an address that
names the connection. Nothing of yours stays running between messages.

## Routes chosen by the message

A WebSocket API has routes like an HTTP API, but a message has no method and no path to match
against. So the **route selection expression** points inside the message instead. The usual one
reads a field of the JSON body:

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

`$FN` is the `orders` function from the previous section, reused only to have something to point
at; a real chat would have a function of its own. On AWS the client connects to
`wss://tnftvxnn.execute-api.sa-east-1.amazonaws.com/prod`; moto prints the `https` form of the
same address. The four routes are the four ways a function is reached:

- `$connect` runs once, when a client opens the connection. It is the place to check who the
  client is, and a function that answers it with anything but a success refuses the connection.
- `$disconnect` runs once, after the connection has closed, from either side. It is a notice
  rather than a request: the client is already gone, and AWS documents it as best effort.
- `send` runs for every message whose body has `"action": "send"`, because that is what the
  selection expression reads.
- `$default` runs for every message that matches no other route, including one that is not JSON
  at all.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 322\" role=\"img\" aria-label=\"A WebSocket connection over time, in three lanes: the client, API Gateway and a function. The client connects and API Gateway calls the $connect route. A message with action send goes to the send route, and one with no action goes to $default. The function calls post-to-connection and API Gateway pushes the message to the client. The client closes and $disconnect runs. Below, three messages are marked, and a bar runs from connect to close for the connection minutes.\"><defs><marker id=\"ws-ah-p\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"ws-ah-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"16\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\" font-weight=\"600\">client</text><path d=\"M16 48 L704 48\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"16\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\" font-weight=\"600\">API Gateway</text><path d=\"M16 140 L704 140\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"16\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\" font-weight=\"600\">function</text><path d=\"M16 232 L704 232\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M110 52 L110 134\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ws-ah-p)\"></path><path d=\"M110 144 L110 226\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ws-ah-a)\"></path><text x=\"116\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">connect</text><text x=\"116\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">$connect</text><path d=\"M230 52 L230 134\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ws-ah-p)\"></path><path d=\"M230 144 L230 226\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ws-ah-a)\"></path><text x=\"236\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">{&quot;action&quot;:&quot;send&quot;}</text><text x=\"236\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">send</text><path d=\"M360 52 L360 134\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ws-ah-p)\"></path><path d=\"M360 144 L360 226\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ws-ah-a)\"></path><text x=\"366\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">{&quot;text&quot;:&quot;hi&quot;}</text><text x=\"366\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">$default</text><path d=\"M480 228 L480 146\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ws-ah-a)\"></path><path d=\"M480 136 L480 54\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ws-ah-p)\"></path><text x=\"486\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">push</text><text x=\"486\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">post-to-connection</text><path d=\"M610 52 L610 134\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ws-ah-p)\"></path><path d=\"M610 144 L610 226\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ws-ah-a)\"></path><text x=\"616\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">close</text><text x=\"616\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">$disconnect</text><circle cx=\"230\" cy=\"268\" r=\"4.5\" fill=\"var(--amber)\"></circle><circle cx=\"360\" cy=\"268\" r=\"4.5\" fill=\"var(--amber)\"></circle><circle cx=\"480\" cy=\"268\" r=\"4.5\" fill=\"var(--amber)\"></circle><text x=\"16\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">messages, either direction</text><rect x=\"110\" y=\"288\" width=\"500\" height=\"12\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"310\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">connection minutes, from connect to close</text></svg>", "caption": "One connection, five moments. The route is chosen per message by the selection expression; the backend speaks first by calling the connection's address. Both meters run: one counts the messages, the other the minutes the connection was open."}
```

## A connection has an id, and the backend uses it

Every connection gets a **connection id**, which arrives in `requestContext.connectionId` of every
event the function receives. A function that wants to reach a client later stores that id
somewhere, a DynamoDB table being the common choice, and deletes it on `$disconnect`. To send, the
backend posts to the connection through the API Gateway Management API:

```
ana@laptop:~/aws$ aws apigatewaymanagementapi post-to-connection --connection-id L0SM9cOFvHcCIhw= --cli-binary-format raw-in-base64-out --data '{"text": "order 42 shipped"}'; echo "exit status $?"
exit status 0
ana@laptop:~/aws$ aws apigatewaymanagementapi get-connection --connection-id L0SM9cOFvHcCIhw= --query Identity
{
    "SourceIp": "192.168.0.1",
    "UserAgent": "Moto Mocks"
}
```

**Nobody ever opened `L0SM9cOFvHcCIhw=`.** It is an id made up for the example, and moto accepted
the message and then described the connection, inventing an address and a user agent for it. AWS
answers both calls with `GoneException`, status `410`, because there is no such connection. That
`410` is not an edge case in production: it is how a backend learns that a client closed the tab
and the `$disconnect` notice has not yet been processed, so a sender handles it by deleting the
stored id and carrying on. On AWS the command also needs
`--endpoint-url https://tnftvxnn.execute-api.sa-east-1.amazonaws.com/prod`, the API's own
address with the stage; here `AWS_ENDPOINT_URL` sends it to moto.

Two limits from AWS's documentation shape every client. A connection lasts **two hours at most**,
and one that carries nothing for **ten minutes** is closed as idle. A client that must stay
connected through a working day therefore sends something now and then and reconnects when the
connection drops, and the backend stores the new id that comes with it.

## Two meters

The sheet printed both of them on 16 October 2026: **1.55 USD per million messages** and
**0.388 USD per million connection minutes**. Messages are counted in both directions and in steps
of 32 KB, so a 70 KB message counts as three. Minutes run for as long as a connection is open,
whether or not anything is said.

Ana's order page keeps 2,000 customers connected for 8 hours a day on 22 working days. The minutes
are 2,000 × 8 × 60 × 22 = 21,120,000, which is 21.12 million × 0.388 = 8.19 USD. If a status
change reaches each customer once every five minutes, that is 96 messages a day each, and
2,000 × 96 × 22 = 4,224,000 messages, which is 4.224 million × 1.55 = 6.55 USD. The month costs
about 14.74 USD.

The comparison worth making is with polling. To see a change within five seconds without a
WebSocket, each page would ask an HTTP API every five seconds: 5,760 requests a day each, so
2,000 × 5,760 × 22 = 253,440,000 requests, and 253.44 million × 1.59 = 402.97 USD. **Polling pays
for every question; a WebSocket pays for every answer that has something in it**, plus a small
charge for the time it waits. The gap closes when updates are as frequent as the polling would
have been, because then every message is paid for either way.
