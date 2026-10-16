---
title: Tags, e o passo que as faz contar
version: 1
---

**Uma tag é uma chave e um valor escritos num recurso, e é o único jeito de uma fatura dizer de quem
foi um custo.** A fatura sabe a conta, o serviço, a região e o tipo de uso de cada linha. Ela não
sabe que uma máquina pertence ao time web ou à cópia de staging da loja, a menos que a máquina diga
isso numa tag. O erro comum é achar que pôr tags é o trabalho todo. **Uma tag num recurso não aparece
num relatório de custos até alguém ativá-la no Billing**, e daí em diante ela rotula só as cobranças
novas.

## Tags no laboratório

As tags deste curso são as da loja: `project=shop`, `env=prod` ou `staging`, e `team=web`, `data` ou
`finance`. Um bucket recebe as tags como um conjunto. Uma instância pode recebê-las no próprio
comando que a cria, que é o hábito que vale ter: um recurso marcado um dia depois ficou um dia sem
tag. A segunda instância abaixo é iniciada sem tags, de propósito:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket shop-assets --create-bucket-configuration LocationConstraint=sa-east-1 --output text
/shop-assets
ana@laptop:~/aws$ aws s3api put-bucket-tagging --bucket shop-assets --tagging 'TagSet=[{Key=project,Value=shop},{Key=env,Value=prod},{Key=team,Value=web}]'
ana@laptop:~/aws$ aws s3api create-bucket --bucket shop-logs --create-bucket-configuration LocationConstraint=sa-east-1 --output text
/shop-logs
ana@laptop:~/aws$ aws ec2 run-instances --image-id ami-0629d059c178d0eac --instance-type m7i.large --tag-specifications 'ResourceType=instance,Tags=[{Key=project,Value=shop},{Key=env,Value=prod},{Key=team,Value=web}]' --query 'Instances[0].InstanceId' --output text
i-eb1bd5fa0d8d0a621
ana@laptop:~/aws$ aws ec2 run-instances --image-id ami-0629d059c178d0eac --instance-type t3.medium --query 'Instances[0].InstanceId' --output text
i-5ef280fe00c97d2e5
```

O moto inventa ids de instância, e os seus diferem dos dois acima. Use os seus nos comandos a
seguir. A **Resource Groups Tagging API** responde a uma pergunta em todos os serviços, quais
recursos têm uma tag:

```
ana@laptop:~/aws$ aws resourcegroupstaggingapi get-resources --tag-filters Key=team,Values=web --query 'ResourceTagMappingList[].ResourceARN'
[
    "arn:aws:s3:::shop-assets",
    "arn:aws:ec2:sa-east-1:123456789012:instance/i-eb1bd5fa0d8d0a621"
]
ana@laptop:~/aws$ aws resourcegroupstaggingapi get-resources --query 'ResourceTagMappingList[].ResourceARN'
[
    "arn:aws:s3:::shop-assets",
    "arn:aws:ec2:sa-east-1:123456789012:instance/i-eb1bd5fa0d8d0a621"
]
ana@laptop:~/aws$ aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId, InstanceType, Tags[?Key==`team`].Value | [0]]' --output text
i-eb1bd5fa0d8d0a621	m7i.large	web
i-5ef280fe00c97d2e5	t3.medium	None
```

O segundo comando pediu todo recurso, sem filtro, e ainda assim imprimiu só os dois com tag. **É
assim que a API é documentada: ela lista recursos que têm tags ou já tiveram, e um recurso que nunca
recebeu tag é invisível para ela.** A instância sem tag e o bucket `shop-logs` existem e faltam
nessa lista. São exatamente os recursos que um relatório de custos não consegue atribuir. Achá-los
exige perguntar a cada serviço, como o terceiro comando faz para o EC2: o `t3.medium` não tem
`team`, e a saída em texto diz `None`. A regra `required-tags` do AWS Config faz a mesma verificação
continuamente, e a lição 21 de `aws-operations` cobre o Config.

Ponha tags na instância perdida e pergunte de novo:

```
ana@laptop:~/aws$ aws ec2 create-tags --resources i-5ef280fe00c97d2e5 --tags Key=project,Value=shop Key=env,Value=staging Key=team,Value=data
ana@laptop:~/aws$ aws resourcegroupstaggingapi get-resources --tag-filters Key=team --query 'ResourceTagMappingList[].[ResourceARN, Tags[?Key==`team`].Value | [0]]' --output text
arn:aws:s3:::shop-assets	web
arn:aws:ec2:sa-east-1:123456789012:instance/i-eb1bd5fa0d8d0a621	web
arn:aws:ec2:sa-east-1:123456789012:instance/i-5ef280fe00c97d2e5	data
```

## Políticas de tag: a grafia, não a presença

Tags são texto livre e diferenciam maiúsculas, então `team=web`, `Team=web` e `team=Web` são três
grupos diferentes num relatório. Um relatório de três grupos para um time está errado de um jeito
que ninguém percebe. Uma **política de tag** (*tag policy*) é um tipo de política do AWS
Organizations, como as SCPs da lição 4, que fixa como uma chave é escrita e quais valores ela pode
ter. Esta diz que `team` é escrita em minúsculas e guarda um de três valores. `enforced_for` pede à
AWS que recuse uma operação de tag numa instância do EC2 que a desrespeite:

```sh
cat > tag-policy.json <<'EOF'
{
  "tags": {
    "team": {
      "tag_key": {"@@assign": "team"},
      "tag_value": {"@@assign": ["web", "data", "finance"]},
      "enforced_for": {"@@assign": ["ec2:instance"]}
    }
  }
}
EOF
```

Ligue o tipo de política na raiz de uma organização nova, crie a política e anexe-a, depois inicie
uma instância com a tag `team=marketing`:

```
ana@laptop:~/aws$ aws organizations create-organization --feature-set ALL --query Organization.Id --output text
o-6yu81updtn
ana@laptop:~/aws$ aws organizations list-roots --query 'Roots[0].Id' --output text
r-k1uz
ana@laptop:~/aws$ aws organizations enable-policy-type --root-id r-k1uz --policy-type TAG_POLICY --query Root.PolicyTypes --output text
ENABLED	TAG_POLICY
ana@laptop:~/aws$ aws organizations create-policy --name team-values --type TAG_POLICY --description 'team is web, data or finance' --content file://tag-policy.json --query Policy.PolicySummary.Id --output text
p-rgyicmvp
ana@laptop:~/aws$ aws organizations attach-policy --policy-id p-rgyicmvp --target-id r-k1uz
ana@laptop:~/aws$ aws ec2 run-instances --image-id ami-0629d059c178d0eac --instance-type t3.medium --tag-specifications 'ResourceType=instance,Tags=[{Key=team,Value=marketing}]' --query 'Instances[0].Tags' --output text
team	marketing
```

**O moto guardou a política, anexou-a e depois a ignorou**: o último comando iniciou uma instância
com um valor que a política não permite. Contra a AWS, a política recusa uma requisição que escreve
`team=marketing` numa instância de uma conta que ela cobre. Essa parte não foi rodada. O que uma
política de tag não faz, nem na AWS, é **exigir** uma tag. A documentação da AWS diz que ela não
aponta recursos sem tags como não conformes, então o `t3.medium` sem tag lá de cima teria passado
por ela. Para recusar um recurso criado sem `team`, uma SCP nega a ação de criação quando a
requisição não tem essa tag. Ela usa a chave de condição `aws:RequestTag/team`, e a lição 4 escreve
SCPs.

## Ativar uma tag para alocação de custos

O Billing guarda a sua própria lista de chaves de tag, e **uma chave só é usada para dividir custos
depois de ativada** lá. Isso acontece na **conta de gerenciamento** de uma organização, porque a
fatura consolidada pertence a essa conta (lição 3). A documentação da AWS dá os prazos. Uma chave
recém-usada pode levar até 24 horas para aparecer nessa lista, e até mais 24 horas depois da
ativação antes de aparecer em relatórios. A API do Cost Explorer tem uma operação para cada metade,
listar as chaves e mudar o status delas, e o moto não tem nenhuma das duas:

```
ana@laptop:~/aws$ aws ce list-cost-allocation-tags 2>&1 | grep ERROR
aws: [ERROR]: An error occurred (500) when calling the ListCostAllocationTags operation (reached max retries: 2): <!doctype html>
```

Contra a AWS,
`aws ce update-cost-allocation-tags-status --cost-allocation-tags-status TagKey=team,Status=Active`
é a ativação; ela não foi rodada. Dois tipos de chave acabam nessa lista. As **definidas pelo
usuário** são as que você escreveu, como `team`. As **geradas pela AWS** são escritas pela AWS, como
`aws:createdBy`, que registra a identidade que criou um recurso. Elas também precisam ser ativadas.

**A ativação não é retroativa.** Uma chave ativada em 20 de outubro divide os custos dali em diante,
e os primeiros dezenove dias do mês ficam num monte só, sem divisão. A AWS acrescentou em 2024 um
pedido de **preenchimento retroativo** (*backfill*), que aplica a ativação atual a até doze meses
anteriores. Ele corrige só a ativação esquecida: o uso que aconteceu enquanto um recurso não tinha
tag não tem tag nenhuma para preencher. **A tag tem de estar no recurso quando o custo acontece.** É
por isso que marcar na criação é o hábito, e por isso o fluxo abaixo tem duas portas em vez de uma.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l13-flow\" aria-label=\"De uma hora de uso a uma linha num relatório, por duas portas. À esquerda, dois recursos: um m7i.large com a tag team=web e um t3.medium sem tag. Cada hora de uso vira uma linha na fatura que leva as tags que o recurso tinha naquela hora: a primeira linha leva team=web, a segunda nenhuma. Porta um, entre os dois: a tag tem de estar no recurso quando o custo acontece. Porta dois, antes do relatório: a chave team tem de estar ativada no Billing, na conta de gerenciamento. À direita, o relatório agrupado por team: team$web guarda a primeira linha, e team$, o resto sem tag, guarda a segunda.\"><defs><marker id=\"l13-flow-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"115.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">uma hora de uso</text><rect x=\"20.0\" y=\"48.0\" width=\"190.0\" height=\"170.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">uma linha na fatura</text><rect x=\"265.0\" y=\"48.0\" width=\"190.0\" height=\"170.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">um relatório, agrupado por team</text><rect x=\"510.0\" y=\"48.0\" width=\"190.0\" height=\"170.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"35.0\" y=\"71.0\" width=\"160.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">m7i.large</text><text x=\"115.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">team=web</text><rect x=\"280.0\" y=\"71.0\" width=\"160.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1 hora, m7i.large</text><text x=\"360.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">tags: team=web</text><path d=\"M197.0 95.0 L277.0 95.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-flow-af-ah-paper-dim)\"></path><rect x=\"525.0\" y=\"71.0\" width=\"160.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">team$web</text><text x=\"605.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">o time web</text><path d=\"M442.0 95.0 L522.0 95.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-flow-af-ah-paper-dim)\"></path><rect x=\"35.0\" y=\"146.0\" width=\"160.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">t3.medium</text><text x=\"115.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">sem tag</text><rect x=\"280.0\" y=\"146.0\" width=\"160.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1 hora, t3.medium</text><text x=\"360.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">tags: -</text><path d=\"M197.0 170.0 L277.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-flow-af-ah-paper-dim)\"></path><rect x=\"525.0\" y=\"146.0\" width=\"160.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">team$</text><text x=\"605.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o resto sem tag</text><path d=\"M442.0 170.0 L522.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-flow-af-ah-paper-dim)\"></path><path d=\"M237.0 48.0 L237.0 218.0\" stroke=\"var(--amber)\" stroke-width=\"2.5\" fill=\"none\" stroke-dasharray=\"3 3\"></path><circle cx=\"237.0\" cy=\"252.0\" r=\"13\" fill=\"var(--amber)\"></circle><text x=\"237.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--ink)\">1</text><text x=\"237.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a tag está no</text><text x=\"237.0\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">recurso na</text><text x=\"237.0\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">hora do uso</text><path d=\"M482.0 48.0 L482.0 218.0\" stroke=\"var(--amber)\" stroke-width=\"2.5\" fill=\"none\" stroke-dasharray=\"3 3\"></path><circle cx=\"482.0\" cy=\"252.0\" r=\"13\" fill=\"var(--amber)\"></circle><text x=\"482.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--ink)\">2</text><text x=\"482.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a chave está</text><text x=\"482.0\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">ativada no</text><text x=\"482.0\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">Billing</text></svg>", "caption": "Um custo chega a um relatório sob uma tag só se a tag estava lá na hora, e a chave foi ativada.", "same": ["Billing"]}
```
