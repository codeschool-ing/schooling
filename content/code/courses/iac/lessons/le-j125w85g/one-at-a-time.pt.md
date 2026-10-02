---
title: Um apply por vez
version: 1
---

Dois merges próximos disparam duas execuções do pipeline, e as duas fazem plan contra o mesmo
state. O lock de state da aula 7 não ajuda nisso. **Um lock impede duas escritas no mesmo instante;
não faz nada contra dois plans feitos antes de qualquer um ser aplicado.** Eis a execução 2, do
commit da tag `Owner`, fazendo plan enquanto a execução 1 ainda esperava a aprovação:

```
ana@laptop:~$ git clone -q git/shop.git ci/run-2
ana@laptop:~/ci/run-2$ git log --oneline -1
53a4007 shop: Owner tag on the VPC
ana@laptop:~/ci/run-2$ ./ci.sh plan 2>&1 | grep -E "# aws|Plan:"
  # aws_security_group.web will be created
  # aws_subnet.a will be created
  # aws_vpc.shop will be created
Plan: 3 to add, 0 to change, 0 to destroy.
```

Três a adicionar. O plan da execução 2 está correto para o state que leu, que ainda estava vazio, e
o arquivo dele descreve uma segunda rede inteira. A execução 1 foi então aprovada e aplicada, como a
seção anterior mostrou, e a aprovação da execução 2 chegou depois disso:

```
+ terraform apply -input=false -lock-timeout=5m tfplan
╷
│ Error: Saved plan is stale
│ 
│ The given plan file can no longer be applied because the state was changed
│ by another operation after the plan was created.
╵
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Uma linha do tempo de duas execuções do pipeline contra um mesmo state. A execução 1 faz o plan com o state vazio. A execução 2, de um commit posterior, também faz o plan contra o state vazio, três a adicionar. A execução 1 aplica, três adicionados, e o state passa a guardar a rede. O plan salvo da execução 2 é recusado como stale. A execução 2 faz o plan de novo, uma mudança, e aplica isso.\"><text x=\"20.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">execução 1</text><text x=\"20.0\" y=\"150.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">execução 2</text><text x=\"20.0\" y=\"236.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">state</text><rect x=\"100\" y=\"46\" width=\"110\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"155.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">plan</text><text x=\"155.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3 a adicionar</text><rect x=\"330\" y=\"46\" width=\"110\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"385.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">apply</text><text x=\"385.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3 adicionados</text><rect x=\"215\" y=\"126\" width=\"110\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">plan</text><text x=\"270.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3 a adicionar</text><rect x=\"450\" y=\"126\" width=\"120\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"510.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">apply</text><text x=\"510.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">recusado: stale</text><rect x=\"590\" y=\"126\" width=\"120\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"650.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">plan, apply</text><text x=\"650.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 a mudar</text><path d=\"M100 236 L385 236\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M385 236 L710 236\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M385 94 L385 226\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"240.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">vazio</text><text x=\"548.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a rede, escrita pela execução 1</text><text x=\"270.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">plan feito contra o state vazio</text></svg>", "caption": "Duas execuções, um state. O plan da execução 2 era verdadeiro quando foi feito e falso quando alguém foi aplicá-lo, e o Terraform percebeu.", "same": ["plan", "apply", "state", "plan, apply"]}
```

**A recusa de plan stale da aula 9 foi o que ficou entre este pipeline e uma VPC duplicada.**
Aplicado como estava, o plan da execução 2 teria criado uma segunda rede `shop` ao lado da
primeira, exatamente o acidente que a aula 7 produziu ao perder um state. O pipeline faz a coisa
honesta com a recusa e faz o plan de novo:

```
ana@laptop:~/ci/run-2$ ./ci.sh plan 2>&1 | grep -E "# aws|Plan:"
  # aws_vpc.shop will be updated in-place
Plan: 0 to add, 1 to change, 0 to destroy.
ana@laptop:~/ci/run-2-apply$ ./ci.sh apply 2>&1 | tail -n 1
Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
```

```
ana@laptop:~/ci/run-2-apply$ aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].[VpcId,CidrBlock]" --output text
vpc-d23fdf50099101ff0	10.20.0.0/16
```

Uma mudança, uma VPC. Terminou bem porque o Terraform confere o serial do state, mas a execução
ainda pediu a alguém que aprovasse um plan que estava errado quando foi lido. Melhor impedir a
segunda execução de fazer plan até a primeira terminar.

## Pôr as execuções numa fila

Os dois serviços de CI fazem isso. No workflow do GitHub, o bloco `concurrency` põe toda execução
do mesmo ref num grupo só, e **só uma execução de um grupo fica em andamento por vez**. Uma
execução que começa enquanto outra está em andamento espera, pendente, e só faz plan depois que a
primeira aplicou, então o plan dela é calculado contra o state que ela vai mesmo encontrar. Dois
detalhes disso decidem as configurações:

O `cancel-in-progress: false` importa porque a alternativa cancela um job em execução, e um job
cancelado no meio do `apply` é o apply parcial da aula 9, feito de propósito. E um grupo guarda no
máximo uma execução pendente: quando chega uma terceira, o GitHub cancela a que esperava e enfileira
a mais nova. Na `main` isso é aceitável, porque o commit mais novo contém toda mudança que entrou
antes dele, então o plan dele cobre todas.

O preço é que uma execução esperando aprovação segura todas as que vêm atrás. Essa é a troca: a
fila anda na velocidade de quem aprova.

No GitLab, `resource_group: production` no job `apply` faz com que só um job desse grupo rode por
vez, em todos os pipelines do projeto. Neste arquivo só o `apply` está nele, então um plan ainda
pode ficar stale enquanto espera, e a recusa acima é o que pega isso.

## A última linha, e ferramentas que fazem tudo isso

O que quer que a fila faça, **o lock do state continua sendo a última linha**: dois applies que
chegam ao bucket no mesmo segundo não conseguem escrever os dois, e o `-lock-timeout=5m` do `ci.sh`
faz o segundo esperar pelo primeiro em vez de falhar. A aula 7 mostrou os dois desfechos.

Algumas ferramentas são construídas exatamente em torno desses problemas. O **Atlantis** é um
servidor que você mesmo roda: ele faz plan quando um pull request abre, aplica quando alguém comenta
`atlantis apply`, e trava cada diretório para um pull request até o merge, então o apply acontece
antes do merge, e não depois. O **HCP Terraform**, o serviço da HashiCorp, roda plans e applies por
conta própria e enfileira as execuções de cada workspace, uma de cada vez. Nenhum dos dois está
instalado aqui, e nenhum muda as ideias: um só lugar aplica, aplica um plan que alguém leu, e aplica
um de cada vez.
