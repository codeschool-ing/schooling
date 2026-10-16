---
title: Políticas inline, e como escolher entre as três
version: 1
---

**Uma política inline é escrita dentro de um usuário, grupo ou role e não pertence a mais nada.**
Ela tem nome mas não tem ARN, então nenhuma outra identidade pode recebê-la. Não tem versões, então
uma edição a sobrescreve. E vive exatamente o tempo da identidade que a guarda. A imagem errada é que
inline é o tipo rápido e informal, para quando uma política gerenciada parece cerimônia demais.
**Inline é o tipo rigoroso**: é o único jeito de garantir que uma permissão nunca seja anexada a uma
segunda identidade por alguém arrumando as coisas.

## Uma política para o edu, o prestador de serviço

O edu entra na loja por dois meses para redesenhar a vitrine, e precisa enviar imagens para um
prefixo do `shop-assets`. Uma permissão que tem de sair junto com ele é o caso para o qual existe a
inline. Salve isto como `~/aws/edu-uploads.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "UploadStorefrontImages",
      "Effect": "Allow",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::shop-assets/storefront/*"
    }
  ]
}
```

O `put-user-policy` a escreve dentro do usuário do edu. **Não há passo de `create-policy`**, porque a
política não existe separada dele:

```
ana@laptop:~/aws$ aws iam create-user --user-name edu --query User.Arn --output text
arn:aws:iam::123456789012:user/edu
ana@laptop:~/aws$ aws iam put-user-policy --user-name edu --policy-name storefront-uploads --policy-document file://edu-uploads.json
ana@laptop:~/aws$ aws iam list-user-policies --user-name edu
{
    "PolicyNames": [
        "storefront-uploads"
    ]
}
ana@laptop:~/aws$ aws iam list-attached-user-policies --user-name edu
{
    "AttachedPolicies": []
}
```

O `list-user-policies` lista só as políticas inline. As gerenciadas anexadas a um usuário são outra
lista, `list-attached-user-policies`, e uma auditoria que lê uma e não a outra perde metade do que um
usuário pode fazer.

Quando o edu sai, o usuário dele vai embora, e a API deixa a ordem visível:

```
ana@laptop:~/aws$ aws iam delete-user --user-name edu

aws: [ERROR]: An error occurred (DeleteConflict) when calling the DeleteUser operation: Cannot delete entity, must delete policies first.
ana@laptop:~/aws$ aws iam delete-user-policy --user-name edu --policy-name storefront-uploads
ana@laptop:~/aws$ aws iam delete-user --user-name edu
ana@laptop:~/aws$ aws iam get-user --user-name edu

aws: [ERROR]: An error occurred (NoSuchEntity) when calling the GetUser operation: The user with name edu cannot be found.
```

**A recusa é uma salvaguarda, não um resto.** A AWS não apaga um usuário que ainda tem uma política,
então a linha de comando nomeia cada uma antes. O botão de apagar do console faz os mesmos passos
por você. De um jeito ou de outro, quando o usuário some **a política inline some com ele**: não há
cópia em lugar nenhum para anexar ao próximo prestador por engano. Uma política gerenciada teria
sobrevivido a ele, ainda anexável, o que às vezes é o que se quer e aqui não é.

## Um principal onde não cabe nenhum

A primeira seção disse que a AWS recusa uma política de identidade que nomeia um `Principal`. O moto
não recusa:

```
ana@laptop:~/aws$ aws iam put-user-policy --user-name bia --policy-name with-principal --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"*"},"Action":"s3:ListBucket","Resource":"arn:aws:s3:::shop-backups"}]}'
ana@laptop:~/aws$ with_key "$bia" aws s3api list-objects-v2 --bucket shop-backups
{
    "RequestCharged": null,
    "Prefix": ""
}
ana@laptop:~/aws$ aws iam delete-user-policy --user-name bia --policy-name with-principal
```

**O moto a guardou, e depois a obedeceu**: o segundo comando é a bia listando `shop-backups`, o que a
política gerenciada pelo cliente dela nunca permitiu. A AWS teria recusado o documento como
malformado antes de guardar qualquer coisa; isso não foi rodado aqui. Num laboratório, isso quer
dizer que uma política que funciona no moto ainda não é uma política que a AWS aceita. A lição 8
nomeia a ferramenta que confere um documento contra a gramática da AWS.

## Os limites, como o moto os informa

```
ana@laptop:~/aws$ aws iam get-account-summary --query "SummaryMap.{PolicySizeQuota:PolicySizeQuota,UserPolicySizeQuota:UserPolicySizeQuota,GroupPolicySizeQuota:GroupPolicySizeQuota,AttachedPoliciesPerUserQuota:AttachedPoliciesPerUserQuota,VersionsPerPolicyQuota:VersionsPerPolicyQuota}"
{
    "PolicySizeQuota": 6144,
    "UserPolicySizeQuota": 2048,
    "GroupPolicySizeQuota": 5120,
    "AttachedPoliciesPerUserQuota": 10,
    "VersionsPerPolicyQuota": 5
}
```

Os números são caracteres, exceto os dois últimos. **Uma política gerenciada comporta 6.144
caracteres, uma política inline num usuário só 2.048**, e um usuário pode ter dez políticas
gerenciadas anexadas. Esses números batem com as cotas da documentação da AWS, onde a última pode
ser aumentada a pedido. O tamanho pequeno das políticas inline de um usuário é uma pista do que elas
são: uma permissão curta e específica, não uma biblioteca.

## Escolhendo

| | gerenciada pela AWS | gerenciada pelo cliente | inline |
|---|---|---|---|
| escrita por | AWS | você | você |
| tem ARN, pode ser anexada a muitos | sim | sim | não |
| versões | as da AWS, sem você opinar | até cinco, e você escolhe a padrão | nenhuma: uma edição sobrescreve |
| muda quando | a AWS decide | você publica uma versão | você a reescreve |
| desaparece quando | nunca, enquanto a AWS a mantiver | você a apaga | a identidade dela é apagada |
| use para | um ponto de partida, ou uma função de trabalho que a AWS descreve bem | **quase tudo o que você escreve** | uma permissão que deve pertencer a uma identidade só |

**Escreva políticas gerenciadas pelo cliente por padrão.** Elas são revisadas uma vez, anexadas onde
for preciso, e revertidas movendo a versão padrão. Use uma política gerenciada pela AWS quando o
escopo dela é de fato o que você quer, sabendo que ela vai crescer sem pedir licença, como a
`ReadOnlyAccess` cresceu, até 188 versões. Deixe a inline para os casos em que uma segunda anexação
seria o defeito, como os envios do edu ou as permissões de uma role que existe para uma máquina só.
