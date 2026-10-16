---
title: Identidades federadas, autenticadas em outro lugar
version: 1
---

**Uma identidade federada é um principal que a AWS não criou e para o qual não guarda credencial
nenhuma.** Outra parte a autentica, um provedor de identidade como o GitHub, o Google ou o diretório
da empresa, e entrega a ela uma declaração assinada. A AWS confere a assinatura, encontra uma role
cuja política de confiança aceita essa declaração, e devolve uma sessão de role como a da seção
anterior. A imagem errada é que a federação cria usuários do IAM para gente de fora. **Nenhum
usuário do IAM é criado e nenhuma chave de longo prazo existe do lado da AWS.** A
senha fica com o provedor, e a sessão morre sozinha.

Dois padrões carregam a declaração, e o IAM tem um tipo de provedor para cada um:

| | **OpenID Connect (OIDC)** | **SAML 2.0** |
|---|---|---|
| a declaração | um JSON web token, assinado pelo provedor | uma asserção XML, assinada pelo provedor |
| provedor típico | GitHub Actions, Google, um cluster Kubernetes | um diretório corporativo: Entra ID, Okta, AD FS |
| a chamada ao STS | `AssumeRoleWithWebIdentity` | `AssumeRoleWithSAML` |
| recurso do IAM | `oidc-provider/<host>` | `saml-provider/<name>` |

Para pessoas, a resposta habitual hoje é o IAM Identity Center, que fala SAML com o diretório uma
vez e administra as roles por você. A lição 11 trata dele. **Para uma máquina fora da AWS, a
resposta é OIDC**, e o deployer da loja é o exemplo.

## O GitHub Actions como provedor OIDC

Toda execução do GitHub Actions pode pedir ao GitHub um token, assinado pelo emissor
`token.actions.githubusercontent.com`, que diz de qual repositório, branch e workflow ela é. O IAM
é instruído a confiar nesse emissor uma vez por conta:

```
ana@laptop:~/aws$ aws iam create-open-id-connect-provider --url https://token.actions.githubusercontent.com --client-id-list sts.amazonaws.com
{
    "OpenIDConnectProviderArn": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
}
ana@laptop:~/aws$ aws iam get-open-id-connect-provider --open-id-connect-provider-arn arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com
{
    "Url": "token.actions.githubusercontent.com",
    "ClientIDList": [
        "sts.amazonaws.com"
    ],
    "ThumbprintList": [],
    "CreateDate": "2026-10-16T16:06:33.079357+00:00",
    "Tags": []
}
```

`sts.amazonaws.com` é a **audiência**: o token precisa dizer que foi emitido para a AWS, então um
token que o GitHub fez para outro serviço é recusado. O `--thumbprint-list` ficou de fora de
propósito. A referência da AWS para o comando diz que o IAM então busca sozinho a impressão digital
do certificado do provedor, e o moto guardou uma lista vazia.

Agora o `deployer` pode confiar no GitHub em vez da bia. Esta política de confiança substitui a da
seção anterior; salve-a como `~/aws/deployer-github.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:shop/web:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

**A linha `sub` é a que importa.** Todo workflow de todo repositório do GitHub recebe tokens do
mesmo emissor. Uma política de confiança só com a linha `aud` confia em todos eles,
desconhecidos inclusive. `repo:shop/web:ref:refs/heads/main` restringe ao branch `main` do
repositório `web` da loja. O `Principal` diz `Federated` em vez de `AWS`, e a ação é a de
identidade web.

```
ana@laptop:~/aws$ aws iam update-assume-role-policy --role-name deployer --policy-document file://deployer-github.json
ana@laptop:~/aws$ aws iam get-role --role-name deployer --query "Role.AssumeRolePolicyDocument.Statement[0].Principal"
{
    "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
}
```

Um workflow agora chamaria `AssumeRoleWithWebIdentity` com o seu token. **Essa chamada não é
assinada com chave nenhuma da AWS**, porque o token é a credencial, então a linha de comando pode
enviá-la com `--no-sign-request`. No moto, com um token que claramente não é um:

```
ana@laptop:~/aws$ aws sts assume-role-with-web-identity --no-sign-request --role-arn arn:aws:iam::123456789012:role/deployer --role-session-name run-1207 --web-identity-token not-a-real-token --query "{User:AssumedRoleUser,Key:Credentials.AccessKeyId}"
{
    "User": {
        "AssumedRoleId": "ARO123EXAMPLE123:run-1207",
        "Arn": "arn:aws:sts::123456789012:assumed-role/deployer/run-1207"
    },
    "Key": "ASIARZPUZDIKB7J62LAY"
}
```

**O moto entregou uma sessão em troca de um token inventado. A AWS o recusaria**: ela confere a
assinatura do token contra as chaves que o provedor publica, a validade, e depois as condições `aud`
e `sub` da política de confiança. Nada disso foi rodado aqui. O moto também preenche
`AssumedRoleId` com um marcador, `ARO123EXAMPLE123`, onde a AWS põe o id da própria role. O formato
da resposta, porém, é o da AWS: uma chave `ASIA` e uma sessão `assumed-role/deployer/...`, **sem
segredo nenhum guardado no GitHub**.

## Um provedor SAML

Um provedor SAML é criado a partir do **documento de metadados** do provedor de identidade, um
arquivo XML que o diretório exporta, com o nome dele, o endereço de login e o certificado com que
assina. A linha de comando recusa um documento com menos de 1000 caracteres antes de enviar
qualquer coisa:

```
ana@laptop:~/aws$ aws iam create-saml-provider --name shop-idp --saml-metadata-document '<EntityDescriptor entityID="https://idp.shop.example.com/saml"/>'

aws: [ERROR]: An error occurred (ParamValidation): Parameter validation failed:
Invalid length for parameter SAMLMetadataDocument, value: 64, valid min length: 1000
```

Um documento crível precisa de um certificado. Estes comandos fazem um descartável com o `openssl`,
que o Ubuntu instala por padrão, e escrevem um documento de metadados mínimo em volta dele, em
`~/aws`:

```sh
openssl req -x509 -newkey rsa:2048 -nodes -days 365 -subj /CN=idp.shop.example.com \
  -keyout idp.key -out idp.crt 2>/dev/null
cert=$(grep -v CERTIFICATE idp.crt | tr -d '\n')
cat > idp-metadata.xml <<EOF
<EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata" entityID="https://idp.shop.example.com/saml">
  <IDPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
    <KeyDescriptor use="signing">
      <KeyInfo xmlns="http://www.w3.org/2000/09/xmldsig#">
        <X509Data><X509Certificate>$cert</X509Certificate></X509Data>
      </KeyInfo>
    </KeyDescriptor>
    <SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
                         Location="https://idp.shop.example.com/saml/sso"/>
  </IDPSSODescriptor>
</EntityDescriptor>
EOF
```

```
ana@laptop:~/aws$ wc -c idp-metadata.xml
1668 idp-metadata.xml
ana@laptop:~/aws$ aws iam create-saml-provider --name shop-idp --saml-metadata-document file://idp-metadata.xml
{
    "SAMLProviderArn": "arn:aws:iam::123456789012:saml-provider/shop-idp"
}
ana@laptop:~/aws$ printf '%1000s' '' > blank.xml; aws iam create-saml-provider --name blank --saml-metadata-document file://blank.xml
{
    "SAMLProviderArn": "arn:aws:iam::123456789012:saml-provider/blank"
}
ana@laptop:~/aws$ aws iam list-saml-providers --query "SAMLProviderList[].Arn"
[
    "arn:aws:iam::123456789012:saml-provider/shop-idp",
    "arn:aws:iam::123456789012:saml-provider/blank"
]
```

Uma role para os usuários do diretório confiaria em `saml-provider/shop-idp` como principal
`Federated`, com a ação `sts:AssumeRoleWithSAML`. **O moto não lê o documento**: um arquivo de 1000
espaços foi aceito do mesmo jeito, pelo terceiro comando acima. A AWS interpreta os metadados e
recusa um documento que não consegue ler; isso não foi rodado aqui.

## O que a conta tem agora

```
ana@laptop:~/aws$ aws iam list-users --query "Users[].[UserName,UserId]" --output text
bia	js9pb6447kryw6le9a1i
caio	uamtq0s7tvnse8tqk0us
dani	c9jkpficj8fz3num8nga
ana@laptop:~/aws$ aws iam list-roles --query "Roles[].[RoleName,RoleId,Arn]" --output text
deployer	AROARZPUZDIKPPMZN5TQR	arn:aws:iam::123456789012:role/deployer
ana@laptop:~/aws$ aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[].Arn" --output text
arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com
```

Três usuários, uma role, um provedor OIDC e os dois provedores SAML. **Só a bia tem uma credencial
que dura**, uma senha e uma chave de acesso. O caio e a dani ainda não têm nenhuma, a role não tem
por construção, e as sessões que o GitHub receberia terminam sozinhas.

## Qual principal, para quem

| quem precisa da AWS | o principal | onde neste curso |
|---|---|---|
| uma pessoa da empresa | federação pelo IAM Identity Center, terminando numa sessão de role | lição 11 |
| um programa que roda na AWS | uma role, entregue à máquina | lição 10 |
| um pipeline fora da AWS | um provedor OIDC e uma role, como acima | esta lição |
| a conta de outra empresa | uma role que ela pode assumir, com um external id | lição 9 |
| um programa que não tem outra saída | um usuário do IAM com chave de acesso, girada | lição 12 |
| fechar a conta, o plano de suporte | o usuário root, com MFA | lição 1 |

**Leia a segunda coluna de cima a baixo e as roles estão quase em toda parte.** Usuários do IAM com
chaves são a penúltima linha, e o usuário root a última, que é também a ordem de preferência.
