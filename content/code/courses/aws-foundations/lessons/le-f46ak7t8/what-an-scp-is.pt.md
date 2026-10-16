---
title: Um teto, nunca uma concessão
version: 1
---

**Uma service control policy define o máximo que qualquer pessoa numa conta pode fazer, e não dá
nada a ninguém.** A imagem errada é a que a palavra "política" sugere depois de algumas semanas de
IAM: anexe a uma conta uma SCP que permite S3 e os desenvolvedores dela podem usar S3. A SCP sozinha
não lhes dá nada. Uma SCP é um filtro por onde toda requisição da conta passa a caminho da decisão do
IAM, e ela só consegue tirar permissões.

## Dois filtros em sequência

Uma requisição de uma identidade numa conta-membro só é permitida se **os dois** disserem sim:

- **o IAM da própria conta**, as políticas anexadas ao usuário ou à role, que as lições 6 a 8
  ensinam;
- **toda SCP entre a conta e a raiz**, que esta lição ensina.

**O que a identidade consegue fazer de fato é o que está nos dois.** O IAM concede; as SCPs põem um
teto sobre a concessão. Uma role com `AdministratorAccess` sob uma SCP que só permite EC2 e S3 pode
usar EC2 e S3. Uma role que só tem `s3:GetObject` sob uma SCP que permite tudo continua só lendo
objetos. E um `Deny` explícito em qualquer dos filtros encerra a questão, diga o outro o que disser.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"l04-filter\" aria-label=\"Dois círculos que se sobrepõem. O da esquerda é o que as políticas do IAM da role permitem: ec2, s3 e rds. O da direita é o que as SCPs acima da conta permitem: ec2, s3 e lambda. Só a sobreposição, ec2 e s3, é o que a role pode fazer. rds é concedido pelo IAM e cortado pelas SCPs; lambda é permitido pelas SCPs e não é concedido por ninguém, então também é recusado.\"><circle cx=\"285.0\" cy=\"160.0\" r=\"120\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><circle cx=\"435.0\" cy=\"160.0\" r=\"120\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"215.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">o que o IAM da role permite</text><text x=\"505.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">o que as SCPs permitem</text><text x=\"225.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rds:*</text><text x=\"225.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">cortado por uma SCP</text><text x=\"495.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">lambda:*</text><text x=\"495.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">ninguém concedeu</text><text x=\"360.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ec2:*</text><text x=\"360.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">s3:*</text><text x=\"360.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">só a sobreposição chega à conta; um Deny em qualquer um tira uma ação dela</text></svg>", "caption": "O IAM concede, as SCPs põem o teto, e a role fica com o que está nos dois."}
```

**O filtro cobre toda identidade de uma conta-membro, o usuário root dela inclusive.** Essa é a
propriedade que nada na conta consegue dar a si mesmo: um administrador da `shop-prod` pode mudar
qualquer política do IAM da `shop-prod`, e nenhuma SCP. Duas coisas ficam fora do filtro. **A conta
de gerenciamento nunca é afetada por uma SCP**, anexada onde for, que é o motivo da lição 3 para ela
não rodar nada. E as **service-linked roles**, as roles que os serviços da AWS criam numa conta para
agir por conta própria, também não são restringidas por SCPs.

## Ligando as SCPs, e a política que já está lá

Reinicie o moto no primeiro terminal (Ctrl+C, depois `moto_server -p 4567`) para esta lição começar
de uma AWS vazia. Depois monte uma pequena parte da árvore da lição 3: a `shop-prod` em
`Workloads/Prod`, e a `sandbox` em `Sandbox`. Os ids vão para variáveis à medida que são criados, e
a função `account` da lição 3 volta para os números das contas:

```
ana@laptop:~/aws$ account() { aws organizations list-accounts --query "Accounts[?Name=='$1'].Id" --output text; }
ana@laptop:~/aws$ aws organizations create-organization --query Organization.Id --output text
o-vpkre95at2
ana@laptop:~/aws$ root=$(aws organizations list-roots --query "Roots[0].Id" --output text)
ana@laptop:~/aws$ workloads=$(aws organizations create-organizational-unit --parent-id $root --name Workloads --query OrganizationalUnit.Id --output text)
ana@laptop:~/aws$ prod=$(aws organizations create-organizational-unit --parent-id $workloads --name Prod --query OrganizationalUnit.Id --output text)
ana@laptop:~/aws$ sandbox=$(aws organizations create-organizational-unit --parent-id $root --name Sandbox --query OrganizationalUnit.Id --output text)
ana@laptop:~/aws$ for a in shop-prod sandbox; do aws organizations create-account --email aws+$a@example.com --account-name $a --query "CreateAccountStatus.[AccountId,AccountName]" --output text; done
896527596556	shop-prod
798632694501	sandbox
ana@laptop:~/aws$ aws organizations move-account --account-id $(account shop-prod) --source-parent-id $root --destination-parent-id $prod
ana@laptop:~/aws$ aws organizations move-account --account-id $(account sandbox) --source-parent-id $root --destination-parent-id $sandbox
```

Agora o tipo de política em si. A lição 3 achou a lista da raiz vazia no moto. Na AWS o tipo é
habilitado quando uma organização é criada com todos os recursos, então este primeiro comando só é
necessário aqui:

```
ana@laptop:~/aws$ aws organizations list-roots --query "Roots[0].PolicyTypes"
[]
ana@laptop:~/aws$ aws organizations enable-policy-type --root-id $root --policy-type SERVICE_CONTROL_POLICY --query Root.PolicyTypes
[
    {
        "Type": "SERVICE_CONTROL_POLICY",
        "Status": "ENABLED"
    }
]
ana@laptop:~/aws$ aws organizations list-policies --filter SERVICE_CONTROL_POLICY --query "Policies[].[Id,Name,AwsManaged]" --output text
p-FullAWSAccess	FullAWSAccess	True
ana@laptop:~/aws$ aws organizations describe-policy --policy-id p-FullAWSAccess --query Policy.Content --output text
{"Version": "2012-10-17", "Statement": [{"Effect": "Allow", "Action": "*", "Resource": "*"}]}
ana@laptop:~/aws$ for t in $root $workloads $prod $(account shop-prod); do echo "$t: $(aws organizations list-policies-for-target --target-id $t --filter SERVICE_CONTROL_POLICY --query "Policies[].Name" --output text)"; done
r-ucqy: FullAWSAccess
ou-ucqy-v4g2cy3n: FullAWSAccess
ou-ucqy-7pqpa5j0: FullAWSAccess
896527596556: FullAWSAccess
```

**Uma SCP existe antes de alguém escrever alguma: a `FullAWSAccess`**, gerenciada pela AWS, que
permite toda ação em todo recurso. Ela está anexada à raiz, a cada OU e a cada conta, como o laço
mostra nível por nível. OUs e contas novas também a recebem. **É por isso que ligar as SCPs não muda
nada**: o teto começa no alto da sala. Toda barreira daqui em diante é escrita contra ela, e a
próxima seção diz os dois jeitos de fazer isso.
