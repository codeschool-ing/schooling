---
title: A árvore: uma raiz, unidades organizacionais e contas
version: 1
---

**Uma organização é uma árvore de contas, de propriedade da conta que fica no topo.** A imagem
errada é uma superconta, onde os recursos de todos os membros se juntam e quem administra a
organização vê tudo. Nada se junta. Cada membro mantém todas as paredes que a lição 2 mediu. O que a
organização acrescenta é uma fatura para todos eles, e regras que descem pelos seus galhos.

Quatro palavras nomeiam as partes:

- **A conta de gerenciamento** criou a organização e paga a fatura dela. Há uma só, ela não pode
  ser removida da organização que gerencia, e a última seção desta lição diz por que ela não deve
  rodar nada. A API ainda a chama pelo nome antigo, `master`, em campos como `MasterAccountId`.
- **Contas-membro** são todas as outras contas da árvore. Cada uma pertence a exatamente uma
  organização por vez.
- **A raiz** é o topo da árvore, uma por organização, com um id que começa com `r-`.
- **Uma unidade organizacional**, uma OU, é uma pasta na árvore, com um id que começa com `ou-`.
  Ela guarda contas e outras OUs, aninhadas até cinco níveis abaixo da raiz. Toda conta e toda OU
  tem exatamente um pai.

**Uma OU não guarda recursos e não tem fatura própria.** Ela existe para que uma regra possa ser
anexada a um galho uma vez, em vez de a cada conta dele, o que a lição 4 faz. Por isso a
árvore é desenhada pelo **que as contas têm em comum**, como produção ou experimentos, e não pelos
departamentos da empresa. Uma regra segue o tipo de trabalho, não a equipe que o faz.

## Montando a árvore da loja

Reinicie o moto no primeiro terminal (Ctrl+C, depois `moto_server -p 4567`) para esta lição começar
de uma AWS vazia. Depois crie a organização:

```
ana@laptop:~/aws$ aws organizations create-organization --query "Organization.[Id,FeatureSet,MasterAccountId]" --output text
o-vpkre95at2	ALL	123456789012
ana@laptop:~/aws$ aws organizations list-roots --query "Roots[].[Id,Name]" --output text
r-ucqy	Root
```

A organização tem um id, `o-` e dez caracteres; `ALL` é o seu conjunto de recursos, que a próxima
seção explica; e a raiz dela já existe. Todo id desta lição é invenção do moto e os seus serão
outros, então os comandos abaixo nunca digitam um: eles procuram cada id pelo nome. Duas funções de
shell fazem a procura, e duram até o terminal ser fechado. Digite-as primeiro no segundo terminal:

```sh
ou() { aws organizations list-organizational-units-for-parent --parent-id "$1" --query "OrganizationalUnits[?Name=='$2'].Id" --output text; }
account() { aws organizations list-accounts --query "Accounts[?Name=='$1'].Id" --output text; }
```

`ou PAI NOME` imprime o id da OU chamada NOME sob PAI, e `account NOME` o número da conta chamada
NOME. Agora as OUs, três sob a raiz e duas sob `Workloads`:

```
ana@laptop:~/aws$ root=$(aws organizations list-roots --query "Roots[0].Id" --output text)
ana@laptop:~/aws$ for name in Security Workloads Sandbox; do aws organizations create-organizational-unit --parent-id $root --name $name --query "OrganizationalUnit.[Id,Name]" --output text; done
ou-ucqy-vkatnym7	Security
ou-ucqy-x5zp8bqc	Workloads
ou-ucqy-as6q74bz	Sandbox
ana@laptop:~/aws$ workloads=$(ou $root Workloads)
ana@laptop:~/aws$ for name in Prod Staging; do aws organizations create-organizational-unit --parent-id $workloads --name $name --query "OrganizationalUnit.[Id,Name]" --output text; done
ou-ucqy-w1hyddq5	Prod
ou-ucqy-hdvl0tp6	Staging
```

E as cinco contas, com a convenção de e-mail da lição 2:

```
ana@laptop:~/aws$ for a in shop-prod shop-staging security log-archive sandbox; do aws organizations create-account --email aws+$a@example.com --account-name $a --query "CreateAccountStatus.[AccountId,AccountName]" --output text; done
332178477898	shop-prod
073648902831	shop-staging
771971365420	security
006227652844	log-archive
652028714336	sandbox
ana@laptop:~/aws$ aws organizations list-children --parent-id $root --child-type ACCOUNT --query "Children[].Id" --output text
123456789012	332178477898	073648902831	771971365420	006227652844	652028714336
```

**Uma conta nova sempre começa sob a raiz.** O `create-account` não recebe pai, então as seis
contas, a de gerenciamento inclusive, são filhas da raiz até alguma coisa movê-las. Mover é
`move-account`, que cita a conta, o pai que ela deixa e o pai para onde vai:

```
ana@laptop:~/aws$ aws organizations move-account --account-id $(account shop-prod) --source-parent-id $root --destination-parent-id $(ou $workloads Prod)
ana@laptop:~/aws$ aws organizations move-account --account-id $(account shop-staging) --source-parent-id $root --destination-parent-id $(ou $workloads Staging)
ana@laptop:~/aws$ for a in security log-archive; do aws organizations move-account --account-id $(account $a) --source-parent-id $root --destination-parent-id $(ou $root Security); done
ana@laptop:~/aws$ aws organizations move-account --account-id $(account sandbox) --source-parent-id $root --destination-parent-id $(ou $root Sandbox)
```

Nenhum dos quatro imprimiu nada, que é a cara do sucesso para o `move-account`. Perguntar à árvore
mostra para onde tudo foi:

```
ana@laptop:~/aws$ aws organizations list-children --parent-id $root --child-type ACCOUNT --query "Children[].Id" --output text
123456789012
ana@laptop:~/aws$ aws organizations list-accounts-for-parent --parent-id $(ou $root Security) --query "Accounts[].[Id,Name]" --output text
771971365420	security
006227652844	log-archive
ana@laptop:~/aws$ aws organizations list-parents --child-id $(account shop-prod) --query "Parents[].[Id,Type]" --output text
ou-ucqy-w1hyddq5	ORGANIZATIONAL_UNIT
ana@laptop:~/aws$ aws organizations list-parents --child-id $(ou $workloads Prod) --query "Parents[].[Id,Type]" --output text
ou-ucqy-x5zp8bqc	ORGANIZATIONAL_UNIT
```

Só a conta de gerenciamento ficou sob a raiz. `Security` guarda as duas contas que vigiam as outras,
e `list-parents` sobe um passo de cada vez: a `shop-prod` fica em `Prod`, e `Prod` fica em
`Workloads`. **Cada passo tem um pai só**, então o caminho de qualquer conta até a raiz é uma linha
única. É isso que faz de "as regras de toda OU acima dela" uma pergunta com uma resposta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 380\" role=\"img\" data-fig=\"l03-tree\" aria-label=\"A organização da loja como as transcrições a montaram. A raiz r-ucqy tem quatro filhos: a conta de gerenciamento 123456789012 e as unidades organizacionais Security, Workloads e Sandbox. Security guarda as contas security, 771971365420, e log-archive, 006227652844. Workloads guarda mais duas unidades, Prod com a conta shop-prod, 332178477898, e Staging com a shop-staging, 073648902831. Sandbox guarda a conta sandbox, 652028714336. Contas são desenhadas como caixas de borda clara, unidades organizacionais como caixas arredondadas.\"><defs><marker id=\"l03-tree-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"300.0\" y=\"22.0\" width=\"120.0\" height=\"36.0\" rx=\"10\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"2\"></rect><text x=\"360.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Root  r-ucqy</text><rect x=\"15.0\" y=\"100.0\" width=\"120.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"75.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">gerenciamento</text><text x=\"75.0\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">123456789012</text><path d=\"M360.0 60.0 L360.0 80.0 L75.0 80.0 L75.0 97.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-tree-af-ah-paper-dim)\"></path><rect x=\"155.0\" y=\"104.0\" width=\"120.0\" height=\"32.0\" rx=\"10\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"215.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Security</text><path d=\"M360.0 60.0 L360.0 80.0 L215.0 80.0 L215.0 101.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-tree-af-ah-paper-dim)\"></path><rect x=\"370.0\" y=\"104.0\" width=\"120.0\" height=\"32.0\" rx=\"10\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"430.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Workloads</text><path d=\"M360.0 60.0 L360.0 80.0 L430.0 80.0 L430.0 101.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-tree-af-ah-paper-dim)\"></path><rect x=\"585.0\" y=\"104.0\" width=\"120.0\" height=\"32.0\" rx=\"10\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"645.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Sandbox</text><path d=\"M360.0 60.0 L360.0 80.0 L645.0 80.0 L645.0 101.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-tree-af-ah-paper-dim)\"></path><rect x=\"150.0\" y=\"190.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"215.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">security</text><text x=\"215.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">771971365420</text><rect x=\"150.0\" y=\"270.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"215.0\" y=\"283.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">log-archive</text><text x=\"215.0\" y=\"299.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">006227652844</text><path d=\"M215.0 136.0 L215.0 160.0 L215.0 160.0 L215.0 187.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-tree-af-ah-paper-dim)\"></path><path d=\"M190.0 136.0 L190.0 160.0 L140.0 160.0 L140.0 290.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M140.0 290.0 L147.0 290.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-tree-af-ah-paper-dim)\"></path><rect x=\"305.0\" y=\"194.0\" width=\"120.0\" height=\"32.0\" rx=\"10\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"365.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Prod</text><rect x=\"435.0\" y=\"194.0\" width=\"120.0\" height=\"32.0\" rx=\"10\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"495.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Staging</text><path d=\"M430.0 136.0 L430.0 165.0 L365.0 165.0 L365.0 191.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-tree-af-ah-paper-dim)\"></path><path d=\"M430.0 136.0 L430.0 165.0 L495.0 165.0 L495.0 191.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-tree-af-ah-paper-dim)\"></path><rect x=\"305.0\" y=\"280.0\" width=\"120.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"365.0\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-prod</text><text x=\"365.0\" y=\"309.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">332178477898</text><rect x=\"435.0\" y=\"280.0\" width=\"120.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"495.0\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-staging</text><text x=\"495.0\" y=\"309.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">073648902831</text><path d=\"M365.0 226.0 L365.0 250.0 L365.0 250.0 L365.0 277.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-tree-af-ah-paper-dim)\"></path><path d=\"M495.0 226.0 L495.0 250.0 L495.0 250.0 L495.0 277.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-tree-af-ah-paper-dim)\"></path><rect x=\"585.0\" y=\"190.0\" width=\"120.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"645.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">sandbox</text><text x=\"645.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">652028714336</text><path d=\"M645.0 136.0 L645.0 160.0 L645.0 160.0 L645.0 187.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-tree-af-ah-paper-dim)\"></path><rect x=\"170.0\" y=\"346.0\" width=\"28.0\" height=\"18.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"206.0\" y=\"355.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma conta</text><rect x=\"330.0\" y=\"346.0\" width=\"28.0\" height=\"18.0\" rx=\"8\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"366.0\" y=\"355.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma unidade organizacional, que não guarda recursos</text></svg>", "caption": "Uma raiz, um pai para cada coisa, e as contas nas folhas."}
```

## O que a organização diz de si mesma

```
ana@laptop:~/aws$ aws organizations describe-organization
{
    "Organization": {
        "Id": "o-vpkre95at2",
        "Arn": "arn:aws:organizations::123456789012:organization/o-vpkre95at2",
        "FeatureSet": "ALL",
        "MasterAccountArn": "arn:aws:organizations::123456789012:account/o-vpkre95at2/123456789012",
        "MasterAccountId": "123456789012",
        "MasterAccountEmail": "master@example.com",
        "AvailablePolicyTypes": [
            {
                "Type": "SERVICE_CONTROL_POLICY",
                "Status": "ENABLED"
            }
        ]
    }
}
ana@laptop:~/aws$ aws organizations list-roots --query "Roots[0].PolicyTypes"
[]
```

`AvailablePolicyTypes` diz que as service control policies estão ligadas; a lista da própria raiz
diz que nenhum tipo de política está habilitado nela. **Essa discordância é do moto.** A referência
da API da AWS para `CreateOrganization` diz que uma organização criada com todos os recursos tem as
service control policies habilitadas na raiz desde o início. O moto deixa a lista da raiz vazia até
alguém rodar `enable-policy-type`, que é a primeira coisa que a lição 4 faz.

O endereço da conta de gerenciamento, `master@example.com`, também é invenção do moto. Na AWS ele é
o endereço de e-mail com que a conta de gerenciamento foi aberta, o endereço do usuário root dela. A
lição 2 disse por que ele deve ser uma caixa compartilhada e não uma pessoa.
