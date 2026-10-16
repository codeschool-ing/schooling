---
title: Herdadas árvore abaixo: permitidas em todo nível, negadas em nenhum
version: 1
---

**Uma requisição passa pelas SCPs só se todo nível entre a conta dela e a raiz a permitir, e nenhum
nível a negar.** A imagem errada é herança como num sistema de arquivos, onde uma configuração numa
pasta é copiada para cada arquivo abaixo e o arquivo pode sobrescrevê-la. Uma SCP nunca é copiada e
nunca é sobrescrita. Cada nível do caminho é um filtro separado, e a requisição atravessa todos: a
raiz, cada OU no caminho para baixo e a própria conta.

As duas metades da regra funcionam de jeitos diferentes, e dão os dois jeitos de escrever SCPs.

## Um deny em qualquer lugar vence: a lista de negação

**Mantenha a `FullAWSAccess` em todo lugar e acrescente políticas que negam.** Todo nível permite
tudo, então a metade da permissão sempre é cumprida. As barreiras são instruções `Deny`, e um deny
anexado em qualquer nível, na raiz ou na conta, barra a requisição. Essa é a **lista de negação**
(deny list), e é a estratégia que a AWS descreve primeiro e que a maioria das empresas usa. Ela tem
uma propriedade que importa num dia corrido: um serviço novo da AWS é permitido no dia em que é
lançado, e ninguém precisa lembrar de acrescentá-lo.

A loja usa uma lista de negação para tudo menos o seu sandbox. A próxima seção escreve os seus quatro
denies.

## Um allow em todo nível: a lista de permissão

**Troque a `FullAWSAccess` de um nível por uma política que permite só alguns serviços**, e dali em
diante só esses serviços passam por aquele nível. Essa é a **lista de permissão** (allow list). A
força dela é que tudo o que não está na lista é recusado, um serviço novo inclusive. O custo dela é
exatamente o mesmo fato: todo serviço de que alguém precisa de verdade tem de ser acrescentado
antes.

O allow tem de estar presente **em todo nível do caminho**. Uma conta cujas próprias SCPs permitem
tudo ainda perde o que a lista de permissão da OU dela deixa de fora. Uma conta sob uma OU que
permite tudo ainda é limitada por uma lista de permissão anexada à própria conta. Os níveis não se
somam; eles se cruzam.

A OU `Sandbox` da loja ganha uma, para os experimentos ficarem em serviços baratos e fáceis de
limpar. Crie um diretório para arquivos de SCP com `mkdir -p ~/aws/scp`, e salve este lá como
`scp/sandbox-allow-list.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "SandboxMayUseOnlyThese",
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "s3:*",
        "lambda:*",
        "dynamodb:*",
        "cloudwatch:*",
        "logs:*",
        "iam:*",
        "sts:*"
      ],
      "Resource": "*"
    }
  ]
}
```

Depois crie a política, anexe-a à `Sandbox`, e só então tire a `FullAWSAccess`. Uma função `policy`,
como as duas da lição 3, acha o id de uma política pelo nome:

```
ana@laptop:~/aws$ policy() { aws organizations list-policies --filter SERVICE_CONTROL_POLICY --query "Policies[?Name=='$1'].Id" --output text; }
ana@laptop:~/aws$ aws organizations create-policy --name sandbox-allow-list --type SERVICE_CONTROL_POLICY --description "What the sandbox may use" --content file://scp/sandbox-allow-list.json --query Policy.PolicySummary.Id --output text
p-18q5xsw4
ana@laptop:~/aws$ aws organizations attach-policy --policy-id $(policy sandbox-allow-list) --target-id $sandbox
ana@laptop:~/aws$ aws organizations detach-policy --policy-id p-FullAWSAccess --target-id $sandbox
ana@laptop:~/aws$ for t in $root $sandbox $(account sandbox); do echo "$t: $(aws organizations list-policies-for-target --target-id $t --filter SERVICE_CONTROL_POLICY --query "Policies[].Name" --output text)"; done
r-ucqy: FullAWSAccess
ou-ucqy-bqcc9il2: sandbox-allow-list
798632694501: FullAWSAccess
```

A raiz e a conta `sandbox` continuam com a `FullAWSAccess`; a OU entre elas carrega só a lista de
permissão, então **a conta fica com a lista de permissão**. Um banco de dados na `sandbox`, `rds:*`,
agora é recusado na OU seja como for escrito o IAM da própria conta, e o mesmo vale para qualquer
serviço que a AWS lançar no ano que vem.

A figura desenha a árvore como ela fica no fim desta lição, com as quatro barreiras da próxima seção
já nela, e segue três requisições árvore abaixo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 400\" role=\"img\" data-fig=\"l04-inheritance\" aria-label=\"As SCPs nos dois caminhos da árvore da loja depois desta lição. A raiz carrega FullAWSAccess, deny-leaving, sa-east-1-only e protect-security-services. No caminho da esquerda, Workloads carrega FullAWSAccess e protect-deployer, Prod e a conta shop-prod carregam FullAWSAccess. No caminho da direita, Sandbox carrega só sandbox-allow-list, e a conta sandbox carrega FullAWSAccess. Um pedido de EC2 em us-east-1 vindo da shop-prod é negado na raiz. Um pedido de RDS em sa-east-1 vindo da sandbox passa pela raiz e não é permitido em Sandbox, então é recusado lá.\"><defs><marker id=\"l04-inheritance-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"230.0\" y=\"16.0\" width=\"260.0\" height=\"86.0\" rx=\"10\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Root</text><text x=\"360.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">FullAWSAccess</text><text x=\"360.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">deny-leaving</text><text x=\"360.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">sa-east-1-only</text><text x=\"360.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">protect-security-services</text><rect x=\"80.0\" y=\"140.0\" width=\"220.0\" height=\"56.0\" rx=\"10\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"190.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Workloads</text><text x=\"190.0\" y=\"171.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">FullAWSAccess</text><text x=\"190.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">protect-deployer</text><rect x=\"80.0\" y=\"226.0\" width=\"220.0\" height=\"41.0\" rx=\"10\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"190.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Prod</text><text x=\"190.0\" y=\"257.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">FullAWSAccess</text><rect x=\"80.0\" y=\"297.0\" width=\"220.0\" height=\"41.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"190.0\" y=\"311.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">shop-prod</text><text x=\"190.0\" y=\"328.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">FullAWSAccess</text><rect x=\"420.0\" y=\"140.0\" width=\"220.0\" height=\"41.0\" rx=\"10\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"530.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Sandbox</text><text x=\"530.0\" y=\"171.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">sandbox-allow-list</text><rect x=\"420.0\" y=\"211.0\" width=\"220.0\" height=\"41.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"530.0\" y=\"225.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">sandbox</text><text x=\"530.0\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">FullAWSAccess</text><path d=\"M300.0 102.0 L300.0 119.5 L190.0 119.5 L190.0 137.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-inheritance-af-ah-paper-dim)\"></path><path d=\"M420.0 102.0 L420.0 119.5 L530.0 119.5 L530.0 137.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-inheritance-af-ah-paper-dim)\"></path><path d=\"M190.0 196.0 L190.0 209.5 L190.0 209.5 L190.0 223.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-inheritance-af-ah-paper-dim)\"></path><path d=\"M190.0 267.0 L190.0 280.5 L190.0 280.5 L190.0 294.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-inheritance-af-ah-paper-dim)\"></path><path d=\"M530.0 181.0 L530.0 194.5 L530.0 194.5 L530.0 208.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-inheritance-af-ah-paper-dim)\"></path><text x=\"190.0\" y=\"364.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">EC2 em us-east-1: negado na raiz</text><text x=\"530.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">RDS em sa-east-1: não permitido em Sandbox</text><text x=\"530.0\" y=\"296.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">EC2 em sa-east-1: permitido em todo nível</text><text x=\"360.0\" y=\"390.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">as políticas destacadas são da loja; FullAWSAccess é da AWS</text></svg>", "caption": "Cada nível do caminho é um filtro. Um deny em qualquer um deles, ou um allow que falta, recusa o pedido."}
```

## A ordem importa, e o moto não a verifica

**A AWS se recusa a deixar um alvo sem SCP nenhuma.** A referência da API para `DetachPolicy` diz que
toda raiz, OU e conta precisa ter pelo menos uma SCP anexada. É por isso que a lista de permissão
entrou antes de a `FullAWSAccess` sair: um alvo sem nada anexado não permitiria nada. A recusa é uma
`ConstraintViolationException` cujo motivo é `MIN_POLICY_TYPE_ATTACHMENT_LIMIT_EXCEEDED`. O moto não
aplica isso:

```
ana@laptop:~/aws$ aws organizations detach-policy --policy-id $(policy sandbox-allow-list) --target-id $sandbox
ana@laptop:~/aws$ aws organizations list-policies-for-target --target-id $sandbox --filter SERVICE_CONTROL_POLICY --query "Policies[].Name"
[]
ana@laptop:~/aws$ aws organizations attach-policy --policy-id $(policy sandbox-allow-list) --target-id $sandbox
```

O moto tirou a última política e a OU ficou com a lista vazia. **Na AWS esse detach teria falhado**,
e essa parte não foi rodada aqui. O último comando pôs a lista de permissão de volta, então a árvore
fica como a loja a quer para a próxima seção.
