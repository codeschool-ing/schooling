---
title: "A troca: um token entra, um token de acesso sai"
version: 1
---

Tudo até aqui foi preparação para um pedido. **O SDK do Azure no pod lê o arquivo do token, envia o
token ao endpoint de token do Entra ID como asserção do cliente, e o Entra ID responde com um token
de acesso para a identidade gerenciada, para o único recurso que o pedido citou.** O SDK põe esse
token de acesso em cada chamada ao Blob Storage, e pede um novo antes que ele vença, lendo o arquivo
de novo a cada vez. Nenhum segredo fica guardado em lugar nenhum, e o token que deu início a tudo
dura uma hora.

**Esta seção é lida, não praticada.** Nada num laptop faz o papel do Entra ID, e o emissor do
cluster kind do laboratório não pode ser alcançado de fora dele, então nenhuma troca foi tentada
neste curso e nada abaixo mostra saída. O que ela mostra vem da documentação da Microsoft, lida em
30 de outubro de 2026.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"Uma sequência em cinco passos entre quatro partes: o pod, o Microsoft Entra ID, o emissor do cluster e o Blob Storage. 1, o pod envia ao Entra ID o seu token projetado como asserção do cliente, com o client id da identidade gerenciada e o escopo que quer. 2, o Entra ID busca o documento de descoberta do emissor e as suas chaves públicas. 3, o Entra ID confere a assinatura, depois o emissor, o sujeito e o público contra a credencial federada, e a expiração. 4, o Entra ID devolve um token de acesso com a sua duração em segundos. 5, o pod grava o recibo no Blob Storage com esse token como bearer. Uma nota diz que nada disso foi executado neste curso: não há tenant, e o emissor do kind não pode ser alcançado de fora do laptop.\"><defs><marker id=\"wi-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"wi-ah-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M90 62 L90 320\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M310 62 L310 188\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M310 234 L310 320\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M520 62 L520 190\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M660 62 L660 200\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M660 244 L660 320\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"15\" y=\"14\" width=\"150\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">o pod</text><text x=\"90.0\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">SDK e arquivo do token</text><rect x=\"235\" y=\"14\" width=\"150\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"310.0\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">Microsoft Entra ID</text><text x=\"310.0\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o endpoint de token</text><rect x=\"440\" y=\"14\" width=\"160\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"520.0\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">o emissor do cluster</text><text x=\"520.0\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">descoberta e chaves</text><rect x=\"612\" y=\"14\" width=\"96\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"660.0\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">Blob Storage</text><text x=\"660.0\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">os recibos</text><text x=\"200\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1 · o token como client_assertion, e um escopo</text><path d=\"M92 98 L306 98\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#wi-ah)\"></path><text x=\"415\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2 · buscar as chaves do emissor</text><path d=\"M312 134 L516 134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#wi-ah-dim)\"></path><text x=\"415\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">as chaves, como um JWKS</text><path d=\"M518 170 L314 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#wi-ah-dim)\"></path><rect x=\"170\" y=\"188\" width=\"280\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"310\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">3 · primeiro a assinatura, depois iss, sub</text><text x=\"310\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">e aud contra a credencial, e exp</text><text x=\"200\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">4 · um token de acesso, e expires_in</text><path d=\"M308 264 L94 264\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#wi-ah)\"></path><text x=\"375\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">5 · gravar o recibo, Authorization: Bearer</text><path d=\"M92 302 L656 302\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#wi-ah)\"></path><rect x=\"458\" y=\"200\" width=\"248\" height=\"44\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"582\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">não executado neste curso:</text><text x=\"582\" y=\"231\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">sem tenant, e o emissor do kind é privado</text></svg>", "caption": "A troca no centro da workload identity. O pod prova quem é com um token que o seu cluster assinou, e o Entra ID só acredita nele depois de conferir essa assinatura contra chaves que buscou no emissor do cluster, e em seguida as três strings da credencial federada. Nada disso roda num laptop.", "same": ["Microsoft Entra ID", "Blob Storage"]}
```

## O pedido

A troca é o client credentials grant do OAuth 2.0, o mesmo que um aplicativo com segredo usa, com o
segredo substituído pelo token do cluster. Escrita como `curl` a partir de um shell no pod, com as
quatro variáveis que o webhook definiu, ela é isto. Não foi executada neste curso: precisa de um
tenant e de um emissor que o Entra ID alcance.

```sh
curl -s "${AZURE_AUTHORITY_HOST}${AZURE_TENANT_ID}/oauth2/v2.0/token" \
  -d grant_type=client_credentials \
  -d client_id="$AZURE_CLIENT_ID" \
  -d client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer \
  --data-urlencode client_assertion@"$AZURE_FEDERATED_TOKEN_FILE" \
  --data-urlencode scope=https://storage.azure.com/.default
```

Leia campo por campo. `client_id` cita a identidade gerenciada, `shop-orders`, pelo client id que a
anotação trazia. `client_assertion` é o próprio token projetado, o conteúdo do arquivo como está, e
`client_assertion_type` diz que é um JWT. `scope` é o recurso para o qual o token de acesso vai
servir, aqui o Blob Storage, escrito na forma `<resource>/.default`. **O escopo tem de ser escrito
assim**: a documentação da Microsoft adverte que um endereço de recurso puro, como
`https://storage.azure.com/`, pode falhar, porque a workload identity usa o endpoint de token v2 do
Entra ID, e não o fluxo de identidade gerenciada do serviço de metadados, que aceitava esse formato.

Uma resposta de sucesso é um JSON com três campos, na documentação do Entra ID: `token_type`, que é
`Bearer`; `expires_in`, a duração do token de acesso em segundos; e `access_token`. O pod então envia
esse token de acesso num cabeçalho `Authorization: Bearer` em cada pedido à conta de armazenamento.

## O que o Entra ID confere antes de responder

Ele só responde quando cada uma destas condições vale, nesta ordem de dependência:

- **a assinatura**, conferida com uma chave pública do conjunto de chaves que o emissor do `iss` do
  token publica, escolhida pelo `kid` do cabeçalho dele. Antes disso, nenhuma claim merece crédito;
- **uma credencial federada na identidade** cujos emissor, sujeito e público sejam o `iss`, o `sub`
  e o `aud` do token, comparados por inteiro e diferenciando maiúsculas de minúsculas;
- **a duração do token**: um token que passou do seu `exp` é recusado.

Duas das falhas têm texto documentado, e nenhuma foi produzida aqui. A página do Entra ID sobre
propagação dá `AADSTS70021: No matching federated identity record found for presented assertion`
para um pedido feito antes de uma credencial nova chegar a todos os servidores, e as palavras
descrevem qualquer token que não corresponda a registro nenhum. A página do AKS dá `AADSTS700212`
para um token cujo público não é o da credencial, enviado por um pod que usou um token feito para
outra coisa.

**Repare no que o Entra ID nunca pede: um segredo do pod.** Ele não precisa de um, porque acredita
na assinatura do cluster e foi avisado de antemão, pela credencial federada, qual service account de
qual cluster pode ser `shop-orders`.

## O que o SDK faz por você

Ninguém escreve o pedido acima na API de pedidos. A biblioteca Azure Identity o faz, em cada uma das
linguagens que a documentação do AKS lista com uma versão mínima; para Python é o `azure-identity`
1.13.0. O aplicativo pede uma credencial e a entrega a um cliente:

```python
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient

blobs = BlobServiceClient('https://shopreceipts.blob.core.windows.net',
                          credential=DefaultAzureCredential())
blobs.get_container_client('receipts').upload_blob('order-1.json', b'{"id": 1}')
```

Esse trecho também não foi executado: a imagem da loja é só a biblioteca padrão, e os recibos são o
exemplo desta lição. `DefaultAzureCredential` tenta uma lista fixa de credenciais em ordem e usa a
primeira que tem o que precisa. Para Python, a documentação da Microsoft dá o começo da lista como
**ambiente, depois workload identity, depois identidade gerenciada**, seguidas das ferramentas da
máquina de um desenvolvedor.

**A ordem é uma armadilha durante uma migração.** A credencial de ambiente é a que a resposta
rápida da primeira seção usava: ela procura `AZURE_CLIENT_ID`, `AZURE_TENANT_ID` e
`AZURE_CLIENT_SECRET`. Um pod que ainda monta o Secret antigo ao lado do token novo entra com o
segredo, todas as vezes, e o token fica sem uso enquanto tudo parece funcionar. Tirar o Secret do pod
faz parte da mudança, e apagar o segredo do aplicativo depois também. Um código que só deve usar o
token pode dizer isso com `WorkloadIdentityCredential`, que lê as quatro variáveis e nada mais.

## O que o token de acesso pode fazer

O token de acesso carrega a identidade gerenciada e nada mais, então o que a API de pedidos pode
fazer é o que os papéis de `shop-orders` permitirem. A lição 9 de `azure-foundations` ensinou o RBAC
do Azure; para os recibos o papel é `Storage Blob Data Contributor`, no contêiner. Não executado
neste curso:

```sh
az role assignment create \
  --assignee-object-id "$ORDERS_PRINCIPAL_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION/resourceGroups/shop/providers/Microsoft.Storage/storageAccounts/shopreceipts/blobServices/default/containers/receipts"
```

`ORDERS_PRINCIPAL_ID` é o principal id da identidade, que `az identity show` devolve ao lado do client
id. A documentação da Microsoft adverte que uma atribuição de papel pode levar até 10 minutos para
valer, então um pod que obtém um token de acesso e depois é recusado pela conta de armazenamento
quase sempre foi configurado certo e cedo demais.

## Três respostas, lado a lado

| | um client secret num Secret | a identidade do kubelet | workload identity |
| --- | --- | --- | --- |
| o que fica guardado | o segredo, em cada cópia | nada | nada |
| expira | na data de fim, um ano por padrão | gerenciado pelo Azure | o token em uma hora, o token de acesso no seu próprio prazo |
| quem pode usar | quem tiver uma cópia | todo pod no nó | uma service account num cluster |
| o que uma pessoa rotaciona | o segredo, até uma data | nada | nada; as chaves de assinatura quando quiser |
| configurado em | Entra ID e Kubernetes | um papel | uma identidade, uma credencial, um papel, uma anotação e um rótulo |

A última linha é o custo honesto. A workload identity leva cinco coisas para configurar onde o
segredo levava duas, e em troca não sobra nada para vazar, nada para lembrar numa data, e uma
identidade que pertence só à API de pedidos. A próxima lição passa de quem o pod é para como os
pedidos chegam até ele.
