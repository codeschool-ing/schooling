---
title: Moldando a resposta: --query, --output, --dry-run e páginas
version: 1
---

**Toda resposta que a linha de comando imprime é um documento JSON da API, recortado pelo `--query`
e disposto pelo `--output`.** Os dois rodam no seu computador, depois de a resposta chegar: nenhum
muda o que foi pedido à AWS nem o que ela devolve. As duas opções do fim desta seção, `--dry-run` e
as de paginação, são do tipo oposto, porque mudam as requisições.

A imagem errada é que o `--query` é um filtro que a AWS aplica. **Ele é uma expressão JMESPath que a
linha de comando avalia sobre a resposta inteira**, e é por isso que ele consegue contar, ordenar e
remodelar, e por isso um filtro no `--query` não deixa uma listagem grande mais barata. Alguns
comandos têm também um `--filters` do lado do servidor, e esse sim reduz o que é enviado.

## JMESPath, a linguagem do `--query`

A lição 1 apresentou `length()` e um filtro. As peças se combinam:

```
ana@laptop:~/aws$ aws iam list-policies --scope AWS --query "length(Policies)"
1544
ana@laptop:~/aws$ aws iam list-policies --scope AWS --query "Policies[?starts_with(PolicyName, \`AmazonS3\`)].PolicyName" --output text
AmazonS3ExpressFullAccess	AmazonS3ExpressReadOnlyAccess	AmazonS3FilesCSIDriverPolicy	AmazonS3FilesClientFullAccess	AmazonS3FilesClientReadOnlyAccess	AmazonS3FilesClientReadWriteAccess	AmazonS3FilesFullAccess	AmazonS3FilesReadOnlyAccess	AmazonS3FullAccess	AmazonS3ObjectLambdaExecutionRolePolicy	AmazonS3OutpostsFullAccess	AmazonS3OutpostsReadOnlyAccess	AmazonS3ReadOnlyAccess	AmazonS3TablesFullAccess	AmazonS3TablesLakeFormationServiceRole	AmazonS3TablesReadOnlyAccess
```

`Policies` é a lista dentro da resposta, `[? … ]` guarda os elementos para os quais a condição é
verdadeira, `starts_with` é uma das funções do JMESPath, e `.PolicyName` projeta um campo de cada
elemento que sobrou. **Literais vão entre crases**, que o shell também usa, então a expressão vai
entre aspas duplas e cada crase é escapada com uma barra invertida.

Mais quatro formas cobrem quase toda consulta deste curso:

| expressão | o que faz |
|---|---|
| `Vpcs[0]` | o primeiro elemento de uma lista |
| `Vpcs[].[VpcId,CidrBlock]` | uma lista de listas, uma linha por elemento, que o `--output text` imprime como colunas |
| `Policies[].{name: PolicyName, v: DefaultVersionId}` | uma lista de objetos com as chaves que você escolhe, que o `--output table` imprime com cabeçalhos |
| `sort_by(Policies, &AttachmentCount)` | a lista ordenada por um campo |

## Quatro jeitos de imprimir a mesma resposta

```
ana@laptop:~/aws$ aws sts get-caller-identity --output json
{
    "UserId": "AKIAIOSFODNN7EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:user/moto"
}
ana@laptop:~/aws$ aws sts get-caller-identity --output text
123456789012	arn:aws:sts::123456789012:user/moto	AKIAIOSFODNN7EXAMPLE
ana@laptop:~/aws$ aws sts get-caller-identity --output yaml
Account: '123456789012'
Arn: arn:aws:sts::123456789012:user/moto
UserId: AKIAIOSFODNN7EXAMPLE
ana@laptop:~/aws$ aws iam list-policies --scope AWS --query "Policies[?starts_with(PolicyName, \`AmazonS3\`)].{name: PolicyName, versions: DefaultVersionId, attached: AttachmentCount}" --output table
---------------------------------------------------------------------
|                           ListPolicies                            |
+----------+-------------------------------------------+------------+
| attached |                   name                    | versions   |
+----------+-------------------------------------------+------------+
|  0       |  AmazonS3ExpressFullAccess                |  v1        |
|  0       |  AmazonS3ExpressReadOnlyAccess            |  v1        |
|  0       |  AmazonS3FilesCSIDriverPolicy             |  v1        |
|  0       |  AmazonS3FilesClientFullAccess            |  v1        |
|  0       |  AmazonS3FilesClientReadOnlyAccess        |  v1        |
|  0       |  AmazonS3FilesClientReadWriteAccess       |  v1        |
|  0       |  AmazonS3FilesFullAccess                  |  v1        |
|  0       |  AmazonS3FilesReadOnlyAccess              |  v1        |
|  0       |  AmazonS3FullAccess                       |  v2        |
|  0       |  AmazonS3ObjectLambdaExecutionRolePolicy  |  v1        |
|  0       |  AmazonS3OutpostsFullAccess               |  v1        |
|  0       |  AmazonS3OutpostsReadOnlyAccess           |  v1        |
|  0       |  AmazonS3ReadOnlyAccess                   |  v3        |
|  0       |  AmazonS3TablesFullAccess                 |  v6        |
|  0       |  AmazonS3TablesLakeFormationServiceRole   |  v6        |
|  0       |  AmazonS3TablesReadOnlyAccess             |  v3        |
+----------+-------------------------------------------+------------+
```

**`json` é para programas, `text` para o shell, `table` para pessoas, e `yaml` para arquivos.** O
`text` põe cada valor numa coluna separada por tabulações, numa ordem que a API decide, e é por isso
que combina bem com um `--query` que escolhe a ordem; `cut` e `read` o separam sem parser. O `table`
desenha bordas e títulos, e é o que nunca se deve passar a outro programa. O último comando mostra o
que um hash de seleção múltipla rende numa tabela: os cabeçalhos são as chaves que a consulta
nomeou. O `yaml-stream` é um quinto formato, que imprime cada página de uma listagem longa conforme
ela chega.

## `--dry-run`: perguntando se, sem fazer

**O EC2 aceita `--dry-run` nas chamadas que criam, mudam ou apagam**, e responde se a chamada teria
sido permitida sem fazê-la:

```
ana@laptop:~/aws$ aws ec2 run-instances --image-id ami-0629d059c178d0eac --instance-type t3.micro --dry-run; echo "exit $?"

aws: [ERROR]: An error occurred (DryRunOperation) when calling the RunInstances operation: Request would have succeeded, but DryRun flag is set.
exit 254
ana@laptop:~/aws$ aws ec2 describe-instances --query "length(Reservations)"
0
```

**Um dry run bem-sucedido é um erro**, `DryRunOperation`, com a frase "Request would have
succeeded", e código de saída 254. Um script que testa `$?` precisa olhar o código do erro, já que
os dois desfechos falham. Quem não tem a permissão recebe `UnauthorizedOperation` na AWS; o moto aqui
não verifica permissões, então essa metade não foi medida. Nenhuma instância foi criada, como a
contagem mostra. A opção é do EC2; a maioria dos serviços não tem nada parecido, e o curso se apoia
na verificação de permissões do moto para a mesma pergunta em outras lições.

## Páginas, que a linha de comando esconde

Listagens voltam da API em páginas: o `ListPolicies` do IAM devolve 100 políticas por chamada por
padrão, com um `Marker` que pede a página seguinte. **A linha de comando segue os marcadores
sozinha** e imprime uma resposta, então as 1544 políticas acima, a cópia do moto das gerenciadas
pela AWS, levaram várias requisições. O `--debug` relata cada uma:

```
ana@laptop:~/aws$ aws iam list-policies --scope AWS --query "length(Policies)" --debug 2>&1 | grep -c "Making request for OperationModel(name=ListPolicies"
16
ana@laptop:~/aws$ aws iam list-policies --scope AWS --page-size 500 --query "length(Policies)" --debug 2>&1 | grep -c "Making request for OperationModel(name=ListPolicies"
4
```

**O `--page-size` muda quantos itens cada requisição pede, e nada na resposta**: 16 requisições de
100 viraram 4 de 500, com as mesmas 1544 políticas no fim. Isso importa diante de um serviço que
limita a taxa, ou de uma chamada que estoura o tempo numa página grande. **O `--max-items` muda a
resposta**: ele para depois de tantos itens e imprime um `NextToken`, e o `--starting-token`
continua dali:

```
ana@laptop:~/aws$ aws iam list-policies --scope AWS --max-items 2 --query "{names: Policies[].PolicyName, next: NextToken}"
{
    "names": [
        "AIDevOpsAgentAccessPolicy",
        "AIDevOpsAgentActionsPolicy"
    ],
    "next": "eyJNYXJrZXIiOiBudWxsLCAiYm90b190cnVuY2F0ZV9hbW91bnQiOiAyfQ=="
}
ana@laptop:~/aws$ NEXT=$(aws iam list-policies --scope AWS --max-items 2 --output json | jq -r .NextToken)
ana@laptop:~/aws$ aws iam list-policies --scope AWS --max-items 2 --starting-token $NEXT --query "Policies[].PolicyName"
[
    "AIDevOpsAgentFullAccess",
    "AIDevOpsAgentReadOnlyAccess"
]
```

O token é da própria linha de comando, construído em volta do marcador do serviço, e só vale para o
mesmo comando com as mesmas opções. O `--no-paginate` desliga o acompanhamento de vez e imprime só a
primeira página que a API mandou.
