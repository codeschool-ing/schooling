---
title: A gramática de um documento de política
version: 1
---

**Uma política é um documento JSON com uma lista de instruções (statements), e cada instrução diz
uma coisa só: este efeito, para estas ações, nestes recursos, sob estas condições.** Essa é a
linguagem inteira. O difícil não é a sintaxe, é a leitura: a imagem errada mais comum é a de um
firewall, em que as regras são lidas de cima para baixo e a primeira que bate vence. **O IAM não tem
ordem.** Toda instrução de toda política que se aplica a uma requisição é considerada junto, e a
lição 8 dá a regra que resolve o conjunto. Esta seção é o vocabulário em que essa regra é escrita.

Esta é a política que esta lição dá à bia, a desenvolvedora da loja. Ela permite listar o bucket
`shop-assets` e ler e gravar os objetos dentro dele, e nada mais. Salve-a como
`~/aws/shop-assets-rw.json`; a seção depois da próxima a cria no moto:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ListTheAssetsBucket",
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::shop-assets"
    },
    {
      "Sid": "ReadAndWriteItsObjects",
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "arn:aws:s3:::shop-assets/*"
    }
  ]
}
```

## Elemento por elemento

| elemento | o que diz | na política da bia |
|---|---|---|
| `Version` | a versão da **linguagem** de políticas, não do seu documento | `2012-10-17`, que é a que se escreve |
| `Statement` | a lista de instruções, um objeto ou um array deles | duas instruções |
| `Sid` | um rótulo opcional, único dentro da política | `ListTheAssetsBucket` |
| `Effect` | `Allow` ou `Deny`, e nada mais | `Allow` nas duas |
| `Action` | quais chamadas de API, como `serviço:Operação` | `s3:ListBucket`, `s3:GetObject`, `s3:PutObject` |
| `Resource` | quais coisas, como ARNs | o bucket, e os objetos dentro dele |
| `Condition` | quando a instrução vale | nenhuma aqui |

**`Version` é a data em que a AWS fixou a linguagem, e nunca muda com as suas edições.** O único
outro valor, `2008-10-17`, é a linguagem de antes das variáveis de política como
`${aws:username}`, que se escrevem dentro de strings e não são lidas como variáveis na versão
antiga. Um documento sem `Version` é lido como o antigo, então escrever a linha toda vez não custa
nada e evita isso.

**Uma ação é um prefixo de serviço e um nome de operação**, e o nome não diferencia maiúsculas de
minúsculas. Dois curingas funcionam nela: `*` para qualquer sequência de caracteres e `?` para
exatamente um. `s3:Get*` cobre `GetObject`, `GetBucketPolicy` e toda outra leitura do S3 cujo nome
comece assim, inclusive as que a AWS acrescentar no ano que vem, que é a propriedade a ter em mente
antes de escrever um curinga. `NotAction` inverte a lista: a instrução passa a cobrir toda ação
exceto as nomeadas.

**Um recurso é um ARN, e o do S3 não tem região nem conta**, porque nomes de bucket são únicos em
toda a AWS: `arn:aws:s3:::shop-assets`. O bucket e os objetos dele são recursos diferentes, e por
isso a política da bia tem duas instruções. **`s3:ListBucket` é uma ação sobre o bucket**, então
precisa do ARN do bucket; `GetObject` e `PutObject` agem sobre objetos, então precisam de
`shop-assets/*`. Trocar os dois recursos é um dos erros mais comuns em políticas do S3, e o
resultado é uma política que não concede nada do que deveria.

**Uma condição é um operador, uma chave e um valor**, como `"IpAddress": {"aws:SourceIp":
"203.0.113.0/24"}`. A lição 8 trata delas, e diz o que o moto faz com uma: ele não a avalia.

## O elemento que não está aqui

Uma política de identidade não tem `Principal`, porque o principal é quem tiver a política anexada.
**`Principal` pertence aos dois tipos de política anexados a outra coisa**: a política de confiança
de uma role, que a lição 6 escreveu, e uma política baseada em recurso, como a política de um
bucket, que a lição 8 lê. A AWS recusa uma política de identidade que nomeia um principal; a última
seção desta lição mostra o moto aceitando uma.
