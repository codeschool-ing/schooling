---
title: Cost Categories, e dividir o que ninguém pode possuir
version: 1
---

Tags agrupam recursos. **Cost Categories** agrupam custos: um conjunto de regras, avaliadas em ordem,
que põem cada linha da conta num valor com nome, por tag, por conta, por serviço, por tipo de uso, ou por
outra categoria. A primeira regra que casa decide; uma linha que nenhuma regra casa recebe o **valor
padrão**. A categoria então aparece no Cost Explorer e no CUR como se fosse mais uma coluna.

A da loja, `team.json`:

```json
{
  "Name": "team",
  "RuleVersion": "CostCategoryExpression.v1",
  "Rules": [
    { "Value": "checkout", "Rule": { "Tags": { "Key": "owner", "Values": ["checkout"] } } },
    { "Value": "api", "Rule": { "Tags": { "Key": "owner", "Values": ["api"] } } },
    { "Value": "platform", "Rule": { "Tags": { "Key": "owner", "Values": ["platform"] } } },
    { "Value": "shared", "Rule": { "Dimensions": { "Key": "USAGE_TYPE", "Values": ["SAE1-DataTransfer-Out-Bytes"] } } }
  ],
  "DefaultValue": "unallocated",
  "SplitChargeRules": [
    { "Source": "shared", "Targets": ["checkout", "api", "platform"], "Method": "PROPORTIONAL" }
  ]
}
```

```
ana@laptop:~/aws/owners$ CATEGORY=$(aws ce create-cost-category-definition --cli-input-json file://team.json --query CostCategoryArn --output text); echo $CATEGORY
arn:aws:ce::123456789012:costcategory/4e42bfb5-2d89-4a85-be93-149cf74f9d80
ana@laptop:~/aws/owners$ aws ce describe-cost-category-definition --cost-category-arn $CATEGORY --query 'CostCategory.[Name,EffectiveStart,DefaultValue,SplitChargeRules[0].Method]' --output text
team	2026-10-01T00:00:00Z	unallocated	PROPORTIONAL
ana@laptop:~/aws/owners$ aws ce list-cost-category-definitions 2>&1 | grep -m1 ERROR
aws: [ERROR]: An error occurred (500) when calling the ListCostCategoryDefinitions operation (reached max retries: 2): <!doctype html>
```

A categoria começa no **primeiro dia do mês atual**, que também é o comportamento da AWS: como uma tag
ativada, uma categoria não se aplica ao passado. O moto a guarda e não lista nenhuma; na AWS
`list-cost-category-definitions` e o console a mostram, e o Cost Explorer pode agrupar por `team`.

## O que as regras fazem com o mês da loja

Leia as regras contra o mês do `bill.py`:

- as três regras de tag põem **433,05** USD em `checkout`, 432,04 em `api`, 231,34 em `platform`;
- a transferência de dados, **180,00**, casa com `shared`;
- as linhas sem tag, **249,19**, não casam com nada e caem em `unallocated`.

A regra de divisão (*split charge*) então divide `shared` entre as três equipes **na proporção dos
custos de cada uma**, 1.096,43 USD no total: checkout fica com 433,05 / 1.096,43 dos 180, 71,09; api
70,93; platform 37,98. Cada equipe agora vê uma parte da transferência de dados que o tráfego dela,
mais ou menos, causou. `PROPORTIONAL` é um de três métodos; `EVEN` divide em partes iguais, e `FIXED` usa
porcentagens que a equipe escreve.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Duas barras empilhadas do mesmo mês, 1.525,62 USD. Antes da divisão: checkout 433,05, api 432,04, platform 231,34, shared 180,00, unallocated 249,19. Depois: checkout 504,14, api 502,97, platform 269,32, e unallocated ainda 249,19. A transferência de dados compartilhada é dividida na proporção dos custos de cada equipe; unallocated não é dividido.\"><defs><marker id=\"spl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">antes da divisão</text><rect x=\"130\" y=\"50\" width=\"161.8\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"210.9\" y=\"65.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">checkout</text><text x=\"210.9\" y=\"80.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">433.05</text><rect x=\"291.8\" y=\"50\" width=\"161.4\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"372.5\" y=\"65.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">api</text><text x=\"372.5\" y=\"80.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">432.04</text><rect x=\"453.2\" y=\"50\" width=\"86.4\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"496.4\" y=\"65.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">platform</text><text x=\"496.4\" y=\"80.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">231.34</text><rect x=\"539.6\" y=\"50\" width=\"67.3\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"573.25\" y=\"65.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">shared</text><text x=\"573.25\" y=\"80.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">180.00</text><rect x=\"606.9\" y=\"50\" width=\"93.1\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"653.4499999999999\" y=\"65.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">unallocated</text><text x=\"653.4499999999999\" y=\"80.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">249.19</text><text x=\"20\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">depois</text><rect x=\"130\" y=\"140\" width=\"188.4\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"224.2\" y=\"155.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">checkout</text><text x=\"224.2\" y=\"170.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">504.14</text><rect x=\"318.4\" y=\"140\" width=\"187.9\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"412.34999999999997\" y=\"155.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">api</text><text x=\"412.34999999999997\" y=\"170.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">502.97</text><rect x=\"506.3\" y=\"140\" width=\"100.6\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"556.6\" y=\"155.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">platform</text><text x=\"556.6\" y=\"170.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">269.32</text><rect x=\"606.9\" y=\"140\" width=\"93.1\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"653.4499999999999\" y=\"155.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">unallocated</text><text x=\"653.4499999999999\" y=\"170.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">249.19</text><text x=\"360\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">USD do mês, pela categoria team; os 180 compartilhados são divididos na proporção, unallocated não</text></svg>", "caption": "O custo compartilhado vai para as equipes; o custo sem dono continua visível com o próprio nome.", "same": ["api", "checkout", "platform", "shared", "unallocated"]}
```

**`unallocated` não é dividido, e não deve ser.** Dividir as instâncias sem tag entre as equipes as faria
sumir nos números de todos, e o objetivo da categoria é que 249,19 USD por mês fiquem visíveis, com um
nome que diz o que são, até alguém assumir cada linha ou apagá-la. Uma linha `unallocated` caindo, mês após
mês, é como uma equipe sabe que as tags estão funcionando.
