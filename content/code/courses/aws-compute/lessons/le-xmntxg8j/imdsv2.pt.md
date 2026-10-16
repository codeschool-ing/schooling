---
title: "IMDSv2: um token antes de cada leitura"
version: 1
---

A primeira versão do serviço de metadados, o IMDSv1, respondia a qualquer `GET` que chegasse até
ele. Isso soa inofensivo quando "chegar até ele" quer dizer "veio da instância". **O problema é que
muito software numa instância envia um pedido para um endereço que outra pessoa escolheu.** Pense
numa aplicação web que busca uma imagem numa URL que o usuário digitou, num disparador de
webhooks, num gerador de PDF que segue links ou num proxy reverso mal configurado. Recebendo
`http://169.254.169.254/...` como endereço, cada um deles faz o pedido de dentro da instância, e o
serviço de metadados vê a instância perguntando.

Essa classe de falha se chama server-side request forgery, SSRF, e contra o IMDSv1 ela era um
caminho curto de um bug numa aplicação até as credenciais da role. Não é hipótese. Em 2019 um
firewall mal configurado na frente da aplicação do Capital One foi levado a pedir o caminho das
credenciais, e as chaves da role que ele devolveu foram usadas para copiar os registros de cerca de
cem milhões de pessoas do S3. **A falha estava na aplicação; o que a tornou cara foi um serviço de
metadados que confiava em qualquer pedido.**

## Dois pedidos em vez de um

O IMDSv2, que a AWS lançou em novembro de 2019, faz toda sessão começar com um `PUT`:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 356\" role=\"img\" aria-label=\"Uma sequência entre três partes: o serviço de metadados em 169.254.169.254, um processo na instância e um contêiner atrás de uma bridge, um salto mais longe. O processo envia um PUT para /latest/api/token com um cabeçalho de TTL e recebe um token, depois envia um GET das credenciais da role com o token num cabeçalho e recebe o nome da role. O contêiner envia o mesmo PUT, mas a resposta é descartada na bridge porque o limite de saltos de 1 se esgotou.\"><defs><marker id=\"imds-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"12\" width=\"180\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"110\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">serviço de metadados</text><text x=\"110\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">169.254.169.254</text><path d=\"M110 58 L110 318\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 4\" fill=\"none\"></path><rect x=\"280\" y=\"12\" width=\"200\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"380\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">um processo na instância</text><text x=\"380\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a CLI, um SDK, o seu script</text><path d=\"M380 58 L380 318\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 4\" fill=\"none\"></path><rect x=\"515\" y=\"12\" width=\"190\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"610\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">um contêiner</text><text x=\"610\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">atrás de uma bridge, um salto a mais</text><path d=\"M610 58 L610 318\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 4\" fill=\"none\"></path><text x=\"245\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">PUT /latest/api/token</text><path d=\"M380 96 L112 96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#imds-ah)\"></path><text x=\"245\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cabeçalho: validade do token, 300 s</text><text x=\"245\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">um token</text><path d=\"M110 140 L378 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#imds-ah)\"></path><text x=\"245\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o TTL IP da resposta é o hop limit</text><text x=\"245\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">GET …/security-credentials/</text><path d=\"M380 188 L112 188\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#imds-ah)\"></path><text x=\"245\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">token num cabeçalho</text><text x=\"245\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">o nome da role</text><path d=\"M110 234 L378 234\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#imds-ah)\"></path><text x=\"495\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">PUT /latest/api/token</text><path d=\"M610 274 L112 274\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#imds-ah)\"></path><path d=\"M110 302 L440 302\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M444 294 L460 310 M460 294 L444 310\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"470\" y=\"302\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">descartada na bridge</text><text x=\"360\" y=\"338\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">com hop limit 1, a resposta com o token não sobrevive a mais um salto</text></svg>", "caption": "Um token antes de cada leitura. O PUT pede um token e diz quanto tempo ele deve durar; cada GET depois o leva junto. A resposta ao PUT sai com um time-to-live IP igual ao hop limit, então com limite 1 ela chega a um processo na instância e morre na primeira bridge atrás da qual um contêiner está."}
```

1. Um `PUT` em `/latest/api/token`, com um cabeçalho `X-aws-ec2-metadata-token-ttl-seconds`
   dizendo quanto tempo o token deve durar, de 1 segundo a 21.600, que são seis horas. A resposta é
   o token.
2. Toda leitura depois disso o leva, num cabeçalho `X-aws-ec2-metadata-token`. Uma leitura com um
   token errado ou vencido recebe `401 Unauthorized`.

O `first-boot.sh` da primeira seção fez exatamente isso com `curl`, e a CLI fez sozinha na última
seção. Aqui estão os mesmos dois passos à mão contra os valores de enfeite do moto:

```
ana@laptop:~/aws$ TOKEN=$(curl -s -X PUT localhost:4567/latest/api/token -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
ana@laptop:~/aws$ echo "$TOKEN"
fake-imdsv2-token
ana@laptop:~/aws$ curl -s -H "X-aws-ec2-metadata-token: $TOKEN" localhost:4567/latest/meta-data/iam/security-credentials/; echo
default-role
ana@laptop:~/aws$ curl -s -H "X-aws-ec2-metadata-token: not-a-token" localhost:4567/latest/meta-data/iam/security-credentials/; echo
default-role
```

**O moto entrega uma constante e não confere nada**: o token é a string `fake-imdsv2-token`, e o
pedido que levava `not-a-token` foi respondido como se fosse válido. Na AWS o token é um valor
opaco amarrado àquela instância, e o último pedido acima recebe `401`. Nada neste laboratório
consegue mostrar a recusa, então o resto desta seção é o comportamento documentado da AWS e não
foi rodado.

## O que o token barra, e como

**Cada uma das três defesas mira um jeito pelo qual o SSRF chegava ao serviço antigo.**

A primeira é o método e o cabeçalho. Os pedidos que uma URL forjada produz são quase sempre
`GET`s, com cabeçalhos que o programa vulnerável escolheu, não o atacante. Um `PUT` com um
cabeçalho próprio é algo que a maioria desses programas não consegue ser levada a enviar, então
eles nunca obtêm um token, e sem ele as leituras falham.

A segunda mira os proxies. Um proxy reverso aberto ou mal configurado repassa qualquer método que
receber, mas acrescenta um cabeçalho `X-Forwarded-For` com o cliente original. **O serviço de
metadados recusa um `PUT` de token que traga `X-Forwarded-For`**, então o proxy que repassa um
pedido também anuncia que é um intermediário e é mandado embora.

A terceira é o **hop limit**, `HttpPutResponseHopLimit`, e é a que precisa de um desenho. A
resposta ao `PUT` sai com o time-to-live IP igual ao hop limit. Cada roteador ou bridge que ela
atravessa diminui esse valor em um, e no zero o pacote é descartado. Com o limite em 1, a resposta
chega a um processo na própria instância e a nada além: um contêiner numa rede bridge do Docker
fica um salto adiante, e o pedido de token dele é respondido com um pacote que morre no caminho.

Esse último ponto corta para os dois lados, e é por isso que o limite é uma configuração e não uma
constante. **Um contêiner que não obtém token não consegue usar a role da instância**, que é o que
você quer quando os contêineres rodam código de outras pessoas. É também por isso que um agente
num contêiner que precisa de verdade dos metadados da instância falha com um timeout em vez de um
erro. O conselho da AWS para instâncias que rodam contêineres é um hop limit de 2. A resposta
melhor para um contêiner que precisa de credenciais da AWS é uma role própria em vez da da
instância: uma task role do ECS, na aula 8, e a role de um pod pelo IRSA, na aula 13.

## O que ele não barra

O IMDSv2 tira o caminho barato. Ele não torna as credenciais secretas para a instância. **Qualquer
programa rodando na instância que envie os próprios pedidos ainda consegue enviar o `PUT`.** Um
código que um atacante conseguiu rodar ali, em vez de só induzir a buscar uma URL, lê as chaves da
role exatamente como a CLI leu. A defesa para isso limita o que a role pode fazer depois de lida.
Quer dizer uma role só com as permissões de que a instância precisa, que é o menor privilégio da
aula 7 de `aws-foundations`, e nada na instância que rode código que não deveria rodar.
