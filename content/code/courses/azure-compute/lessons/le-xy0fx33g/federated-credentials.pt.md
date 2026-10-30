---
title: O emissor, e uma credencial federada que confia nele
version: 1
---

O token da seção anterior é assinado pelo cluster, e o Entra ID nunca ouviu falar do cluster. **Uma
credencial de identidade federada é o registro que apresenta um ao outro: três strings numa
identidade gerenciada atribuída pelo usuário, dizendo que um token deste emissor, com este sujeito e
este público, pode agir como esta identidade.** Não há segredo nela nem certificado. O Entra ID
compara as três strings com o `iss`, o `sub` e o `aud` do token, mas só depois de conferir a
assinatura do token contra chaves que ele busca no próprio emissor, e é por isso que o cluster tem
de publicá-las.

Duas imagens estão erradas aqui, e as duas são comuns. A credencial não é um login que o cluster
faz: nada do lado do Azure jamais entra no cluster, e o cluster nunca entra em nada. E a credencial
não mora no cluster. Ela é filha da identidade gerenciada, então uma identidade pode confiar em
vários clusters, e apagar um cluster deixa as credenciais dele nas identidades até alguém removê-las.

## O emissor que um cluster publica

Todo cluster Kubernetes assina os tokens das suas service accounts, então todo cluster tem um
emissor. O que o AKS acrescenta é um emissor público. Com o **emissor OIDC** ligado, o AKS serve dois
documentos num endereço na internet, e são eles que o Entra ID lê:

- `/.well-known/openid-configuration`, o documento de descoberta, que dá o nome do emissor e diz
  onde estão as chaves dele;
- `/openid/v1/jwks`, o conjunto de chaves: as metades públicas das chaves com que o cluster assina.

A documentação da Microsoft, lida em 30 de outubro de 2026, dá o endereço como
`https://{region}.oic.prod-aks.azure.com/{tenant_id}/{uuid}/`, uma região, o tenant e um GUID gerado
para cada cluster que nunca muda; para o cluster da loja a região é `brazilsouth`. No AKS Standard,
um cluster criado no Kubernetes 1.34 ou mais novo já nasce com o emissor ligado, e um mais antigo ou
já existente precisa ligá-lo, o que reinicia o API server por um instante. **Uma vez ligado, ele não
pode ser desligado.** As chaves por trás dele rotacionam com `az aks oidc-issuer
rotate-signing-keys`, e a chave antiga e a nova continuam válidas por 24 horas depois disso, tempo
suficiente para o token de cada pod ser substituído por um assinado com a chave nova.

A linha de comando cita as duas chaves que um cluster precisa ligar, e a consulta que lê o endereço
de volta. A ajuda é texto real desta versão; a consulta precisa de uma assinatura e foi recusada:

```
ana@laptop:~/azure$ az aks create --help | grep -e "--enable-oidc-issuer" -e "--enable-workload-identity "
    --enable-oidc-issuer                                          : Enable OIDC issuer.
    --enable-workload-identity                                    : Enable workload identity addon.
ana@laptop:~/azure$ az aks show --resource-group shop --name shop-aks --query oidcIssuerProfile.issuerUrl --output tsv
ERROR: Please run 'az login' to setup account.
```

O API server do kind serve os mesmos dois documentos, pelos mesmos caminhos, e o `kubectl` consegue
lê-los com `--raw`. Pergunte ao cluster da seção anterior:

```
ana@laptop:~/azure$ kubectl get --raw /.well-known/openid-configuration | jq
{
  "issuer": "https://kubernetes.default.svc.cluster.local",
  "jwks_uri": "https://172.19.0.2:6443/openid/v1/jwks",
  "response_types_supported": [
    "id_token"
  ],
  "subject_types_supported": [
    "public"
  ],
  "id_token_signing_alg_values_supported": [
    "RS256"
  ]
}
ana@laptop:~/azure$ kubectl get --raw /openid/v1/jwks | jq '.keys[] | {kid, kty, alg, use}'
{
  "kid": "99-AqXpwvaaJFbhi-CMj4RxNpGO2Fraa1hS_2keI3XU",
  "kty": "RSA",
  "alg": "RS256",
  "use": "sig"
}
```

O `kid` no conjunto de chaves é o `kid` no cabeçalho do token decodificado na seção anterior: **é
assim que quem recebe sabe qual chave pública confere um dado token**, e é por isso que uma rotação
pode publicar duas chaves ao mesmo tempo. O documento de descoberta tem a mesma forma do exemplo da
documentação do AKS, campo por campo. O que difere é de onde ele pode ser lido. O emissor do kind é
`https://kubernetes.default.svc.cluster.local`, um nome que só resolve dentro de um cluster, e o
conjunto de chaves dele fica num endereço privado do Docker no seu laptop. **O Entra ID não
conseguiria buscar essas chaves, então não poderia acreditar num token deste cluster nem com um
tenant de verdade por trás**, e esse é mais um motivo para este curso não tentar a troca.

## A identidade, e a sua credencial

A identidade é uma **identidade gerenciada atribuída pelo usuário**, do tipo que a lição 8 de
`azure-foundations` criou como recurso próprio, aqui chamada `shop-orders`. Credenciais federadas
podem ser acrescentadas a uma dessas ou a um registro de aplicativo, e não a uma identidade
atribuída pelo sistema, que vive e morre com um recurso. A declaração abaixo é todo o lado do Azure:
uma versão reduzida do cluster da lição 11, que mantém só o que esta lição acrescenta a ele, e a
identidade com a sua credencial. Salve como `~/azure/identity.bicep`, sem as notas:

```schooling-example
{"language": "bicep", "file": "identity.bicep", "parts": [{"code": "// identity.bicep\nparam location string = 'brazilsouth'\n\nresource aks 'Microsoft.ContainerService/managedClusters@2026-01-01' = {\n  name: 'shop-aks'\n  location: location\n  identity: {\n    type: 'SystemAssigned'\n  }\n  properties: {\n    dnsPrefix: 'shop'\n    agentPoolProfiles: [\n      {\n        name: 'system'\n        mode: 'System'\n        count: 3\n        vmSize: 'Standard_D4s_v5'\n      }\n    ]\n", "note": "**O cluster da lição 11, reduzido** às propriedades sem as quais ele não existe. Os node pools, o tier e as configurações de upgrade são daquela lição; esta acrescenta os dois blocos abaixo."}, {"code": "    oidcIssuerProfile: {\n      enabled: true\n    }\n    securityProfile: {\n      workloadIdentity: {\n        enabled: true\n      }\n    }\n  }\n}\n\n", "note": "**As duas chaves.** `oidcIssuerProfile` publica o emissor e as suas chaves; `workloadIdentity` instala o webhook que altera os pods com o rótulo. A segunda é inútil sem a primeira, e nada no arquivo diz isso."}, {"code": "resource orders 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {\n  name: 'shop-orders'\n  location: location\n}\n\n", "note": "A identidade que a API de pedidos assume. Ela é um recurso próprio, então sobrevive a qualquer cluster, e o client id dela é o que a anotação da service account cita."}, {"code": "resource trust 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2024-11-30' = {\n  parent: orders\n  name: 'shop-aks-orders'\n  properties: {\n    issuer: aks.properties.oidcIssuerProfile.issuerURL\n", "note": "**A credencial é filha da identidade**, não do cluster. `issuer` é lido do cluster em vez de digitado: a comparação é exata, então uma barra final faltando numa URL colada é uma credencial que não corresponde a token nenhum."}, {"code": "    subject: 'system:serviceaccount:shop:orders'\n", "note": "O `sub` do token: o namespace `shop` e a service account `orders`. **Uma credencial confia numa service account num cluster**, e em nada mais que esse cluster assine."}, {"code": "    audiences: [\n      'api://AzureADTokenExchange'\n    ]\n  }\n}\n\noutput clientId string = orders.properties.clientId\n", "note": "O público que o volume projetado pediu. A saída é o client id que vai na anotação, e que o Azure gera quando cria a identidade."}]}
```

Compile, e leia a credencial de volta no template:

```
ana@laptop:~/azure$ bicep build identity.bicep
ana@laptop:~/azure$ jq '.resources[] | select(.type | endswith("federatedIdentityCredentials")) | .properties' identity.json
{
  "issuer": "[reference(resourceId('Microsoft.ContainerService/managedClusters', 'shop-aks'), '2026-01-01').oidcIssuerProfile.issuerURL]",
  "subject": "system:serviceaccount:shop:orders",
  "audiences": [
    "api://AzureADTokenExchange"
  ]
}
```

Compila sem avisos, e o emissor no template ainda é uma expressão, que o Resource Manager resolve a
partir do cluster quando implanta. Faltam dois passos do lado do Azure, e nenhum está no arquivo. A
identidade precisa de um papel na conta de armazenamento, que a lição 9 de `azure-foundations`
ensinou e a próxima seção mostra como comando. E o client id de `shop-orders` vai para a anotação da
service account, onde `orders.yaml` já tem o marcador.

## O que o compilador pega, e o que ele não consegue

Cometa três deslizes de uma vez: `audience` no lugar de `audiences`, um `s` a mais no sujeito, e o
emissor desligado.

```
ana@laptop:~/azure$ sed -e 's/audiences:/audience:/' -e 's/serviceaccount:shop/serviceaccounts:shop/' -e '/oidcIssuerProfile/,/}/s/enabled: true/enabled: false/' identity.bicep > slips.bicep
ana@laptop:~/azure$ bicep build slips.bicep
/home/ana/azure/slips.bicep(39,3) : Warning BCP035: The specified "object" declaration is missing the following required properties: "audiences". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP035]
/home/ana/azure/slips.bicep(42,5) : Warning BCP089: The property "audience" is not allowed on objects of type "FederatedIdentityCredentialProperties". Did you mean "audiences"? [https://aka.ms/bicep/core-diagnostics#BCP089]
```

**Um deslize de três foi encontrado.** A propriedade com o nome errado é recusada com o nome certo
sugerido, e a ausência dela relatada como uma propriedade obrigatória que falta. Os outros dois
compilam sem uma palavra, porque para o compilador são uma string e um booleano do tipo certo.
`system:serviceaccounts:shop:orders` é um sujeito que nenhum token vai trazer, então o Entra ID não
acharia credencial correspondente; a mensagem documentada para um token sem registro correspondente
é `AADSTS70021: No matching federated identity record found for presented assertion`. O emissor
desligado deixa o webhook ligado sem nada de onde o Entra ID possa buscar chaves. Nenhum dos dois
erros aparece até um pod pedir um token, e esse é o argumento mais forte para ler `issuer` do
cluster, como o arquivo faz, e conferir `subject` contra um token decodificado, como a seção anterior
fez.

## A linha de comando, e os limites

`az identity federated-credential create` escreve o mesmo registro sem Bicep. A ajuda dele diz com o
que cada propriedade é comparada:

```
ana@laptop:~/azure$ az identity federated-credential create --help | sed -n '/^Properties Arguments/,/^$/p'
Properties Arguments
    --audiences                                                  : The aud value in the token sent
                                                                   to Azure for getting the user-
                                                                   assigned managed identity token.
                                                                   The value configured in the
                                                                   federated credential and the one
                                                                   in the incoming token must
                                                                   exactly match for Azure to issue
                                                                   the access token.  Support
                                                                   shorthand-syntax, json-file and
                                                                   yaml-file. Try "??" to show more.
                                                                   Default:
                                                                   ['api://AzureADTokenExchange'].
    --issuer                                                     : The openId connect metadata URL
                                                                   of the issuer of the identity
                                                                   provider that Azure AD would use
                                                                   in the token exchange protocol
                                                                   for validating tokens before
                                                                   issuing a token as the user-
                                                                   assigned managed identity.
    --subject                                                    : The sub value in the token sent
                                                                   to Azure AD for getting the user-
                                                                   assigned managed identity token.
                                                                   The value configured in the
                                                                   federated credential and the one
                                                                   in the incoming token must
                                                                   exactly match for Azure AD to
                                                                   issue the access token. Either
                                                                   'subject' or
                                                                   'claimsMatchingExpression' must
                                                                   be defined, but not both.
```

Três frases ali decidem o comportamento. O público tem **padrão** `api://AzureADTokenExchange`, o
valor que a documentação da Microsoft recomenda e adverte contra mudar. Sujeito e público têm de
**corresponder exatamente** ao token, então `system:serviceaccount:shop:*` é um sujeito que contém
um asterisco, que token nenhum satisfaz, e não um padrão. E a última frase do sujeito cita a única
alternativa: `claimsMatchingExpression`, que a mesma ajuda lista entre os seus argumentos em preview
e que testa as claims do token com uma expressão em vez de uma string fixa. Uma credencial tem um ou
outro, nunca os dois.

Para a loja, o comando é este. Ele não foi executado neste curso: precisa de uma assinatura.

```sh
az identity federated-credential create \
  --name shop-aks-orders \
  --identity-name shop-orders \
  --resource-group shop \
  --issuer "$AKS_OIDC_ISSUER" \
  --subject system:serviceaccount:shop:orders \
  --audiences api://AzureADTokenExchange
```

`AKS_OIDC_ISSUER` guarda o endereço lido com a consulta `az aks show` acima.

A documentação da Microsoft, lida em 30 de outubro de 2026, fixa os limites que dão forma a como
essas credenciais se organizam:

- **20 credenciais federadas por identidade gerenciada.** Cada uma é uma service account num
  cluster, então uma identidade usada pela API de pedidos em quatro clusters gasta quatro, e uma
  equipe que troca de cluster a cada upgrade gasta uma por cluster que ainda não limpou.
- **Leva um instante para propagar.** A página do AKS fala em alguns segundos, a do Entra ID diz que
  um pedido feito vários minutos depois ainda pode falhar com `AADSTS70021` enquanto o cache do
  diretório se atualiza, e as duas recomendam uma breve espera e novas tentativas.
- **Nunca duas ao mesmo tempo numa identidade.** Criar várias credenciais sob a mesma identidade
  simultaneamente falha com HTTP 409, então um template que declara mais de uma faz cada uma
  depender da anterior. Credenciais sob identidades diferentes podem ser criadas em paralelo.

O primeiro limite é o que cresce com a plataforma. O AKS tem uma resposta para ele chamada
identity bindings, que deixa muitos clusters compartilharem uma credencial através de um proxy que o
AKS roda; a documentação o trata como assunto próprio, e este curso o deixa lá.
