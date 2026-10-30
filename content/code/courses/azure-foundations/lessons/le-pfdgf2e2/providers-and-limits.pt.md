---
title: Resource providers, limites de pedidos, e o outro plano
version: 1
---

**O Resource Manager não sabe construir uma rede. Ele sabe quem pode pedir, e para qual serviço passar
o pedido.** Os serviços por trás dele são os **resource providers**, um por namespace:
`Microsoft.Network`, `Microsoft.Compute`, `Microsoft.Storage`, `Microsoft.KeyVault` e muitos outros.
Esta seção trata de três consequências desse arranjo.

## Um provider precisa ser registrado

**Uma assinatura só cria um tipo cujo provider esteja registrado nela.** O registro configura a
assinatura para trabalhar com aquele provider, e a documentação da Microsoft recomenda registrar só os
que você usa: cada registro pode acrescentar ao tenant uma aplicação da Microsoft, e um provider que
ninguém registrou é um que uma credencial roubada também não consegue usar. Alguns vêm registrados
desde o início. Uma implantação pelo portal, ou de um template Bicep ou ARM, registra os providers que
cita; um recurso que precisa calado de um segundo provider, de monitoramento por exemplo, é onde alguém
encontra o erro `MissingSubscriptionRegistration`. O remédio é um comando,
`az provider register --namespace Microsoft.Insights`, e o `az provider show --namespace
Microsoft.Network --query registrationState` diz em que pé um provider está. **Nenhum dos dois foi
executado aqui**: os dois são perguntas sobre uma assinatura.

Um provider também diz, para cada um dos seus tipos, **quais regiões o oferecem e quais `api-version`s
existem**. Essa é a resposta oficial para "consigo criar isto em `brazilsouth`?", e ela vem do
`az provider show` com uma conta. Sem conta, as páginas de documentação do provider trazem a mesma
lista.

## Limites de pedidos

O Resource Manager conta pedidos, e os recusa depois de um limite. **Desde 2024 ele usa um balde de
tokens por assinatura e por região**: cada tipo de pedido tira um token de um balde, e o balde se enche
de novo a uma taxa fixa. A documentação da Microsoft dá estes números:

| escopo | pedidos | tamanho do balde | reposição por segundo |
|---|---|---|---|
| assinatura | leituras | 250 | 25 |
| assinatura | escritas | 200 | 10 |
| assinatura | exclusões | 200 | 10 |
| tenant | leituras | 250 | 25 |
| tenant | escritas | 200 | 10 |
| tenant | exclusões | 200 | 10 |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l25-bucket\" aria-label=\"Um balde de tokens para leituras de assinatura, desenhado como uma coluna de 250 tokens. Uma rajada de 250 leituras o esvazia de uma vez. Depois disso, voltam 25 tokens por segundo, então o script pode seguir a 25 leituras por segundo. Um pedido com o balde vazio recebe 429 e um Retry-After.\"><defs><marker id=\"l25-bucket-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l25-bucket-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40.0\" y=\"40.0\" width=\"90.0\" height=\"150.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"44.0\" y=\"44.0\" width=\"82.0\" height=\"142.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">250</text><text x=\"85.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">cheio</text><text x=\"85.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">250 tokens</text><rect x=\"240.0\" y=\"40.0\" width=\"90.0\" height=\"150.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">0</text><text x=\"285.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">depois de uma rajada</text><text x=\"285.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">250 leituras de uma vez</text><rect x=\"440.0\" y=\"40.0\" width=\"90.0\" height=\"150.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"444.0\" y=\"179.0\" width=\"82.0\" height=\"7.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"485.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">25</text><text x=\"485.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">um segundo depois</text><text x=\"485.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mais 25</text><path d=\"M131.0 115.0 L239.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l25-bucket-af-ah-paper-dim)\"></path><path d=\"M331.0 115.0 L439.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l25-bucket-af-ah-paper-dim)\"></path><rect x=\"560.0\" y=\"60.0\" width=\"140.0\" height=\"110.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" font-weight=\"600\" fill=\"var(--amber)\">429</text><text x=\"630.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Retry-After</text><text x=\"630.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">se o balde</text><text x=\"630.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">estiver vazio</text><path d=\"M285.0 39.0 L285.0 22.0 L630.0 22.0 L630.0 59.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l25-bucket-af-ah-amber)\"></path></svg>", "caption": "Leituras da assinatura: uma rajada de 250, e depois 25 por segundo enquanto você continuar.", "same": ["250 tokens"]}
```

Então um script pode ler 250 vezes numa rajada, e depois 25 vezes por segundo enquanto continuar. Passado
o limite, a resposta é **429 Too Many Requests** com um `Retry-After` em segundos, e um pedido mandado
antes desse tempo é recusado de novo com um novo valor. As respostas também trazem cabeçalhos como
`x-ms-ratelimit-remaining-subscription-reads`, que dizem quanto sobra. **Um script que passa por centenas
de recursos deve ler esses cabeçalhos e respeitar o `Retry-After`**, em vez de tentar de novo na hora e
gastar também o próximo token. Alguns providers também devolvem 429 por motivos próprios, como outra
operação segurando uma trava no recurso, e o código de erro no corpo é o que distingue os dois casos.

## O plano de controle e o plano de dados

**Tudo nesta lição até aqui é o plano de controle**: criar, configurar e apagar recursos, pelo
`management.azure.com`. Usar um recurso é outro plano inteiramente, com endereço próprio:

| | plano de controle | plano de dados |
|---|---|---|
| storage | criar a conta `shopassets`, definir a replicação | ler e escrever blobs em `shopassets.blob.core.windows.net` |
| máquina virtual | criá-la, redimensioná-la, pará-la | entrar nela por SSH |
| key vault | criar o cofre, definir quem pode administrá-lo | ler um segredo em `kv-shop-prod.vault.azure.net` |
| quem responde | o Resource Manager, e depois o provider | o próprio serviço |

A diferença decide três coisas. **As permissões são separadas**: um papel pode permitir administrar uma
storage account sem permitir ler um único blob dela, o que a lição 9 chama de *data actions*. **O caminho
é separado**: um pedido do plano de dados nunca passa pelo Resource Manager, então os limites dele são
os do serviço, não os da tabela acima. E **as regras de rede valem para o plano de dados**: o private
endpoint da lição 19 fecha `shopassets.blob.core.windows.net` para a internet, enquanto a conta continua
podendo ser administrada pelo `management.azure.com` como antes.

O sufixo de `storage` que a lição 1 leu no `az cloud show`, `core.windows.net`, é o endereço do plano de
dados, e o `management.azure.com` ao lado dele é o do plano de controle: a CLI guarda os dois, porque
fala com os dois.
