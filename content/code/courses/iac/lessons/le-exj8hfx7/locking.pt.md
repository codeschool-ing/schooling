---
title: Travamento, para que uma execução grave por vez
version: 1
---

Duas execuções que leem o mesmo estado e o gravam de volta produzem a clássica atualização perdida.
Cada uma leu o serial 5, cada uma fez a sua mudança na AWS, cada uma grava o serial 6, e a que gravar
por último apaga o registro da outra. Os recursos que a primeira criou ficam então reais, cobrados e
desconhecidos do estado, que é o acidente da segunda rede chegando por um caminho mais silencioso.
**Uma trava faz a segunda execução esperar ou falhar antes de ler qualquer coisa.**

Com `use_lockfile = true`, o backend S3 trava criando um segundo objeto ao lado do estado, a key do
estado com `.tflock` no fim, e o cria com uma **gravação condicional**: o S3 só aceita o objeto se
ainda não existir nenhum com aquela key. Duas execuções disputando a trava não podem ganhar as duas,
porque é o próprio S3 que decide qual gravação chegou primeiro. A execução que tem a trava apaga o
objeto quando termina.

A Ana faz uma mudança que vale aplicar, uma tag `Environment` na VPC:

```
ana@laptop:~/shop$ sed -i 's/{ Name = "shop" }/{ Name = "shop", Environment = "dev" }/' main.tf
```

Num terminal ela inicia o `terraform apply`, lê o plan, e deixa a pergunta *Do you want to perform
these actions?* na tela enquanto confere outra coisa. **O apply segura a trava desde o momento em que
começa até sair**, pergunta incluída. Num segundo terminal, o bucket:

```
ana@laptop:~/shop$ aws s3 ls --recursive s3://shop-tfstate-123456789012
2026-10-02 00:51:41       5835 shop/terraform.tfstate
2026-10-02 00:52:18        223 shop/terraform.tfstate.tflock
```

E um plan nesse segundo terminal, que é o que um colega ou um job de CI teria feito:

```
ana@laptop:~/shop$ terraform plan
╷
│ Error: Error acquiring the state lock
│ 
│ Error message: operation error S3: PutObject, https response error
│ StatusCode: 412, RequestID:
│ JXOdvefHqyTq5sSvp19pAUr8bWkyHAaboBlPa0I2mNWZyZeHWx4K, HostID:
│ 9Gjjt1m+cjU4OPvX9O9/8RuvnG41MRb/18Oux2o5H5MY7ISNTlXN+Dz9IG62/ILVxhAGI0qyPfg=,
│ api error PreconditionFailed: At least one of the pre-conditions you
│ specified did not hold
│ Lock Info:
│   ID:        5e1a4241-7664-589b-97c1-6af57ee23698
│   Path:      shop-tfstate-123456789012/shop/terraform.tfstate
│   Operation: OperationTypeApply
│   Who:       ana@vm
│   Version:   1.16.4
│   Created:   2026-10-02 03:52:18.315841962 +0000 UTC
│   Info:      
│ 
│ 
│ Terraform acquires a state lock to protect the state from being written
│ by multiple users at the same time. Please resolve the issue above and try
│ again. For most commands, you can disable locking with the "-lock=false"
│ flag, but this is not recommended.
╵
```

O `412` e o `PreconditionFailed` são o S3 recusando a gravação condicional: o objeto de trava existe.
Abaixo deles está o conteúdo da própria trava, e ele responde às perguntas que você tem nessa hora.
`Who` é o usuário e a máquina que a seguram (a máquina do laboratório se chama `vm`), `Operation` diz
que é um apply, `Created` diz desde quando, e `ID` é o que você precisa se quem a segura nunca
voltar. **Plans também travam**, embora não gravem nada na AWS: um plan lê o estado, e ler metade de
um estado que está sendo gravado dá o plan de um mundo que nunca existiu.

Falhar não é a única opção. O `-lock-timeout` faz uma execução tentar de novo pelo tempo que você
permitir:

```
ana@laptop:~/shop$ terraform plan -lock-timeout=60s
Acquiring state lock. This may take a few moments...
aws_vpc.shop: Refreshing state... [id=vpc-10f2b2857589fd959]
aws_security_group.web: Refreshing state... [id=sg-3bb7d165786e44657]
aws_subnet.public_a: Refreshing state... [id=subnet-1849baa846a6631fa]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.
ana@laptop:~/shop$ aws s3 ls --recursive s3://shop-tfstate-123456789012
2026-10-02 00:52:26       5907 shop/terraform.tfstate
```

`Acquiring state lock` é o plan esperando enquanto, no primeiro terminal, a Ana respondia `yes` e o
apply terminava. Depois o plan pegou a trava e planejou contra o estado que o apply acabara de gravar: a tag já
está lá, então não há nada a fazer, e o objeto de trava sumiu da listagem. Num pipeline, um lock
timeout de alguns minutos transforma dois jobs que colidiram em dois jobs que rodaram em sequência.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Uma linha do tempo com duas execuções e o bucket entre elas. A execução um, um apply, grava o objeto de trava e espera na pergunta. A execução dois, um plan, tenta gravar o mesmo objeto de trava e o S3 recusa com 412. A execução dois tenta de novo sob -lock-timeout. A execução um recebe a resposta, grava o estado novo e apaga a trava. A execução dois então pega a trava e planeja contra o estado novo.\"><defs><marker id=\"lk-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"lk-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"80.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">terminal 1</text><text x=\"80.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">bucket</text><text x=\"80.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">terminal 2</text><path d=\"M150 40 L700 40\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M150 220 L700 220\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"200\" y=\"112\" width=\"440\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">terraform.tfstate.tflock</text><path d=\"M220 44 L220 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lk-ah-phosphor)\"></path><text x=\"225.0\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">apply: trava</text><path d=\"M300 216 L300 150\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#lk-ah-amber)\"></path><text x=\"305.0\" y=\"196.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">plan: 412</text><text x=\"410.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">-lock-timeout: tenta de novo</text><path d=\"M520 44 L520 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lk-ah-phosphor)\"></path><text x=\"525.0\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">yes: estado, destrava</text><path d=\"M600 216 L600 150\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lk-ah-phosphor)\"></path><text x=\"605.0\" y=\"196.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">plan: trava</text></svg>", "caption": "Um objeto de trava, criado só se ainda não existir: a segunda execução falha ou espera, e nunca grava junto com a primeira.", "same": ["bucket", "terminal 1", "terminal 2", "plan: 412"]}
```

**Antes de o S3 conseguir fazer isso sozinho**, o backend S3 guardava as travas numa tabela do
DynamoDB, indicada com `dynamodb_table`. Você vai encontrar isso na maioria das configurações escritas
antes da mudança. A tabela é mais uma coisa para criar e pagar, e o Terraform atual marca o argumento
como deprecated em favor do `use_lockfile`.

## Quando a trava sobrevive à execução

Uma execução que termina normalmente remove a sua trava, e uma interrompida com Ctrl-C também. Uma
execução *morta*, por um laptop que perde a energia, um runner de CI recolhido ou um `kill -9`, não
remove nada. A Ana faz uma segunda mudança, inicia o apply no primeiro terminal, e o processo morre na
pergunta:

```
ana@laptop:~/shop$ sed -i 's/{ Name = "shop-a" }/{ Name = "shop-a", Environment = "dev" }/' main.tf
```

```
ana@laptop:~/shop$ terraform plan 2>&1 | grep -A 7 "Lock Info"
│ Lock Info:
│   ID:        59944514-fb19-86ba-d242-b8c55f2168ca
│   Path:      shop-tfstate-123456789012/shop/terraform.tfstate
│   Operation: OperationTypeApply
│   Who:       ana@vm
│   Version:   1.16.4
│   Created:   2026-10-02 03:52:35.945232236 +0000 UTC
│   Info:      
```

```
ana@laptop:~/shop$ aws s3 cp s3://shop-tfstate-123456789012/shop/terraform.tfstate.tflock - | jq .
{
  "ID": "59944514-fb19-86ba-d242-b8c55f2168ca",
  "Operation": "OperationTypeApply",
  "Info": "",
  "Who": "ana@vm",
  "Version": "1.16.4",
  "Created": "2026-10-02T03:52:35.945232236Z",
  "Path": "shop-tfstate-123456789012/shop/terraform.tfstate"
}
```

Ninguém segura mais essa trava, e toda execução vai falhar nela até que seja removida:

```
ana@laptop:~/shop$ terraform force-unlock -force 59944514-fb19-86ba-d242-b8c55f2168ca
Terraform state has been successfully unlocked!

The state has been unlocked, and Terraform commands should now be able to
obtain a new lock on the remote state.
ana@laptop:~/shop$ terraform apply -auto-approve | tail -n 1
Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
```

**O `force-unlock` só é seguro quando você sabe que quem segura a trava morreu.** Aqui o processo não
existia mais e o `Who` apontava para a própria máquina da Ana, então ela podia ter certeza. Usado numa
execução que só está lenta, ele deixa entrar um segundo escritor junto com o primeiro, que é
exatamente a atualização perdida que a trava existia para impedir. A flag `-force` pula a pergunta de
confirmação; sem ela, o Terraform pergunta antes. O mesmo vale para o `-lock=false`, que a própria
mensagem de erro diz não ser recomendado.
