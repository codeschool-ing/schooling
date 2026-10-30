---
title: Como o pod consegue um token
version: 1
---

Nada na seção 03 entregou uma credencial ao pod, e mesmo assim a biblioteca cliente dele vai
conseguir uma. **O truque é o servidor de metadados: o mesmo endereço que responde numa máquina do
Compute Engine responde dentro do pod, mas no GKE ele é o servidor de metadados do GKE, e busca
tokens para a identidade do pod, não para a do nó.** Conhecer a sequência é o que torna legível uma
falha nela.

## A troca, passo a passo

Nada aqui roda sem um cluster e um projeto do Google; a sequência é a documentada pelo Google.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Cinco colunas: o contêiner, o servidor de metadados do GKE no nó, o Security Token Service, a API de credenciais do IAM e o Cloud Storage. Setas em ordem: 1, o contêiner pede um token a 169.254.169.254; 2 e 3, o servidor de metadados manda o token da conta de serviço do Kubernetes ao Security Token Service e recebe um token federado; 4, troca esse token por um token de acesso de photos-reader na API de credenciais do IAM; 5, o token volta ao contêiner, que chama o Cloud Storage com ele.\"><defs><marker id=\"l15t-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"16\" y=\"16\" width=\"128\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"80\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">contêiner</text><path d=\"M80 58 L80 316\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"156\" y=\"16\" width=\"128\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"220\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">metadados do GKE</text><path d=\"M220 58 L220 316\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"306\" y=\"16\" width=\"128\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"370\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Security Token Service</text><path d=\"M370 58 L370 316\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"446\" y=\"16\" width=\"128\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"510\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">credenciais do IAM</text><path d=\"M510 58 L510 316\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"576\" y=\"16\" width=\"128\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"640\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Cloud Storage</text><path d=\"M640 58 L640 316\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M86 86 L214 86\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15t-ah)\"></path><text x=\"150.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">1 token?</text><path d=\"M226 120 L364 120\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15t-ah)\"></path><text x=\"295.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">2 token da KSA</text><path d=\"M364 154 L226 154\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15t-ah)\"></path><text x=\"295.0\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">3 token federado</text><path d=\"M226 188 L504 188\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15t-ah)\"></path><text x=\"365.0\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">4 agir como photos-reader</text><path d=\"M504 222 L226 222\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15t-ah)\"></path><text x=\"365.0\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">token de acesso</text><path d=\"M214 256 L86 256\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15t-ah)\"></path><text x=\"150.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">5 token de acesso</text><path d=\"M86 290 L634 290\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15t-ah)\"></path><text x=\"360.0\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">ler o bucket</text></svg>", "caption": "Todo token da sequência é de curta duração, e nenhum fica guardado no pod. A vinculação da seção 03 é o que deixa o passo 4 dar certo.", "same": ["1 token?", "Cloud Storage", "Security Token Service"]}
```

1. A biblioteca cliente dentro do contêiner pede um token de acesso ao servidor de metadados,
   exatamente como faria numa máquina virtual: uma requisição HTTP para `169.254.169.254` com o
   cabeçalho `Metadata-Flavor: Google`, o endereço e o cabeçalho que a lição 7 encontra no Compute
   Engine.
2. Num nó com `GKE_METADATA`, esse endereço é respondido pelo **servidor de metadados do GKE**, um
   pod que o GKE roda em todo nó. Ele sabe qual pod está pedindo, e portanto com qual conta de
   serviço do Kubernetes o pod roda.
3. Ele obtém um token dessa conta de serviço do Kubernetes, assinado pelo cluster, e o troca no
   **Security Token Service do Google** por um token federado da identidade
   `planner-dev.svc.id.goog[shop/photos]`.
4. Como a conta de serviço do Kubernetes tem a anotação, ele então usa o token federado para pedir
   à **API de credenciais do IAM** um token de acesso de `photos-reader`. O IAM permite por causa
   da vinculação `roles/iam.workloadIdentityUser`.
5. O token de acesso, válido por cerca de uma hora, volta para a biblioteca cliente, que o manda ao
   Cloud Storage. A biblioteca pede de novo antes de ele expirar.

**Em nenhum passo existe algo de longa duração.** Não há arquivo para vazar, e um token roubado para
de funcionar sozinho dentro da hora.

## Lendo uma falha

Cada passo tem o seu jeito de falhar, e o erro aponta o passo se você conhece a sequência:

| o que o pod vê | o passo que falhou | a causa de costume |
|---|---|---|
| um token da conta de serviço do nó, não de `photos-reader` | 2 | o node pool não tem `GKE_METADATA`, então os metadados do próprio nó responderam |
| `Permission ... iam.serviceAccounts.getAccessToken denied` | 4 | falta a vinculação `workloadIdentityUser`, ou ela nomeia o namespace ou o nome errado |
| um token de `photos-reader`, depois `403` do Storage | 5 | a conta de serviço não tem papel no bucket |
| um token, mas da conta de serviço do Google errada | 4 | a anotação nomeia outro e-mail |

A segunda linha é a mais comum, e a causa quase sempre é um erro de digitação em `[shop/photos]`:
um namespace escrito de um jeito na vinculação e de outro no Deployment, que o IAM trata como duas
identidades diferentes sem reclamar.

## O que o pod não consegue mais fazer

Com `GKE_METADATA` no node pool, um pod **não alcança a conta de serviço do próprio nó** pelo
servidor de metadados; é para isso que o servidor do GKE fica na frente. Sem ele, todo pod de um nó
conseguiria um token da identidade do nó, que em muitos clusters tem escopos amplos. Então ligar o
Workload Identity é também desligar esse caminho, e vale fazê-lo num cluster antes mesmo de algum
pod usá-lo.
