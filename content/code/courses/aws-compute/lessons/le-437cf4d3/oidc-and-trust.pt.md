---
title: O emissor do cluster, e um role que confia nele
version: 1
---

O IRSA tem três peças, e só uma delas é nova. **O cluster já tem um provedor de identidade próprio;
você diz ao IAM que acredite nele; e escreve um role cuja política de confiança aceita uma service
account e mais ninguém.** Um quarto passo, fora da AWS, aponta a service account para o role. Esta
seção monta as três peças no moto e mostra a quarta como o arquivo que ela é.

A imagem que muita gente traz é a de que o cluster faz login no IAM em nome do pod, ou de que o IRSA
cria por baixo um usuário do IAM por pod. **Nenhuma das duas acontece.** O próprio pod chama o STS,
levando um token que o Kubernetes assinou, e a AWS lhe dá credenciais porque o IAM foi avisado de
antemão de quem é a assinatura a aceitar. Nada na AWS guarda um segredo para o pod, que é a
propriedade que a seção anterior pediu.

## O emissor que todo cluster tem

O Kubernetes já assina um token para cada service account, para que um pod possa provar ao API
server quem é. No EKS quem assina é publicado como um **emissor OpenID Connect**: uma URL, única do
cluster, onde qualquer um pode buscar um documento de descoberta e as chaves públicas que conferem as
assinaturas. A aula 11 viu o campo quando criou um cluster. Crie um de novo, e peça o emissor:

```
ana@laptop:~/aws$ aws eks create-cluster --name shop --role-arn arn:aws:iam::123456789012:role/shop-cluster --resources-vpc-config subnetIds=subnet-0a1,subnet-0b2 --query cluster.identity
{
    "oidc": {
        "issuer": "https://oidc.eks.sa-east-1.amazonaws.com/id/lOAQdZ7XP0"
    }
}
ana@laptop:~/aws$ ISSUER=$(aws eks describe-cluster --name shop --query cluster.identity.oidc.issuer --output text)
ana@laptop:~/aws$ aws iam create-open-id-connect-provider --url "$ISSUER" --client-id-list sts.amazonaws.com
{
    "OpenIDConnectProviderArn": "arn:aws:iam::123456789012:oidc-provider/oidc.eks.sa-east-1.amazonaws.com/id/lOAQdZ7XP0"
}
```

Duas coisas nessa resposta são do moto, e não da AWS. Na AWS a última parte do emissor tem 32
caracteres hexadecimais, onde o moto inventa dez com maiúsculas e minúsculas, e o cluster do moto
informa Kubernetes 1.19, uma versão que a AWS aposentou há muito tempo. Mais importante para esta
aula, **nada responde naquela URL no seu laptop.** Na AWS ela serve
`/.well-known/openid-configuration` e um conjunto de chaves, e o STS busca as chaves ali; aqui nenhum
servidor guarda chaves e nenhum token é assinado, então a próxima seção precisa tomar cuidado com o
que a troca prova.

O terceiro comando é o passo que importa. **Um provedor OIDC do IAM é um registro na sua conta que
diz: tokens assinados por este emissor, para esta audiência, merecem crédito.** A audiência,
`--client-id-list`, é `sts.amazonaws.com`, que é o que os tokens do EKS feitos para o IRSA trazem.

Não há `--thumbprint-list`, e na AWS nenhum é necessário. A referência da API que a linha de comando
traz diz que o campo é opcional. A AWS confere o certificado TLS do endpoint de chaves do emissor
contra a sua própria biblioteca de autoridades certificadoras confiáveis, e só consulta um
thumbprint quando esse certificado não foi assinado por uma delas. O de um emissor do EKS foi.

É preciso um provedor **por cluster**, porque cada cluster tem o seu emissor. Uma equipe que roda um
cluster por ambiente e troca de cluster nas atualizações cria e apaga provedores tão seguido quanto
clusters, e o IAM limita quantos uma conta pode ter, 100 por padrão. A seção 05 volta a esse custo.

## A política de confiança

A aula 9 de `aws-foundations` dividiu um role em dois: a política de permissão diz o que o role pode
fazer, e a política de confiança diz quem pode se tornar ele. O IRSA mora na política de confiança.
Cole isto no terminal onde `ISSUER` foi definido; ele escreve o `trust.json` do seu próprio cluster:

```schooling-example
{"language": "sh", "parts": [{"code": "OIDC=${ISSUER#https://}\ncat > trust.json <<EOF\n{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Effect\": \"Allow\",\n", "note": "`OIDC` é o emissor sem o `https://`, porque é assim que o IAM nomeia o provedor e as chaves das suas condições. O `EOF` do heredoc não está entre aspas, então o shell põe o valor de `$OIDC` no arquivo em todo lugar onde ele aparece."}, {"code": "      \"Principal\": {\n        \"Federated\": \"arn:aws:iam::123456789012:oidc-provider/$OIDC\"\n      },\n", "note": "**Quem pode assumir o role: quem tiver um token deste emissor, e só deste.** `Federated` nomeia o provedor OIDC do IAM criado acima. Um token assinado pelo emissor de outro cluster não casa com nada aqui."}, {"code": "      \"Action\": \"sts:AssumeRoleWithWebIdentity\",\n", "note": "A única porta de entrada. É a chamada que troca um token por credenciais, e é a única ação que a declaração permite."}, {"code": "      \"Condition\": {\n        \"StringEquals\": {\n          \"$OIDC:sub\": \"system:serviceaccount:shop:photos\",\n", "note": "`sub` é o sujeito do token: o namespace `shop` e a service account `photos`. **Sem esta linha qualquer pod do cluster poderia assumir o role**, porque o token de todo pod vem do mesmo emissor."}, {"code": "          \"$OIDC:aud\": \"sts.amazonaws.com\"\n        }\n      }\n    }\n  ]\n}\nEOF\n", "note": "`aud` é a audiência para a qual o token foi emitido. Um token que o Kubernetes emitiu para outra finalidade, com outra audiência, é recusado mesmo quando o sujeito confere."}]}
```

O que ele escreveu, com o emissor deste cluster nos três lugares onde estava a variável:

```
ana@laptop:~/aws$ cat trust.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789012:oidc-provider/oidc.eks.sa-east-1.amazonaws.com/id/lOAQdZ7XP0"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.sa-east-1.amazonaws.com/id/lOAQdZ7XP0:sub": "system:serviceaccount:shop:photos",
          "oidc.eks.sa-east-1.amazonaws.com/id/lOAQdZ7XP0:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
```

As duas condições são a parte para ler devagar. Um token deste emissor só serve para este role se o
seu `sub` nomeia a service account `photos` no namespace `shop` e o seu `aud` diz STS. **Tire a
linha do `sub` e o role passa a confiar em todo pod do cluster**, inclusive no pod de depuração da
seção anterior, porque os tokens de todos vêm do mesmo emissor. O mesmo erro numa forma mais branda
é `StringLike` com `system:serviceaccount:shop:*`, que entrega o role a toda service account do
namespace, inclusive às criadas no ano que vem.

Depois, o próprio role, e a única coisa que ele pode fazer:

```
ana@laptop:~/aws$ aws iam create-role --role-name photos-reader --assume-role-policy-document file://trust.json --query Role.Arn
"arn:aws:iam::123456789012:role/photos-reader"
ana@laptop:~/aws$ aws iam put-role-policy --role-name photos-reader --policy-name read-photos --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:GetObject","Resource":"arn:aws:s3:::shop-photos-123456789012/*"}]}'
```

`read-photos` permite `s3:GetObject` no bucket da loja e nada mais. Essa política de permissão é uma
como outra qualquer; o que faz deste um role de IRSA é só a política de confiança acima dela.

## A quarta peça, no Kubernetes

O role existe, e o cluster ainda precisa saber a qual service account ele pertence. Isso é uma
anotação na service account, e o pod nomeia a service account na sua spec:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: photos
  namespace: shop
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/photos-reader
```

**Este arquivo não é aplicado em lugar nenhum deste curso, porque o moto não roda Kubernetes** e não
existe API server para o `kubectl` conversar. Num cluster de verdade, `kubectl apply -f` o cria, e um
pod com `serviceAccountName: photos` na spec recebe o role. Só um pod criado depois da anotação
recebe: o role é ligado ao pod quando o pod é feito, então um que já estava rodando continua sem ele,
e esse é o motivo mais comum de uma anotação "não funcionar".

A anotação sozinha não concede nada. Uma service account anotada com um role cuja política de
confiança nomeia outro sujeito recebe um token que o STS vai recusar, e a primeira chamada do pod à
AWS falha. **A política de confiança é a fechadura, e a anotação é só o endereço no envelope.**

`eksctl create iamserviceaccount` faz os quatro passos num comando só, e a maioria das equipes usa
ele ou o módulo de EKS do Terraform. Fazer os passos à mão uma vez é como se aprende a ler o que
essas ferramentas deixam na conta.
