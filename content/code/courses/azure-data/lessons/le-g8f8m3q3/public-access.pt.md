---
title: Acesso anônimo, a uma configuração de distância
version: 1
---

**Um contêiner pode ficar legível por qualquer um na internet com uma configuração, e sem assinatura
de tipo nenhum.** O Blob Storage chama isso de nível de acesso público do contêiner, e ele tem três
valores: `off`, que é privado; `blob`, em que qualquer um que saiba o nome de um blob consegue lê-lo; e
`container`, em que qualquer um também consegue listar os nomes. Ele existe por bons motivos, como as
imagens de produto de um site público, e é o formato por trás da maioria dos vazamentos de
armazenamento que saíram no jornal. A configuração fica no contêiner, então um contêiner tornado
público numa sexta à tarde para um teste rápido continua público na segunda.

## No Azurite

```
ana@laptop:~/azure$ az storage container set-permission -n orders-raw --public-access blob -o none
ana@laptop:~/azure$ curl -s "$BLOB"
order_id,customer_id,total_cents
29-1,c-17,4590
29-2,c-03,12800
ana@laptop:~/azure$ curl -s "$CONTAINER?restype=container&comp=list" | grep -o "<Code>.*</Code>"
<Code>AuthorizationFailure</Code>
ana@laptop:~/azure$ az storage container set-permission -n orders-raw --public-access container -o none
ana@laptop:~/azure$ curl -s "$CONTAINER?restype=container&comp=list" | grep -o "<Name>[^<]*</Name>"
<Name>exports/2026/10/orders-2026-10-29.csv</Name>
ana@laptop:~/azure$ az storage container set-permission -n orders-raw --public-access off -o none
ana@laptop:~/azure$ curl -s -o /dev/null -w "%{http_code}\n" "$BLOB"
403
```

**`blob` deixou a exportação legível por um `curl` sem credenciais**, e recusou a listagem: nesse
nível, um estranho precisa saber o nome exato. `container` acrescentou a listagem, e a listagem
entregou o nome. Voltar para `off` fechou as duas. No Azurite, como no Azure, a configuração vale a
partir da próxima requisição.

**Saber o nome não é proteção.** Nomes num lake são previsíveis de propósito: a lição 2 escolheu
`exports/2026/10/orders-2026-10-29.csv` para que um programa achasse sozinho o arquivo do dia seguinte,
e um estranho consegue achá-lo do mesmo jeito. O nível `blob` é público para todo nome que alguém
consiga adivinhar.

## A chave acima do contêiner

No Azure há mais uma camada, que o Azurite não tem: **a configuração de acesso anônimo da conta**,
`allowBlobPublicAccess`. Quando ela é false, nenhum contêiner da conta pode ser público, diga o nível
dele o que disser, e um pedido para definir um nível é recusado. A documentação da Microsoft diz que
contas novas são criadas com ela em false por padrão. Isso fecha o vazamento mais comum para quem não
faz nada, e o deixa aberto em contas antigas, criadas antes da mudança, e em qualquer conta em que
alguém a ligou.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Uma requisição assinada por ninguém, vinda de fora, precisa passar por duas configurações para chegar a um blob. A de fora é o allowBlobPublicAccess da conta, que o Azurite não tem; em false, ela vence qualquer contêiner. A de dentro é o nível de acesso público do contêiner: off é privado, blob permite ler pelo nome, container permite ler e listar; o Azurite o aplica.\" data-fig=\"l06-layers\"><defs><marker id=\"l06-layers-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--wire)\"/></marker></defs><rect x=\"230\" y=\"20\" width=\"470\" height=\"260\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"244\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">conta: allowBlobPublicAccess</text><text x=\"686\" y=\"38\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">Azurite: não existe</text><rect x=\"254\" y=\"58\" width=\"422\" height=\"202\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><text x=\"268\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">contêiner: nível de acesso público</text><text x=\"662\" y=\"76\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">Azurite: aplicado</text><rect x=\"278\" y=\"98\" width=\"120\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><text x=\"338\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">off</text><text x=\"410\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">privado</text><rect x=\"278\" y=\"132\" width=\"120\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><text x=\"338\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">blob</text><text x=\"410\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">leitura pelo nome</text><rect x=\"278\" y=\"166\" width=\"120\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><text x=\"338\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">container</text><text x=\"410\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">leitura e listagem</text><rect x=\"500\" y=\"196\" width=\"150\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"575\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">o blob</text><text x=\"575\" y=\"233\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">orders-2026-10-29.csv</text><text x=\"244\" y=\"270\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">false na conta vence qualquer nível de contêiner</text><text x=\"20\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">uma requisição</text><text x=\"20\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">assinada por ninguém</text><line x1=\"150\" y1=\"223\" x2=\"496\" y2=\"223\" stroke=\"var(--amber)\" stroke-width=\"1.8\" marker-end=\"url(#l06-layers-ah)\"/></svg>", "caption": "O acesso anônimo é decidido duas vezes. O laboratório mostra a decisão de dentro e não a de fora."}
```

Isso faz do acesso anônimo uma decisão tomada duas vezes, uma na conta e outra no contêiner, e o
arranjo seguro mantém a chave da conta em false em todo lugar, menos numa conta feita para arquivos
públicos e mais nada. A última seção a declara com o Terraform.
