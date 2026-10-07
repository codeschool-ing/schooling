---
title: O plano como dado, e uma trava que o lê
version: 2
---

O texto de um plano é escrito para pessoas: colunas alinhadas, atributos inalterados escondidos, um
resumo. **Um programa nunca deveria interpretar esse texto.** O layout dele não é uma promessa e
muda entre versões. O mesmo plano está disponível em JSON, e esse formato é versionado de
propósito:

```
ana@laptop:~/shop$ terraform show -json tfplan | jq '{format_version, terraform_version, n: (.resource_changes | length)}'
{
  "format_version": "1.2",
  "terraform_version": "1.16.4",
  "n": 12
}
```

Aqui ele roda sobre o plano salvo da seção anterior, como estava antes de ser aplicado. A parte de
que uma verificação precisa é `resource_changes`, uma entrada por recurso, cada uma com uma lista
de ações:

```
ana@laptop:~/shop$ terraform show -json tfplan | jq -c '.resource_changes[] | {address, actions: .change.actions}'
{"address":"data.aws_iam_policy_document.assets_read","actions":["read"]}
{"address":"aws_iam_role.web","actions":["no-op"]}
{"address":"aws_iam_role_policy.web_assets","actions":["create"]}
{"address":"aws_instance.web","actions":["delete","create"]}
{"address":"aws_s3_bucket.assets","actions":["create"]}
{"address":"aws_security_group.web","actions":["no-op"]}
{"address":"aws_subnet.a","actions":["update"]}
{"address":"aws_subnet.b","actions":["delete"]}
{"address":"aws_vpc.shop","actions":["no-op"]}
{"address":"aws_vpc_security_group_ingress_rule.https","actions":["no-op"]}
{"address":"aws_vpc_security_group_ingress_rule.ssh","actions":["no-op"]}
{"address":"random_password.db","actions":["create"]}
```

Doze entradas onde o texto mostrava sete, porque o JSON também lista cada recurso que o plano deixa
como está, como `no-op`. O resto corresponde aos símbolos: `create` é `+`, `update` é `~`, `delete`
é `-`, `read` é `<=`. **Uma substituição é uma lista de dois**, `["delete","create"]`, e com
`create_before_destroy` seria `["create","delete"]`. Então "este plano apaga alguma coisa?" tem uma
resposta de uma palavra em JSON: alguma lista contém `delete`?

Vale fazer essa pergunta por máquina porque o plano em texto facilita deixá-la passar. Uma
substituição é uma destruição, e num plano comprido ela parece só mais um bloco de linhas `~` com um
comentário no topo. A Ana escreve uma trava de poucas linhas, `check-plan.sh`, que recusa qualquer
plano que apague, pelo motivo que for:

```sh
#!/bin/sh
# Refuse a saved plan that deletes anything, replacements included.
set -eu
plan=${1:-tfplan}
deletes=$(terraform show -json "$plan" | jq -r '
  .resource_changes[]
  | select(.change.actions | index("delete"))
  | "\(.change.actions | join(","))  \(.address)"')
if [ -n "$deletes" ]; then
  echo "refused: this plan deletes"
  echo "$deletes"
  exit 1
fi
echo "ok: this plan deletes nothing"
```

Ela o torna executável com `chmod +x check-plan.sh`. `index("delete")` é o jeito do jq de perguntar
se a lista contém essa string; o `select` fica com as entradas em que contém. Rodada sobre o mesmo plano, a trava nomeia as duas exclusões, a
substituição primeiro, e falha:

```
ana@laptop:~/shop$ ./check-plan.sh tfplan; echo "exit $?"
refused: this plan deletes
delete,create  aws_instance.web
delete  aws_subnet.b
exit 1
```

Sobre um plano que só acrescenta coisas, ela passa. Este é o plano de duas seções adiante, salvo
lá com `terraform plan -out=tfplan`, que cria três recursos:

```
ana@laptop:~/shop$ ./check-plan.sh tfplan; echo "exit $?"
ok: this plan deletes nothing
exit 0
```

**Uma trava não decide; ela faz uma pessoa decidir.** A Ana e o revisor já tinham concordado em
perder a sub-rede `b` e reconstruir o `web`, e o plano foi aplicado na seção anterior. O que a trava
muda é que uma exclusão não passa mais porque ninguém a notou. Num pipeline (aula 15), uma recusa
como esta pode segurar o job até alguém aprovar a exclusão explicitamente; num laptop, é um hábito
que você roda antes do `apply tfplan`.

## O código de saída de um plano

Existe mais uma resposta legível por máquina, e ela nem precisa de JSON. Com `-detailed-exitcode`,
o `terraform plan` sai com 0 quando não há nada a fazer, 1 num erro e 2 quando há mudanças. Antes do
apply:

```
ana@laptop:~/shop$ terraform plan -detailed-exitcode > /dev/null; echo "exit $?"
exit 2
```

E depois dele, o mesmo comando não encontra nada pendente:

```
ana@laptop:~/shop$ terraform plan -detailed-exitcode > /dev/null; echo "exit $?"
exit 0
```

**Isso transforma "tem algo pendente?" numa pergunta que um job agendado pode fazer toda noite.**
Saída 2 numa configuração em que ninguém mexeu quer dizer que o mundo mudou, e a aula 7 mostrou como
é o drift quando você o encontra.
