---
title: Um apply que falha no meio
version: 2
---

É natural pensar num apply como uma transação de banco de dados: ou toda mudança do plano acontece
ou nenhuma acontece. **Ele não é uma, e não tem como ser.** Cada recurso é uma chamada separada à
API da nuvem, e não existe chamada de API que desfaça as três anteriores. Quando uma chamada falha,
o Terraform para de começar trabalho novo, mantém o que já deu certo e diz o que falhou.

A Ana acrescenta workers de batch à loja: um security group, uma sub-rede `c` e uma instância nela.
Ela digita a faixa da sub-rede de cabeça e erra um dígito, `10.30` onde a VPC é `10.20`:

```
ana@laptop:~/shop$ git diff
diff --git a/main.tf b/main.tf
index cc59f60..20936a5 100644
--- a/main.tf
+++ b/main.tf
@@ -76,3 +76,24 @@ resource "aws_iam_role_policy" "web_assets" {
 resource "random_password" "db" {
   length = 24
 }
+
+resource "aws_security_group" "batch" {
+  name        = "batch"
+  description = "batch workers"
+  vpc_id      = aws_vpc.shop.id
+}
+
+resource "aws_subnet" "c" {
+  vpc_id            = aws_vpc.shop.id
+  cidr_block        = "10.30.3.0/24"
+  availability_zone = "sa-east-1a"
+  tags              = { Name = "shop-c" }
+}
+
+resource "aws_instance" "batch" {
+  ami                    = "ami-785db401"
+  instance_type          = "t3.micro"
+  subnet_id              = aws_subnet.c.id
+  vpc_security_group_ids = [aws_security_group.batch.id]
+  tags                   = { Name = "batch" }
+}
```

A Ana salva o plano com `terraform plan -out=tfplan`. O plano sai limpo. **O Terraform confere que `10.30.3.0/24` é um CIDR válido, e ele é**; se cabe
dentro da VPC é algo que só a API sabe. A trava de duas seções atrás também passa, porque nada é
apagado. Então o apply:

```
ana@laptop:~/shop$ terraform apply tfplan; echo "exit $?"
aws_subnet.c: Creating...
aws_security_group.batch: Creating...
aws_security_group.batch: Creation complete after 1s [id=sg-0f05ca3472b6dbbca]
╷
│ Error: creating EC2 Subnet: operation error EC2: CreateSubnet, https response error StatusCode: 400, RequestID: c90SD4mAktjhE1nWlSkLjgYWfZYKv4KibyRoPxnPSPW8I43QpAJO, api error InvalidSubnet.Range: The CIDR '10.30.3.0/24' is invalid.
│ 
│   with aws_subnet.c,
│   on main.tf line 86, in resource "aws_subnet" "c":
│   86: resource "aws_subnet" "c" {
│ 
╵
exit 1
```

O security group e a sub-rede começaram juntos, já que um não precisa do outro. O grupo foi criado.
A sub-rede foi recusada pela API, aqui o moto respondendo como o EC2 responde, com
`InvalidSubnet.Range`. E a instância nem aparece no log: ela precisa do id da sub-rede, não existe
nenhum, então ela nunca foi iniciada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Um apply, três recursos novos. O security group batch foi criado e agora está no estado. A sub-rede c foi recusada pela API porque a faixa está fora da VPC. A instância batch precisa das duas, então nunca foi iniciada. Nada do que foi criado é desfeito.\"><defs><marker id=\"pa-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"pa-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30\" y=\"30\" width=\"250\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"155.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">aws_security_group.batch</text><text x=\"155.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">criado: agora está no estado</text><rect x=\"30\" y=\"160\" width=\"250\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"155.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">aws_subnet.c</text><text x=\"155.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">recusada pela API</text><rect x=\"440\" y=\"95\" width=\"250\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"565.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">aws_instance.batch</text><text x=\"565.0\" y=\"141.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nunca iniciada</text><path d=\"M282 65 L436 115\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pa-ah-phosphor)\"></path><path d=\"M282 195 L436 145\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pa-ah-amber)\"></path><text x=\"360.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o próximo plan propõe só o que falta</text></svg>", "caption": "Um apply não é uma transação. O que deu certo fica, o que falhou é reportado, e o que dependia da falha nunca rodou."}
```

**O que deu certo está no estado**, gravado no momento em que a API respondeu:

```
ana@laptop:~/shop$ terraform state list
data.aws_iam_policy_document.assets_read
aws_iam_role.web
aws_iam_role_policy.web_assets
aws_instance.web
aws_s3_bucket.assets
aws_security_group.batch
aws_security_group.web
aws_subnet.a
aws_vpc.shop
aws_vpc_security_group_ingress_rule.https
aws_vpc_security_group_ingress_rule.ssh
random_password.db
```

O `aws_security_group.batch` está lá, e nada foi desfeito. O plano seguinte propõe só o que falta:

```
ana@laptop:~/shop$ terraform plan -no-color | grep -E "^  #|Plan:"
  # aws_instance.batch will be created
  # aws_subnet.c will be created
Plan: 2 to add, 0 to change, 0 to destroy.
```

É essa propriedade que faz de um apply que falhou algo recuperável, e não uma bagunça. O Terraform
não precisa lembrar que um apply falhou; o estado já registra o que existe, então planejar de novo
compara a configuração com isso e acha a diferença, como em qualquer outro plano. A Ana corrige a
faixa para `10.20.3.0/24` e aplica de novo, e faz commit quando dá certo:

```
ana@laptop:~/shop$ terraform apply -auto-approve | tail -n 6
aws_subnet.c: Creation complete after 0s [id=subnet-ec52a070d4b58b596]
aws_instance.batch: Creating...
aws_instance.batch: Still creating... [00m10s elapsed]
aws_instance.batch: Creation complete after 10s [id=i-0f4b71b89e1e778e8]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

Dois criados, a sub-rede e a instância. O security group da execução que falhou não é criado uma
segunda vez, porque o estado diz que ele existe.

## Onde dói

Três casos transformam um apply parcial de um incômodo num incidente.

**Uma substituição que falha no meio.** Na ordem padrão, `-/+`, o objeto antigo é destruído antes
de o novo ser criado. Se a criação é a chamada que falha, o antigo já se foi e nada ocupou o lugar
dele. A aula 6 mostrou o `create_before_destroy` exatamente para isso.

**Trabalho fora do Terraform que contava com o sucesso.** Um script que roda depois do `apply` e
configura a instância nova não tem o que configurar. Confira o código de saída: o `terraform apply`
saiu com 1 lá em cima, e nada depois dele deveria rodar.

**Um plano salvo se esgota.** O apply que falhou gravou o estado, então o `tfplan` agora está
desatualizado como qualquer outro plano calculado antes de uma gravação:

```
ana@laptop:~/shop$ terraform apply tfplan; echo "exit $?"
╷
│ Error: Saved plan is stale
│ 
│ The given plan file can no longer be applied because the state was changed
│ by another operation after the plan was created.
╵
exit 1
```

O caminho é sempre um plano novo, porque só um plano novo descreve o mundo como ficou depois da
falha.
