---
title: O caminho que um pedido faz
version: 1
---

**O portal, a CLI do Azure, o Azure PowerShell, o Bicep, o Terraform e todo SDK são clientes. Nenhum
deles cria coisa alguma. Cada um transforma o que você pediu em pedidos HTTP para um endereço,
`https://management.azure.com/`, e esse endereço é o Azure Resource Manager.** A lição 1 o achou no
`az cloud show`. Esta lição segue um pedido até ele, até onde um laboratório sem conta consegue ir, e
lê o resto na documentação da Microsoft.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l25-path\" aria-label=\"O caminho de um pedido. À esquerda, os clientes: o portal, a CLI do Azure, o Azure PowerShell, o Bicep e o Terraform. Passo 1: o cliente obtém um token do Microsoft Entra ID em login.microsoftonline.com. Passo 2: ele manda o pedido com o token ao Resource Manager em management.azure.com. Passo 3: o Resource Manager confere o token, o papel, as políticas, as travas e o limite de pedidos. Passo 4: ele entrega o pedido ao resource provider, como o Microsoft.Network, que faz o trabalho.\"><defs><marker id=\"l25-path-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l25-path-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l25-path-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10.0\" y=\"30.0\" width=\"150.0\" height=\"260.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><rect x=\"20.0\" y=\"40.0\" width=\"130.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">portal</text><rect x=\"20.0\" y=\"84.0\" width=\"130.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">az</text><rect x=\"20.0\" y=\"128.0\" width=\"130.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Az PowerShell</text><rect x=\"20.0\" y=\"172.0\" width=\"130.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Bicep</text><rect x=\"20.0\" y=\"216.0\" width=\"130.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Terraform</text><text x=\"85.0\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os clientes</text><rect x=\"230.0\" y=\"20.0\" width=\"200.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Microsoft Entra ID</text><text x=\"330.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">login.microsoftonline.com</text><path d=\"M161.0 56.0 L229.0 50.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l25-path-af-ah-phosphor)\"></path><text x=\"190.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><rect x=\"230.0\" y=\"130.0\" width=\"200.0\" height=\"150.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Resource Manager</text><text x=\"330.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">management.azure.com</text><text x=\"330.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">token válido?</text><text x=\"330.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o papel permite?</text><text x=\"330.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a política permite?</text><text x=\"330.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">sem trava?</text><text x=\"330.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">abaixo do limite?</text><path d=\"M161.0 166.0 L229.0 190.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l25-path-af-ah-amber)\"></path><text x=\"190.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">2</text><text x=\"442.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">3</text><rect x=\"520.0\" y=\"160.0\" width=\"180.0\" height=\"80.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">resource provider</text><text x=\"610.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Microsoft.Network</text><text x=\"610.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">faz o trabalho</text><path d=\"M431.0 230.0 L519.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l25-path-af-ah-paper-dim)\"></path><text x=\"475.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">4</text><text x=\"475.0\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">os passos 2 a 4 são os mesmos qualquer que seja o cliente</text></svg>", "caption": "Cinco clientes, um emissor de tokens, uma API. O que é recusado é recusado no meio.", "same": ["Microsoft Entra ID", "Resource Manager", "portal", "resource provider"]}
```

Quatro passos, sempre nesta ordem:

1. **O cliente obtém um token do Microsoft Entra ID.** Ele faz login em `login.microsoftonline.com`,
   para um tenant em particular, e pede um token cuja audiência é o Resource Manager: o *escopo*
   `https://management.azure.com/.default`. O token é uma declaração assinada de quem é o chamador, e
   a documentação da Microsoft lhe dá uma vida útil entre 60 e 90 minutos.
2. **O cliente manda o pedido ao Resource Manager** com o token no cabeçalho `Authorization`, o id do
   recurso como caminho, e uma `api-version` na query string.
3. **O Resource Manager o confere.** O token é válido e feito para ele? O chamador tem um papel que
   permite essa ação nesse escopo, que é a lição 9? Alguma Azure Policy proíbe, que é a lição 4? Há uma
   trava no recurso? A assinatura passou do limite de pedidos, que a última seção desta lição cobre?
4. **O Resource Manager entrega o pedido ao resource provider** dono do tipo, `Microsoft.Network` para
   uma rede virtual, que faz o trabalho e responde.

**Toda porta compartilha os passos 2 a 4.** Uma permissão recusada, uma política que nega, um pedido
limitado: cada um é a mesma resposta qualquer que seja o cliente que o mandou, porque não é o cliente
que decide.

## O passo 1, contra o Entra ID de verdade

O primeiro passo é o que o laboratório consegue dar de verdade, porque o endpoint de login responde a
qualquer um. Este é o pedido que um programa faz para entrar como aplicação, do jeito que os service
principals da lição 7 fazem. Aqui ele é mandado com um tenant e uma aplicação que não existem:

```sh
mkdir -p ~/azure/arm && cd ~/azure/arm
```

```
ana@laptop:~/azure/arm$ curl -sS -X POST https://login.microsoftonline.com/aaaabbbb-0000-cccc-1111-dddd2222eeee/oauth2/v2.0/token -d grant_type=client_credentials -d client_id=00001111-aaaa-2222-bbbb-3333cccc4444 -d client_secret=not-a-secret -d scope=https://management.azure.com/.default | jq '{error, error_codes, first: (.error_description | split(". ")[0])}'
{
  "error": "invalid_request",
  "error_codes": [
    90002
  ],
  "first": "AADSTS90002: Tenant 'aaaabbbb-0000-cccc-1111-dddd2222eeee' not found"
}
```

**Essa recusa veio do próprio Microsoft Entra ID**: `AADSTS90002` é o código dele para um tenant que
ele não conhece. O pedido tem exatamente o formato de um que funciona. O tenant no endereço, o id e o
segredo da aplicação, e o escopo que pede um token para o Resource Manager. Com um tenant e uma
aplicação de verdade, a resposta é um documento JSON com um `access_token`. O `jq` ficou com a primeira
frase da descrição, porque o resto traz um id e um horário que mudam a cada chamada.

## Os passos 2 a 4, até onde a CLI chega

O `--debug` mostra a CLI do Azure trabalhando num comando. Filtrado para as linhas que importam:

```
ana@laptop:~/azure/arm$ az group list --debug 2>&1 | grep -E 'Command table|client_type=|ERROR: cli'
DEBUG: cli.azure.cli.core: Command table: group list
DEBUG: cli.azure.cli.core.commands.client_factory: Getting management service client client_type=ResourceManagementClient
ERROR: cli.azure.cli.core.azclierror: Please run 'az login' to setup account.
```

A CLI achou o comando, depois montou um `ResourceManagementClient`, o cliente do provider
`Microsoft.Resources` do Resource Manager, e só então foi procurar um token para lhe dar, não achou
login nenhum, e parou. **Com uma conta, as linhas seguintes da mesma saída são o próprio pedido HTTP**:
`GET https://management.azure.com/subscriptions/<id>/resourcegroups?api-version=...`, os cabeçalhos com o
token removido, e a resposta.

Um pedido mandado direto ao Resource Manager sem token recebe **401**, e um cabeçalho chamado
`WWW-Authenticate` que diz de qual autoridade obter um token. **Isso não foi executado aqui**: a máquina
onde as lições foram gravadas não tem permissão para alcançar `management.azure.com`, e nada neste
curso manda pedido para lá.
